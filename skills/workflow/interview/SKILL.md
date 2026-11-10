---
name: interview
description: Conduct the BottegaStack plan interview. Use when starting a new run, before planning, to ask targeted questions with the native question UI until every requirement, use case, edge case, constraint, and acceptance criterion is covered.
---

# BottegaStack Interview

Turn a vague request into a complete plan. The master runs this skill; the
planner does not.

## Base skills
- Load `domain-modeling` when a term needs sharpening, or when a decision
  belongs in `GLOSSARY.md` or an ADR.
- The user can invoke `wait-what`. If they say "wait, what?", re-pitch in
  simplified English using the project's glossary.

## Design-tree rounds

Map the interview as a design tree: every decision branches into the decisions
that hang off it. Work in rounds. The **frontier** is every decision whose
prerequisites are already settled: the questions you can ask now without
guessing.

Ask the whole frontier in one round. Number each question and give your
recommended answer. Then wait before the next round.

```
❓ **Q1** — **<question title>**: <question body, options if useful>

➡️ <your recommended answer>

---

❓ **Q2** — **<question title>**: <question body>

➡️ <your recommended answer>
```

Word each question so "yes" accepts your recommendation. Finding facts is your
job, not the user's: if a question needs a fact from the repo or a tool, look
it up. The decisions are the user's: put each to them and wait.

Each answer pushes the frontier outward and unblocks dependent questions. A
question that depends on another open question belongs to a later round. Stop
when the frontier is empty: every branch visited, nothing silently assumed. Do
not hand the plan to the planner until the user confirms the shared
understanding.

## Rules
- Explore first. Read `AGENTS.md`, `GLOSSARY.md`, and the code the request
  touches. Never ask a question the repository already answers.
- Ask 3-5 questions per `question` call, not twenty. The tool always offers a
  free-form answer; add options where they help, recommended answer first.
- Ask only what changes the plan: a requirement, use case, constraint, or test.
- Do not invent product decisions. Pricing, public copy, permissions, and
  "free vs paid" belong to the user.
- Keep a small request small; do not inflate a one-line fix into product
  discovery.
- Keep asking until every category below is answered or explicitly accepted as
  an assumption. Then return the interview answers and stop.

## Question checklist

| Category | Ask |
|---|---|
| Problem and goal | What problem, for whom, why now? Success in one sentence. |
| Users and actors | Who uses it, with what roles? Who must not? What changes for existing users? |
| Use cases | Primary and alternate flows; empty, loading, error, first run, repeat, cancel, network failure, slow response; long text, missing or duplicate data, zero or many items. |
| Scope | What is in, out, and must not change: APIs, schemas, user state, deploy config, dependencies, behaviour? |
| Constraints | Stack, styling, compatibility, performance, accessibility, i18n, data model and API contracts. |
| Acceptance criteria | Which observable behaviour proves each requirement? How do we verify: command, page, file, screenshot? What must be true before merge? |
| UI and UX | Layout, copy, responsive, interaction states; existing components, patterns, and tokens to follow. |
| Security and privacy | Auth, permissions, validation, data exposure in responses, logs, URLs; secrets, abuse limits, storage, retention. |
| Testing | What to test, at which seams, with which fixtures and browser checks? |
| Rollout | Migrations, feature flags, deploy steps, rollback. |
| Risks and unknowns | What could go wrong, what is unknown, what would make us stop? |
| Definition of done | What must be true before the human merges, and what evidence should review see? |

## Stop condition

Stop when every category is answered or explicitly accepted as an assumption.
Record genuine unknowns under **Assumptions** or **Open questions**; never
guess silently.

## Return the interview

The answers live in the conversation. Return them as your reply, or keep them
in chat when you are the master, using these headings:

```markdown
# Interview: <feature>

## Request
The user's request, verbatim.

## Decisions
- <decision> — <why>

## Use cases
1. <flow>
2. <edge case>

## Scope
### In
### Out

## Constraints
## Acceptance criteria
## UI / UX
## Security and privacy
## Testing and verification
## Rollout and rollback
## Assumptions
## Open questions
## Definition of done
## Risks
```

## Gotchas

- Asking more than 3-5 questions in one batch.
- Asking what the repo conventions already answer.
- Letting a vague answer pass without a concrete acceptance criterion.
- Filling gaps with invented requirements or product decisions.
- Planning with an open question.
- Writing the answers to a file instead of keeping them in chat.
