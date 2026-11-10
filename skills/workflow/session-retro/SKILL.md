---
name: session-retro
description: Retrospective on a PaganiStack job. Turn repeated mistakes and friction into rules, lint, tests, or skill edits. Use after a job closes or when the same finding appears twice.
---

# Session Retro

Improve the environment, not just the code.

## Read

- `.agents/plans/<id>/job.md` and `decision.md`.
- The review files and `checks.md`.
- `AGENTS.md` and `mistakes.md`. If `mistakes.md` is missing, create it with
  `pagani seed mistakes.md`.

## Find candidates

- **Navigation:** the agent took too long to find a file or dependency.
- **Automated checks:** a mistake a lint, type, test, or hook could catch.
- **Coding standards:** a rule the reviewer should enforce; prefer a check over
  prose.
- **Global `AGENTS.md`:** lines that belong in a check or a skill instead.
- **Tool economy:** an expensive tool call or a missing helper.
- **Rule placement:** a rule that sits too low in the hierarchy; move it to the
  highest item that prevents recurrence.
- **No-ops:** instructions that do not change behavior.
- **Information access:** a log or read-only source the agent needed but did not
  have.

## Correction hierarchy

1. Architecture or data structure.
2. Hook or permission rule.
3. Lint, type, or test.
4. Script or skill.
5. `AGENTS.md`/`mistakes.md` rule.
6. Human review.

Prefer the highest item that actually prevents recurrence. This follows the
`## Rule placement` order in `AGENTS.md`: move a repeated rule down the list
until it sticks.

## Model-upgrade decay check

When the model changes, test one component at a time. Remove it on a branch, run a
real job, then keep or delete it. A component that fixed an
old model's weakness may be dead weight on the new one. Do not remove several at
once: you will not know which one still earns its place.

## Output

`retro.md` with candidates ordered by severity, each with:

- the evidence,
- the proposed change,
- the expected effect,
- the file to edit.

For a recurring mistake, output a ready-to-apply patch to the specific skill's
`## Gotchas` section:

```markdown
### Patch: skills/<category>/<skill>/SKILL.md

## Gotchas

- <new bullet, in the same voice as the existing ones>
```

Ask before editing `AGENTS.md`, a skill, or a lint config. Apply the patch only
after approval.

## Report

```
CANDIDATES: <count>
TOP: <one line>
APPLIED: <none|list>
```

## Gotchas

- A retro that only adds prose. If the rule can be a hook, a lint rule, a test,
  or a script, put it there instead.
- A frozen harness. Never removing a rule lets the stack grow without limit;
  check whether an old component still earns its place.
- Adding a rule that duplicates a check the tooling already enforces.
- Editing `AGENTS.md` or a skill before the human approves.
