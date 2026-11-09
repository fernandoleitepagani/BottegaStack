# Changelog

## Unreleased
- `bin/pagani` split: the installed `pagani` is runtime-only; install, uninstall, and lint moved to `bin/pagani-setup` (repo and tarball only). `pagani install` / `upgrade --self` fetch it from the recorded source.
- Claude Code is the only runtime (OpenCode, model variants, evals, network allowlist removed).
- Install is a self-contained copy; `get.sh` is a one-line tarball install (`PAGANI_REF` picks a ref). `pagani upgrade --self` refreshes it.
- Headless builder: `pagani build <job> <task>` runs the builder in the background with a budget, timeout, and slim tool set; `pagani build --status <job> [--every <s>]` prints one progress line, which the master posts via `Monitor`.
- The master runs as the main agent (`claude --agent master`) and answers pure questions without a job; its frontmatter carries the hooks.
- Guards and hooks: builder guard, `Stop` hook (no ending a turn mid-pipeline unless a builder or check is running), pre-commit refusal of project files.
- Project files created by `init`/`upgrade` are excluded via `.git/info/exclude`, not committed; `/pagani` auto-initializes a project and fills `scripts/check`.
- Templates: `ROADMAP.md` and `TASKS.md` merged into `PLAN.md`; `CODING_STANDARDS.md` moved into `AGENTS.md`; PR template dropped.
- Removed `claude-hook.sh` (auto-format, PreCompact handoff). Run your formatter inside `scripts/check`; `pagani upgrade` cleans old projects.

## 0.5.0
- Local automation: worktree prune, `upgrade`, dirty-tree gate, lane classify, exact cost, budget, dashboard, backup, skill evals, `untrusted-content`. Most of it was later removed.

## 0.4.0
- Opt-in format hook, gitleaks git hooks, PreCompact handoff, retro scan, skill-usage log, weekly timer.

## 0.3.x
- Lanes (`trivial` to `high-risk`), model variants, `pagani lint`, `job new`, `check`, `gate`, reviewer evals, `verify` scripts.

## 0.2.0 and 0.1.0
- Installer and CLI, `resources/` templates, Claude Code skill categories, P0/P1 skills, initial master/planner/builder/reviewer workflow.
