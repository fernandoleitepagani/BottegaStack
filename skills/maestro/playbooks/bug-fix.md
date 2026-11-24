### Bug fix

**You own this task. Plan, review, verify.** Delegate investigation and the fix to subagents, stay in the lead.

Be scientific. Every shipped line traces to runtime evidence. Belt-and-suspenders that "might help" is a hypothesis, not a fix. It does not ship. When evidence refutes a hypothesis, revert what it motivated. The smallest change the evidence justifies ships, nothing more.

1. Reproduce it yourself on the matching surface via the project's `verify-<app>` skill (Non-negotiables), even when a debug or instrumentation protocol says to ask the user to reproduce. Ask the user only with a stated, specific reason that surface cannot reach the target, and only after driving it as far as it goes (agents do not drive a UI, so for UI-only bugs say what the user should check). If it won't reproduce directly, synthesize the trigger, tighten conditions, or instrument until it fires.
2. Binary-search the cause. Form the candidate hypotheses, then rule them out until one survives. Seed them with the **understand** skill (how mode over the affected subsystem, why mode for regression history). Each pass, take the split that cuts the most remaining problem space, get runtime evidence, eliminate. When program state is unclear, add instrumentation or logging and read it as the code runs. Don't guess. Drive a long or stubborn hunt with `/loop`. Confirm the surviving *mechanism* with runtime evidence before step 3.
3. Plan the fix (the **architect** trigger applies). Delegate implementation to a subagent (role: writer) with a specific scope.
4. Verify on the same surface per `references/delegate.md` **Verification**. The original repro now passes. Unit tests show branch behavior, not bug absence.
5. **Failing test first** when a cheap local test path exists (the user asked for TDD, or an existing unit, component, or integration test covers the codepath): write the smallest test that would have caught the bug, encoding intended behavior, and run it to confirm it fails for the intended reason before the fix; rerun it after. When the test would need broad harness setup, brittle mocks, slow end-to-end infrastructure, or production-only state, skip it and use the closest executable check (a targeted script, a repro command, a log assertion). Prefer no test over a bad one, and never change a test to match a wrong implementation. On a delegate's worktree branch, the failing test or repro commits before the fix; in the user's checkout, commit nothing unless asked and report the order instead (**Sequence Work into Verifiable Units**).
6. End at the final gate. `open a PR` continues with the **pr** skill.

**Reply:** what was broken, root cause, fix, how you verified. Paste failing-then-passing repro output verbatim.
