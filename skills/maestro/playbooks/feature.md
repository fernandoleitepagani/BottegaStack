### Feature

**You own the design. Plan, delegate, verify.**

1. Open the run before any edit or spawn: `<maestro dir>/scripts/bottega start "<goal>" --risk <normal|high> --condition "<acceptance condition>" [--condition ...]`. Every condition later needs a `--proof` with the same words (`<maestro dir>/playbooks/final-gate.md`).
2. Map what the change touches with explorers (`investigation.md`, **Briefing an explorer**). Read yourself only what you must judge: the data shape, the interfaces, the code you will review. If it changes a shared interface, public API, data format, schema or config other code reads, run `<maestro dir>/../blast-radius/SKILL.md` on the planned change; its dependents join the write scope.
3. Shape before logic: types, signatures and states with `not implemented` bodies (**Shape Before Logic**). A state machine over scattered booleans, a table over branching, a typed model over repeated shape assumptions.
4. Tests go at the seams the spec agreed, one behavior at a time: red, then green (**Test Behavior, Not Implementation**).
5. Delegate to implementers (router **Subagents**), each with the goal, the paths it may write, the shape, its tests, and the checks that prove done. Disjoint files run in parallel in separate worktrees; shared writes go to one owner (**Separate Before Serializing Shared State**).
6. Verify on the real artifact (**Prove It Works**), through the project's `verify-<app>` skill when one exists. Agents never drive or screenshot a UI: for UI, say exactly what the user should look at and mark it unverified until they confirm.
7. Review per `<maestro dir>/../review/SKILL.md`. Fix rounds follow `../../review/fix.md` (**Caps**).
8. Small ordered commits on the run's own branch, or uncommitted in the user's checkout (`../worker.md`). Run the final gate (`<maestro dir>/playbooks/final-gate.md`).

**Reply:** what you built, what you chose and why, open decisions, and the evidence per condition.
