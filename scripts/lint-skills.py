#!/usr/bin/env python3
"""Repo lint for bottega skill content. Run from the repo root. Exit 1 on any problem.

Checks that prose alone can't keep in sync:
- every skills/<dir>/SKILL.md has frontmatter whose name matches <dir> and a description
- disable-model-invocation is true everywhere except the skills in AUTO_INVOKE
- SKILLS-INDEX.md lists each non-principle skill exactly once, and nothing that doesn't exist
- delegate.md's Principles index names each principles.md section exactly once
- the README, guide and HANDOFF counts of skills and principles match the files
- no doc or skill names a skill that isn't bundled (CUT lists the removed ones)
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS = os.path.join(ROOT, "skills")
AUTO_INVOKE = set()
NOT_INDEXED = {"maestro"}
problems = []


def read(*parts):
    with open(os.path.join(ROOT, *parts), encoding="utf-8") as f:
        return f.read()


def frontmatter(text):
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    fm = {}
    for line in m.group(1).splitlines():
        k, sep, v = line.partition(":")
        if sep:
            fm[k.strip()] = v.strip()
    return fm


skills = sorted(d for d in os.listdir(SKILLS) if os.path.isfile(os.path.join(SKILLS, d, "SKILL.md")))
for d in sorted(os.listdir(SKILLS)):
    if os.path.isdir(os.path.join(SKILLS, d)) and d not in skills:
        problems.append(f"skills/{d}: no SKILL.md")

for s in skills:
    fm = frontmatter(read("skills", s, "SKILL.md"))
    where = f"skills/{s}/SKILL.md"
    if fm is None:
        problems.append(f"{where}: missing frontmatter")
        continue
    if fm.get("name") != s:
        problems.append(f"{where}: name '{fm.get('name')}' does not match directory")
    if not fm.get("description"):
        problems.append(f"{where}: missing description")
    dmi = fm.get("disable-model-invocation") == "true"
    if s in AUTO_INVOKE and dmi:
        problems.append(f"{where}: must stay model-invocable")
    if s not in AUTO_INVOKE and not dmi:
        problems.append(f"{where}: missing disable-model-invocation: true")

principles = [t.strip() for t in re.findall(r"^## (.+)$", read("skills", "maestro", "references", "principles.md"), re.M)]
others = [s for s in skills if s not in NOT_INDEXED]

index = re.findall(r"^- `([a-z0-9-]+)`", read("skills", "maestro", "SKILLS-INDEX.md"), re.M)
for s in others:
    n = index.count(s)
    if n != 1:
        problems.append(f"SKILLS-INDEX.md: '{s}' listed {n} times, want 1")
for s in set(index) - set(others):
    problems.append(f"SKILLS-INDEX.md: '{s}' is not a bundled skill")

delegate = read("skills", "maestro", "references", "delegate.md")
section = delegate.split("## Principles", 1)[1].split("\n## ", 1)[0]
named = [m.group(1).rstrip(".") for m in re.finditer(r"^- \*\*([^*]+?)\.?\*\*", section, re.M)]
for t in principles:
    if named.count(t) != 1:
        problems.append(f"delegate.md Principles: '{t}' listed {named.count(t)} times, want 1")
for t in set(named) - set(principles):
    problems.append(f"delegate.md Principles: '{t}' has no section in principles.md")

words = {8: "eight", 9: "nine", 10: "ten", 11: "eleven", 12: "twelve", 13: "thirteen", 14: "fourteen", 15: "fifteen", 16: "sixteen", 17: "seventeen"}
COUNTED = (
    ["README.md", "evals/README.md"]
    + ["docs/guide/" + f for f in sorted(os.listdir(os.path.join(ROOT, "docs", "guide"))) if f.endswith(".md")]
    + [f"harnesses/{h}/README.md" for h in sorted(os.listdir(os.path.join(ROOT, "harnesses")))
       if os.path.isfile(os.path.join(ROOT, "harnesses", h, "README.md"))]
)
for path in COUNTED:
    text = read(*path.split("/"))
    for kind, want in (("skills", len(skills)), ("principles", len(principles))):
        for m in re.finditer(r"\b(\d+|[A-Z]?[a-z]+teen|eight|nine|ten)\s+(?:bundled\s+)?" + kind + r"\b", text):
            got = m.group(1).lower()
            if got.isdigit() or got in words.values():
                if got not in (str(want), words.get(want, "")):
                    problems.append(f"{path}: says '{m.group(0)}', there are {want} {kind}")

# Skills that were cut must not be named as live anywhere a user or agent reads.
CUT = ["understand", "crossfire", "parallel", "architect", "wayfinder", "figure-it-out", "setup-maestro", "pr",
       "grill", "unattended",
       "interface-review", "better-interface", "better-accessibility", "better-colors", "better-layout",
       "better-typography", "better-ui", "better-writing", "tdd"]
CUT_REF = re.compile(r"(?:`/?|/)(" + "|".join(re.escape(c) for c in CUT) + r")(?:`| skill)")
LIVE = ["harnesses/claude/agents/maestro-agent.md"] + COUNTED
for dirpath, _, files in os.walk(SKILLS):
    LIVE += [os.path.relpath(os.path.join(dirpath, f), ROOT) for f in files if f.endswith(".md")]
for path in LIVE:
    for n, line in enumerate(read(*path.split(os.sep if os.sep in path else "/")).splitlines(), 1):
        if "Pocock" in line or "mattpocock" in line:
            continue
        for m in CUT_REF.finditer(line):
            if m.group(1) == "crossfire" and line[m.end():].startswith((" row", "\" row")):
                continue
            problems.append(f"{path}:{n}: names cut skill '{m.group(1)}'")

# Bundled file references: a backticked or linked path to a bundled .md or script resolves from
# the file's own dir, the maestro skill dir (`references/`, `scripts/`), or the
# skills dir. Runtime paths (.bottega/, ~/, a user project's files) are not bundled, so skipped.
MAESTRO = os.path.join(SKILLS, "maestro")
REF = re.compile(r"(?:`|\]\()((?:<maestro dir>/|<skills dir>/|\.\./|references/|scripts/)(?:[\w.-]+/)*[\w.-]+\.(?:md|sh|py|mjs))[`)#]")
for base_dir in (SKILLS, os.path.join(ROOT, "harnesses", "claude", "agents")):
    for dirpath, _, files in os.walk(base_dir):
        for f in files:
            if not f.endswith(".md"):
                continue
            path = os.path.join(dirpath, f)
            rel = os.path.relpath(path, ROOT)
            parts = os.path.relpath(dirpath, SKILLS).split(os.sep)
            skill_root = os.path.join(SKILLS, parts[0]) if base_dir == SKILLS and parts[0] != "." else MAESTRO
            for n, line in enumerate(open(path, encoding="utf-8"), 1):
                for m in REF.finditer(line):
                    ref = m.group(1)
                    if ref.startswith("<maestro dir>/"):
                        cands = [os.path.join(MAESTRO, ref[len("<maestro dir>/"):])]
                    elif ref.startswith("<skills dir>/"):
                        cands = [os.path.join(SKILLS, ref[len("<skills dir>/"):])]
                    else:  # relative: from this file, from its skill's root, or from maestro (agents)
                        cands = [os.path.join(dirpath, ref), os.path.join(skill_root, ref), os.path.join(MAESTRO, ref)]
                    if not any(os.path.exists(c) for c in cands):
                        problems.append(f"{rel}:{n}: '{ref}' does not resolve to a bundled file")

for p in problems:
    print(p)
print(f"{len(skills)} skills, {len(principles)} principles, {len(problems)} problems")
sys.exit(1 if problems else 0)
