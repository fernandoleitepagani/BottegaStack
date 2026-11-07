# Changelog

## 0.4.0

Six optional automations. All are opt-in: nothing runs until you install or
invoke it.

- Format hook (opt-in via `pagani init`): a Claude Code `PostToolUse` hook on
  `Edit|Write` runs `scripts/format <file>`. `pagani init` copies the stub
  `scripts/format`; fill it with the project formatter.
- Gitleaks git hooks (opt-in via `pagani hooks install [path]`): `pre-commit`
  scans staged changes for secrets; `pre-push` runs `scripts/check`. `pagani
  init` installs them when `.git` exists. Existing non-pagani hooks are backed
  up, and a missing gitleaks is a clean skip.
- PreCompact handoff (opt-in via `pagani init`): the Claude Code `PreCompact`
  hook writes a snapshot to the newest job's `handoff.md`, or
  `pagani/handoff.md` when there is no job.
- Retro scan (opt-in via `pagani retro-scan`): finds findings repeated across
  jobs. `--write` saves `pagani/retro-scan.md`; `--exit-code` exits 1 on
  repeats so Close can prompt `session-retro`.
- Skill-usage logging (opt-in via `pagani init` or the OpenCode plugin): the
  Claude Code `Skill` hook and the OpenCode `pagani-skill-log` plugin append to
  `pagani/skill-usage.tsv`; `pagani skill-log <name>` logs manually.
- Weekly timer (opt-in via `pagani timer install [path] [--at "Mon 09:00"]`):
  a systemd user timer runs headless `pagani weekly`. It spends tokens and is
  never installed by default.

## 0.3.1

- Fixed eval scoring: clean cases fail on any verdict other than `PASS`; bug
  cases count only when the verdict is `CHANGES` and the output contains the
  case keyword. The runner now prints recall and noise for `train`, `test`, and
  `all`.
- `pagani classify` and `pagani route` read risk paths from the `## Risk paths`
  section of `REVIEW.md` instead of a hardcoded list, with a fallback to
  `resources/REVIEW.md`.
- Added the `unknown` lane for an empty diff and the `standard` lane for large
  non-risk diffs (more than 300 changed lines or more than 10 files).
- `pagani check` now appends `checks.log`; `pagani usage end` records the
  first-pass `y`/`n` from the first check in `checks_first_pass`.
- `pagani usage start|end` warns when neither `opencode` nor `ccusage` is
  installed, without failing.
- `pagani lint` now fails when an agent or skill references a project file that
  has no template in `resources/`.
- The installer is idempotent: unchanged generated files are not backed up or
  rewritten on a second run.
- `verify.sh` kills the started process group, reaps it, and removes the pid
  file when startup times out. `verify.conf` puts `PORT` before `READY_URL` so
  the URL expands to the configured port.
- Removed the stale "run `pagani usage` at the end" wording from both masters.

## 0.3.0

- Added lanes: `trivial`, `bugfix`, `small`, `standard`, `high-risk`; Step 0
  classifies and later escalates.
- Added `agents/models.conf` and generated model variants for both targets.
- Added `explorer` and tier variants: `planner-std`, `planner-strong`,
  `builder-lite`, `builder-strong`, `review-code-lite`, `review-code-strong`,
  `review-security-strong`, `approver-strong`.
- Added `pagani lint`, `pagani job new`, `pagani classify`, `pagani check`,
  `pagani gate`, and `pagani usage start|end`.
- Added real `scripts/verify` start/stop/flow and `docs/FEATURE-MAP.md`.
- Added `.claude/settings.json` permissions and a generated Claude `/pagani`
  command from the master body.
- Added `CLAUDE.md` (`@AGENTS.md`) and `resources/mistakes.md`.
- Added Gotchas sections to 12 PaganiStack-authored skills.
- Added reviewer eval cases with diffs, `run.sh`, recall/noise, and train/test.
- Added cost snapshots in `usage.md` and a `pagani/metrics.tsv` row.
- Fixed `CONTEXT.md` references to `GLOSSARY.md`; removed the `teach`
  dependency; fixed installer idempotent backups.
- Documented that backups of `pagani/jobs/` and prompt-injection defenses are
  not implemented.

## 0.2.0

- Added the installer and `pagani` CLI for OpenCode and Claude Code.
- Added `resources/` project templates.
- Reorganized skills into the nine Claude Code categories plus `workflow/` and
  `design/`.
- Removed the paid `design-mobile-apps` skill.
- Added P0 category skills: library-reference, data-analysis, weekly-review,
  scaffold, ci-cd, runbook, infra-ops.
- Added P1 skills: adversarial-review, simplify, review-pr, pr, session-handoff,
  session-retro, skill-creator, agent-browser, vercel-react-best-practices.
- Added reviewer evals and a score sheet.
- Added review convergence, finding verification, risk tiers, and a PR review
  flow.
- Added `TASKS.md`, handoff, retro, worktrees, usage, status, and PR helpers.
- No cloud sessions.

## 0.1.0

- Initial PaganiStack workflow: master, planner, builder, reviewers, approver.
