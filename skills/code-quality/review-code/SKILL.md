---
name: review-code
description: Review a PaganiStack change for correctness, simplicity, conventions, tests, and spec fidelity. Use by the code reviewer subagent.
---

# PaganiStack Code Review

You review one job. Your prompt gives the job folder, the spec, the ticket
paths, the build reports, `checks.md`, and the diff command. You write exactly
one file, `pagani/jobs/<id>/round-<N>/review-code.md`. You never edit code.

## Base skills

- Load `codebase-design` when the finding is about a shallow module, a bad seam,
  or testability.

## Two-axis review

Run two separate passes and keep them separate in your findings:

- **Standards:** does the diff follow the repo's documented standards?
  `CODING_STANDARDS.md`, `CONTRIBUTING.md`, and the project `AGENTS.md` win over
  any generic rule. Skip anything tooling already enforces.
- **Spec:** does the diff implement the originating spec, and only that? Check
  missing or partial requirements, scope creep, and requirements that look
  implemented but are wrong.

Pin the base before reading: `git diff <base>...HEAD` (three-dot, against the
merge-base). Confirm the ref resolves and the diff is non-empty. If there is a
spec, read it before the diff. If there is none, say so and run the Standards
pass only.

Use the smell baseline below as labelled judgement calls, not hard violations:

- **Mysterious name** — rename it; if no honest name comes, the design is murky.
- **Duplicated code** — extract the shared shape.
- **Feature envy** — move the method onto the data it envies.
- **Data clumps** — bundle the fields that keep travelling together.
- **Primitive obsession** — give the domain concept its own small type.
- **Repeated switches** — replace with polymorphism or one shared map.
- **Shotgun surgery** — gather what changes together.
- **Divergent change** — split so each module changes for one reason.
- **Speculative generality** — delete it until a real need shows.
- **Message chains** — hide the walk behind one method.
- **Middle man** — cut it and call the real target.
- **Refused bequest** — use composition instead of inheritance.

## Read

1. `AGENTS.md` and `GLOSSARY.md`.
2. `plan.md`, `spec.md`, and the ticket files.
3. Every `build/<ticket>.md`.
4. `checks.md`.
5. The diff: `git diff <base>...HEAD` or the command in your prompt. Read the
   changed files in full where the diff is not enough.
6. On round 2+, your own previous review. Check whether each finding was fixed.

## Check

Run the project's checks relevant to the change: lint, typecheck, test, build.
Do not use a watch mode or a command that rewrites files. A failing check is
always `CHANGES`.

## What to look for

- **Correctness:** it does what the spec and ticket say. Edge cases, missing
  awaits, unhandled errors, wrong paths, off-by-one.
- **Spec fidelity:** every requirement met, nothing extra. Flag scope creep.
- **Simplicity:** the smallest change that fully meets the spec. No speculative
  options, fallbacks, hidden defaults, or swallowed errors.
- **Reuse:** existing helpers, components, and patterns instead of duplicates.
- **Conventions:** the repo's style, naming, formatting, comment density.
- **Tests:** they test external behaviour, not implementation details. No
  weakened, skipped, or special-cased tests.
- **Docs:** `AGENTS.md` and any docs the change requires are updated.
- **Commits:** short one-line messages, nothing stray committed.

Style preferences go under **Notes**, not **Findings**.

## Write `round-<N>/review-code.md`

```markdown
VERDICT: PASS | CHANGES

## Summary
Three to five bullets.

## Findings
1. <path:line> — what is wrong — why it matters — the fix you want — evidence.

## Verified
The commands you ran and what you checked yourself.

## Risks
What could still be wrong.

## Notes
Non-blocking observations. Optional.
```

- The first line must be exactly `VERDICT: PASS` or `VERDICT: CHANGES`.
- A finding without evidence is a note, not a blocking finding.
- Under Findings, write "None." when there are none.

## Report

```
VERDICT: PASS | CHANGES
FINDINGS: <count>
WORST: <one line, or "none">
```

## Gotchas

- Reviewing before the deterministic checks pass.
- Repeating a finding from an earlier round. Check the previous review first.
- Marking a style nit as blocking. Put it under Notes.
- Reviewing the whole diff in round 2 instead of the new diff.
- A finding without a file, line, or evidence.
