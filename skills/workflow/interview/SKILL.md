---
name: interview
description: Conduct the PaganiStack plan interview. Use when starting a new job, before writing plan.md, to ask targeted questions with the native question UI until every requirement, use case, edge case, constraint, and acceptance criterion is covered.
---

# PaganiStack Interview

Turn a vague request into a complete plan. The master runs this skill; the
planner does not.

## Base skills

- Load `domain-modeling` when a term needs sharpening, or when a decision belongs
  in `GLOSSARY.md` or an ADR.
- If the user says "wait, what?", re-pitch in simplified English using the
  project's glossary. The `wait-what` skill is available for the user to invoke.

## Design-tree rounds

Map the interview as a design tree: every decision branches into the decisions
that hang off it. Work it in rounds. The **frontier** is every decision whose
prerequisites are already settled: the questions you can ask now without
guessing at answers you have not heard yet.

Ask the whole frontier in one round. Number each question and give your
recommended answer. Then wait for the answers before the next round.

```
❓ **Q1** — **<question title>**: <question body, options if useful>

➡️ <your recommended answer>

---

❓ **Q2** — **<question title>**: <question body>

➡️ <your recommended answer>
```

Word each question so "yes" accepts your recommendation. Finding facts is your
job, not the user's: if a question needs a fact from the repo or a tool, look it
up. The decisions are the user's: put each to them and wait.

Each answer reshapes the tree: settled decisions push the frontier outward and
unblock questions that depended on them. A question whose answer depends on
another open question belongs to a later round. Stop when the frontier is empty:
every branch visited, nothing silently assumed. Do not write `plan.md` until the
user confirms the shared understanding.

## Rules

- Explore first. Read `AGENTS.md`, `GLOSSARY.md`, and the code the request
  touches. Never ask a question the repository already answers.
- Ask 3-5 questions per `question` call, not twenty. The tool always offers a
  free-form answer; add options where they help. Put your recommended answer
  first in the options.
- Ask only what changes the plan. If the answer would not change a requirement,
  a use case, a constraint, or a test, do not ask it.
- Keep asking until every category below is answered or explicitly accepted as
  an assumption. Then write `interview.md` and stop.
- Do not invent product decisions. Pricing, public copy, permissions, and
  "free vs paid" belong to the user.
- If the request is small, say so and keep the interview short. Do not inflate
  a one-line fix into a product discovery session.

## Question checklist

### 1. Problem and goal

- What problem does this solve, and for whom?
- Why now?
- What does success look like in one sentence?

### 2. Users and actors

- Who uses it? Signed in, signed out, different roles?
- Who must not be able to use it?
- What changes for existing users?

### 3. Use cases

- Primary flow, step by step.
- Alternate flows.
- Empty, loading, and error states.
- First run and repeat use.
- Cancelled action, network failure, slow response.
- Edge cases: long text, missing data, duplicate action, zero items, many items.

### 4. Scope

- What is in scope?
- What is explicitly out of scope?
- What must not change: public APIs, schemas, user state, deploy config,
  dependencies, existing behaviour?

### 5. Constraints

- Stack, framework, language, styling system.
- Backwards compatibility.
- Performance budget.
- Accessibility requirements.
- i18n and copy language.
- Data model and API contracts.

### 6. Acceptance criteria

- What observable behaviour proves each requirement?
- How will we verify it: command, page, file, screenshot?
- What must be true before merge?

### 7. UI and UX

- Layout, copy, responsive behaviour.
- Interaction details: hover, focus, disabled, loading.
- Which existing components and patterns should it match?
- Design-system tokens or guidelines to follow.

### 8. Security and privacy

- Auth and permissions.
- User input and validation.
- Data exposure in responses, logs, URLs.
- Secrets.
- Abuse and rate limits.
- Storage and retention.

### 9. Testing

- What should be tested?
- Which seams?
- Fixtures and test data.
- Browser checks.

### 10. Rollout

- Schema changes or migrations.
- Feature flags.
- Deploy steps.
- Rollback plan.

### 11. Risks and unknowns

- What could go wrong?
- What do we not know yet?
- What would make us stop?

### 12. Definition of done

- What must be true before the human merges?
- What evidence should the approver see?

## Stop condition

Stop when every category is answered or explicitly accepted as an assumption.
If something is still unknown but the user is comfortable proceeding, record it
under **Assumptions** or **Open questions**; do not silently guess.

## Write `interview.md`

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

## Anti-patterns

- A wall of twenty questions.
- Asking about things the code already shows.
- Asking the user to make a decision the repo conventions already make.
- Filling gaps with invented requirements.
- Proceeding to `plan.md` with unresolved product decisions.

## Gotchas

- Asking more than 3-5 questions in one batch.
- Asking what the repository already answers.
- Inventing a product decision the user did not make.
- Letting a vague answer pass without a concrete acceptance criterion.
- Proceeding to `plan.md` with an open question.
