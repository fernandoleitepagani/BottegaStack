---
name: create-verification-skill
description: Use when a project has no `.claude/skills/verify-*` skill, or when its start command, ports, URLs, or proof flows are undocumented. Discover how to start the project and prove changes work, then write a project verification skill after the user approves the draft.
---

# Create a verification skill

Turn a project's real start and test path into a project skill that `verification` can load.

## Discover

1. Read `AGENTS.md`, `README.md`, `package.json`, `Makefile`, `pyproject.toml`, and `scripts/verify.conf` for start, test, lint, typecheck, and build commands.
2. Find the port and URL from scripts and config defaults. Do not print secrets or personal env values.
3. Find the flows that prove a change: routes, CLI commands, test suites, fixtures, and seed data.
4. Read `scripts/verify.conf` when present (`START_CMD`, `READY_URL`, `PORT`); prefer it over a new command.
5. Run the start command once and confirm the ready check. Run the test command once.

## Write the skill

Write only after the user has seen the draft in chat and approved it with `AskUserQuestion`.

- Create `.claude/skills/verify-<project>/SKILL.md` at the project root. Never write it into the BottegaStack repo.
- Frontmatter: `name: verify-<project>` and a trigger-rich `description`.
- Sections: **Start** (exact command and env), **Ready check** (URL or command and expected output), **Flows** (named checks with the command or steps), **Read results** (log and screenshot paths, pass/fail signal), **Stop** (cleanup).
- Point at `scripts/verify` instead of duplicating it.

## Gotchas

- Guessing ports or commands. Run each one; a skill that does not work is worse than none.
- Writing before approval. Show the draft and ask first.
- Copying secrets or personal data into the skill.
- Writing to the BottegaStack repo instead of the project root.
- Leaving a dev server running after discovery. Stop it.

## Report

```
SKILL: .claude/skills/verify-<project>/SKILL.md
EVIDENCE: <commands run and output>
GAPS: <what could not be checked, or "none">
```
