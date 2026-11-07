---
name: approval
description: Act as the PaganiStack final gate. The master reads the SPEC, build, checks, and reviews, decides APPROVE or ESCALATE, writes decision.md with an explainer and, for standard/high-risk, a quiz, and presents it to the human.
---

# PaganiStack Approval

You are the final gate for one job. The master runs this skill directly; there
is no separate review or approval agent. Read the job folder, `SPEC.md`, the
build reports, `checks.md`, and every review file, then write exactly one file,
`pagani/jobs/<id>/decision.md`. Never edit code and never merge or push.

## Base skills

- Explainer and quiz rules: use retrieval practice (ask the human to recall),
  one tangible win per question, no formatting hints, and answers that are
  answerable from the artifacts.
- Run `unslop` on the explainer before writing it.

## Read

1. `AGENTS.md`, `GLOSSARY.md`, and any docs they list.
2. `SPEC.md`.
3. Every `build/<task>.md`.
4. `checks.md`.
5. Every `round-*/review-code.md`, including earlier rounds.
6. The diff: `git diff <base>...HEAD`.
7. `git log --oneline <base>..HEAD` and `git merge-tree --write-tree <base> HEAD`
   if available.

## Decide

Before deciding, re-run the deterministic checks from `AGENTS.md` in the job
checkout. A failing check is `ESCALATE`.

`APPROVE` only if all of these hold:

- Every acceptance criterion in `SPEC.md` is met, with evidence you find
  convincing. Spot-check at least one criterion yourself.
- The final `review-code.md` is `VERDICT: PASS`, and no Note describes a real
  problem.
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

## Write `decision.md`

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
Required for `standard` and `high-risk`: 3-5 questions with answers.
For `trivial`, `bugfix`, and `small`: `Not applicable`.

## For the human
Only when escalating: the exact decision or check you need, and the files to
look at. When approving, say what the human should confirm before merging.
```

Rules:

- The first line must be exactly `APPROVE` or `ESCALATE`.
- The explainer is for a human who has not read the diff. Explain the mechanism,
  not the line numbers.
- The quiz is mandatory only for `standard` and `high-risk`. It has 3-5
  questions, answerable from the artifacts and the code, not from hidden
  context. Include the answers.
- For `trivial`, `bugfix`, and `small`, write a short explainer and no quiz; mark
  `## Quiz` as `Not applicable`.
- Do not invent acceptance criteria. Use `SPEC.md`.
- Do not approve a change you would not merge yourself.

## Present the decision

After writing `decision.md`, present it to the human in the conversation:

1. State the decision and the one-line why.
2. Show the explainer.
3. For `standard` and `high-risk`, show the quiz without the answers first, then
   the answers after the human attempts it, or together if they prefer.
4. Ask for the decision with the native question tool. Offer approve and merge,
   approve and commit, approve and push, approve and open PR, rework, and reject.

The human decides. Do not merge or push before they answer.

## Report

```
DECISION: APPROVE | ESCALATE
WHY: <one line>
QUIZ: <count> questions | not applicable
```

## Gotchas

- Approving with stale `checks.md`. Run `pagani job gate <job>` first.
- Mapping an acceptance criterion to a build claim instead of evidence.
- A quiz on a `trivial`, `bugfix`, or `small` lane, or a missing quiz on
  `standard`/`high-risk`.
- A quiz with formatting hints or answers that are not in the artifacts.
- Approving a change you cannot explain in two sentences.
- Missing the risk tier: auth, payments, data, deploy, schema, dependencies.
- Writing `decision.md` and merging without asking the human.
