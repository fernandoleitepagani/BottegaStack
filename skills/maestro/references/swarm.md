# Swarm

## Start

Open the todo list with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Pick the worker model per **In bottega** below. For a model race, name each arm's model up front.
4. Give each worker its own writable output when it writes. When workers verify or measure commits, each brief names the exact SHAs. A measurement brief also names the method (sample count, what one sample is, order). The worker records both in its result.

## Phase B: Fan out

Spawn all N workers in one message, typed and isolated per **In bottega** below.

When a worker must start from a non-default pushed branch, the brief says to check it out first.

Every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence. A worker that can prove a defect reports `ISSUES` and lists every issue it can prove, not only the first.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Read the terminal results. Drop a result that does not record the SHAs and method its brief names, and respawn that worker once. After a second miss, record a gap. A gap does not count as a pass. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

## Phase D: Report

Return one consolidated in-chat report with a result table, issue one-liners, gaps or dropouts, and the race rule when used.

## In bottega

Adapted from pstack's `swarm` (MIT, see NOTICE). Every bottega fan-out of more than one worker follows this file. These rules take precedence where they differ:

- **Where it runs.** The high-risk review of a large diff (`review.md`, **Verifier swarm**), the optional pre-merge swarm in `/ship full`, `/triage`'s parallel investigation, `/maintain-verification-skill`'s source wave, and a wide `blast-radius.md` check.
- **Todo list:** put the four phases in the todo list.
- **Worker model:** the role's line in the user's model file (`playbooks/setup.md`), else its default in `subagents.md`: `explorer` for read-only slices, `verifier` for checks and repros.
- **Spawning:** read-only workers are explorers, told not to edit files; workers that write or run repros are delegates in their own worktrees, in the background (harness file).
- **Ask first** before spawning more than 3 workers, unless a full-autonomy grant covers it (`subagents.md`).
- **Results** that prove a defect go to `review.md` **Verify findings** before anything is fixed. A gap is never a pass.
