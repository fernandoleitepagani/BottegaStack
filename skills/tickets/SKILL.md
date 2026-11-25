---
name: tickets
description: "Split a spec into tickets that each fit one fresh orchestrator session (300k tokens, ±10%), with the orchestrator/subagent split, roles and models, an implementation order with parallel waves, and an opus- or sonnet-level orchestrator per ticket. Use for /tickets, 'break this into tickets', or after /plan."
disable-model-invocation: true
---

# Tickets

Turn a spec into tickets. Each ticket is one fresh `/implement` session. The output says, for every ticket, what the orchestrator does itself, what it hands to which subagents, when the ticket can run, and which model runs its orchestrator.

The slicing rules are adapted from Matt Pocock's `to-tickets` skill (github.com/mattpocock/skills, MIT).

`<maestro dir>` is `../maestro` from this file, as an absolute path. Roles, subagent types and models come from `<maestro dir>/references/subagents.md`.

## Input

A spec path (`.bottega/plans/<slug>/spec.md`), or the plan agreed in this conversation. With neither, route to `/plan` (`../plan/SKILL.md`). Read the spec in full, then explore the code it touches with explorer subagents (`<maestro dir>/references/explore.md`). Measure the files the tickets will touch with `wc -c`: you need the sizes for the budget.

## 1. Slice

- **Vertical, not horizontal.** Each ticket cuts a thin path through every layer it needs (types, logic, interface, tests) and is demoable or checkable on its own. "All the types", "all the API" or "all the tests" is not a ticket.
- **One session each.** Every ticket fits the session budget below. Split any ticket over it, and merge tickets so small that the session overhead dominates (under about 60k).
- **Prefactor first.** When the change is hard to make in the current structure, the first ticket reshapes it, behavior unchanged ("make the change easy, then make the easy change").
- **Wide refactors** go expand, migrate, contract: add the new path, move callers in batches (a ticket per batch), delete the old path.
- **Acceptance criteria are checks.** Each is a command or observation and the output that proves it, drawn from the spec's **Done when** and **Test seams**.

## 2. Budget each ticket (orchestrator only)

The budget is the orchestrator's own context in a fresh session: **300k tokens, ±10% (hard limit 330k)**. Subagent contexts don't count; only their briefs and reports do. Estimate in tokens, at about 4 characters per token:

| Item | Estimate |
|---|---|
| Session overhead (system prompt, tools, CLAUDE.md, maestro, `/implement`, references) | 45k, or the figure `/context` showed at the start of the last fresh session |
| Ticket and spec | file size ÷ 4 |
| Files the orchestrator reads itself | file size ÷ 4 for each, counted once |
| Each subagent | about 5k (brief plus report) |
| Diff review and the gate | 2 × diff size ÷ 4, plus 10k |
| Tool output and replies | 20% of everything above |

Plan each ticket at or under **300k**. Split one estimated above it. The 10% band up to 330k is slack for surprises during the run, not planned room: `/implement` hands off before passing 330k.

To keep the orchestrator inside budget, push wide reads into explorer subagents and have the orchestrator read only the files it must judge: the ones it reviews in the diff and the ones that hold the data shape.

## 3. Split the work inside each ticket

**The orchestrator does:** read the ticket, decide the data shape and the interfaces, write the subagent briefs, review every diff, run or check the acceptance criteria, and run the final gate. It writes code itself only for an edit of a few lines that would cost more to brief than to make.

**Subagents do** everything else. Name each one with its role, its `subagent_type`, and its model and effort from the role table at the ticket's risk:

- **explorer** (`Explore`): read-only mapping, tracing, and fact-finding.
- **implementer** (`bottega:maestro-agent`): writes code and tests in one scope. Use `isolation: "worktree"` when two implementers run at once.
- **reviewer** (`bottega:maestro-agent`): reviews the finished diff against the ticket and runs repros (`<maestro dir>/references/review.md`). At high risk it is also the adversarial review.

Mark which subagents run in parallel. Two subagents run in parallel only when their write sets don't overlap.

## 4. Order and parallel waves

- **Blocked by.** A ticket is blocked by every ticket whose output it reads or builds on.
- **Shared files.** Two tickets that write the same file are serialized even when neither depends on the other (**Separate Before Serializing Shared State**). Put the earlier one in `Blocked by`.
- **Waves.** Wave 1 is every ticket with no blockers. Wave N is every ticket whose blockers are all in earlier waves. Tickets in one wave run in parallel, one session each, each in its own git worktree.

## 5. Pick the abstract model tiers

Pick the **lowest abstract tier** (`heavy`, `medium`, `standard`, `fast` — mapped per harness in `<maestro dir>/references/models.md`) that uses the least tokens/limits while remaining as precise as needed, for **both** the orchestrator and every subagent:

- **`heavy`**: high risk, auth/security, concurrency, data migrations, shared interfaces across >3 modules, or adversarial crossfire.
- **`medium`**: open design decisions inside the ticket, multi-file coordination, tricky debugging, or high-risk implementer/reviewer.
- **`standard`**: well-scoped normal-risk orchestrator, standard implementers and reviewers.
- **`fast`**: explorers, codebase mapping, read-only fact-finding.

The user sets the orchestrator model at the start of the ticket's fresh session (using their harness's translation of the tier in `references/models.md`).

## 6. Agree, then write

Show the breakdown as one numbered table: ticket, title, blocked by, wave, orchestrator tier, budget estimate, risk. Ask the user directly in chat: Is the granularity right? Are the blocking edges right? Should any tickets merge or split? Iterate until they approve. Then write the files:

**`.bottega/plans/<slug>/tickets/T<nn>-<slug>.md`**, one per ticket, numbered blockers first:

```markdown
# T<nn> <title>
Status: todo
Blocked by: T<nn>, ... | none
Wave: <n>
Risk: normal | high
Orchestrator: heavy | medium | standard | fast — <why>
Budget: ~<n>k of 300k (overhead <n>k, reads <n>k, <n> subagents <n>k, diff and gate <n>k, margin <n>k)

## What to build
<the vertical slice, in two to five lines>
## Acceptance criteria
- [ ] <command or observation> → <the output that proves it>
## Files
- Writes: <paths or globs>
- Orchestrator reads: <paths>
## Orchestrator does
- <decisions, reviews, checks, the gate>
## Subagents
| # | Role | Tier | Task | Writes | Runs with |
|---|---|---|---|---|---|
| 1 | explorer | fast | <task> | none | 2 |
## Notes
<spec decisions this ticket depends on, gotchas>
```

**`.bottega/plans/<slug>/PLAN.md`**:

```markdown
# <title>: plan
Spec: spec.md

| Ticket | Title | Blocked by | Wave | Orchestrator | Budget | Risk | Status |
|---|---|---|---|---|---|---|---|

## Order
- Wave 1 (parallel): T01, T02 (no shared writes)
- Wave 2: T03 (needs T01)

## Running a ticket
1. Fresh session (`/clear`, or a new terminal; one git worktree per parallel ticket).
2. `/model <level from the ticket>`.
3. `/implement .bottega/plans/<slug>/tickets/T<nn>-<slug>.md`
```

With GitHub on request (the user names the repo), also create one issue per ticket with `gh issue create`, after one confirmation listing them all, and put each issue link in its ticket file.

**Reply:** the table, the waves, the total estimated budget, and the command for the first ticket.
