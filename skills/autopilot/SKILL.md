---
name: autopilot
description: Run a task, ticket queue (PLAN.md), or standing program unattended until checkable exit conditions pass. Always asks upfront whether to auto-merge (/ship full) or stop at verified PRs (/ship stop).
disable-model-invocation: true
---

# Autopilot

**You own the outcome while nobody is watching. Define done as a check, decide who does each piece, and prove every result before it lands.** Your updates go unread until long after you stop, so stay active until done: a turn that ends while checks are pending stops the work.

## Before starting: ask the landing mode once

Before editing, spawning, or starting `/loop`, ask the user one question (unless they already specified it in the prompt):

1. **Auto-merge (`land`):** Build, verify, and run `/ship full` (`../ship/SKILL.md`) to watch CI and squash-merge once all gates are green.
2. **Stop at verified PRs (`stack`):** Build, verify, and run `/ship stop` (`../ship/SKILL.md`) to open verified Draft PRs and hand them over without merging.

**Reversibility gate:** Even if the user chose `land`, any PR touching one-way-door surfaces (migrations, data deletion, auth/security, billing, breaking public API contracts, destructive infra/deploy scripts) is forced to `stack` (`/ship stop`).

## Modes

Name the mode in the first reply and in every `/loop` tick prompt:

- `task`: one task driven to a checkable exit condition ("run until done", "/loop until X").
- `queue`: independent PRs, one owner each. A ticket plan (`.bottega/plans/<slug>/PLAN.md` from `/tickets`) runs as a `queue`: each ticket is one unit, its owner runs `/implement` (`../implement/SKILL.md`) with `isolation: "worktree"`, and the waves set the order.
- `program`: a standing project over days (many stacked PRs, many agents). Work one agent can finish in one session is `task`, not this.

## Permissions

The user's request for an `/autopilot` run is the permission for these steps (harness-level auto-approve or pre-allowed prefixes are still required so the CLI does not prompt):

- Push and rebase this run's own branches, and `git push --force-with-lease` pinned to the SHA you last pushed or took over. Never touch shared branches.
- Use any test method the proof needs (run the app or dev server, a `verify-<app>` skill) without asking first.
- In `land` mode only (and two-way-door diffs only): merge a PR via `/ship full` once all gates pass.

Everything on the **Always pause** list in `../maestro/SKILL.md` (**Autonomy**) still pauses: deploys, data deletion, customer messages, force-push to shared branches, and forge-enforced approvals.

## Every mode

1. **Exit condition first.** State done as a checkable predicate (tests green, repro fixed, all N PRs verified/merged) registered in `.bottega/proofs.tsv`. Never relax it to declare victory. If requirements are vague or unverifiable, stop and ask instead of running unattended.
2. **Wake.** Use `/loop`. An event to watch (CI, a merge) gets a watcher and a long heartbeat as fallback; no event gets a fixed interval sized to when the result is worth re-checking.
3. **Smallest verified step.** Each iteration makes the smallest change the evidence justifies, verifies it against the predicate, keeps it if it advanced, reverts it if not (**Sequence Work into Verifiable Units**).
4. **Circuit breakers.** Cap fix rounds at 2 per failure class (3rd failure or 2 rounds with no progress → `ESCALATE` and stop). Past ~270k orchestrator tokens, save `.bottega/handoff.md` and stop cleanly.
5. **Assume you die.** Keep the decision trail below in `.bottega/`, one row per iteration, plus each spawned agent's id, PR, and `stuck_after` runtime, so a replacement can pick up.
6. **Side findings.** Fix what blocks the predicate in its own PR. Log everything else to `.bottega/followups.md`; do not fix it now.
7. **Ask only** for an irreversible step, a product call no experiment settles, or a dead end that survived a replan.

## `queue` and `program`

8. **One owner per PR.** Each owner is an `Agent` (role: implementer) with `isolation: "worktree"`, the only writer of its branch. Cap fan-out: worktree runs share CPU, ports, and disk.
9. **Start with one unit.** Take the first PR through kickoff, verification, and `/ship` before fanning out, so a flawed kickoff costs one agent.
10. **Verify independently.** Nothing ships until agents that never wrote the code prove it. Run `../maestro/references/review.md` (**Verifier swarm** at high risk or `land` mode, with a live lane through `verify-<app>` when present).
11. **Ship & merge.** Hand each verified PR to `../ship/SKILL.md`:
    - `land` mode (two-way doors only) → `/ship full` (watches CI, fixes legitimate failures within cap, merges bottom-up). Confirm `git patch-id` at the verdict SHA matches the head before merging; hold past a third rebase.
    - `stack` mode (or any one-way door) → `/ship stop` (Draft PR, no merge, no further pushes after handoff).
12. **Supervise by side effects.** Read the diff, not the summary. Replace stuck agents past `stuck_after` with a fresh one carrying its consolidated brief; after two retries, drop the unit and replan.
13. **`program` only:** You never write code. Use sub-coordinators only when one area has many workers (max 3 levels deep, ~10 workers each).
14. **On the operator's stop,** every owner gets a zero-writes hold, reports where it stands, and keeps its brief.

## Decision trail

Any unattended run keeps an append-only trail in `.bottega/decisions.tsv` (or `.bottega/<task-slug>.tsv`), columns `ts phase decision why evidence result`, written with `../maestro/scripts/log.sh`. Log decision points (forks, unit verdicts, pivots/reverts, blockers)—one row per loop iteration, evidence as pointers (SHA, PR, `file:line`, artifact path). Before handing back, audit the trail against the session transcript; at high risk, have a `reviewer` check it. Keep it local (never commit unless asked).

**Reply:** Catch the user up per **Catch-up** in `../maestro/references/explore.md`: exit condition and whether it holds, each PR's state and link, what was discarded/dropped and why, and any calls waiting on the user. Run through `../unslop/SKILL.md`.
