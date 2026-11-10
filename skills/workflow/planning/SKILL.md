---
name: planning
description: Write one PaganiStack job SPEC.md with requirements, decisions, and a tracer-bullet task graph. Use by the planner subagent after the interview.
---
# PaganiStack Planning
Write one artifact: `.agents/plans/<id>/SPEC.md`. Never code, reviews, or decisions.
Read `interview.md`, the project `SPEC.md`, `PLAN.md`, `AGENTS.md`, `GLOSSARY.md`,
and the code the work touches. Do not guess names; seed missing files with
`pagani seed SPEC.md` and `pagani seed PLAN.md`. Load `codebase-design` for
architecture or testability vocabulary, `domain-modeling` to keep `GLOSSARY.md`
and ADRs current, and `wayfinding` when the work is too big for one spec. The
template is adapted from Matt Pocock's `to-spec` and `to-tickets`; keep its shape.
## Template
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
## Options considered
1. <direction> — <trade-off>
2. <direction> — <trade-off>
Chosen: <direction> because <reason>.
## Implementation decisions
Modules, interfaces, contracts, schema changes, API shapes, state machines.
## Testing decisions
External behaviour, not implementation; the modules tested, seams, prior art.
## Sensors
- `scripts/check`: <tests, lint, types, build>
- `scripts/verify` / agent-browser: <flows, screenshots>
- Neither: <SSO, browser modals, background jobs, data freshness>
## Tasks
### Task 1 — <title>
**What to build:** the end-to-end behaviour, from the user's perspective.
**Blocked by:** <task numbers/titles> or "None (can start immediately)".
**Files and interfaces:** modules, types, or contracts; no stale line numbers.
**Allowed files:** exact paths this task may create or modify. No others.
**Test first:** the failing test or check that proves the task before the fix.
**Done when:** the observable result and the command that proves it.
**Acceptance criteria:**
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
- A task is a tracer bullet: a narrow but complete vertical slice (data, logic, UI, tests), demoable or verifiable alone and one context window.
- Fill `Allowed files`, `Test first`, and `Done when`; an empty field means not ready.
- Prefactoring comes first; a task with no blockers can start immediately. Wide refactors use expand-contract.
- Inline decision-rich prototype code only when a decision depends on it; no stale paths or line numbers.
## Rules
- Synthesize the interview; do not interview again.
- Acceptance criteria are the contract and each is checkable with only the repo; test the highest existing seam, prefer one.
- Show 2-3 directions and trade-offs under `## Options considered`; the user still approves one `SPEC.md`, so not a new checkpoint.
- Use the project's vocabulary, include needed doc updates, prefer the smallest change, and add no options or extras the user did not ask for.
- Put unanswered categories under **Open questions** and stop; the master asks the user and re-runs you. Never invent a product decision.
- Keep the graph acyclic; the first wave holds every task with no blockers. Too vague to task means stop.
## Report
```
WROTE: <file>
OPEN QUESTIONS: <none, or a short list>
NEXT: <what the master should do>
```
## Gotchas
- Horizontal tasks: one layer per task instead of a vertical slice.
- Open questions left inside `SPEC.md` instead of returned to the master.
- Acceptance criteria nobody with only the repo can check.
- A task graph with a cycle, or a first wave missing a ready task.
