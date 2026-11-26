---
name: autopilot
description: Run a task, ticket queue (PLAN.md), or standing program unattended until checkable exit conditions pass. Always asks upfront whether to auto-merge (/ship full) or stop at verified PRs (/ship stop).
disable-model-invocation: true
---

# Autopilot

**Run by the orchestrator (the main session) while nobody is watching. Define done as a check, decide who does each piece, and prove every result before it lands.** Your updates go unread until long after you stop, so stay active until done: a turn that ends while checks are pending stops the work.

## Before starting: ask the landing mode once

Before editing, spawning, or starting `/loop`, ask the user one question (unless they already specified it in the prompt):

1. **Auto-merge (`/ship full`):** Build, verify, and run `/ship full` (`../ship/SKILL.md`) to watch CI and squash-merge once all gates are green.
2. **Stop at verified PRs (`/ship stop`):** Build, verify, and run `/ship stop` (`../ship/SKILL.md`) to open verified Draft PRs and hand them over without merging.

**Reversibility gate:** Even if the user chose `/ship full`, any PR touching one-way-door surfaces (migrations, data deletion, auth/security, billing, breaking public API contracts, destructive infra/deploy scripts) is forced to `/ship stop` (Draft PR).

## Modes

Name the mode in the first reply and in every `/loop` tick prompt:

- `task`: one task driven to a checkable exit condition ("run until done", "/loop until X").
- `queue`: independent PRs orchestrated from the main session, one worktree per unit. A ticket plan (`.bottega/plans/<slug>/PLAN.md` from `/tickets`) runs as a `queue`: the orchestrator drives each ticket in wave order, delegating only leaf `explorer`, `implementer`, and `reviewer` subagents (never spawning a subagent to run `/implement`, per `../maestro/references/delegate.md`).
- `program`: a standing project over days (many stacked PRs, many agents). Work one agent can finish in one session is `task`, not this.

## Permissions

The user's request for an `/autopilot` run is the permission for these steps (harness-level auto-approve or pre-allowed prefixes are still required so the CLI does not prompt):

- Push and rebase this run's own branches, and `git push --force-with-lease` pinned to the SHA you last pushed or took over. Never touch shared branches.
- Use any test method the proof needs (run the app or dev server, a `verify-<app>` skill) without asking first.
- In `/ship full` mode only (and two-way-door diffs only): merge a PR once all gates pass.

Everything on the **Always pause** list in `../maestro/SKILL.md` (**Autonomy**) still pauses; that list is the single source. A unit that needs the user's hands gets a wizard (`../wizard/SKILL.md`): log it as blocked with the wizard's path, move on to the next unit, and resume it once the wizard's outputs exist.

## Every mode

1. **Exit condition first.** State done as a checkable predicate (tests green, repro fixed, all N PRs verified/merged) and open the run with `bottega start` (registering conditions in `.bottega/proofs.tsv`). Never relax it to declare victory. If requirements are vague or unverifiable, stop and ask instead of running unattended.
2. **Wake.** Use `/loop` (or your harness's recurring schedule). An event to watch (CI, a merge) gets a watcher and a long heartbeat as fallback; no event gets a fixed interval sized to when the result is worth re-checking.
3. **Smallest verified step.** Each iteration makes the smallest change the evidence justifies, verifies it against the predicate, keeps it if it advanced, reverts it if not (**Sequence Work into Verifiable Units**).
4. **Circuit breakers.** Cap fix rounds at 2 per failure class (3rd failure or 2 rounds with no progress → `ESCALATE` and stop). Past ~270k orchestrator tokens, run `../maestro/playbooks/pause.md` and stop cleanly.
5. **Assume you die.** Keep the decision trail below in `.bottega/`, one row per iteration, plus each spawned agent's id, PR, and `stuck_after` threshold (default: 30 minutes wall time or 3 failed attempts without progress), so a replacement can pick up.
6. **Side findings.** Fix what blocks the predicate in its own PR. Log everything else to `.bottega/followups.md`; do not fix it now.
7. **Ask only** for an irreversible step, a product call no experiment settles, or a dead end that survived a replan.

## `queue` and `program`

8. **Orchestrator-driven leaf delegation.** The main session owns the ticket/PR queue, wave ordering, and final gate; each unit's leaf `implementer` runs in its own isolated worktree (`subagents.md`) as the only writer of its branch. Cap fan-out: worktree runs share CPU, ports, and disk.
9. **Start with one unit.** Take the first PR through kickoff, verification, and `/ship` before fanning out, so a flawed kickoff costs one unit.
10. **Verify independently.** Nothing ships until fresh reviewers that never wrote the code prove it. Run `../maestro/references/review.md` (at high risk or opted-in `/ship full`, use the high-risk review: a blast-radius check for a diff of 100 lines or fewer, else the **Verifier swarm**, with a live lane through `verify-<app>` when present).
11. **Ship & merge.** Hand each verified PR to `../ship/SKILL.md`:
    - `/ship full` (two-way doors only) → watches CI, fixes legitimate failures within cap, merges bottom-up. Confirm `git patch-id` at the verdict SHA matches the head before merging; hold past a third rebase.
    - `/ship stop` (or any one-way door) → Draft PR, no merge, no further pushes after handoff.
12. **Supervise by side effects.** Read the diff, not the summary. Replace stuck leaf agents past `stuck_after` (default 30m / 3 failed attempts) with a fresh one carrying its consolidated brief; after two retries, drop the unit and replan.
13. **`program` only:** You never write code directly; delegate all writes to leaf implementers in isolated worktrees.
14. **On the operator's stop,** every active worker gets a zero-writes hold, reports where it stands, and keeps its brief.

## Decision trail

Any unattended run keeps an append-only trail in `.bottega/decisions.tsv` (or `.bottega/<task-slug>.tsv`), columns `ts phase decision why evidence result`, written with `../maestro/scripts/log.sh`. Log decision points (forks, unit verdicts, pivots/reverts, blockers): one row per loop iteration, evidence as pointers (SHA, PR, `file:line`, artifact path). Before handing back, audit the trail against the session transcript; at high risk, have a `reviewer` check it. Keep it local (never commit unless asked).

**Reply:** Catch the user up per **Catch-up** in `../maestro/playbooks/investigation.md`: exit condition and whether it holds, each PR's state and link, what was discarded/dropped and why, and any calls waiting on the user. Run through `../unslop/SKILL.md`.
