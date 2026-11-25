---
name: garden
description: Periodic, buffered codebase health audit. Scan mode appends anti-patterns to .bottega/garden.md without fixing; review mode clusters the buffer, recent commits, and .bottega/followups.md into systemic fix proposals. Read-only on product code.
disable-model-invocation: true
---

# Garden

Two-stage codebase gardening and post-merge sampling audit. Keeps a lightweight buffer of recurring anti-patterns ("weeds") so you fix the soil systematically instead of playing whack-a-mole one PR at a time.

Never edit product files during a `/garden` run.

## Modes

### 1. `scan` (collect into buffer)
Use after a wave of PRs, on a target directory, or from a scheduled CI check:
1. Spawn a read-only `explorer` subagent to inspect `git log --since="2 weeks ago" --stat` (or the requested window/directory) and sample 10–15 representative commits—prioritizing larger diffs, bugfixes, and `full-send` merges.
2. Ignore one-off nits. Extract only **recurring** agent shortcuts or smells (e.g., repeated `as any` / type casts, duplicated helpers, swallowed errors, bypassed abstractions, brittle mocks, growing monolithic files).
3. Append each finding via `../maestro/scripts/bottega garden add "<pattern>" "<file:line or commit>" "<evidence>"` (writes to `.bottega/garden.md` and ensures `.bottega/.gitignore`).
4. Run `../maestro/scripts/bottega hygiene` to check `CLAUDE.md`/`AGENTS.md` line counts. Report how many entries were appended and stop. Do not fix anything yet.

### 2. `review` (cluster & propose — default)
Use every ~2 weeks (or whenever `.bottega/garden.md` has accumulated entries):
1. Read `.bottega/garden.md` (if present) and `.bottega/followups.md`. If `.bottega/garden.md` is empty or missing, run `scan` first.
2. Cluster duplicates and related symptoms into the top **2–4 systemic patterns**, each with concrete `file:line` or commit-hash citations.
3. For each pattern, recommend the highest-leverage fix: **architecture/abstraction → types → lint rule → test → docs** (ready to hand off to `/correct` or `/tickets` if the user approves).
4. Stop and report. Once the user picks which patterns to mechanize, mark or clear the reviewed entries in `.bottega/garden.md`.

Run the reply through `../unslop/SKILL.md`.
