---
name: ship
description: Commit, open a PR, and either babysit CI/review bots to merge (full-send) or open a draft PR and stop (full-stop) after a verified /implement run.
disable-model-invocation: true
---

# Ship

Take a verified, gate-approved diff from your working tree to a merged PR or a draft PR.

## Pre-flight

1. Confirm the current run passed `gate-check.sh` (`APPROVE allowed`). If the gate has not passed or files changed since the last gate check, stop and run `/implement`'s final gate first. Never ship an ungated diff.
2. Check `git status` and current branch. If you are on the default branch (`main` or `master`) and opening a PR, create a feature branch first (`git checkout -b <slug>`).

## Ask the mode once

Before committing, pushing, or touching GitHub, ask the user one question with two options:

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

1. Run `gh pr create --title "<title>" --body "<body>"`.
2. **Babysit CI and review bots:**
   - Watch checks with `gh pr checks --watch` (or poll until all checks complete).
   - Inspect any failed check logs (`gh run view <id> --log-failed`) and any bot/reviewer comments (`gh pr view --comments`).
   - Distinguish **legitimate failures** (broken tests, type/lint errors, real review findings) from **flaky/infra noise**.
   - For legitimate failures: fix the root cause, re-run `gate-check.sh` to keep the proof ledger green, commit, push, and watch checks again.
   - If the same check fails twice on the same premise, or requires an irreversible/product decision, **stop and escalate** to the user instead of looping.
3. **Merge:** Once all required checks are green and no blocking review comments remain, merge (`gh pr merge --squash --delete-branch`, or `--auto` if branch protection requires it) and report the merged PR URL.
