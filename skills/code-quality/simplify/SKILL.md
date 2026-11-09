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

## Gotchas

- Deleting the `set -e` or error handling the spec required and calling it
  cleanup.
- Removing a real fallback, such as the `sed` path used when `python3` is
  absent.
- Collapsing a backticked skill reference into prose, which breaks the
  `pagani doctor` reference check.
- "Simplifying" the master by dropping the Step 0 playbook gate.
- Deleting code that looks unused only because no test covers it.
