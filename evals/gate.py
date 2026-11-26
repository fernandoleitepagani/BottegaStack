#!/usr/bin/env python3
"""Regression gate: compare an eval run with the saved baseline. Makes no model calls.

Usage:
  python3 evals/gate.py evals/results/<stamp>.jsonl          # compare with evals/baseline.jsonl
  python3 evals/gate.py NEW.jsonl --baseline OTHER.jsonl
  python3 evals/gate.py --promote A.jsonl [B.jsonl ...]       # save runs as the new baseline

Flags, per task and arm, and exits 1 when any is found:
  - pass rate dropped (correctness checks)
  - behavior pass rate dropped (maestro's rules, bottega arm)
  - a check that passed in every baseline trial now fails in some trial
  - mean fresh tokens rose more than --token-jump (default 30%)
  - mean cost rose more than --cost-jump (default 30%); cache reads drive cost, not fresh tokens
Reports, without failing: improvements, new tasks with no baseline, tasks the run skipped.
"""
import argparse
import json
import os
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
BASELINE = os.path.join(HERE, "baseline.jsonl")


def load(paths):
    rows = []
    for p in paths:
        with open(p) as f:
            rows += [json.loads(line) for line in f if line.strip()]
    return rows


def group(rows):
    out = defaultdict(list)
    for r in rows:
        out[(r["task"], r["arm"])].append(r)
    return out


def stats(rs):
    behav = [r["behavior_pass"] for r in rs if r.get("behavior_pass") is not None]
    toks = [r["tokens"] for r in rs if r.get("tokens") is not None]
    costs = [r["cost_usd"] for r in rs if r.get("cost_usd") is not None]
    checks = defaultdict(list)
    for r in rs:
        for c in r["checks"]:
            checks[c["name"]].append(c["pass"])
    return {
        "n": len(rs),
        "pass": sum(r["pass"] for r in rs) / len(rs),
        "behavior": sum(behav) / len(behav) if behav else None,
        "tokens": sum(toks) / len(toks) if toks else None,
        "cost": sum(costs) / len(costs) if costs else None,
        "denied": sum(r.get("denied") or 0 for r in rs),
        "checks": checks,
        "setup": {(r.get("model"), r.get("effort")) for r in rs},
    }


def pct(x):
    return "-" if x is None else f"{x:.0%}"


def promote(paths, merge=False):
    latest = {}
    src = ([BASELINE] if merge and os.path.exists(BASELINE) else []) + list(paths)
    for p in src:  # later files win for the same task and arm (replacing all its trials)
        by_key = group(load([p]))
        for key, rs in by_key.items():
            latest[key] = sorted(rs, key=lambda r: r["trial"])
    with open(BASELINE, "w") as f:
        for key in sorted(latest):
            for r in latest[key]:
                f.write(json.dumps(r) + "\n")
    mode = "merged" if merge else "replaced"
    print(f"baseline ({mode}): {len(latest)} task/arm pairs from {len(paths)} file(s) -> {os.path.relpath(BASELINE)}")


def compare(new_path, base_path, jump, cost_jump):
    base, new = group(load([base_path])), group(load([new_path]))
    bad, notes = [], []
    for key in sorted(new):
        task, arm = key
        n = stats(new[key])
        if key not in base:
            notes.append(f"{task} [{arm}]: new, no baseline (pass {pct(n['pass'])})")
            continue
        b = stats(base[key])
        tag = f"{task} [{arm}]"
        if n["setup"] != b["setup"]:
            notes.append(f"{tag}: model/effort differ from baseline {sorted(b['setup'])} vs {sorted(n['setup'])}")
        if n["pass"] < b["pass"]:
            bad.append(f"{tag}: pass rate {pct(b['pass'])} -> {pct(n['pass'])}")
        elif n["pass"] > b["pass"]:
            notes.append(f"{tag}: pass rate improved {pct(b['pass'])} -> {pct(n['pass'])}")
        if b["behavior"] is not None and n["behavior"] is not None:
            if n["behavior"] < b["behavior"]:
                bad.append(f"{tag}: behavior {pct(b['behavior'])} -> {pct(n['behavior'])}")
            elif n["behavior"] > b["behavior"]:
                notes.append(f"{tag}: behavior improved {pct(b['behavior'])} -> {pct(n['behavior'])}")
        elif b["behavior"] is None and n["behavior"] is not None and n["behavior"] < 1.0:
            bad.append(f"{tag}: behavior newly failing (- -> {pct(n['behavior'])})")
        elif b["behavior"] is not None and n["behavior"] is None:
            notes.append(f"{tag}: behavior grading dropped ({pct(b['behavior'])} -> -)")
        if n["denied"] > 0:
            notes.append(f"{tag}: {n['denied']} permission denial(s)")
        for name, results in n["checks"].items():
            was = b["checks"].get(name)
            if was and all(was) and not all(results):
                bad.append(f"{tag}: check '{name}' newly fails")
        if b["tokens"] and n["tokens"]:
            change = n["tokens"] / b["tokens"] - 1
            if change > jump:
                bad.append(f"{tag}: fresh tokens +{change:.0%} ({b['tokens']:.0f} -> {n['tokens']:.0f})")
            elif change < -jump:
                notes.append(f"{tag}: fresh tokens {change:.0%} ({b['tokens']:.0f} -> {n['tokens']:.0f})")
        if b["cost"] and n["cost"]:
            change = n["cost"] / b["cost"] - 1
            if change > cost_jump:
                bad.append(f"{tag}: cost +{change:.0%} (${b['cost']:.3f} -> ${n['cost']:.3f})")
            elif change < -cost_jump:
                notes.append(f"{tag}: cost {change:.0%} (${b['cost']:.3f} -> ${n['cost']:.3f})")
    for key in sorted(set(base) - set(new)):
        notes.append(f"{key[0]} [{key[1]}]: in baseline, not in this run")

    for line in notes:
        print(f"note  {line}")
    for line in bad:
        print(f"FAIL  {line}")
    single = any(len(rs) == 1 for rs in new.values())
    if bad and single:
        tasks = sorted({line.split(" [")[0] for line in bad})
        print(f"\nOne trial per task is noisy. Confirm before acting:\n"
              f"  python3 evals/run.py --tasks {','.join(tasks)} --trials 3")
    print(f"\n{'regressions: ' + str(len(bad)) if bad else 'no regressions'} "
          f"({len(new)} task/arm pairs vs {os.path.relpath(base_path)})")
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run", nargs="*")
    ap.add_argument("--baseline", default=BASELINE)
    ap.add_argument("--token-jump", type=float, default=0.30)
    ap.add_argument("--cost-jump", type=float, default=0.30)
    ap.add_argument("--promote", action="store_true", help="save the given runs as the baseline")
    ap.add_argument("--merge", action="store_true", help="with --promote, merge into existing baseline instead of replacing it")
    args = ap.parse_args()
    if not args.run:
        ap.error("give a results .jsonl file")
    if args.promote:
        promote(args.run, merge=args.merge)
        return
    if len(args.run) != 1:
        ap.error("compare takes one results file")
    if not os.path.exists(args.baseline):
        sys.exit(f"no baseline at {args.baseline}; save one with --promote <results.jsonl>")
    sys.exit(compare(args.run[0], args.baseline, args.token_jump, args.cost_jump))


if __name__ == "__main__":
    main()
