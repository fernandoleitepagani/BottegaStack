---
name: scaffold
description: Create a new component, service, route, migration, or test fixture that matches the project's existing conventions. Use when adding a new file or module rather than changing an existing one.
---

# Scaffold

Create the smallest new thing that matches the project.

## Process

1. Read `AGENTS.md` and find the closest existing example of the same kind.
2. Copy its structure, naming, exports, tests, and wiring. Do not invent a new
   pattern.
3. If the project has a generator, use it. If not, create only the files the
   example needs.
4. Add a test at the existing seam.
5. Run the project's checks.
6. Update the index, route, barrel, or registration point the example uses.

## Checklist

- [ ] Name matches the surrounding convention.
- [ ] Files live where the example lives.
- [ ] Exports and imports match.
- [ ] Test added.
- [ ] Checks pass.
- [ ] No speculative options or unused files.

## Output

The new files plus a short `scaffold.md`:

```markdown
# Scaffold: <thing>

## Closest example
## Files created
## Wiring
## Tests
## Checks
```

## Report

```
SCAFFOLD: <thing>
FILES: <count>
TESTS: <pass/fail>
```
