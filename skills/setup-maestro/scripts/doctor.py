#!/usr/bin/env python3
"""bottega doctor: read-only environment checks. Exit 1 if any FAIL."""
import os
import re
import shlex
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MODELS = ("opus", "sonnet", "haiku")
EFFORTS = ("low", "medium", "high")
results = []


def out(level, msg, hint=""):
    results.append(level)
    print("%-4s  %s%s" % (level, msg, ("  -> " + hint) if hint else ""))


def roles():
    try:
        text = open(os.path.join(HERE, "..", "SKILL.md"), encoding="utf-8").read()
        block = text.split("### 5.", 1)[1].split("```")[1]
    except (OSError, IndexError):
        return None
    found = set()
    for ln in block.splitlines():
        m = re.match(r"^([a-z][a-z -]*?):\s", ln)
        if m and not ln.startswith("#"):
            found.add(m.group(1))
    return found


def value_ok(role, v):
    v = v.strip()
    if v == "none":
        return True
    for item in v.split(","):
        p = item.split()
        if len(p) != 2 or p[0] not in MODELS or p[1] not in EFFORTS:
            return False
        if p[1] == "high" and p[0] != "haiku":
            return False
    return True


def check_tools():
    if sys.version_info >= (3, 9):
        out("ok", "python3 %d.%d" % sys.version_info[:2])
    else:
        out("FAIL", "python3 %d.%d is older than 3.9" % sys.version_info[:2], "install Python 3.9+")
    for tool, level, why in (("git", "FAIL", "bottega needs git"),
                             ("gh", "warn", "needed for PRs"),
                             ("node", "warn", "needed for check-plan.mjs")):
        if shutil.which(tool):
            out("ok", tool + " on PATH")
        else:
            out(level, tool + " not on PATH", "install " + tool + " (" + why + ")")


def check_rules(home):
    path = os.path.join(home, ".claude", "rules", "bottega-models.md")
    if not os.path.exists(path):
        out("ok", "model rule absent, defaults in use")
        return
    known = roles()
    bad = unknown = 0
    budget = False
    with open(path, encoding="utf-8") as f:
        for n, ln in enumerate(f, 1):
            ln = ln.strip()
            if ln.startswith("# budget"):
                budget = True
            if not ln or ln.startswith("#"):
                continue
            m = re.match(r"^([^:|]+):\s*(.*)$", ln)
            parts = m.group(2).split("|") if m else []
            if not m or len(parts) != 2:
                out("FAIL", "bottega-models.md line %d is not 'role: <normal> | <high>'" % n, "rerun /setup-maestro")
                bad += 1
                continue
            role = m.group(1).strip()
            if known is not None and role not in known:
                out("warn", "bottega-models.md line %d: unknown role '%s' (retired)" % (n, role), "rerun /setup-maestro")
                unknown += 1
            if not all(value_ok(role, p) for p in parts):
                out("FAIL", "bottega-models.md line %d: bad value for '%s'" % (n, role), "rerun /setup-maestro")
                bad += 1
    if not budget:
        out("warn", "bottega-models.md has no '# budget' line", "rerun /setup-maestro")
    if not (bad or unknown):
        out("ok", "model rule valid")


def check_statusline(home):
    import json
    path = os.path.join(home, ".claude", "settings.json")
    try:
        with open(path, encoding="utf-8") as f:
            sl = json.load(f).get("statusLine")
    except (OSError, ValueError, AttributeError):
        sl = None
    if not sl:
        out("warn", "bottega status line not installed", "run /setup-maestro")
        return
    cmd = sl.get("command", "") if isinstance(sl, dict) else ""
    if "statusline.py" not in cmd:
        out("ok", "another status line is set")
        return
    try:
        script = next(p for p in shlex.split(cmd) if p.endswith("statusline.py"))
    except (ValueError, StopIteration):
        out("FAIL", "cannot parse status line command", "rerun /setup-maestro")
        return
    if not os.path.isfile(script):
        out("FAIL", "status line script missing: " + script, "rerun /setup-maestro")
        return
    stable = os.path.join(home, ".claude", "bottega", "statusline.py")
    if os.path.abspath(script) != os.path.abspath(stable):
        out("warn", "status line points at an old plugin path: " + script, "rerun /setup-maestro")
        return
    src = os.path.join(HERE, "statusline.py")
    try:
        same = open(script, "rb").read() == open(src, "rb").read()
    except OSError:
        same = True
    if same:
        out("ok", "status line installed: " + script)
    else:
        out("warn", "status line copy is from another bottega version", "rerun /setup-maestro")


def main():
    home = os.path.expanduser("~")
    check_tools()
    check_rules(home)
    check_statusline(home)
    return 1 if "FAIL" in results else 0


if __name__ == "__main__":
    sys.exit(main())
