### Bug fix

**You own the cause. Plan, delegate, verify.** Every shipped line traces to runtime evidence. A change that "might help" is a hypothesis, not a fix, and doesn't ship.

1. Open the run before any edit or spawn: `<maestro dir>/scripts/bottega start "<goal>" --risk <normal|high> --condition "<acceptance condition>" [--condition ...]`. Every condition later needs a `--proof` with the same words (`<maestro dir>/references/final-gate.md`).
2. Reproduce it on the real surface (the project's `verify-<app>` skill when one exists). If it won't reproduce, tighten the conditions or add instrumentation until it fires. Ask the user only for something you can't reach, and say what.
3. Rule out hypotheses with runtime evidence until one survives (**Fix Root Causes**). For a wide trace, brief explorers per `investigation.md` (**Briefing an explorer**). After two failed fixes on one premise, test the premise (**Attack the Premise**).
4. Pin it: the smallest test that fails for the reported reason, written before the fix, when a cheap test path exists; otherwise the closest rerunnable check. If the fix changes a shared interface, run `<maestro dir>/references/blast-radius.md` on it first.
5. Delegate the fix to an implementer (router **Subagents**) with the cause, the pin, the paths it may write, and the checks that prove done.
6. Verify on the same surface: the original repro now passes. Inconclusive or wrong surface is not a pass (**Prove It Works**).
7. Review per `<maestro dir>/references/review.md`. At most 2 fix rounds, then ESCALATE.
8. Commit the failing test before the fix on the run's own branch; in the user's checkout leave changes uncommitted for `/ship` (`delegate.md`). Run the final gate (`<maestro dir>/references/final-gate.md`).

**Reply:** what was broken, the root cause, the fix, and the failing-then-passing output.
