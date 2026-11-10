---
name: blast-radius
description: Find what a change could break outside the diff: map direct and transitive dependents, name the key safety fact, and prove or disprove it with a real run. Use before merging a change to shared code, contracts, or symbols.
---

# Blast Radius

Read-only: report what a change could break; edit nothing.

## 1. Map dependents

From the diff, list every changed symbol, file, route, type, schema, and
contract. For each, find direct dependents with imports, call sites, and grep,
then recurse to transitive ones. Record `file:line` for each hit. Stop at the
repo boundary and note external consumers you cannot see.

## 2. Pick the key safety fact

Across the dependents, isolate the one fact that decides safe or unsafe: an
unchanged signature, a caller that ignores the change, a serialized format that
must match, a default that must hold. Say what would have to be true.

## 3. Prove it

Prove the fact by running real code or a cheap test — a unit test, a REPL
snippet, `curl`, a fixture that exercises the caller. Quote the command and
output. If you cannot prove it, mark it unproven, not safe.

## 4. Output

Return this as your reply:

```markdown
## What changed
<symbols/files/contracts>
## Key safety fact
<fact> — PROVEN | UNPROVEN — `<command>` — `<output>`
## Confirmed risks
1. <file:line> — <what breaks> — <evidence>
## Cleared checks
- <dependent> — <why it is unaffected>
## Cheap test before merge
`<command>` — expected: <result>
```

## Gotchas

- Stopping at direct callers and missing transitive dependents.
- Asserting the safety fact instead of running it.
- Treating an unproven fact as safe.
- Editing code or tests to make the check pass.
- Missing stringly contracts: JSON fields, env names, CLI flags, routes, schemas.
- Ignoring external consumers the repo cannot see.
