# Changelog

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
