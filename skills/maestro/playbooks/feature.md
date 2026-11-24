### Feature

**You own the design. Plan, review, verify.** Delegate implementation. Stay in the lead.

1. The **understand** skill (how mode) over the affected subsystem.
2. The **architect** trigger applies. Skip it on a no.
3. Write the throughput checkpoint as four todo items. A dimension that genuinely does not apply (single file, no fan-out) keeps its item with `n/a: <reason>` rather than being dropped:
   - **Blocking first steps.** Gates run before fan-out.
   - **Independent workstreams.** Disjoint files, services, or layers parallelize. Shared writes serialize.
   - **Shared mutable state.** Default to splitting the target (the **Separate Before Serializing Shared State** principle). Serialize only for real invariants.
   - **Smallest safe decomposition.** If one worker is best, name why.
4. Delegate code-writing to a subagent (role: writer) with a specific scope: file paths, the named data shape and its organizing structure per **Shape Before Logic** (a state machine over scattered booleans, a table or registry over branching, a typed model over repeated shape assumptions), chosen before the delegate writes logic, and success criteria. When the implementation admits several valid shapes (error handling, abstraction layer, test structure), suggest the **parallel** skill (bakeoff mode) and ask the user whether to run it. On a no, delegate to one subagent. Delegation is mandatory, with no skip-with-reason escape, and the Delete First does not override it: the gain is review separation, not lines saved. A subagent forbidden to spawn satisfies this by owning the diff directly with the same review separation. The delegate brief (`references/delegate.md`) carries the comment, scope, and commit rules.
5. Verify on the matching surface per `references/delegate.md` **Verification**.
6. Shape small, ordered commits per `references/delegate.md` **Scope and commits** (never in the user's checkout unless asked). Stack follow-ups.
   Use the **Sequence Work into Verifiable Units** principle, building, verifying, and committing each small unit before the next.
7. If the design is contested, `crossfire` before shipping.
8. End at the final gate. `open a PR` continues with the **pr** skill.

Code-coupled work (one feature, one migration) goes to a single owner with the checkpoint inline. That owner fans out internally after the blocking phase. Parent-level fan-out is for slices that produce independent artifacts (audits, cross-subsystem investigations, competing experiments). Rewrite the checkpoint at phase boundaries. Spawn a fresh owner rather than chaining interrupts.

**Reply:** what you built, what you chose and why, the throughput checkpoint, open decisions. Tables for design alternatives.
