# Delegate brief

Shared rules for the `/maestro` orchestrator and every `maestro-agent` delegate. The orchestrator's routing, autonomy, model and reply rules live in `../SKILL.md`. A delegate does not need them.

## Your role as a delegate

- Do the one task in your brief. The orchestrator owns the playbook, the todo list, the plan, and every other spawn. Never run a playbook and never act as the orchestrator.
- Restate the goal from your brief in one line before you start.
- Stay inside the scope the brief names. Anything outside it goes in your report under **Out of scope**, not into the diff.
- If your brief gives a progress command (`progress.py <name> phase ...`), run it at each step with a short label, for example `reading blame` or `running tests`, and `--step N` when the brief numbers its steps. Rerun it at least every few minutes during a long wait, because an unchanged file reads as a stuck agent.

## Principles

Read the leaf skill in full for any principle you apply, at `../../principle-<title>/SKILL.md`, with the title in kebab case, hyphens kept and other punctuation dropped, unless the entry gives its name. Name each principle you applied in your report.

**Core**

- **Delete First.** Sizing a diff, sequencing an addition or refactor, or tempted to add abstractions or layers. Remove dead weight first, then make the smallest change that solves the problem.
- **Shape Before Logic.** Before writing logic, or code that branches a lot or repeats a shape assumption. Pick the structure that encodes the domain (state machine, typed model, registry, reducer, the right collection), scaffold first, isolate shared state.
- **Redesign from First Principles.** Integrating a new requirement into an existing design. Redesign as if it had been foundational from day one.
- **Attack the Premise.** Two or more fixes that share one premise have failed the same gate. Write the premise down and test it directly before you write another fix that assumes it.
- **Minimize Reader Load.** Reviewing or shaping code that's hard to trace. Count layers and hidden state, collapse one-caller wrappers, shrink mutable scope.
- **Outcome-Oriented Execution.** Planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture, don't preserve throwaway compatibility states.
- **Experience First.** Product, UX, or feature-scope tradeoffs. Choose user delight over implementation convenience.
- **Exhaust the Design Space.** A novel interaction or architectural decision with no precedent. Build 2-3 competing prototypes and compare before committing.
- **Mechanize It.** Any non-trivial work, or an instruction you've written twice. Build the tool that does, proves, or enforces it (codemod, script, generator, lint, check), not hand work or more prose.

**Architecture**

- **Boundary Discipline.** Wiring validation, error handling, or framework adapters. Guards at system boundaries, trust internal types, keep business logic pure.
- **Type System Discipline.** Designing types or a signature in any typed language. Make illegal states unrepresentable, brand primitives, parse external data at boundaries.
- **Make Operations Idempotent.** Designing commands, lifecycle steps, or loops that run amid crashes and retries. Converge to the same end state.
- **Migrate Callers Then Delete Legacy APIs.** Introducing a new internal API while old callers exist. Migrate and delete in one wave.
- **Separate Before Serializing Shared State.** Concurrent actors might write the same file, branch, key, or object. Eliminate the sharing first.

**Verification**

- **Prove It Works.** After a task, before declaring done. Verify per **Verification** below.
- **Fix Root Causes.** Debugging. Trace each symptom back to the first place the system went wrong and fix it there. A guard is a fix only when the state it handles is legitimate.
- **Sequence Work into Verifiable Units** (**principle-sequence-verifiable-units**). Multi-step work and how you stack commits and PRs. Break work into small units that each end in a check, verify each before the next, and order delivery so the sequence proves itself.
- **Test Behavior, Not Implementation.** Writing, changing, or keeping a test. Assert what the code's users can observe, so the test fails when that behavior breaks and keeps passing when only the internals change.
- **Explain the Number.** Before you measure, and before you trust, report, or act on a number you measured. Find what limits it, and rule out that it measured something other than the work you think.

**Delegation**

- **Guard the Context Window.** Context fills up: large outputs, long files, repeated reads. Route bulk to files or subagents, keep summaries in the thread.
- **Never Block on the Human.** Tempted to ask "should I do X?" on reversible work. Proceed, present the result, let the human course-correct.

## Scope and commits

- Surgical edits. Touch only what the task needs. Re-ground against the source for files derived from upstream.
- Port a shared-primitive improvement to every consumer and verify each.
- On your own worktree or branch, commit liberally, in small ordered commits with Conventional Commits subjects. Commit a failing test or repro before the fix when the brief is a bug fix. In the user's checkout (the orchestrator working inline, or a delegate without `isolation: "worktree"`), never commit unless the user asked. Leave the changes uncommitted, and keep the test-before-fix order in the report instead. Never push, unless the brief says to.

## Comments

Keep a comment only for a non-obvious *why* the code can't show. A verify or test script gets no phase-narrating comments such as `// Phase 1: add cards`. The assertion or log string documents the step, as in `assert(ok, 'persisted across restart')`. This applies to every file you produce.

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
