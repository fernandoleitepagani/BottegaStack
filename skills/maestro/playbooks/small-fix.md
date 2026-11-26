### Small fix

**You own a one-file change. Make it inline, prove it, gate it.** Fits one file, about 20 changed lines or fewer, normal risk, and a clear ask. Anything bigger goes to Bug fix, Feature, or Refactoring.

1. Open the run before any edit or spawn: `<maestro dir>/scripts/bottega start "<goal>" --risk <normal|high> --condition "<acceptance condition>" [--condition ...]`. Every condition later needs a `--proof` with the same words (`<maestro dir>/references/final-gate.md`).
2. You write the code, so the delegate rules bind you (`<maestro dir>/references/delegate.md`, **Scope and commits** and **Comments**; read them only if a case below is unclear): touch only what the fix needs; no comments except a license header, a constraint the code can't show (API quirk, issue or spec link), a linter directive, or a public API doc; don't commit in the user's checkout unless asked; never weaken a test to make it pass.
3. A bug: reproduce it first and write the smallest test that fails for the reported reason when a cheap test path exists (**Fix Root Causes**). Then make the change.
4. Check it on the real artifact, not "it compiles" (**Prove It Works**).
5. Review: one fresh `standard` reviewer runs both axes of `<maestro dir>/references/review.md` in a single pass (**Tiny diffs**). Verified findings go through its **Fix step**.
6. If the change grows past one file or about 20 lines, or the risk turns out high, stop and continue in the matching playbook from its step 2; the run stays open.
7. Run the final gate (`<maestro dir>/references/final-gate.md`). APPROVE only on exit 0.

**Reply:** the gate decision, the change, and the check with its output.
