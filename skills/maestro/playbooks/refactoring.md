### Refactoring

**You own the contract. The structure changes; the behavior does not.** A missing feature or a real bug found on the way is split out (Feature, Bug fix), and the structural change ships first.

1. Open the run before any edit or spawn: `<maestro dir>/scripts/bottega start "<goal>" --risk <normal|high> --condition "<acceptance condition>" [--condition ...]`. Every condition later needs a `--proof` with the same words (`<maestro dir>/references/final-gate.md`).
2. Run `<maestro dir>/references/blast-radius.md` on the planned change: what it breaks outside the diff, every dependent (strings, config, wire formats, dynamic dispatch), and the one fact it's safe because of. The dependents join the write scope.
3. Pin current behavior before anything moves: a characterization test, snapshot, or equivalence script that covers the blast-radius safety fact. A type check is not a pin.
4. Name the target shape as if built today (**Redesign from First Principles**). It must delete branches or states, not add indirection.
5. Delete first: dead code, one-caller wrappers, orphan references (**Delete First**).
6. Move in small steps that keep the pin green. Migrate every caller and delete the old API in the same ticket, no shims (**Migrate Callers Then Delete Legacy APIs**). Spot-check renames in strings and docs. Delegate mechanical edits to implementers (router **Subagents**).
7. Prove behavior is unchanged on the real artifact: the pin, plus an equivalence check for larger moves (**Prove It Works**). If the diff doesn't lower reader load, revert it (**Minimize Reader Load**).
8. Review per `<maestro dir>/references/review.md`. Commit a subtraction, then the reshape, on the run's own branch (`delegate.md`). Run the final gate (`<maestro dir>/references/final-gate.md`).

**Reply:** the structure that changed, the pin and the equivalence proof, the reader-load change, and what got reverted.
