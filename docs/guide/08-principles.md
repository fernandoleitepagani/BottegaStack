# Steer with principle names

bottega ships 19 principles in four reference files (core, architecture, verification, delegation). `/maestro` reads their index at the start of every multi-step task, applies the ones the task triggers, and names each applied principle in its reply along with the decision it changed.

You don't invoke principles. You use their names to steer. Each name points at a complete rule the agent has already read, so one phrase redirects the work more precisely than a paragraph of instructions.

## Steering in practice

Say the agent is about to bolt a new adapter onto three existing ones:

```text
use delete first. delete the obsolete adapters first, then design what's left.
```

Say it claims success because the build passed:

```text
apply prove it works. run the real import flow and show me the written records.
```

Say two parallel attempts are about to write to the same branch:

```text
separate before serializing shared state. give each attempt its own worktree, no locks.
```

Each phrase lands because the rule behind it is specific. The agent still has to say, in its reply, which decision the rule changed. A principle citation with no decision behind it means the agent named the rule without applying it.

## The 21, briefly

The core principles decide how much to build and when to rethink the design:

- [Delete First](../../skills/maestro/references/principles/core.md) prefers deletion and the smallest change that solves the problem.
- [Shape Before Logic](../../skills/maestro/references/principles/core.md) chooses the core data structures before writing logic.
- [Redesign from First Principles](../../skills/maestro/references/principles/core.md) integrates a new requirement as if it had been there from day one.
- [Attack the Premise](../../skills/maestro/references/principles/core.md) writes down the premise that two or more failed fixes shared and tests it directly before the next fix.
- [Minimize Reader Load](../../skills/maestro/references/principles/core.md) collapses layers and hidden state a reader must hold in their head.
- [Outcome-Oriented Execution](../../skills/maestro/references/principles/core.md) converges rewrites on the target design instead of preserving throwaway compatibility states.
- [Exhaust the Design Space](../../skills/maestro/references/principles/core.md) builds two or three competing prototypes when there's no precedent.
- [Mechanize It](../../skills/maestro/references/principles/core.md) builds the script that does or proves the work, so a reviewer can rerun it. When an agent keeps doing the same thing by hand, have it write the tool or skill it wishes it had. If a script can do a step the same way every time, use the script, and save agents for the judgment calls.

The architecture principles decide where state, validation, and compatibility live:

- [Boundary Discipline](../../skills/maestro/references/principles/architecture.md) validates at the boundary and trusts internal types.
- [Type System Discipline](../../skills/maestro/references/principles/architecture.md) makes illegal states unrepresentable.
- [Make Operations Idempotent](../../skills/maestro/references/principles/architecture.md) converges retries on the same end state.
- [Migrate Callers Then Delete Legacy APIs](../../skills/maestro/references/principles/architecture.md) migrates and deletes in one wave.
- [Separate Before Serializing Shared State](../../skills/maestro/references/principles/architecture.md) removes the sharing before adding coordination.

The verification principles define what counts as proof:

- [Prove It Works](../../skills/maestro/references/principles/verification.md) verifies the real artifact, not a proxy.
- [Fix Root Causes](../../skills/maestro/references/principles/verification.md) reproduces and traces to the cause before changing code.
- [Sequence Work into Verifiable Units](../../skills/maestro/references/principles/verification.md) ends each small unit in a check before starting the next.
- [Test Behavior, Not Implementation](../../skills/maestro/references/principles/verification.md) asserts what the code's users can observe, so a test fails when that behavior breaks and survives a change to the internals.

The delegation principles keep parallel work sane:

- [Guard the Context Window](../../skills/maestro/references/principles/delegation.md) routes bulk reading to subagents and keeps findings in the main chat.
- [Never Block on the Human](../../skills/maestro/references/principles/delegation.md) proceeds on reversible work and presents the result.

And one meta principle:

- [`/correct`](../../skills/correct/SKILL.md) applies it to a whole repo, as shown in [Make it yours](./09-make-it-yours.md#fix-the-environment-with-correct).

Don't memorize the list. Skim it now, then come back when you catch the agent doing something a name here would have prevented. That's how the vocabulary sticks.

Next: [Make it yours](./09-make-it-yours.md).
