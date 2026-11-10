---
name: implementation
description: Implement exactly one BottegaStack task with TDD, run the project checks, commit locally, and report in your final reply. Use by the builder subagent.
---

# BottegaStack Implementation

Implement exactly one task. Write code on the named branch, commit locally, and end your final reply with the report below. Load `diagnosis` if a failing check or bug blocks you; build a red-capable feedback loop before changing code.

## TDD rules

- **Red before green**, one vertical slice at a time: failing test, watch it fail for the right reason, smallest passing change. No tests-then-code slicing, no speculative features; refactoring belongs to review.
- **Test behavior, not internals:** tests read like a spec, survive refactors, and use independent expected values. Do not mock internal collaborators or private methods.
- **Pre-agree the seam:** name the public boundary the test exercises and confirm it with the user.
- **Protect existing tests:** they are evaluator inputs; never edit, delete, skip, or weaken one to pass (principle `test-behavior-not-implementation`). The only paths are `STATUS: BLOCKED` or a master-approved change under `## Test changes`.

## Read and check first

1. Project `AGENTS.md` and `GLOSSARY.md`; the run's SPEC and the task's `Allowed files`, `Test first`, and `Done when`.
2. On fix rounds the review findings in your prompt; the neighbouring code; load `verification` if the task has UI or browser criteria.
3. Work in the named worktree or use absolute paths; `git branch --show-current` must match your prompt, else report `STATUS: BLOCKED`.
4. If the code already satisfies the task, report that with evidence instead of inventing work.
5. `Allowed files` is a hard boundary (principle `stay-in-allowed-files`); needing another file means `STATUS: BLOCKED` with the path and reason.

## Build

- Make the smallest change that fully meets the task (principle `laziness-protocol`); match surrounding idioms, formatting, naming, imports, and comment density. No speculative options, fallbacks, hidden defaults, or extras; stay inside the task.
- Run scoped tests often; at the end run install if needed, lint, typecheck, test, build. No watch mode or command that rewrites files repo-wide.
- Commit locally with short one-line messages, staging explicit paths, never `git add -A`. Never push, merge into the base, or open a PR.

## Report format

Write this at the end of the round; keep a short log if there was more than one
round. It is your final reply, not a file.

```markdown
STATUS: READY | BLOCKED

# Build: <task title>

## Summary
What the branch does now.

## What changed
Files and behaviour.

## How it works
The mechanism in plain language.

## Why this choice
The trade-off and the rejected alternative.

## Evidence
Commands, results, pages, screenshots.

## Tests
What you ran and what passed.

## Test changes
Existing tests changed, skipped, or removed, and the approval. `None.` when untouched.

## Risks
What could still be wrong.

## Log
### Round <N>
What you did; on fix rounds, each finding and the response.
```

If you cannot meet the task, report `STATUS: BLOCKED` on the first line and explain exactly what blocks you under `## Blocked` (principle `never-block-on-the-human`). Do not paper over it.

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

- Committing on the wrong branch; reporting READY before the project checks pass; reusing a stale dev server from an earlier round.
- Editing a test to make it pass; fix the code or report `STATUS: BLOCKED`.
- Touching a file outside `Allowed files`; stop and report `STATUS: BLOCKED`.
- Writing the report to a file instead of ending the reply with it.
