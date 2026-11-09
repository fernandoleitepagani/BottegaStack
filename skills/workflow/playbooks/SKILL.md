---
name: playbooks
description: Pick a PaganiStack playbook (trivial, bugfix, feature, refactor, pr-babysit) and a risk modifier (low, standard, high) at Step 0. Use before planning, again after the first builder commit, and whenever a job's scope changes.
---

# Playbooks
Pick a playbook and risk at Step 0, write both to `job.md`, and run only the steps you need. Risk only escalates.
## Route
| Request | Playbook |
|---|---|
| docs, copy, comments, config; no behaviour change | `trivial` |
| a reproducible symptom | `bugfix` |
| normal product work | `feature` |
| behaviour must not change | `refactor` |
| an open PR needs CI or review follow-up | `pr-babysit` |
Read the request, `AGENTS.md`, `GLOSSARY.md` if it exists, and `REVIEW.md` first. If the user passes `--playbook <playbook>`, use it; `quick` means `trivial` or a small `bugfix`. Work that fits none: use `figure-it-out` (added later).
## Risk
`low` internal and reversible; `standard` the default; `high` for auth, payments, data/schema/migrations, deploy/CI config, installers, dependency changes, secrets handling, or any glob under `## Risk paths` in `REVIEW.md` (a missing file means none; defaults in `resources/REVIEW.md`).
`high` adds `adversarial-review`, `simplify`, `review-code` (`model: opus`), and `pagani build --review <job> <task> [--block]`, which writes `pagani/jobs/<job>/build/<task>.review2.md`. After the first builder commit run `git diff --stat <base>...HEAD` and `git diff --name-only <base>...HEAD`; escalate if a risk glob is touched, ~300 lines change, or the scope grows. Never downgrade.
## Common rules
- **Light path:** `trivial` and small `bugfix` use branch `pagani/quick-<slug>` and `pagani build --here <slug> --task "<text>" [--block]`; no job folder, SPEC, or worktree. State lives in `pagani/quick/<slug>/` (`run`, `rc`, `progress`, `prompt`, `report.md`, `builder.log`).
- **Waiting on external events:** do not sleep-poll. Invoke the `loop` skill with a stated interval (120s for CI, 300s for a long build) and cap (for example 20 checks); stop when the condition is met or the cap is reached, and report the last state.
- **Every job:** at start copy the matched playbook's steps verbatim into `TodoWrite`, and keep a skipped step with a one-line skip reason; at the end reply with verbatim before/after evidence and label each claim measured, inferred, or guessed (see principle `prove-it-works`).
- **Gotchas:** classify by risk path, not file count; re-run the diff check after the first builder commit; one `review-code` covers UI, UX, and security; the project check still runs on `trivial`.
## trivial
1. Create branch `pagani/quick-<slug>`.
2. Run `pagani build --here <slug> --task "<text>" --block`.
3. Run `./scripts/check` and fix any failure.
4. Run `review-code` on the diff.
5. Check the diff against `Allowed files`.
6. Post the before/after evidence.
`Done: <what changed>`
`Evidence: <verbatim before/after output>`
`Claims: measured | inferred | guessed`
## bugfix
1. Load `diagnosis`; reproduce the symptom.
2. Write a failing test first.
3. If the change is small use the light path (`pagani build --here <slug> --task "<text>" --block`); otherwise `pagani job new` and a SPEC.
4. Run `./scripts/check`.
5. Run `review-code`.
6. Show the failing test passing.
`Done: <fix>`
`Evidence: <failing then passing output>`
`Claims: measured | inferred | guessed`
## feature
1. Load `interview`; ask with `AskUserQuestion` and write `interview.md`.
2. Spawn `planner` to write `SPEC.md`; run `pagani seed SPEC.md` if it is missing.
3. Run `pagani job new "<title>"`; write `Playbook`/`Risk` to `job.md`.
4. For each ready task run `pagani worktree create <job> <task>`, then `pagani build <job> <task> --block`; when `pagani build --check` passes builders run headless on the model in `builder.env`.
5. Run `pagani job check`, then `review-code`; write `summary.md` at this checkpoint.
6. Load `approval`, write `decision.md`, load `closeout`, then run `pagani job report --retro --exit-code`.
`Done: <feature>`
`Evidence: <check and review output>`
`Claims: measured | inferred | guessed`
## refactor
1. State the behaviour that must not change and capture tests for it.
2. Expand: add the new seam beside the old one.
3. Migrate callers and run `./scripts/check` after each step.
4. Contract: delete the old path; keep tests green.
5. For each unit run `pagani build <job> <task> --block`, then `review-code`.
6. Show before/after test output proving behaviour is unchanged.
`Done: <refactor>`
`Evidence: <green tests before and after>`
`Claims: measured | inferred | guessed`
## pr-babysit
Use `pr-babysit.md`: watch read-only, triage, fix through the light path, and push only after `AskUserQuestion` approval.
`Done: <PR state>`
`Evidence: <verbatim gh output>`
`Claims: measured | inferred | guessed`
