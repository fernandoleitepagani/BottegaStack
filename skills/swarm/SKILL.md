---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report; also the high-risk verifier swarm for a large diff. Adapted from pstack's swarm. Use for /swarm, 'swarm this', parallel coverage, races, or a high-risk review of a large diff."
disable-model-invocation: true
---

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

- **Where it runs.** The high-risk review of a large diff (**Verifier swarm** below), the optional pre-merge swarm in `/ship full`, `/triage`'s parallel investigation, `/maintain-verification-skill`'s source wave, and a wide blast-radius check (`../blast-radius/SKILL.md`).
- **Todo list:** put the four phases in the todo list.
- **Worker model:** the role's line in the user's model file (`../setup-bottega/SKILL.md`), else its default in the router's **Subagents** table (`../maestro/SKILL.md`): `explorer` for read-only slices, `verifier` for checks and repros.
- **Spawning:** read-only workers are explorers, told not to edit files; workers that write or run repros are delegates in their own worktrees, in the background (harness file).
- **Ask first** before spawning more than 3 workers, unless a full-autonomy grant covers it (router **Subagents**).
- **Results** that prove a defect go to `../review/SKILL.md` **Verify findings** before anything is fixed. A gap is never a pass.

## Verifier swarm (large high-risk diff, or opted-in `/ship full`)

For a high-risk diff over 100 lines or 2 files, or when the user opts into it on `/ship full`, run a coverage swarm (this skill) of 3 `verifier` workers (1 to 4 on request), one per slice:

1. **Regression:** drive existing features end to end through the project's `verify-<app>` skill, or its integration suite, to catch breakage outside the diff.
2. **Edge cases:** run the **Adversarial brief** below.
3. **Contract:** try to violate the acceptance criteria, state invariants or public contracts; include a blast-radius pass (`../blast-radius/SKILL.md`) on the riskiest shared interface.

Only findings with a runnable reproduction count. Merge them into one list for `../review/SKILL.md` **Verify findings**, then `../review/fix.md`, and log the combined verdict as the `crossfire` row (`../maestro/playbooks/final-gate.md`, **Crossfire row**).

## Adversarial brief (the edge-case slice)

> Break this change. Read the goal, the check output, and the full diff, each changed file in full. Prove each finding with a run against the real code: a failing test, a repro script, or output showing the wrong behavior. Keep repros in a scratch or worktree location. Report each finding as title, `file:line`, the exact command, the output it printed, and the output the goal requires. Anything you did not run is a note, not a finding. Skip style and naming. No findings is a valid result.
>
> Try: empty, null, zero, one, many. Duplicate actions, retries, double submits. Timeouts and partial failure. Concurrent writes. Permission boundaries (another user, another tenant, signed out). Data loss and rollback. Injection into HTML, SQL, shell, paths, URLs. Old, new, and mixed data across a migration. (Breakage outside the diff is the blast-radius check's job.)
