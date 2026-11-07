---
name: simplify
description: Remove unnecessary complexity from a change before review. Use after the implementation passes checks and before the reviewers spend time on it.
---

# Simplify

Keep the behavior; remove the extras.

## Look for

- Speculative options, flags, hooks, or parameters the spec did not ask for.
- Fallbacks and hidden defaults that hide a real failure.
- Dead code, unused imports, and commented-out blocks.
- Duplicated logic that already exists as a helper.
- A shallow wrapper that only passes through.
- A new abstraction with one caller.
- A comment that restates the code.

## Process

1. Read the diff and the spec.
2. List the simplifications.
3. Apply only the ones that preserve behavior.
4. Run the checks after each group.
5. Stop when the diff is the smallest change that meets the spec.

## Rules

- Do not rewrite unrelated code.
- Do not remove error handling that the spec requires.
- Do not change public behavior.
- If a simplification is risky, leave it and note it.

## Output

`simplify.md`:

```markdown
# Simplify

## Removed
## Kept
## Checks
```

## Report

```
REMOVED: <count>
CHECKS: <pass/fail>
```
