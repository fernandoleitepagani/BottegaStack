#!/usr/bin/env python3
"""Install bottega's status line into ~/.claude/settings.json, touching only `statusLine`.

Usage:
  set-statusline.py --check          print only the current statusLine value, never the rest of the file
  set-statusline.py --print-command  print the statusLine command that would be installed; writes nothing
  set-statusline.py                  copy statusline.py, back up and replace statusLine

statusline.py is copied (atomically, mode 0644) to ~/.claude/bottega/statusline.py and statusLine
points at that copy, so plugin updates or moves cannot break it. Re-running refreshes the copy.
Before writing, a non-bottega statusLine is saved to ~/.claude/statusline.backup.json (or
statusline.backup-<UTC stamp>.json if that exists with a different value), and the whole file is
copied to ~/.claude/settings.json.bottega-backup-<UTC stamp> (same permissions). Backups are never
overwritten and their contents are never printed; only their paths are. The old fixed name
settings.json.bottega-backup is only read by other tools, never written. The settings write is
atomic. Other keys keep their values; JSON formatting is normalized.
"""
import json
import os
import shlex
import shutil
import sys
import time

CLAUDE = os.path.join(os.path.expanduser("~"), ".claude")
SETTINGS = os.path.join(CLAUDE, "settings.json")
BACKUP_LINE = os.path.join(CLAUDE, "statusline.backup.json")
STABLE = os.path.join(CLAUDE, "bottega", "statusline.py")
SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "statusline.py")


def load():
    if not os.path.exists(SETTINGS):
        return {}
    with open(SETTINGS) as f:
        data = json.load(f)
    if not isinstance(data, dict):
        sys.exit("error: settings.json is not a JSON object; not touching it")
    return data


def command():
    return f"python3 {shlex.quote(STABLE)}"


def unique(path_fmt, stamp):
    path, n = path_fmt.format(stamp), 1
    while os.path.exists(path):
        path = path_fmt.format(f"{stamp}-{n}")
        n += 1
    return path


def install_copy():
    os.makedirs(os.path.dirname(STABLE), exist_ok=True)
    tmp = STABLE + ".tmp"
    shutil.copyfile(SCRIPT, tmp)
    os.chmod(tmp, 0o644)
    os.replace(tmp, STABLE)


def main():
    if "--print-command" in sys.argv[1:]:
        print(command())
        return
    try:
        data = load()
    except ValueError as e:
        sys.exit(f"error: settings.json is not valid JSON ({e}); not touching it")
    current = data.get("statusLine")
    if "--check" in sys.argv[1:]:
        print(json.dumps(current) if current is not None else "no statusLine set")
        return

    stamp = time.strftime("%Y%m%d-%H%M%S", time.gmtime())
    is_ours = isinstance(current, dict) and "statusline.py" in str(current.get("command", ""))
    if current is not None and not is_ours:
        target = BACKUP_LINE
        if os.path.exists(target):
            try:
                with open(target) as f:
                    same = json.load(f) == current
            except (OSError, ValueError):
                same = False
            target = None if same else unique(os.path.join(CLAUDE, "statusline.backup-{}.json"), stamp)
        if target:
            os.makedirs(CLAUDE, exist_ok=True)
            with open(target, "w") as f:
                json.dump(current, f, indent=2)
            print(f"saved the previous statusLine to {target}")
    if os.path.exists(SETTINGS):
        backup = unique(SETTINGS + ".bottega-backup-{}", stamp)
        shutil.copy2(SETTINGS, backup)
        print(f"backed up settings.json to {backup}")

    install_copy()
    data["statusLine"] = {"type": "command", "command": command(), "refreshInterval": 2}
    os.makedirs(CLAUDE, exist_ok=True)
    tmp = SETTINGS + ".tmp"
    mode = os.stat(SETTINGS).st_mode & 0o777 if os.path.exists(SETTINGS) else 0o600
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, mode)
    with os.fdopen(fd, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, SETTINGS)
    print(f"statusLine set to: {command()}")


if __name__ == "__main__":
    main()
