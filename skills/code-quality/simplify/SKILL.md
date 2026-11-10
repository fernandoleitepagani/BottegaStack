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
- A comment that restates the code, and the comment kinds listed under Comments below.

## Process

1. Read the diff and the spec.
2. List the simplifications.
3. Apply only the ones that preserve behavior.
4. Run the checks after each group.
5. Stop when the diff is the smallest change that meets the spec.

## Comments

A comment pass runs with the simplification (adapted from pstack's `no-comments`). Scope is the diff against the base branch, or the files the caller names. Delete narration, banners, commented-out code, and workaround sermons. These survive: license headers; non-obvious behavior forced by an external dependency, platform, or protocol you cannot reshape; doc comments that define a public API contract; an issue or RFC link that explains a constraint code cannot express; `prettier-ignore`. When unsure a keep applies, delete the comment.

- A surprise in our own code is a reshape target, not a comment: name the symbol and fix it by rename, extract, type, or restructure so the behavior is obvious without prose.
- Lint and type suppressions (`eslint-disable`, `@ts-ignore`, `# noqa`) survive only when the rule is faulty or style-only. If the rule guards correctness or safety, remove the suppression and fix the cause.
- Words like `IMPORTANT`, `do not remove`, `too risky`, and `fine for now` are suspicion, not proof. Read the nearby code and load `how` or `why` on the symbol before keeping or killing.
- A comment that claims a constraint (`do not change wording`, `talk to X first`): offer the cheapest in-scope type, runtime check, test, or CI lint, and ask with `AskUserQuestion`. If approved, encode it, then delete the comment. Otherwise delete it and report the constraint as unenforced.
- Touch comments only; never rewrite application code in this pass.

## Rules

- Do not rewrite unrelated code.
- Do not remove error handling that the spec requires.
- Do not change public behavior.
- If a simplification is risky, leave it and note it.

## Output

Return as your reply, never as a file: **Removed** (what and why), **Kept** (risky
simplifications left alone, with the reason), **Checks** (the check output).

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
  `maestro doctor` reference check.
- "Simplifying" the master by dropping the Step 0 playbook gate.
- Deleting code that looks unused only because no test covers it.
