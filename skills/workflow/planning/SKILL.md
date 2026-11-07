---
name: planning
description: Write one PaganiStack job SPEC.md with requirements, decisions, and a tracer-bullet task graph. Use by the planner subagent after the interview.
---

# PaganiStack Planning

You write one planning artifact: `pagani/jobs/<id>/SPEC.md`. You never write
code, reviews, or decisions. Your prompt names the job folder.

Read `interview.md`, the project `SPEC.md`, `ROADMAP.md`, `TASKS.md`, `AGENTS.md`,
`GLOSSARY.md`, and the code the work touches. Do not guess at names.

## Base skills

- The template below is adapted from Matt Pocock's `to-spec` and `to-tickets`.
  Keep its shape; do not invent a different spec format.
- Load `codebase-design` for module, interface, depth, seam, and adapter
  vocabulary when the spec touches architecture or testability.
- Load `domain-modeling` to keep `GLOSSARY.md` and ADRs current as decisions
  land.
- If the work is too big for one spec, load `wayfinding` first and settle the
  destination and decisions before writing it.

## Write `pagani/jobs/<id>/SPEC.md`

```markdown
# Spec: <title>

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

## Implementation decisions
Modules, interfaces, contracts, schema changes, API shapes, state machines.
No stale file paths. If a prototype encoded a decision, inline the decision-rich
part and say it came from a prototype.

## Testing decisions
What makes a good test (external behaviour, not implementation details), which
modules are tested, the seams, and prior art in the repo.

## Sensors
- `scripts/check` covers: <tests, lint, types, build>
- `scripts/verify` / agent-browser covers: <flows, screenshots>
- Neither covers: <SSO, browser modals, background jobs, data freshness>

## Tasks
### Task 1 — <title>
**What to build:** the end-to-end behaviour this task makes work, from the
user's perspective.

**Blocked by:** <task numbers/titles> or "None (can start immediately)".

**Files and interfaces:** the modules, components, types, or contracts this
task touches. No stale line numbers.

**Allowed files:** exact paths this task may create or modify. No other files.

**Test first:** the failing test or check that proves the task before the fix.

**Done when:** the observable result and the command that proves it.

**Acceptance criteria:**
- [ ] <criterion>
- [ ] <criterion>

**Verification:** the exact command, page, or check that proves it.

### Task 2 — <title>
...

## UI / UX
## Security and privacy
## Rollout and rollback
## Assumptions
## Open questions
## Definition of done
## Risks
```

## Task rules

- A task is a **tracer bullet**: a narrow but complete vertical slice through
  every layer (data, logic, UI, tests). It is demoable or verifiable on its own.
- It fits one fresh context window.
- Fill `Allowed files`, `Test first`, and `Done when` for every task. A task
  with an empty `Allowed files` or `Done when` is not ready.
- Prefactoring comes first.
- A task with no blockers can start immediately.
- Wide refactors are the exception: use expand–contract, with the expand first,
  migrate batches next, and contract last.
- No file paths or code snippets that will go stale, unless a decision depends
  on them.

## Rules

- Synthesize the interview. Do not interview again.
- Acceptance criteria are the contract. Every one must be checkable by someone
  who only has the repo.
- Use the highest existing seam for tests. Prefer one seam over many.
- Include doc updates the change needs.
- Use the project's domain vocabulary.
- Prefer the smallest change that fully meets the request.
- Do not add options, fallbacks, or extras the user did not ask for.
- If a category is genuinely unanswered, put it under **Open questions** and
  stop. The master will ask the user and re-run you. Do not invent a product
  decision.
- The task graph must have no cycles. The first wave contains every task with
  no blockers.
- If the request is too vague to task, stop and say so; do not invent scope.

## Report

```
WROTE: <file>
OPEN QUESTIONS: <none, or a short list>
NEXT: <what the master should do>
```

## Gotchas

- Horizontal tasks: one layer per task instead of a vertical slice.
- Leaving open questions inside `SPEC.md` instead of returning them to the
  master.
- Acceptance criteria that cannot be checked by someone with only the repo.
- Adding options or fallbacks the request did not ask for.
- A task without a test-first check or an allowed-files list.
- Stale file paths or line numbers.
- A task graph with a cycle, or a first wave that is missing a ready task.
