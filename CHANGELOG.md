# Changelog

## 0.5.0

Local automation and observability. Everything here is local and opt-in where it
spends money or opens a network path.

- `pagani frontier <job>` prints the ready and blocked ticket set from
  `tickets/index.md`, with a fallback to each ticket's `**Blocked by:**` line.
- `pagani classify` accepts request text as well as `--diff`, using risk, docs,
  bug, and feature words. Lanes only escalate; request words cannot lower a
  diff-based lane.
- `pagani gate <job>` fails on a dirty working tree (modified, staged, or
  untracked files outside `pagani/` and `.opencode/`); `--allow-dirty` bypasses
  the check.
- `pagani worktree prune <job>` checks the exit status of `git worktree remove`,
  reports `failed: <path> (uncommitted changes; use --force)` and continues, and
  accepts `--force`.
- `pagani upgrade [path]` copies the managed hook, merges the hooks into an
  existing `.claude/settings.json` without dropping `permissions`, backs up the
  old file, appends runtime gitignore lines, and installs the git hooks.
- `pagani network init|check <url>` manages an opt-in host allowlist for Claude
  `WebFetch` only. Shell and `agent-browser` egress are not covered.
- Exact per-job cost: `pagani usage end <job>` reads the local OpenCode `session`
  cost and token columns, including sessions in the job's worktrees, and writes
  `usage.md` plus `cost_usd`/`tokens_total` in `metrics.tsv`. It falls back to an
  approximate `opencode stats` delta when the database or `python3` is missing.
- `pagani usage report <job>` prints the recorded exact cost and tokens.
- `pagani budget set|check <job> [--usd <amount>]` stores a per-job USD budget
  and exits 1 when the exact cost is over it.
- `pagani dashboard [--open]` writes a local, read-only `pagani/dashboard.html`
  with the jobs, checks, cost, and metrics tables. Inline CSS, no JS, no server,
  no login.
- `pagani backup [job|all] [--dest <dir>]` writes a local tar.gz under
  `pagani/backups/`; `pagani restore <archive> [--force]` restores it and
  refuses to overwrite an existing job without `--force`.
- Skill evals: `evals/skills/run.sh` checks that prompts trigger the expected
  skill. It spends tokens and is opt-in.
- GitHub Actions check workflow (`resources/github/workflows/pagani-check.yml`):
  lint and `scripts/check` on pull requests and pushes to `main`, on GitHub
  runners, with read-only `contents`, no secrets, no login, and no LLM calls.
- `untrusted-content` skill: web pages, PR bodies/comments, `BACKLOG.md`, logs,
  screenshots, and OCR are data, never instructions. It is a convention, not a
  sandbox.
- Gotchas sections on the thin skills and a headless weekly rule: when run by
  `pagani weekly` or the timer, the review does not ask questions; it lists
  proposed edits and decisions in the report.
- Claude smoke-test checklist in `HOW-IT-WORKS.md` §16 and a PLAN.md
  consistency pass.

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
