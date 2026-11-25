# Delegate brief

Shared rules for the `/maestro` orchestrator and every `maestro-agent` delegate. The orchestrator's routing, autonomy, model and reply rules live in `../SKILL.md`. A delegate does not need them.

## Your role as a delegate

- Do the one task in your brief. The orchestrator owns the ticket, the todo list, the plan, and every other spawn. Never run `/grill`, `/tickets` or `/implement` yourself, and never act as the orchestrator.
- Restate the goal from your brief in one line before you start.
- Stay inside the scope the brief names. Anything outside it goes in your report under **Open**, not into the diff.

## Principles

All 17 are in `principles.md` next to this file, one short section each. Read a section before you apply it. Each one is listed with when it applies:

- **Delete First.** Sizing a diff, or tempted to add a layer.
- **Shape Before Logic.** Before writing logic that branches a lot or repeats a shape assumption.
- **Redesign from First Principles.** Fitting a new requirement into an existing design.
- **Attack the Premise.** Two fixes sharing one premise have failed.
- **Minimize Reader Load.** Code that's hard to trace.
- **Mechanize It.** Repetitive work, or an instruction written twice.
- **Boundary Discipline.** Wiring validation, error handling, or adapters.
- **Type System Discipline.** Designing types or a signature.
- **Make Operations Idempotent.** A step that may rerun after a crash or retry.
- **Migrate Callers Then Delete Legacy APIs.** A new internal API while old callers exist.
- **Separate Before Serializing Shared State.** Concurrent writers to one file, branch, or key.
- **Prove It Works.** Before declaring done (see **Verification** below).
- **Fix Root Causes.** Debugging.
- **Sequence Work into Verifiable Units.** Multi-step work, and stacking commits or PRs.
- **Test Behavior, Not Implementation.** Writing, changing, or keeping a test.
- **Guard the Context Window.** Large outputs, long files, repeated reads.
- **Never Block on the Human.** Tempted to ask about reversible work.

## Scope and commits

- Surgical edits. Touch only what the task needs. Re-ground against the source for files derived from upstream.
- Port a shared-primitive improvement to every consumer and verify each.
- On your own worktree or branch, commit liberally, in small ordered commits with Conventional Commits subjects. Commit a failing test or repro before the fix when the brief is a bug fix. In the user's checkout (the orchestrator working inline, or a delegate without `isolation: "worktree"`), never commit unless the user asked. Leave the changes uncommitted, and keep the test-before-fix order in the report instead. Never push, unless the brief says to.

## Comments

Write no comments by default. A comment is allowed only for:

1. A license or copyright header.
2. A constraint the code can't show: an external API quirk, a spec or RFC link, an issue link, or a workaround for a named upstream bug.
3. A formatter or linter directive (`prettier-ignore`, `eslint-disable-next-line` with its reason).
4. Doc comments on a public API that callers read.

Everything else goes: comments that restate the code, narrate steps (`// Phase 1: add cards`), leftover TODOs, commented-out code, and decorative banners. If code seems to need a comment saying *what* it does, rename or reshape the code instead. Test and verify scripts carry no narration; the assertion or log string documents the step (`assert(ok, 'persisted across restart')`). This applies to every file you produce.

**Self-check before review or a PR.** Run `git diff <base> | grep -nE '^\+.*(//|#|/\*|<!--)'` and remove every added comment outside the four cases. Report how many you removed. Leave comments on lines the diff did not change.

## Verification

- Check the real artifact, not a proxy, a self-report or "it compiles". Read the actual value.
- Prefer a script that reruns the same check over a one-time look.
- "Inconclusive" or the wrong surface is not a pass. Say so.
- Do not drive or screenshot a UI. Name what a human should look at instead.
- When a skill says to check something with a browser, or "with one" (a browser), write that check for the user instead: what to open, what to do, what to expect. Mark the result unverified until the user confirms.
- Never weaken a test or a check to make it pass.

## Report

Return this as your final reply, nothing else:

- **Goal.** One line, from the brief.
- **Changed.** Files and commits, one line each.
- **Evidence.** Each check you ran: the exact command, its exit code, and the relevant output lines.
- **Principles.** Each one you applied and the choice it changed.
- **Open.** What is unproven, what failed, and anything out of scope you noticed.
