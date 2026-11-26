# Implement a ticket

Each ticket runs in a fresh session. Start it the way `PLAN.md` says:

```text
/clear
# set model to your harness's translation of the ticket's tier (e.g. standard)
/implement .bottega/plans/team-workspaces/tickets/T01-schema-and-types.md
```

Changes with no ticket skip `/implement`: `/maestro fix the off-by-one in pagination` routes straight to the matching playbook.

## What happens

`/implement` loads the ticket (blocking tickets must be done; the ticket is marked in progress), then picks one playbook by the ticket's kind and follows it. Each playbook opens the gate with the acceptance criteria as its first step and ends at the final gate.

| Kind | Playbook | Shape |
|---|---|---|
| One file, about 20 lines, normal risk | [`small-fix`](../../skills/maestro/playbooks/small-fix.md) | Inline edit, a check, one reviewer for both axes |
| Broken behavior | [`bug-fix`](../../skills/maestro/playbooks/bug-fix.md) | Reproduce on the real surface, rule out causes with evidence, failing test before the fix |
| New behavior | [`feature`](../../skills/maestro/playbooks/feature.md) | Explorers map the code, shape before logic, tests at the spec's seams |
| Structure only | [`refactoring`](../../skills/maestro/playbooks/refactoring.md) | Blast radius first, pin behavior, delete first, migrate every caller, prove nothing changed |

All of them delegate the code to implementers with a named write scope (in separate worktrees when they run at once), verify the real artifact, and review the diff. Two reviewers check it in parallel, Spec and Standards; a diff of about 20 lines gets one reviewer for both. At high risk a small diff gets a blast-radius check and a larger one a swarm of three verifiers. Findings count only when a run proves them, and fixes go to a fresh implementer, at most 2 rounds, then ESCALATE. Afterwards `/implement` marks the ticket done and lists the tickets it unblocked.

If the session nears 300k tokens, it pauses (`playbooks/pause.md`); you `/clear` and pick up with `playbooks/pickup.md`.

## Comments and prose

Code carries no comments by default. The exceptions are license headers, constraints the code can't show (an API quirk, an issue link), linter directives, and public API docs. Prose (replies, PR bodies, docs) goes through `/unslop`.

Next: [Verify and ship](./05-verify-and-ship.md).
