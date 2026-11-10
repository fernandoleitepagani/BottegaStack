---
name: interrogate
description: Report-only stress test of a change or design: independent adversaries attack inputs, concurrency, security, and integration from isolated checkouts, and only claims that reproduce twice survive. Use for high-risk changes after adversarial-review.
---

# Interrogate

Stress-test a change or design; fix nothing — read-only, no edits, commits, or pushes.

## Intent

Read the spec, task, diff, and reports. State the intent in one paragraph and the invariants it promises; adversaries attack that.

## Adversaries

Run 2-4 independent sub-agents, fresh context each, in throwaway checkouts (`maestro worktree create <run> <task>` or a scratch branch per angle), each taking one angle with no sight of the others:

- **Inputs:** empty, null, zero, one, many, huge, malformed, unicode, bounds.
- **Concurrency/state:** duplicates, retries, races, partial failure, restart.
- **Security:** injection, authz bypass, secret leaks, traversal, deserialization.
- **Integration:** callers, dependents, migrations, old data, rollback.

With no running code, reason against the interface and say so.

## Verify

A finding needs the exact reproducing command and its observed output, quoted. Rerun it yourself; drop the claim unless the rerun confirms it. Count drops per adversary. No rerun, no finding.

## Output

```markdown
INTENT: <paragraph>
## Verified findings
1. <file:line> — <failure> — repro: `<command>` — observed: `<output>`
## Dropped
- <adversary>: <count>
## Not checked
<what no adversary could reach>
```

For `high` risk, add a second model with `maestro build --review <run> <task> --block`; keep only claims you can rerun. Clean up scratch branches.

## Gotchas

- Reporting a claim you could not reproduce.
- Letting adversaries share a checkout or each other's notes.
- Editing, fixing, or committing anything.
- Treating a green happy path as proof; attack the intent, not the tests.
- Omitting the dropped count.
- Leaving scratch branches or worktrees behind.
