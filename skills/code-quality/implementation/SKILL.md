---
name: implementation
description: Implement exactly one PaganiStack task with TDD, run the project checks, commit locally, and write build/<task>.md. Use by the builder subagent.
---

# PaganiStack Implementation

You implement exactly one task. You write code on the named branch and exactly
one report file, `pagani/jobs/<id>/build/<task>.md`.

## Base skills

- Load `diagnosis` if a failing check or a bug blocks the task. Build a
  red-capable feedback loop before changing code.

## TDD rules

- **Red before green.** Write the failing test first, then only enough code to
  pass it. Do not anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per
  cycle.
- **Test behavior, not internals.** Tests should read like a specification and
  survive refactors. Do not mock internal collaborators or private methods.
- **Pre-agree the seam.** Before writing the test, name the public boundary it
  exercises and confirm it with the user. A test at the wrong seam gives false
  confidence.
- **Avoid tautological tests.** Expected values must come from an independent
  source: a known-good literal, a worked example, or the spec.
- **No horizontal slicing.** Do not write all tests first and all code second;
  work in vertical slices.
- **Refactoring is not part of the loop.** It belongs to review.

## Read first

1. Project `AGENTS.md` and `GLOSSARY.md`.
2. The job `SPEC.md` and the named task.
3. The neighbouring code.
4. `verification` skill if the task has UI or browser criteria.

## Before you start

1. If a worktree is named, all code changes happen there. Start every shell
   command with `cd <worktree> && ` or use absolute paths.
2. Run `git branch --show-current`. It must match the branch in your prompt. If
   it does not, stop and report `STATUS: BLOCKED`.
3. If the task is already satisfied by the code, report that with evidence
   instead of inventing work.

## Build

- Make the smallest change that fully meets the task.
- Match the surrounding code: idioms, formatting, naming, imports, comment
  density.
- No speculative options, fallbacks, hidden defaults, or extras the spec did not
  ask for.
- Stay inside the task. Do not fix unrelated things.
- Use TDD where practical:
  1. Write the failing test at the seam the spec named.
  2. Run it and watch it fail for the right reason.
  3. Make it pass with the smallest change.
  4. Refactor.
- Run the scoped tests often. Run the project's full checks once at the end:
  install if needed, lint, typecheck, test, build.
- Do not run a watch mode, a prompt, or a command that rewrites files across the
  repo.
- Commit locally on the task branch with short one-line messages. Stage
  explicit paths, never `git add -A`.
- Never push, merge into the base branch, or open a PR. The master does that
  only when the user asks.

## Write `build/<task>.md`

Rewrite it at the end of the round. Keep a short log if the task had more than
one round.

```markdown
STATUS: READY | BLOCKED

# Build: <task title>

## Summary
What the branch does now, in a few lines.

## What changed
Files and behaviour.

## How it works
The mechanism in plain language, so a human can follow it without reading the
diff first.

## Why this choice
The trade-off and the alternative rejected.

## Evidence
The commands you ran and their results, the pages you checked, the screenshots.

## Tests
What you ran, what passed, what you added.

## Risks
What could still be wrong.

## Log
### Round <N>
What you did. On fix rounds, list each finding and what you did about it.
```

If you cannot meet the task, write `STATUS: BLOCKED` on the first line and
explain exactly what blocks you under `## Blocked`. Do not paper over a failure
to reach READY.

## Report

```
TASK: <id>
STATUS: DONE | BLOCKED | FAILED
FILES: <comma-separated changed files>
WHAT: <2-4 sentences>
DEVIATIONS: <or "none">
TESTS: <pass/fail summary>
QUESTIONS: <or "none">
```

## Gotchas

- Committing on the wrong branch. Check `git branch --show-current` first.
- Touching files outside the task. Stop and report if the task needs them.
- `git add -A` picking up unrelated files. Stage explicit paths.
- Reporting READY before the project checks pass.
- Reusing a stale dev server from an earlier round.
