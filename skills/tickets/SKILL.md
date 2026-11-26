---
name: tickets
description: "Split a spec into tickets that each fit one fresh orchestrator session (one vertical slice that one session finishes without compacting), with the orchestrator/subagent split, roles and abstract model tiers (heavy, medium, standard, fast), and an implementation order with parallel waves. Use for /tickets, 'break this into tickets', or after /plan."
disable-model-invocation: true
---

# Tickets

Turn a spec into tickets. Each ticket is one fresh `/implement` session. The output says, for every ticket, what the orchestrator does itself, what it hands to which subagents, when the ticket can run, and which model runs its orchestrator.

The slicing rules are adapted from Matt Pocock's `to-tickets` skill (github.com/mattpocock/skills, MIT).

`<maestro dir>` is `../maestro` from this file, as an absolute path. Roles, subagent types and models come from `<maestro dir>/SKILL.md`, **Subagents**.

## Input

A spec path (`.bottega/plans/<slug>/spec.md`), or the plan agreed in this conversation. With neither, route to `/plan` (`../plan/SKILL.md`). Read the spec in full, then explore the code it touches with explorer subagents (`<maestro dir>/playbooks/investigation.md`). Measure the files the tickets will touch with `wc -c`: you need the sizes for the budget.

## 1. Slice

- **Vertical, not horizontal.** Each ticket cuts a thin path through every layer it needs (types, logic, interface, tests) and is demoable or checkable on its own. "All the types", "all the API" or "all the tests" is not a ticket.
- **One session each.** Every ticket fits the session budget below. Split any ticket over it, and merge tickets so small that the session overhead dominates (under about 60k).
- **Prefactor first.** When the change is hard to make in the current structure, the first ticket reshapes it, behavior unchanged ("make the change easy, then make the easy change").
- **Wide refactors** go expand, migrate, contract: add the new path, move callers in batches (a ticket per batch), delete the old path.
- **Acceptance criteria are checks.** Each is a command or observation and the output that proves it, drawn from the spec's **Done when** and **Test seams**.

## 2. Size each ticket

Each ticket is one vertical slice that a fresh orchestrator session can finish without compacting its context. Split a ticket that needs more than one session's worth of reading, review or fix rounds. Keep the orchestrator lean: push wide reads into explorer subagents and read yourself only the files you must judge (the diff and the data shape).

## 3. Split the work inside each ticket

**The orchestrator does:** read the ticket, decide the data shape and the interfaces, write the subagent briefs, review every diff, run or check the acceptance criteria, and run the final gate. It writes code itself only for an edit of a few lines that would cost more to brief than to make.

**Subagents do** everything else. Name each one with its role and abstract tier from the router's **Subagents** table (`<maestro dir>/SKILL.md`) at the ticket's difficulty (spawn fields and concrete models come from the harness file, `<maestro dir>/harness/<your harness>.md`):

- **explorer**: read-only mapping, tracing, and fact-finding (`fast`).
- **implementer**: writes code and tests in one scope (`standard`, or `medium` at high risk). Isolate in a separate worktree/branch when implementers run in parallel.
- **reviewer**: reviews the finished diff against the ticket and runs repros (`<maestro dir>/../review/SKILL.md`). At high risk the blast-radius check or verifier swarm runs on the `verifier` role.

Mark which subagents run in parallel. Two subagents run in parallel only when their write sets don't overlap.

## 4. Order and parallel waves

- **Blocked by.** A ticket is blocked by every ticket whose output it reads or builds on.
- **Shared files.** Two tickets that write the same file are serialized even when neither depends on the other (**Separate Before Serializing Shared State**). Put the earlier one in `Blocked by`.
- **Waves.** Wave 1 is every ticket with no blockers. Wave N is every ticket whose blockers are all in earlier waves. Tickets in one wave run in parallel, one session each, each in its own git worktree.

## 5. Pick the abstract model tiers

Pick the **lowest abstract tier** (`heavy`, `medium`, `standard`, `fast`, mapped per harness in the harness file's **Models** table) that uses the least tokens/limits while remaining as precise as needed, for **both** the orchestrator and every subagent:

- **`heavy`**: high risk, auth/security, concurrency, data migrations, shared interfaces across >3 modules, or the high-risk verifier.
- **`medium`**: open design decisions inside the ticket, multi-file coordination, tricky debugging, or high-risk implementer/reviewer.
- **`standard`**: well-scoped normal-risk orchestrator, standard implementers and reviewers.
- **`fast`**: explorers, codebase mapping, read-only fact-finding.

The user sets the orchestrator model at the start of the ticket's fresh session (using their harness file's **Models** table).

## 6. Agree, then write

Show the breakdown as one numbered table: ticket, title, blocked by, wave, orchestrator tier, risk. Ask the user directly in chat: Is the granularity right? Are the blocking edges right? Should any tickets merge or split? Iterate until they approve. Then write the files:

**`.bottega/plans/<slug>/tickets/T<nn>-<slug>.md`**, one per ticket, numbered blockers first:

```markdown
# T<nn> <title>
Status: todo | in-progress | done | blocked: <why>
Blocked by: T<nn>, ... | none
Wave: <n>
Risk: normal | high
Orchestrator: heavy | medium | standard | fast: <why>

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
2. `/model` to your harness's translation of the ticket's `Orchestrator` tier (harness file, **Models**).
3. `/implement .bottega/plans/<slug>/tickets/T<nn>-<slug>.md`
```

With GitHub on request (the user names the repo), also create one issue per ticket with `gh issue create`, after one confirmation listing them all, and put each issue link in its ticket file.

**Reply:** the table, the waves, the total estimated budget, and the command for the first ticket.
