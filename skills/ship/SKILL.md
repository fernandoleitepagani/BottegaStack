---
name: ship
description: Commit, open a PR, and either babysit CI/review bots to merge (full-send) or open a draft PR and stop (full-stop) after a verified /implement run.
disable-model-invocation: true
---

# Ship

Take a verified, gate-approved diff from your working tree to a merged PR or a draft PR.

## Pre-flight

1. Confirm the current run passed `bottega verify` (or `gate-check.sh`, `APPROVE allowed`). If the gate has not passed or files changed since the last gate check, stop and run `/implement`'s final gate first. Never ship an ungated diff.
2. Check `git status` and current branch. If you are on the default branch (`main` or `master`) and opening a PR, create a feature branch first (`git checkout -b <slug>`).
3. **Reversibility check (two-way vs. one-way door):** Inspect the diff for one-way-door surfaces—data migrations or deletion, schema drops, auth/security boundaries, billing/money, breaking public API contracts, or destructive infra/deploy scripts. If any are present, **force `full-stop` (Draft PR)** and tell the user why; do not allow `full-send` auto-merge on one-way doors.

## Ask the mode once

- If the reversibility check forced `full-stop`, skip this question and run Mode 2 directly.
- If the user already passed `full` / `full-send` (e.g., `/ship full`) or `stop` / `full-stop` (e.g., `/ship stop`), skip this question and run that mode directly (subject to the reversibility check above).
- Otherwise, before committing, pushing, or touching GitHub, ask the user one question with two options:

1. **Full auto (`full-send`):** Commit, push the branch, open a ready PR, watch CI checks and review bots (`babysit-pr`), fix legitimate failures, and merge automatically once all required checks are green.
2. **Draft stop (`full-stop`):** Commit everything cleanly, push the branch, open a **Draft PR** (`gh pr create --draft`), and stop—no CI watching and no merge.

Wait for the user's choice before running any write/push command.

## Shared steps (both modes)

1. **Commit:** Stage only the files expected by the run (never `.bottega/` or stray untracked files). Write a concise, problem-focused commit message (why, not a file list).
2. **Push:** Push the feature branch to `origin` (`git push -u origin <branch>`).
3. **Draft PR body:** Keep it short and problem-focused:
   - **Why:** The problem solved or ticket/spec link.
   - **What:** 2–4 bullets on observable behavior changes.
   - **Proof:** Summary of the passing `gate-check.sh` conditions (and crossfire result if high risk).
   - Run `unslop` mentally—no filler or file-by-file narration.

## Mode 2: Draft stop (`full-stop`)

1. Run `gh pr create --draft --title "<title>" --body "<body>"`.
2. Report the PR URL and stop immediately. Do not watch CI, do not mark ready, and do not merge.

## Mode 1: Full auto (`full-send` + `babysit-pr`)

1. **Optional pre-merge swarm:** If the run was `normal` risk and did not run a `verify-<app>` pass, you may run a 2-verifier mini-swarm (`../maestro/references/review.md` **Verifier swarm**) before pushing when extra auto-merge confidence is wanted.
2. Run `gh pr create --title "<title>" --body "<body>"`.
3. **Babysit CI and review bots:**
   - Watch checks with `gh pr checks --watch` (or poll until all checks complete).
   - Inspect any failed check logs (`gh run view <id> --log-failed`) and any bot/reviewer comments (`gh pr view --comments`).
   - Distinguish **legitimate failures** (broken tests, type/lint errors, real review findings) from **flaky/infra noise**.
   - For legitimate failures: fix the root cause, re-run `gate-check.sh` to keep the proof ledger green, commit, push, and watch checks again.
   - If the same check fails twice on the same premise, or requires an irreversible/product decision, **stop and escalate** to the user instead of looping.
4. **Merge:** Once all required checks are green and no blocking review comments remain, merge (`gh pr merge --squash --delete-branch`, or `--auto` if branch protection requires it) and report the merged PR URL.
