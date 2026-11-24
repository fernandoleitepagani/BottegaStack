#!/usr/bin/env python3
"""Files a maestro run changed, for gate-check.sh. Read-only on the repo.

Usage:
  run-files.py snapshot <state dir>   record HEAD and a hash of every dirty file
  run-files.py changed <state dir>    print each file changed since the snapshot, one per line
  run-files.py outside <glob>...      read files on stdin, print those no glob matches

"Changed" means a file whose content differs from the snapshot (edited, created, deleted, or
reverted to clean) or that a commit since the snapshot touched. A file already dirty at the start
and left alone does not count, so the user's own unrelated edits never block the gate. Paths are
relative to the repo root and skip `.bottega/`. Exit 3 outside a git work tree, or with no
snapshot. A glob matches by fnmatch, by exact path, or as a directory prefix ending in `/`.
"""
import fnmatch
import json
import os
import subprocess
import sys

SNAPSHOT = "run-start.json"


def git(*args):
    p = subprocess.run(["git", "-c", "core.quotePath=false", *args], capture_output=True, text=True)
    return p.returncode, p.stdout


def ours(path):
    return path == ".bottega" or path.startswith(".bottega/") or "/.bottega/" in path


def dirty(root):
    code, out = git("-C", root, "status", "--porcelain=v1", "-uall")
    paths = []
    for line in out.splitlines():
        path = line[3:]
        if " -> " in path:  # a rename: the new path is what exists now
            path = path.split(" -> ", 1)[1]
        if path.startswith('"') and path.endswith('"'):
            path = path[1:-1]
        if path and not ours(path):
            paths.append(path)
    hashes = {}
    present = [p for p in paths if os.path.isfile(os.path.join(root, p))]
    if present:
        p = subprocess.run(["git", "-C", root, "hash-object", "--stdin-paths"],
                           input="\n".join(present) + "\n", capture_output=True, text=True)
        hashes = dict(zip(present, p.stdout.split()))
    return {p: hashes.get(p, "deleted") for p in paths}


def root_or_exit():
    code, out = git("rev-parse", "--show-toplevel")
    if code != 0:
        sys.exit(3)
    return out.strip()


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == "outside":
        globs = sys.argv[2:]
        for f in sys.stdin.read().splitlines():
            if f and not any(f == g or fnmatch.fnmatch(f, g) or (g.endswith("/") and f.startswith(g))
                             for g in globs):
                print(f)
        return
    if len(sys.argv) != 3 or cmd not in ("snapshot", "changed"):
        sys.exit(__doc__)
    root = root_or_exit()
    path = os.path.join(sys.argv[2], SNAPSHOT)
    if cmd == "snapshot":
        code, head = git("-C", root, "rev-parse", "--verify", "--quiet", "HEAD")
        os.makedirs(sys.argv[2], exist_ok=True)
        with open(path, "w") as f:
            json.dump({"head": head.strip() if code == 0 else None, "dirty": dirty(root)}, f)
        return
    try:
        with open(path) as f:
            snap = json.load(f)
    except (OSError, ValueError):
        sys.exit(3)
    before, now = snap.get("dirty", {}), dirty(root)
    changed = {p for p, h in now.items() if before.get(p) != h}
    changed |= {p for p in before if p not in now}
    code, head = git("-C", root, "rev-parse", "--verify", "--quiet", "HEAD")
    if snap.get("head") and code == 0 and head.strip() != snap["head"]:
        _, out = git("-C", root, "diff", "--name-only", snap["head"], "HEAD")
        changed |= {p for p in out.splitlines() if p and not ours(p)}
    elif not snap.get("head") and code == 0:
        _, out = git("-C", root, "ls-files")
        changed |= {p for p in out.splitlines() if p and not ours(p)}
    for p in sorted(changed):
        print(p)


if __name__ == "__main__":
    main()
