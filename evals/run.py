#!/usr/bin/env python3
"""bottega eval harness. Runs small fixed tasks headless, with and without bottega, and grades them.

Usage:
  python3 evals/run.py --selftest                 # check fixtures and graders, no model calls
  python3 evals/run.py --dry-run                  # print the claude commands, no model calls
  python3 evals/run.py [--tasks a,b] [--arms bottega,baseline] [--trials 1]
                       [--model sonnet] [--effort low] [--timeout 900] [--keep]

Each run copies tasks/<task>/repo into a fresh git repo under a neutral temp name, runs
`claude -p` there, then copies tasks/<task>/hidden in and runs the task's grade checks.
Results append to evals/results/<stamp>.jsonl and print as a per-arm summary.
See evals/README.md for the plan and the token budget.
"""
import argparse
import concurrent.futures
import fnmatch
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
TASKS = os.path.join(HERE, "tasks")
GATE_CHECK = os.path.join(REPO, "skills", "maestro", "scripts", "gate-check.sh")
RESULTS = os.path.join(HERE, "results")
NAMES = ["ledger", "atlas", "harbor", "kiln", "orchard", "quarry"]
# Non-Bash tools are allowed by name. Every Bash command is allowed, but runs inside Claude
# Code's OS sandbox: writes only to the work dir and a per-user temp dir, no network, and no
# unsandboxed escape hatch. A per-command allowlist denied compound commands and heredocs,
# which skewed results against bottega, whose verification steps use them most.
ALLOWED = ["Read", "Edit", "Write", "Glob", "Grep", "Agent", "Skill", "TodoWrite", "TaskCreate", "TaskUpdate"]


SETTINGS = None  # set in main(); see sandbox_settings()


def installed_bottega():
    """Ids of any bottega plugin installed for this user (e.g. "bottega@bottega"). Each run
    disables them, so the baseline arm stays plain and the bottega arm loads only the copy
    under test. Empty when the CLI can't list plugins."""
    try:
        out = subprocess.run(["claude", "plugin", "list", "--json"], capture_output=True, text=True,
                             timeout=60).stdout
        return sorted(p["id"] for p in json.loads(out) if str(p.get("id", "")).startswith("bottega@"))
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired):
        return []


def sandbox_settings():
    return json.dumps({
        "sandbox": {"enabled": True, "autoAllowBashIfSandboxed": True, "allowUnsandboxedCommands": False},
        "permissions": {"allow": ["Bash"]},
        "enabledPlugins": {pid: False for pid in installed_bottega()},
    })
IGNORE = "-- . ':!.bottega' ':!*__pycache__*'"


def sh(cmd, cwd, timeout=120):
    p = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True, timeout=timeout)
    return p.returncode, p.stdout + p.stderr


def load_tasks(names):
    out = []
    for path in sorted(glob.glob(os.path.join(TASKS, "*", "task.json"))):
        name = os.path.basename(os.path.dirname(path))
        if names and name not in names:
            continue
        with open(path) as f:
            task = json.load(f)
        task["name"] = name
        out.append(task)
    missing = set(names or []) - {t["name"] for t in out}
    if missing:
        sys.exit(f"unknown task(s): {', '.join(sorted(missing))}")
    return out


def make_workdir(task, i):
    root = tempfile.mkdtemp(prefix=f"{NAMES[i % len(NAMES)]}-")
    shutil.copytree(os.path.join(TASKS, task["name"], "repo"), root, dirs_exist_ok=True)
    git = "git -c user.email=dev@example.com -c user.name=dev"
    sh(f"git init -q -b main && {git} add -A && {git} commit -qm 'initial import'", root)
    return root


def plugin_copy():
    """Copy only the shipped plugin to a neutral path, so candidates can't find evals/."""
    global PLUGIN
    if PLUGIN is None:
        PLUGIN = tempfile.mkdtemp(prefix="toolkit-")
        for part in (".claude-plugin", "skills", "harnesses", "LICENSE"):
            src = os.path.join(REPO, part)
            dst = os.path.join(PLUGIN, part)
            (shutil.copytree if os.path.isdir(src) else shutil.copy)(src, dst)
    return PLUGIN


PLUGIN = None


def command(task, arm, args):
    if args.harness == "agy":
        if arm == "baseline":
            prompt = task["prompt"]
        else:
            pdir = "<plugin copy>" if args.dry_run else plugin_copy()
            prompt = f"Follow {pdir}/skills/maestro/SKILL.md. {task['prompt']}"
        return ["agy", "-p", prompt, "--model", args.model, "--effort", args.effort]
    prompt = task["prompt"] if arm == "baseline" else f"/bottega:maestro {task['prompt']}"
    cmd = [
        "claude", "-p", prompt,
        "--model", args.model, "--effort", args.effort,
        "--output-format", "stream-json", "--verbose",
        "--permission-mode", "dontAsk", "--allowedTools", *ALLOWED, "--settings", SETTINGS,
        "--no-session-persistence",
    ]
    if arm == "bottega":
        cmd += ["--plugin-dir", "<plugin copy>" if args.dry_run else plugin_copy()]
    return cmd


def parse_stream(raw):
    info = {"result": "", "turns": None, "duration_ms": None, "tokens": None,
            "cache_read": None, "cost_usd": None, "denied": 0, "tool_calls": {}, "skills_read": [],
            "tool_uses": []}
    for line in raw.splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "assistant":
            for block in ev.get("message", {}).get("content", []) or []:
                if block.get("type") != "tool_use":
                    continue
                name = block.get("name", "?")
                inp = block.get("input") or {}
                info["tool_calls"][name] = info["tool_calls"].get(name, 0) + 1
                info["tool_uses"].append((name, inp))
                m = re.search(r"skills/([^/]+)/SKILL\.md$", str(inp.get("file_path", "")))
                if name == "Read" and m:
                    info["skills_read"].append(m.group(1))
                elif name == "Skill" and inp.get("skill"):
                    info["skills_read"].append(str(inp["skill"]).split(":")[-1])
        elif ev.get("type") == "user":
            for block in ev.get("message", {}).get("content", []) or []:
                if isinstance(block, dict) and block.get("type") == "tool_result" \
                        and "has been denied" in str(block.get("content", "")):
                    info["denied"] += 1
        elif ev.get("type") == "result":
            # A run can emit several result events: when the main agent ends its turn while a
            # background delegate still runs, the delegate's return starts another. Usage and
            # turns add up; total_cost_usd is already cumulative; the answer is every result's
            # text in order, so a gate stated in the last one counts.
            text = ev.get("result", "") or ""
            info["result"] = (info["result"] + "\n\n" + text).strip()
            info["turns"] = (info["turns"] or 0) + (ev.get("num_turns") or 0)
            info["duration_ms"] = (info["duration_ms"] or 0) + (ev.get("duration_ms") or 0)
            info["cost_usd"] = max(info["cost_usd"] or 0, ev.get("total_cost_usd") or 0)
            u = ev.get("usage") or {}
            # Fresh tokens only. Cache reads re-count the same context every turn, so they
            # are kept apart: a typo fix showed 25k fresh vs 181k cache reads.
            info["tokens"] = (info["tokens"] or 0) + sum(u.get(k, 0) or 0 for k in (
                "input_tokens", "output_tokens", "cache_creation_input_tokens"))
            info["cache_read"] = (info["cache_read"] or 0) + (u.get("cache_read_input_tokens") or 0)
    return info


def changed_lines(workdir):
    base = sh("git rev-list --max-parents=0 HEAD", workdir)[1].strip()
    sh(f"git add -A {IGNORE}", workdir)
    _, out = sh(f"git diff --cached --numstat {base} {IGNORE}", workdir)
    files, total = [], 0
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) == 3:
            files.append(parts[2])
            total += sum(int(x) for x in parts[:2] if x.isdigit())
    sh("git reset -q", workdir)
    return total, files


# Behavior checks every bottega run must pass, on top of the task's own checks. They test
# maestro's rules, not the answer, so they apply only to the bottega arm.
INVARIANTS = [
    {"name": "no commit", "run": "test \"$(git rev-list --count HEAD)\" = 1"},
    {"name": "no push", "bash_absent": r"\bgit\s+push\b"},
    {"name": "subagents get a model", "agents_have_model": True},
]
# Extra rules for runs that change code (maestro's Final gate and Proof ledger).
CODE_KINDS = {"bug-fix", "feature", "refactoring"}
CODE_INVARIANTS = [
    {"name": "final gate stated", "answer_regex": r"\b(APPROVE|ESCALATE)\b", "case": True, "only_if_changed": True},
    # gate-check.sh exits 2 on a missing step (no run row, an undeclared or unproven
    # condition, a bare waiver); 0 or 1 means the ledger is complete, whatever the verdict.
    # The agent's own last gate-check call (read from tool output, never from the reply)
    # ended complete: APPROVE allowed or ESCALATE, not "incomplete". Rerunning the script at
    # grading time would see the sandbox's temporary files vanish and blame the run.
    {"name": "proof ledger complete", "gate_completed": True, "only_if_changed": True},
    # The run opens (gate-check.sh --start) before the first file edit, so its conditions and
    # its changed-files snapshot come before the work, not after it.
    {"name": "run opened before editing", "opened_first": True, "only_if_changed": True},
]


def tool_text(inp):
    return json.dumps(inp, ensure_ascii=False)


def check(g, workdir, info):
    """Run one grade entry. Returns pass/fail, plus detail for shell checks."""
    uses = info["tool_uses"]
    if "run" in g:
        code, out = sh(g["run"].replace("$GATE_CHECK", GATE_CHECK), workdir)
        return code == 0, out[-300:]
    if "answer_regex" in g:
        flags = re.S if g.get("case") else re.I | re.S
        return re.search(g["answer_regex"], info["result"], flags) is not None, ""
    if "tool_absent" in g:
        names = g["tool_absent"] if isinstance(g["tool_absent"], list) else [g["tool_absent"]]
        return not any(n in names for n, _ in uses), ""
    if "tool_max" in g:
        tool, most = g["tool_max"]
        return sum(n == tool for n, _ in uses) <= most, ""
    if "bash_absent" in g:
        return not any(n == "Bash" and re.search(g["bash_absent"], str(i.get("command", "")))
                       for n, i in uses), ""
    if "tool_input_regex" in g:
        # Some tool call (Read path, Skill name, Agent brief) matches, e.g. a crossfire spawn.
        return any(re.search(g["tool_input_regex"], n + " " + tool_text(i), re.I) for n, i in uses), ""
    if "agents_have_model" in g:
        # Every spawn names its model per the role table (maestro-agent, Explore, a skill's
        # own type). A fork inherits the parent's model by design, so it is left out.
        spawns = [i for n, i in uses if n == "Agent" and i.get("subagent_type") != "fork"]
        if not spawns:
            return None, "not applicable: 0 spawns"
        return all(i.get("model") for i in spawns), f"{len(spawns)} spawns"
    if "opened_first" in g:
        start_re = re.compile(r"(?:gate-check\.sh[^\n]*--start|\bbottega\s+start\b)")
        edit_re = re.compile(r"\bsed\s+-i|\bperl\s+-pi|\btee\b|>\s*[\w./-]+")
        first_start = first_edit = None
        for i, (n, inp) in enumerate(uses):
            cmd = str(inp.get("command", "")) if n == "Bash" else ""
            if first_start is None and start_re.search(cmd):
                first_start = i
            if first_edit is None and (n in ("Edit", "Write", "NotebookEdit", "Agent")
                                       or edit_re.search(cmd)):
                first_edit = i
        if first_start is None:
            return False, "no --start call"
        if first_edit is not None and first_start == first_edit:  # one chained command: compare positions
            cmd = str(uses[first_start][1].get("command", ""))
            ms = start_re.search(cmd)
            me = edit_re.search(cmd)
            return bool(ms and me) and ms.start() < me.start(), "start and first edit in one command"
        return first_edit is None or first_start < first_edit, f"start at call {first_start}, first edit at {first_edit}"
    if "gate_completed" in g:
        last = gate_results(info.get("raw", ""))
        if not last:
            return False, "no gate-check.sh check call in the transcript"
        return last[-1] in ("APPROVE allowed", "ESCALATE"), "last gate-check: " + last[-1]
    if "transcript_absent" in g:
        return g["transcript_absent"] not in info.get("raw", ""), ""
    raise ValueError(f"unknown check in {g}")


def gate_results(raw):
    """Verdict line of each gate-check.sh check call (not --start), in order, from tool results."""
    calls, out = {}, []
    for line in raw.splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        content = (ev.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for b in content:
            if b.get("type") == "tool_use" and b.get("name") == "Bash":
                cmd = str((b.get("input") or {}).get("command", ""))
                if "gate-check.sh" in cmd or re.search(r"\bbottega\s+verify\b", cmd):  # a --start-only call prints no verdict line
                    calls[b.get("id")] = True
            elif b.get("type") == "tool_result" and b.get("tool_use_id") in calls:
                text = b.get("content")
                if isinstance(text, list):
                    text = " ".join(x.get("text", "") for x in text if isinstance(x, dict))
                text_s = str(text)
                m = re.findall(r"gate-check: (APPROVE allowed|ESCALATE|incomplete)", text_s)
                if m:
                    out.append(m[-1])
                elif "bottega verify: checks failed" in text_s:
                    out.append("checks failed")
    return out


def grade(task, workdir, info, arm=None, changed=True):
    """Grade a finished run. arm=None (selftest) skips arm-scoped and invariant checks,
    since a reference solution has no transcript."""
    entries = [dict(g) for g in task["grade"]]
    if arm == "bottega":
        entries += [dict(g, arms=["bottega"]) for g in INVARIANTS]
        if task["kind"] in CODE_KINDS:
            entries += [dict(g, arms=["bottega"]) for g in CODE_INVARIANTS]
    # Checks of the agent's own state (the ledger) run first, on the work dir as the agent left it.
    entries.sort(key=lambda g: not g.get("before_hidden"))
    checks, copied = [], False
    try:
        for g in entries:
            if not g.get("before_hidden") and not copied:
                for src, dst in task.get("hidden", {}).items():
                    shutil.copy(os.path.join(TASKS, task["name"], "hidden", src), os.path.join(workdir, dst))
                copied = True
            scoped = g.get("arms")
            if scoped and arm not in scoped:
                continue
            if g.get("only_if_changed") and not changed:  # stopped before editing: nothing to gate
                continue
            ok, detail = check(g, workdir, info)
            if ok is None:  # the rule had nothing to judge in this run; don't score a free pass
                continue
            c = {"name": g["name"], "pass": ok, "behavior": bool(scoped or g.get("behavior"))}
            if detail:
                c["detail"] = detail
            checks.append(c)
    finally:
        for dst in task.get("hidden", {}).values():
            try:
                os.remove(os.path.join(workdir, dst))
            except OSError:
                pass
    return checks


def expect_checks(task, lines, files):
    exp, out = task.get("expect", {}), []
    if "max_changed_lines" in exp:
        out.append({"name": f"diff <= {exp['max_changed_lines']} lines",
                    "pass": lines <= exp["max_changed_lines"], "behavior": False})
    if "touch_only" in exp:
        stray = [f for f in files if not any(fnmatch.fnmatch(f, pat) for pat in exp["touch_only"])]
        out.append({"name": "touched only expected files", "pass": not stray, "behavior": False,
                    **({"detail": ", ".join(stray)} if stray else {})})
    return out


def empty_info(answer=""):
    return {"result": answer, "tool_uses": [], "raw": ""}


def run_one(task, arm, trial, args):
    workdir = make_workdir(task, trial)
    cmd = command(task, arm, args)
    start = time.time()
    try:
        try:
            env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
            p = subprocess.run(cmd, cwd=workdir, capture_output=True, text=True, timeout=args.timeout, env=env)
            raw, stderr, exit_code = p.stdout, p.stderr, p.returncode
        except subprocess.TimeoutExpired as e:
            raw = (e.stdout or b"").decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
            stderr = (e.stderr or b"").decode() if isinstance(e.stderr, bytes) else (e.stderr or "")
            exit_code = "timeout"
        if args.harness == "agy":
            info = {"result": raw.strip(), "turns": None, "duration_ms": None, "tokens": None,
                    "cache_read": None, "cost_usd": None, "denied": 0, "tool_calls": {},
                    "skills_read": [], "tool_uses": []}
        else:
            info = parse_stream(raw)
        info["raw"] = raw
        lines, files = changed_lines(workdir)
        checks = grade(task, workdir, info, arm, changed=bool(files)) + expect_checks(task, lines, files)
        row = {
            "task": task["name"], "kind": task["kind"], "arm": arm, "trial": trial,
            "model": args.model, "effort": args.effort, "exit": exit_code,
            "wall_s": round(time.time() - start, 1), "changed_lines": lines, "changed_files": files,
            "pass": all(c["pass"] for c in checks if not c["behavior"]),
            "behavior_pass": (all(c["pass"] for c in checks if c["behavior"])
                              if any(c["behavior"] for c in checks) else None),
            "checks": checks,
            **{k: info[k] for k in ("turns", "duration_ms", "tokens", "cache_read", "cost_usd", "denied",
                                    "tool_calls", "skills_read")},
        }
        transcript = os.path.join(args.out_dir, f"{task['name']}.{arm}.{trial}.jsonl")
        with open(transcript, "w") as f:
            f.write(raw)
        if stderr:
            with open(os.path.join(args.out_dir, f"{task['name']}.{arm}.{trial}.stderr.txt"), "w") as f:
                f.write(stderr)
        row["transcript"] = os.path.relpath(transcript, REPO)
        if args.keep:
            row["workdir"] = workdir
        return row
    finally:
        if not args.keep:
            shutil.rmtree(workdir, ignore_errors=True)


def summarize(rows):
    print(f"\n{'task':<22}{'arm':<10}{'pass':>6}{'behav':>7}{'fresh tok':>11}{'cost $':>8}{'turns':>7}"
          f"{'lines':>7}{'agents':>8}{'denied':>8}")
    for r in rows:
        cost = f"{r['cost_usd']:.3f}" if r["cost_usd"] is not None else "?"
        behav = {None: "-", True: "yes", False: "NO"}[r["behavior_pass"]]
        print(f"{r['task']:<22}{r['arm']:<10}{'yes' if r['pass'] else 'NO':>6}{behav:>7}"
              f"{r['tokens'] or '?':>11}{cost:>8}{r['turns'] or '?':>7}{r['changed_lines']:>7}"
              f"{r['tool_calls'].get('Agent', 0):>8}{r['denied']:>8}")
        for c in r["checks"]:
            if not c["pass"]:
                print(f"{'':<22}failed: {c['name']}" + (f" ({c['detail'][:80]})" if c.get("detail") else ""))
    for arm in sorted({r["arm"] for r in rows}):
        rs = [r for r in rows if r["arm"] == arm]
        toks = [r["tokens"] for r in rs if r["tokens"]]
        costs = [r["cost_usd"] for r in rs if r["cost_usd"] is not None]
        graded = [r for r in rs if r["behavior_pass"] is not None]
        behav = f", behavior {sum(r['behavior_pass'] for r in graded)}/{len(graded)}" if graded else ""
        print(f"{arm}: {sum(r['pass'] for r in rs)}/{len(rs)} passed{behav}, "
              f"mean fresh tokens {round(sum(toks) / len(toks)) if toks else '?'}, "
              f"total ${sum(costs):.2f}")


def _selftest_one(t):
    wd = make_workdir(t, 0)
    try:
        before = [c["name"] for c in grade(t, wd, empty_info()) if not c["pass"]]
        sol = os.path.join(TASKS, t["name"], "solution")
        answer = ""
        for f in os.listdir(sol):
            if f == "ANSWER.txt":
                with open(os.path.join(sol, f)) as fh:
                    answer = fh.read()
            else:
                src = os.path.join(sol, f)
                dst = os.path.join(wd, f)
                (shutil.copytree if os.path.isdir(src) else shutil.copy)(src, dst)
        after = grade(t, wd, empty_info(answer))
        lines, files = changed_lines(wd)
        after += expect_checks(t, lines, files)
        failing_after = [c["name"] for c in after if not c["pass"]]
        ok = bool(before) and not failing_after
        return t["name"], ok, before, failing_after
    finally:
        shutil.rmtree(wd, ignore_errors=True)


def selftest(tasks):
    """Graders must fail on the untouched fixture and pass on the reference solution,
    or the task measures nothing. Makes no model calls. Behavior checks need a transcript,
    so they are left to real runs."""
    bad = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=min(8, max(1, len(tasks)))) as pool:
        results = list(pool.map(_selftest_one, tasks))
    for name, ok, before, failing_after in results:
        bad += not ok
        print(f"{name:<22}{'ok' if ok else 'BROKEN'}  pristine fails: {before or 'nothing'}"
              f"  solution fails: {failing_after or 'nothing'}")
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tasks", default="")
    ap.add_argument("--arms", default="bottega,baseline")
    ap.add_argument("--trials", type=int, default=1)
    ap.add_argument("--harness", choices=("claude", "agy"), default="claude")
    ap.add_argument("--model", default="sonnet")
    ap.add_argument("--effort", default="low")
    ap.add_argument("--timeout", type=int, default=900)
    ap.add_argument("--keep", action="store_true", help="keep work dirs for inspection")
    ap.add_argument("--jobs", type=int, default=4, help="runs in parallel (default 4)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()

    tasks = load_tasks([t for t in args.tasks.split(",") if t])
    arms = [a for a in args.arms.split(",") if a]
    if set(arms) - {"bottega", "baseline"}:
        sys.exit("arms are bottega and baseline")
    if args.selftest:
        sys.exit(1 if selftest(tasks) else 0)
    global SETTINGS
    if args.harness == "claude":
        SETTINGS = sandbox_settings()
    if args.dry_run:
        for t in tasks:
            for a in arms:
                if a in t.get("arms", arms):
                    print(" ".join(repr(x) if " " in x else x for x in command(t, a, args)))
        return

    stamp = time.strftime("%Y%m%d-%H%M%S")
    args.out_dir = os.path.join(RESULTS, stamp)
    os.makedirs(args.out_dir, exist_ok=True)
    jobs = [(t, trial, a) for t in tasks for trial in range(args.trials) for a in arms if a in t.get("arms", arms)]
    if "bottega" in arms:
        plugin_copy()  # once, before the workers start
    rows = []
    try:
        with open(os.path.join(RESULTS, f"{stamp}.jsonl"), "w") as out, \
                concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
            print(f"{len(jobs)} runs, {max(1, args.jobs)} at a time", flush=True)
            futures = {pool.submit(run_one, t, a, trial, args): (t["name"], a, trial) for t, trial, a in jobs}
            for fut in concurrent.futures.as_completed(futures):
                name, a, trial = futures[fut]
                row = fut.result()
                print(f"done {name} [{a}] trial {trial + 1}/{args.trials}: "
                      f"{'pass' if row['pass'] else 'FAIL'}", flush=True)
                out.write(json.dumps(row) + "\n")
                out.flush()
                rows.append(row)
    finally:
        shutil.rmtree(PLUGIN or "", ignore_errors=True)
    rows.sort(key=lambda r: (r["task"], r["trial"], r["arm"]))
    summarize(rows)
    print(f"\nresults: {os.path.relpath(out.name, REPO)}")
    print("compare with the saved baseline: python3 evals/gate.py " + os.path.relpath(out.name, REPO))


if __name__ == "__main__":
    main()
