---
name: planning
description: Write PaganiStack plan.md, spec.md, and the tracer-bullet ticket graph. Use in planner mode PLAN, SPEC, or TICKETS.
---

# PaganiStack Planning

You write planning artifacts. You never write code, reviews, or decisions. Your
prompt names the job folder and one mode: `PLAN`, `SPEC`, or `TICKETS`.

Read the project `AGENTS.md` and `GLOSSARY.md` first. Read the code the work
touches; do not guess at names.

## Base skills

- The templates below are adapted from Matt Pocock's `to-spec` and `to-tickets`.
  Keep their shape; do not invent a different spec format.
- Load `codebase-design` for module, interface, depth, seam, and adapter
  vocabulary when the plan touches architecture or testability.
- Load `domain-modeling` to keep `GLOSSARY.md` and ADRs current as decisions
  land.
- If the work is too big for one spec, load `wayfinding` first and settle
  the destination and decisions before writing this plan.

## MODE: PLAN

Read `pagani/jobs/<id>/interview.md` and the code. Write
`pagani/jobs/<id>/plan.md`.

```markdown
# Plan: <title>

## Problem
## Goal
## Users and actors
## Use cases
1. <primary flow>
2. <alternate flow>
3. <empty / loading / error state>
4. <edge case>

## Scope
### In
### Out

## Constraints
## Acceptance criteria
1. <observable behaviour> — verify by <command / page / file>
## UI / UX
## Security and privacy
## Testing and verification
## Rollout and rollback
## Assumptions
## Open questions
## Definition of done
## Risks
```

Rules:

- Synthesize the interview. Do not interview again.
- If a category is genuinely unanswered, put it under **Open questions** and
  stop. The master will ask the user and re-run you.
- Use the project's domain vocabulary.
- Prefer the smallest change that fully meets the request.
- Do not add options, fallbacks, or extras the user did not ask for.
- No stale file paths or code snippets unless a decision depends on them.

## MODE: SPEC

Read `plan.md`, `AGENTS.md`, and the code. Write `pagani/jobs/<id>/spec.md`.

```markdown
# <title>

## Problem Statement
The problem from the user's perspective.

## Solution
The solution from the user's perspective.

## User Stories
1. As a <actor>, I want <feature>, so that <benefit>.

## Implementation Decisions
Modules, interfaces, contracts, schema changes, API shapes, state machines.
No stale file paths. If a prototype encoded a decision, inline the decision-rich
part and say it came from a prototype.

## Testing Decisions
What makes a good test (external behaviour, not implementation details), which
modules are tested, the seams, and prior art in the repo.

## Acceptance Criteria
1. <observable behaviour> — verify by <command / page / file>.

## Out of Scope
## Assumptions
## Further Notes
```

Rules:

- Acceptance criteria are the contract. Every one must be checkable by someone
  who only has the repo.
- Use the highest existing seam for tests. Prefer one seam over many.
- Include doc updates the change needs.
- If something is missing, put it under **Assumptions** or return an open
  question; do not invent a product decision.

## MODE: TICKETS

Read `spec.md`, `plan.md`, and the code. Write:

- `pagani/jobs/<id>/tickets/index.md` — the task graph.
- `pagani/jobs/<id>/tickets/<NN>-<slug>.md` — one file per ticket.

### Ticket rules

- A ticket is a **tracer bullet**: a narrow but complete vertical slice through
  every layer (data, logic, UI, tests). It is demoable or verifiable on its own.
- It fits one fresh context window.
- Prefactoring comes first.
- A ticket with no blockers can start immediately.
- Wide refactors are the exception: use expand–contract, with the expand first,
  migrate batches next, and contract last.
- No file paths or code snippets that will go stale, unless a decision depends
  on them.

### `index.md`

```markdown
# Tickets: <spec title>

## Graph
- 01-<slug> — blocked by: none
- 02-<slug> — blocked by: 01-<slug>
- 03-<slug> — blocked by: 01-<slug>

## Waves
- Wave 1: 01-<slug>
- Wave 2: 02-<slug>, 03-<slug>

## Notes
```

### One ticket

```markdown
# <NN>: <title>

**What to build:** the end-to-end behaviour this ticket makes work, from the
user's perspective.

**Blocked by:** <ticket numbers/titles> or "None (can start immediately)".

**Files and interfaces:** the modules, components, types, or contracts this
ticket touches. No stale line numbers.

**Acceptance criteria:**
- [ ] <criterion>
- [ ] <criterion>

**Verification:** the exact command, page, or check that proves it.
```

Rules:

- Every ticket must be independently verifiable.
- The graph must have no cycles.
- The first wave must contain every ticket with no blockers.
- If the spec is too vague to ticket, stop and say so; do not invent scope.

## Report

```
MODE: <mode>
WROTE: <files>
OPEN QUESTIONS: <none, or a short list>
NEXT: <what the master should do>
```

## Gotchas

- Horizontal tickets: one layer per ticket instead of a vertical slice.
- Leaving open questions inside `spec.md` instead of returning them to the master.
- Acceptance criteria that cannot be checked by someone with only the repo.
- Adding options or fallbacks the request did not ask for.
- Stale file paths or line numbers.
