# Implement a ticket

Each ticket runs in a fresh session. Start it the way `PLAN.md` says:

```text
/clear
/model sonnet
/implement .bottega/plans/team-workspaces/tickets/T01-schema-and-types.md
```

Small changes with no ticket go the same way: `/maestro fix the off-by-one in pagination` routes to `/implement` in direct mode, and it writes the split itself.

## What happens

1. **Load.** It checks that every blocking ticket is done, marks the ticket in progress, and opens the gate with the acceptance criteria as conditions.
2. **Understand.** Explorers map the code. The orchestrator reads only what it must judge.
3. **Shape before logic.** Types, signatures and states first, with empty bodies. When two shapes are equally good, it can offer to run two implementers and pick the better base.
4. **Pin the behavior,** depending on the kind of work:
   - **Bug:** reproduce on the real surface, narrow the cause with evidence, then write a failing test before the fix when a cheap test path exists.
   - **Refactor:** a characterization test or equivalence check first, then small steps that keep it green. Callers migrate and the old API goes in the same ticket.
   - **Feature:** tests at the seams the spec agreed, one behavior at a time.
5. **Delegate.** Implementers write the code, each with a named write scope, in separate worktrees when they run at once. The orchestrator reads every diff.
6. **Verify** the real artifact: the command, the stored value, the profile. For UI, it tells you what to look at.
7. **Review.** A fresh reviewer checks the diff against the ticket. At high risk the review is adversarial: findings count only when a run proves them, over up to 3 rounds (5 for security or data). Fixes go to a fresh implementer, at most 2 rounds, then ESCALATE.
8. **Close.** Small ordered commits, the final gate, the ticket marked done, and the next tickets it unblocked.

If the session nears 300k tokens, it writes a handoff; you `/clear` and resume.

## Comments and prose

Code carries no comments by default. The exceptions are license headers, constraints the code can't show (an API quirk, an issue link), linter directives, and public API docs. Prose (replies, PR bodies, docs) goes through `/unslop`.

Next: [Verify and ship](./05-verify-and-ship.md).
