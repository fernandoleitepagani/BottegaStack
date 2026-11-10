---
name: playbooks
description: Pick a BottegaStack playbook (trivial, bugfix, feature, refactor, pr-babysit) and a risk modifier (low, standard, high) at Step 0. Use before planning, again after the first builder commit, and whenever a run's scope changes.
---

# Playbooks
Pick a playbook and risk at Step 0 and track the chosen steps in the todo list. Run only the steps you need. Risk only escalates.
## Route
| Request | Playbook |
|---|---|
| docs, copy, comments, config; no behaviour change | `trivial` |
| a reproducible symptom | `bugfix` |
| normal product work | `feature` |
| behaviour must not change | `refactor` |
| an open PR needs CI or review follow-up | `pr-babysit` |
Read the request, `AGENTS.md`, `GLOSSARY.md` if it exists, and `REVIEW.md` first. If the user passes `--playbook <playbook>`, use it; `quick` means `trivial` or a small `bugfix`. Work that fits none: use `figure-it-out`.
## Risk
`low` internal and reversible; `standard` the default; `high` for auth, payments, data/schema/migrations, deploy/CI config, installers, dependency changes, secrets handling, or any glob under `## Risk paths` in `REVIEW.md` (a missing file means none; defaults in `resources/REVIEW.md`).
`high` adds `adversarial-review`, `simplify`, `review-code` (`model: opus`), and `maestro build --review <slug> <task> [--block]`; findings come back as the reviewer's reply, copied to `build/<task>.review2.md` in the state directory. After the first builder commit run `git diff --stat <base>...HEAD` and `git diff --name-only <base>...HEAD`; escalate if a risk glob is touched, ~300 lines change, or the scope grows. Never downgrade.
## Runs and state
- A **run** is one execution of a playbook. Its id is the slug; its branch is `bottega/<slug>`; its state is `$STATE/<slug>/`. `STATE` is the per-repo state directory in the system temp dir (`BOTTEGA_STATE_DIR` overrides it), shared by worktrees. Nothing is written inside the repo or the worktree.
- `maestro start "<title>"` creates the branch and state directory and prints `run:`, `branch:`, and `state:`. It auto-inits the project and requires a clean tree.
- The planner returns the SPEC as its final reply; save it with `maestro spec <slug> [file]`, which extracts `tasks/<n>.md` and prints the task count.
- Human-readable records live in chat and the PR or merge commit: interview answers, summaries, handoffs, decisions, per-round reviews, builder reports, and check output. Reviewers and builders return their report as the reply; there is no report file to write.
- Track steps with the todo list: `TodoWrite`, or `TaskCreate`/`TaskUpdate`/`TaskList`/`TaskGet` when `TodoWrite` is unavailable. One item per task; mark it `in_progress` at build start and `completed` at the end. Keep a skipped step with a one-line skip reason.
## Common rules
- **Light path:** `trivial` and small `bugfix` use `maestro build --here <slug> --task "<text>" [--block]`; no SPEC or worktree; state lives in `$STATE/quick/<slug>/` and commits land on the current branch.
- **Checks:** `maestro check <slug>` runs `./scripts/check` and writes `checks.log` and `checks.result` in the state directory. `maestro gate <slug>` fails on a dirty tree, a failed check, or stale checks; run it before approval and before a merge.
- **Commit order:** in `bugfix` and `feature` commit the failing test first (a commit that changes only test files), then the fix. `maestro gate` prints `warning: no failing-test commit before the fix` when the first non-test commit comes first.
- **Waiting on external events:** do not sleep-poll. Invoke the `loop` skill with a stated interval (120s for CI, 300s for a long build) and cap (for example 20 checks); stop when the condition is met or the cap is reached, and report the last state.
- **Every playbook ends with Steps 6 and 7:** load `approval` and `closeout`; the decision goes through `AskUserQuestion`, even on the light path. The default closeout is a PR whose body carries the write-up; a local merge writes the same text in the merge-commit message.
- **Every run:** at start copy the matched playbook's steps verbatim into the todo list; at the end reply with verbatim before/after evidence and label each claim measured, inferred, or guessed (see principle `prove-it-works`).
- **Gotchas:** classify by risk path, not file count; re-run the diff check after the first builder commit; one `review-code` covers UI, UX, and security; the project check still runs on `trivial`.
## trivial
0. **Step 0 — Route and set up.** Docs, copy, comments, or config only; no behaviour change. Record the plan in the todo list.
2. **Step 2 — Build.** Run `maestro build --here <slug> --task "<text>" --block`; commits land on the current branch and state is `$STATE/quick/<slug>/`.
3. **Step 3 — Checks.** Run `./scripts/check` and fix any failure; post the output.
4. **Step 4 — Review.** Load `review-code`; review the diff.
6. **Step 6 — Approval.** Load `approval`; post the decision and explainer and ask with `AskUserQuestion`.
7. **Step 7 — Closeout.** Load `closeout`; end with the PR body or the merge-commit write-up (Done / Evidence / Claims).
`Done: <what changed>`
`Evidence: <verbatim before/after output>`
`Claims: measured | inferred | guessed`
## bugfix
0. **Step 0 — Route and diagnose.** Load `diagnosis`; reproduce the symptom. A small fix takes the light path; otherwise run `maestro start "<title>"` and track the steps in the todo list.
1. **Step 1 — SPEC.** For a run, spawn `planner`; it returns the SPEC as its final reply. Save it with `maestro spec <slug> [file]`.
2. **Step 2 — Build.** Commit the failing test first (test files only), then the fix; `maestro gate` warns if the first non-test commit comes first. Light path: `maestro build --here <slug> --task "<text>" --block`. Run: `maestro worktree create <slug> <task>`, then `maestro build <slug> <task> --block`.
3. **Step 3 — Checks.** Light path: `./scripts/check`. Run: `maestro check <slug>`, then `maestro gate <slug>`.
4. **Step 4 — Review.** Load `review-code`; findings return as the reply.
5. **Step 5 — Fix.** Pass findings back with `maestro build <slug> <task> --revise <file|->`; max two rounds.
6. **Step 6 — Approval.** Load `approval`; present the decision, not a file.
7. **Step 7 — Closeout.** Load `closeout`; default is a PR whose body carries the write-up.
8. **Step 8 — Close.** Show the failing test passing, verbatim. For a run, run `maestro report --retro --exit-code`; load `session-retro` if it exits 1.
`Done: <fix>`
`Evidence: <failing then passing output>`
`Claims: measured | inferred | guessed`
## feature
0. **Step 0 — Route and set up.** Confirm the playbook and risk. Run `maestro start "<title>"`; it prints the run, branch, and state directory. Track the steps in the todo list.
1. **Step 1 — SPEC.** Load `interview`; ask with `AskUserQuestion` (answers live in chat and the PR body). Spawn `planner`; it returns the SPEC as its final reply. Save it with `maestro spec <slug> [file]`; check the task graph and confirm the printed task count.
2. **Step 2 — Build.** Track one todo item per task. For each ready task run `maestro worktree create <slug> <task>`, then `maestro build <slug> <task> --block`; when `maestro build --check` passes builders run headless on the model in `builder.env`. Commit the failing test first, then the fix; `maestro gate` warns when the order is wrong.
3. **Step 3 — Checks.** `maestro check <slug>`, then `maestro gate <slug>`; on failure load `diagnosis` and pass the findings to a fresh builder.
4. **Step 4 — Review.** Spawn `review-code`; findings return as the reply. `high` adds `adversarial-review` and `simplify`. Post the summary in chat.
5. **Step 5 — Fix.** Pass findings back with `maestro build <slug> <task> --revise <file|->`; max two rounds, then escalate.
6. **Step 6 — Approval.** Load `approval`; read the SPEC, the checks, and the review replies, and present the decision and explainer with `AskUserQuestion`.
7. **Step 7 — Closeout.** Load `closeout`; default is a PR whose body carries Done / Evidence / Claims and the acceptance mapping; a merge commit carries the same text.
8. **Step 8 — Close.** Run `maestro report --retro --exit-code`; load `session-retro` if it exits 1.
`Done: <feature>`
`Evidence: <check and review output>`
`Claims: measured | inferred | guessed`
## refactor
0. **Step 0 — Route and set up.** Run `maestro start "<title>"`. State the behaviour that must not change and capture tests for it. Track the steps in the todo list.
1. **Step 1 — SPEC.** Spawn `planner`; it returns the SPEC as its final reply. Save it with `maestro spec <slug> [file]`.
2. **Step 2 — Build.** Expand: add the new seam beside the old one. Migrate callers and run `maestro check <slug>` after each step. Contract: delete the old path; keep tests green. For each unit run `maestro worktree create <slug> <task>`, then `maestro build <slug> <task> --block`; use the light path for small units.
3. **Step 3 — Checks.** `maestro check <slug>`, then `maestro gate <slug>`.
4. **Step 4 — Review.** Load `review-code`; findings return as the reply.
5. **Step 5 — Fix.** Pass findings back with `maestro build <slug> <task> --revise <file|->`; max two rounds.
6. **Step 6 — Approval.** Load `approval`; present the decision, not a file.
7. **Step 7 — Closeout.** Load `closeout`; default is a PR whose body carries the write-up.
8. **Step 8 — Close.** Show before/after test output proving behaviour is unchanged; run `maestro report --retro --exit-code`.
`Done: <refactor>`
`Evidence: <green tests before and after>`
`Claims: measured | inferred | guessed`
## pr-babysit
Use `pr-babysit.md`: watch read-only, triage, fix through the light path (`$STATE/quick/<slug>/`), track the steps in the todo list, and push only after `AskUserQuestion` approval. End with the PR write-up.
`Done: <PR state>`
`Evidence: <verbatim gh output>`
`Claims: measured | inferred | guessed`
