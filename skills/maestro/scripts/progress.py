#!/usr/bin/env python3
"""Write a maestro progress file, .bottega/agents/<name>.json, for the status line.

Usage:
  progress.py <name> start <model> <effort> [--total N] [--stuck-after SECONDS] [--set k=v ...]
  progress.py <name> phase "<label>" [--step N] [--set k=v ...]
  progress.py <name> done|failed [--set k=v ...]

Run from the workspace root, or pass --dir <path to .bottega/agents>. Each call rewrites
the file atomically, which also refreshes the status line's heartbeat.
"""
import argparse
import json
import os
import sys
import time


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("name")
    ap.add_argument("action", choices=["start", "phase", "done", "failed"])
    ap.add_argument("rest", nargs="*")
    ap.add_argument("--total", type=int)
    ap.add_argument("--step", type=int)
    ap.add_argument("--stuck-after", type=int)
    ap.add_argument("--set", action="append", default=[], metavar="KEY=VALUE")
    ap.add_argument("--dir", default=os.path.join(".bottega", "agents"))
    a = ap.parse_args()

    if not a.name.replace("-", "").replace("_", "").isalnum():
        sys.exit("error: name must be letters, digits, '-' or '_'")
    os.makedirs(a.dir, exist_ok=True)
    # Keep .bottega/ untracked: self-ignore the enclosing .bottega dir, never overwrite.
    parts = os.path.abspath(a.dir).split(os.sep)
    if ".bottega" in parts:
        bdir = os.sep.join(parts[: parts.index(".bottega") + 1]) or os.sep
        try:
            with open(os.path.join(bdir, ".gitignore"), "x") as g:
                g.write("*\n")
        except OSError:
            pass
    path = os.path.join(a.dir, a.name + ".json")
    try:
        with open(path) as f:
            info = json.load(f)
    except (OSError, ValueError):
        info = {}
    now = int(time.time())

    if a.action == "start":
        if len(a.rest) != 2:
            sys.exit("error: start needs <model> <effort>")
        info = {"name": a.name, "model": a.rest[0], "effort": a.rest[1], "state": "running", "started": now}
    elif a.action == "phase":
        if len(a.rest) != 1:
            sys.exit("error: phase needs one label")
        info.setdefault("name", a.name)
        info.setdefault("state", "running")
        info.setdefault("started", now)
        info["phase"] = a.rest[0]
    else:
        info.setdefault("name", a.name)
        info["state"] = a.action
        info["finished"] = now

    if a.total is not None:
        info["total"] = a.total
    if a.step is not None:
        info["step"] = a.step
    if a.stuck_after is not None:
        info["stuck_after"] = a.stuck_after
    for kv in a.set:
        key, sep, value = kv.partition("=")
        if not sep or not key:
            sys.exit(f"error: --set wants key=value, got {kv!r}")
        info[key] = int(value) if value.isdigit() else value

    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(info, f)
    os.replace(tmp, path)


if __name__ == "__main__":
    main()
