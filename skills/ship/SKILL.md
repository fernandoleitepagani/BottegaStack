---
name: ship
description: Commit, open a PR, and either babysit CI/review bots to merge (/ship full) or open a draft PR and stop (/ship stop) after a verified /implement run.
disable-model-invocation: true
---

# Ship

Take a verified, gate-approved diff from your working tree to a merged PR (`/ship full`) or a draft PR (`/ship stop`). This skill is the sole owner of PR creation and landing.

## Pre-flight

1. Confirm the current run passed `bottega verify` (or `gate-check.sh`, `APPROVE allowed`). If the gate has not passed or files changed since the last gate check, stop and run `/implement`'s final gate first. Never ship an ungated diff.
2. Check `git status` and current branch. If you are on the default branch (`main` or `master`) and opening a PR, create a feature branch first (`git checkout -b <slug>`).
3. **Reversibility check (two-way vs. one-way door):** Inspect the diff for one-way-door surfaces—data migrations or deletion, schema drops, auth/security boundaries, billing/money, breaking public API contracts, or destructive infra/deploy scripts. `bottega ship --ready` also blocks common one-way-door paths mechanically. If any are present, **force `stop` (Draft PR)** and tell the user why; do not allow `full` auto-merge on one-way doors.

## Ask the mode once

- If the reversibility check forced `stop`, skip this question and run Mode 2 directly.
- If the user already passed `full` (e.g., `/ship full`) or `stop` (e.g., `/ship stop`), skip this question and run that mode directly (subject to the reversibility check above).
- Otherwise, before committing, pushing, or touching GitHub, ask the user one question with two options:

1. **Full auto (`/ship full`):** Commit, push the branch, open a ready PR, watch CI checks and review bots, fix legitimate failures, and merge automatically once all required checks are green.
2. **Draft stop (`/ship stop`):** Commit everything cleanly, push the branch, open a **Draft PR**, and stop—no CI watching and no merge.

Wait for the user's choice before running any write/push command.

## Shared steps (both modes)

1. **Commit:** Run the comments self-check (`../maestro/references/delegate.md`, **Comments**). Stage only the files expected by the run (never `.bottega/` or stray untracked files). Use small ordered commits with Conventional Commits subjects (`type(scope): subject`). When continuing someone else's PR or branch, keep their commits and authorship and add `Co-authored-by:` trailers.
2. **Draft PR body:** Keep it under ~40 lines, written through `../unslop/SKILL.md`:
   - `## Why` — the problem solved or ticket/spec link.
   - `## What changed` — 2–4 bullets on observable behavior changes.
   - `## Verification` — summary of the passing `gate-check.sh` conditions (and crossfire result if high risk).
3. **Push and open PR via `bottega ship`:** Use `<maestro dir>/scripts/bottega ship` (which enforces clean tree, passing final gate, feature branch, and one-way-door checks).

## Mode 2: Draft stop (`/ship stop`)

1. Run `<maestro dir>/scripts/bottega ship --draft --title "<title>" --body "<body>"`.
2. Report the PR URL and stop immediately. Do not watch CI, do not mark ready, and do not merge.

## Mode 1: Full auto (`/ship full`)

1. **Optional pre-merge swarm:** If the run was `normal` risk and did not run a `verify-<app>` pass, you may run a 2-verifier mini-swarm (`../maestro/references/review.md` **Verifier swarm**) before pushing when extra auto-merge confidence is wanted.
2. Run `<maestro dir>/scripts/bottega ship --ready --title "<title>" --body "<body>"`.
3. **Babysit CI and review bots:**
   - Watch checks with `gh pr checks --watch` (or poll until all checks complete).
   - Inspect any failed check logs (`gh run view <id> --log-failed`) and any bot/reviewer comments (`gh pr view --comments`).
   - Distinguish **legitimate failures** (broken tests, type/lint errors, real review findings) from **flaky/infra noise**.
   - For legitimate failures: fix the root cause, re-run `bottega verify` to keep the proof ledger green, commit, push, and watch checks again.
   - If the same check fails twice on the same premise, or requires an irreversible/product decision, **stop and escalate** to the user instead of looping.
4. **Merge:** Once all required checks are green and no blocking review comments remain, merge (`gh pr merge --squash --delete-branch`, or `--auto` if branch protection requires it) and report the merged PR URL.

## Existing PR or Stack (`babysit` / `land`)

When the user asks to babysit an existing PR (e.g. `babysit PR #N` or `get this PR green`) or land a stack of PRs (`land the stack`):

1. **Skip PR creation:** Check out the PR branch (`gh pr checkout <N>`), verify no one-way-door surfaces are being auto-merged, and jump straight to **Mode 1, steps 3–4** (babysit CI/review bots, fix legitimate failures, re-run `bottega verify`, and merge).
2. **Stacked PRs:** Order the stack bottom-up (base PR first). For each PR in order: verify it with a fresh reviewer if not already verified at its current head, watch CI until green, merge, confirm the merge via `gh pr view`, and rebase/retarget the next PR in the stack onto trunk before proceeding.
