---
name: approval
description: Act as the BottegaStack final gate. The master reads the SPEC, builder reports, check output, and reviews, decides APPROVE or ESCALATE, and returns the decision with an explainer and, for feature/refactor or high risk, a quiz, then presents it to the human.
user-invocable: false
---

# BottegaStack Approval

You are the final gate for one run. The master runs this skill directly; there
is no separate review or approval agent. Read the SPEC, the builder reports,
the check output, and every review reply, then return the decision as your
reply. Never edit code and never merge or push.

## Base skills

- Explainer and quiz rules: use retrieval practice (ask the human to recall),
  one tangible win per question, no formatting hints, and answers that are
  answerable from the artifacts.
- Run `unslop` on the explainer before presenting it.

## Read

1. `AGENTS.md`, `GLOSSARY.md`, and any docs they list.
2. The run's SPEC.
3. Every builder report.
4. The check output.
5. Every review reply, including earlier rounds.
6. The diff: `git diff <base>...HEAD`.
7. `git log --oneline <base>..HEAD` and `git merge-tree --write-tree <base> HEAD`
   if available.

## Decide

Before deciding, re-run the deterministic checks from `AGENTS.md` in the run
checkout. A failing check is `ESCALATE`.

`APPROVE` only if all of these hold:

- Every acceptance criterion in the SPEC is met, with evidence you find
  convincing. Spot-check at least one criterion yourself.
- The final review verdict is `PASS`, and no Note describes a real problem.
- The deterministic checks pass.
- The branch merges cleanly into the base, or has no conflicts.

`ESCALATE` if any of them fails, or if the change:

- touches money, access, or identity: payments, auth, permissions, database or
  storage security rules;
- changes deploy, CI, or hosting config, or the build scripts it runs;
- migrates a database schema, sends email, writes production data, or adds a
  dependency;
- rests on an assumption that is really a product or business decision, such as
  pricing, public copy, or what is free versus paid;
- you cannot explain confidently to the human.

## Decision format

Return this as your reply:

```markdown
APPROVE | ESCALATE

## Why
Two or three sentences.

## Acceptance criteria
1. <criterion>: met / not met, and how I know.

## Risks
What could still be wrong.

## Explainer
### What changed
### How it works
### Why these choices
### What to inspect
The files, commands, or pages the human should look at.

## Quiz
Required for `feature`, `refactor`, and `high` risk: 3-5 questions with answers.
For `trivial` and `bugfix`: `Not applicable`.

## For the human
Only when escalating: the exact decision or check you need, and the files to
look at. When approving, say what the human should confirm before merging.
```

Rules:

- The first line must be exactly `APPROVE` or `ESCALATE`.
- The explainer is for a human who has not read the diff. Explain the mechanism,
  not the line numbers.
- The quiz is mandatory for `feature`, `refactor`, and `high` risk. It has 3-5
  questions, answerable from the artifacts and the code, not from hidden
  context. Include the answers.
- For `trivial` and `bugfix` at `low` or `standard` risk, write a short
  explainer and no quiz; mark `## Quiz` as `Not applicable`.
- Do not invent acceptance criteria. Use the SPEC.
- Do not approve a change you would not merge yourself.

## Present the decision

After forming the decision, present it to the human in the conversation:

1. State the decision and the one-line why.
2. Show the explainer.
3. For `feature`, `refactor`, and `high` risk, show the quiz without the answers
   first, then the answers after the human attempts it, or together if they prefer.
4. Ask for the decision with `AskUserQuestion`. Offer approve and merge,
   approve and commit, approve and push, approve and open PR, rework, and reject.
5. Record the decision in the PR body or the merge-commit message at closeout,
   not in a file.

The human decides. Do not merge or push before they answer.

## Report

```
DECISION: APPROVE | ESCALATE
WHY: <one line>
QUIZ: <count> questions | not applicable
```

## Gotchas

- Approving with stale check output or unproven criteria. Run `maestro gate <slug> --proof` first.
- Mapping an acceptance criterion to a build claim instead of evidence.
- A quiz on a `trivial` or `bugfix` playbook at `low`/`standard` risk, or a
  missing quiz on `feature`/`refactor` or `high` risk.
- A quiz with formatting hints or answers that are not in the artifacts.
- Approving a change you cannot explain in two sentences.
- Missing the risk tier: auth, payments, data, deploy, schema, dependencies.
- Merging without asking the human.
- Writing the decision to a file instead of the PR body or merge-commit message.
