---
name: implement
description: "Build one ticket, or one small direct task, in a fresh session: explore, shape, delegate to implementers, verify, review, and end at the final gate. Handles features, bug fixes, and refactors. Use for /implement <ticket path>, or when /maestro routes a change that fits one session."
disable-model-invocation: true
---

# Implement

One ticket per fresh session. You orchestrate: you decide, brief, review, and prove. Subagents explore and write.

`<maestro dir>` is `../maestro` from this file, as an absolute path. Before your first tool call, read `<maestro dir>/references/delegate.md` and `<maestro dir>/references/final-gate.md`. Read `<maestro dir>/references/subagents.md` before your first spawn.

## 0. Load

- **Ticket mode** (`/implement <path>`): read the ticket and the spec it belongs to. Check that every `Blocked by` ticket says `Status: done`; if one doesn't, stop and say which. Set the ticket to `Status: in-progress`. Its acceptance criteria are your conditions, its risk is your risk, and its **Orchestrator does** and **Subagents** sections are your plan. Follow them. A change to that split goes in your reply with the reason.
- **Direct mode** (a small task with no ticket, routed by `/maestro` or `/grill`): state the goal, the risk, and the checks that prove done, and write the split yourself in the todo list. If it turns out to need more than one session, stop and route to `/grill` (`../grill/SKILL.md`).

Open the run before your first edit or spawn (final gate step 0), with each acceptance criterion as a `--condition`.

**Context budget.** Your own context limit for this session is 300k tokens, ±10%. Past about 270k, finish the current step and run the Handoff pause (`<maestro dir>/references/handoff.md`). Never pass 330k.

## 1. Understand

Send explorer subagents (`<maestro dir>/references/explore.md`) to map what the change touches. Read yourself only the files you must judge: the data shape, the interfaces, and the code you will review.

## 2. Shape before logic

Write the types, signatures and states the change needs, with `not implemented` bodies, before any logic (**Shape Before Logic**). Prefer a state machine to scattered booleans, a table to branching, a typed model to repeated shape assumptions. If several shapes are equally valid, run two implementers on the same brief in separate worktrees, then pick one base and graft what the other did better. Ask first unless the ticket already says so.

## 3. Pin the behavior, by kind

- **Bug.** Reproduce it on the real surface first (the project's `verify-<app>` skill when one exists). Narrow the cause by ruling out hypotheses with runtime evidence, never guesses (**Fix Root Causes**). After two failed fixes on one premise, test the premise (**Attack the Premise**). Write the smallest test that fails for the reported reason before the fix, when a cheap test path exists. Otherwise use the closest rerunnable check.
- **Refactor.** Pin the current behavior first with a characterization test, snapshot, or equivalence script. A type check is not a pin. Delete first, then move in small steps that keep the pin green. Migrate every caller and delete the old API in the same ticket. If the diff doesn't lower reader load, revert it.
- **Feature.** Tests go at the seams the spec agreed, one behavior at a time: red, then green (**Test Behavior, Not Implementation**).

## 4. Delegate the code

Brief each implementer (`bottega:maestro-agent`, with `model` and `effort` from the role table, and the absolute path of `<maestro dir>/SKILL.md` as the brief's first line) with the goal, the paths it may write, the shape from step 2, the test or pin from step 3, and the checks that prove done. Use `isolation: "worktree"` when two write at once. Run independent briefs in parallel. You own every diff: read it, don't trust the report.

## 5. Verify

Check the real artifact, never a self-report or "it compiles" (**Prove It Works**). Run each acceptance criterion and keep the command and its output. Agents don't drive or screenshot a UI: say exactly what the user should look at, and mark that check unverified until they confirm.

## 6. Review

Always run one reviewer subagent over the finished diff, per `<maestro dir>/references/review.md`. At high risk the review is adversarial and logs the `crossfire` row the gate needs. Verified findings go through the fix step in that file: at most **2 fix rounds**, and a third failure is ESCALATE.

## 7. Close

1. Shape small ordered commits per `delegate.md` **Scope and commits**.
2. Run the final gate (`<maestro dir>/references/final-gate.md`). APPROVE only on exit 0.
3. **Ticket mode:** tick the acceptance criteria that passed, set `Status: done` (or `blocked: <why>` on ESCALATE), and update the ticket's row in `PLAN.md`. List the tickets this one unblocked and the command to start each, with the model level each one names.

**Reply:** the gate decision first, then what changed and for whom, the evidence per criterion, the principles that changed a choice, the context you used against the 300k budget, and the next tickets.
