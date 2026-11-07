---
name: library-reference
description: Document how to use a project's internal library, CLI, SDK, or API correctly. Use when the agent needs the real entry points, invariants, examples, and gotchas instead of guessing from names.
---

# Library Reference

Use this when a project has an internal library, CLI, SDK, or API that the agent
will use repeatedly. The goal is a small, high-signal reference, not a copy of
the docs.

## Process

1. Read the project `AGENTS.md` and find the library's real entry point.
2. Read the source and the tests. The tests show intended use; the source shows
   the invariants.
3. Write `references/<library>.md` with:
   - the public entry points and signatures,
   - one minimal example per common task,
   - invariants and ordering constraints,
   - error modes and what to do,
   - **Gotchas**: the failures the agent will hit if it guesses.
4. Keep the skill's `SKILL.md` as the index. Point to the reference file; do not
   paste the whole API into it.
5. Verify the examples by running them or the library's tests.

## Gotchas to look for

- A field that means different things in two services.
- A table or endpoint that is append-only; the latest row is not the newest by
  timestamp.
- A staging service that returns success even when the side effect failed.
- A required initialization step that the type system does not enforce.
- A default that is wrong for this project.

## Output

```
references/<library>.md
```

## Report

```
LIBRARY: <name>
ENTRY POINTS: <count>
GOTCHAS: <count>
VERIFIED: <commands>
```
