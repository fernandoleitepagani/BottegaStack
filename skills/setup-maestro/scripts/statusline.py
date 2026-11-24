#!/usr/bin/env python3
"""Bottega status line: model and effort, context bar, cache state, subagents.

Reads Claude Code's status line JSON on stdin and prints one line. Also writes
.bottega/status.json so the agent can read context and cache state, and prunes
old progress files in .bottega/agents/. Debug aid: if BOTTEGA_STATUSLINE_DEBUG is a file path,
one JSON line of the input's dotted key paths (never values) is appended to it.

Fields read (https://code.claude.com/docs/en/statusline): model.display_name,
effort.level, context_window.used_percentage, context_window.context_window_size,
context_window.total_input_tokens (current context: input + cache reads and
writes, not cumulative), context_window.current_usage (summed as fallback),
prompt_cache.warm and prompt_cache.expires_at (Claude Code 2.1.251+; on older
versions the field is absent, cache shows "?" and the cold-cache rule is inert),
workspace.project_dir.

Progress files (.bottega/agents/<name>.json) hold name, model, effort, state
(running|done|failed), started, finished, and optionally phase, step and total
(rendered "3/5"), and stuck_after (seconds of silence before "quiet").
"""
import json
import os
import sys
import time

DONE_TTL = 600         # drop done/failed progress files after 10 minutes
QUIET_AFTER = 300      # a running file untouched this long shows "quiet" (override per file: stuck_after)
ABANDONED_AFTER = 86400  # a running file untouched for a day is from a dead session: drop it


def pick(d, *paths, default=None):
    for path in paths:
        cur = d
        for key in path.split("."):
            if isinstance(cur, dict) and key in cur:
                cur = cur[key]
            else:
                cur = None
                break
        if cur is not None:
            return cur
    return default


def key_paths(obj, prefix=""):
    out = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            path = f"{prefix}.{k}" if prefix else str(k)
            out.append(path)
            out.extend(key_paths(v, path))
    return out


def human(n):
    if n is None:
        return "?"
    n = float(n)
    return f"{n / 1000:.0f}k" if n >= 1000 else f"{n:.0f}"


def bar(pct, width=10):
    pct = max(0.0, min(100.0, float(pct or 0)))
    full = int(round(pct / 100 * width))
    return "█" * full + "░" * (width - full)


def elapsed(seconds):
    seconds = int(max(0, seconds))
    return f"{seconds // 60}m{seconds % 60:02d}s" if seconds >= 60 else f"{seconds}s"


def mtime_age(path, now):
    try:
        return now - os.path.getmtime(path)
    except OSError:
        return 0


def remove(path):
    try:
        os.remove(path)
    except OSError:
        pass


def agents_summary(agent_dir, now):
    running, done, lines, quiet = 0, 0, [], []
    try:
        names = sorted(os.listdir(agent_dir))
    except OSError:
        return 0, 0, [], []
    for name in names:
        if not name.endswith(".json"):
            continue
        path = os.path.join(agent_dir, name)
        try:
            with open(path) as f:
                info = json.load(f)
        except (OSError, ValueError):
            continue
        state = info.get("state", "running")
        started = float(info.get("started") or now)
        finished = float(info.get("finished") or 0)
        if state in ("done", "failed"):
            age = now - finished if finished else mtime_age(path, now)
            if age > DONE_TTL:
                remove(path)
                continue
            done += 1
            continue
        # Heartbeat: time since the file last changed. Delegates rewrite it at every step,
        # so a long silence means the agent is stuck, looping, or its session died.
        beat = mtime_age(path, now)
        if beat > ABANDONED_AFTER:
            remove(path)
            continue
        running += 1
        label = f"{info.get('name', name[:-5])} {elapsed(now - started)}"
        step, total = info.get("step"), info.get("total")
        if isinstance(step, int) and isinstance(total, int) and total > 0:
            label += f" {step}/{total}"
        if info.get("phase"):
            label += f": {info['phase']}"
        try:
            limit = float(info.get("stuck_after") or QUIET_AFTER)
        except (TypeError, ValueError):
            limit = QUIET_AFTER
        if beat > limit:
            label += f" (quiet {elapsed(beat)})"
            quiet.append(info.get("name", name[:-5]))
            lines.insert(len(quiet) - 1, label)  # quiet agents first: they need a look
        else:
            lines.append(label)
    return running, done, lines, quiet


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}
    now = time.time()

    debug = os.environ.get("BOTTEGA_STATUSLINE_DEBUG")
    if debug:
        try:
            with open(debug, "a") as f:
                f.write(json.dumps({"keys": key_paths(data)}) + "\n")
        except (OSError, ValueError):
            pass

    model = pick(data, "model.display_name", "model.id", default="?")
    effort = pick(data, "effort.level", "effort", default=None)
    if isinstance(effort, dict):
        effort = None

    pct = pick(data, "context_window.used_percentage", default=None)
    used = pick(data, "context_window.total_input_tokens", default=None)
    if not used:
        cu = pick(data, "context_window.current_usage", default=None)
        if isinstance(cu, dict):
            used = sum(int(cu.get(k) or 0) for k in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens")) or used
    size = pick(data, "context_window.context_window_size", default=None)
    if pct is None and used and size:
        pct = 100.0 * float(used) / float(size)

    warm = pick(data, "prompt_cache.warm", default=None)
    expires = pick(data, "prompt_cache.expires_at", default=None)
    if warm and isinstance(expires, (int, float)) and expires < now:
        warm = False
    cache = "?" if warm is None else ("warm" if warm else "cold")

    project = pick(data, "workspace.project_dir", "workspace.current_dir", "cwd", default=os.getcwd())
    bdir = os.path.join(project, ".bottega")

    running, done, lines, quiet = agents_summary(os.path.join(bdir, "agents"), now)

    if os.path.isdir(bdir):
        status = {
            "context_pct": None if pct is None else round(float(pct), 1),
            "tokens": used,
            "context_size": size,
            "cache": cache,
            "agents_running": running,
            "agents_quiet": quiet,
            "updated": int(now),
        }
        tmp = os.path.join(bdir, ".status.json.tmp")
        try:
            with open(tmp, "w") as f:
                json.dump(status, f)
            os.replace(tmp, os.path.join(bdir, "status.json"))
        except OSError:
            pass

    parts = [f"{model}" + (f" · {effort}" if effort else "")]
    if pct is not None:
        parts.append(f"ctx {bar(pct)} {float(pct):.0f}% {human(used)}/{human(size)}")
    parts.append(f"cache {cache}")
    if running or done:
        parts.append(f"agents {running} running {done} done")
    if lines:
        parts.append(" · ".join(lines[:2]) + (f" +{len(lines) - 2}" if len(lines) > 2 else ""))
    print(" │ ".join(parts))


if __name__ == "__main__":
    main()
