# Changelog

## Unreleased
- New playbooks: `investigate`, `perf`, `prototype`, `ship`, `autopilot`, and `pause` (covers pause and resume); `closeout` gains a merge-readiness gate that blocks merge until unmet items are fixed or waived.
- Cheap first-pass review: for `low` risk the master runs the headless `maestro build --review` first; only findings escalate to the Claude reviewer.
- Effort routing: `~/.claude/rules/bottega-models.md` holds `role: value, effort` per role; the master passes both per Agent call and headless builds pass `--effort`.
- `maestro stack` detects the repo's language, package manager, commands, and frameworks; the master confirms it and records the profile in `AGENTS.md`.
- `maestro doctor` warns on missing gitleaks, a tracked `.env`, no dependency-update config, and no CI security job.
- New skills: `interrogate` and `blast-radius` (report-only), plus `linux-sysadmin`, `podman-operator`, and `bash-scripting` in the new `sysadmin`, `containers`, and `devops` categories, adapted from ChrisTitusTech/titstack (MIT).
- Builds report `tokens: in <n> out <n>` and `steps: <n>`; the USD cap and every cost figure are gone, and the 30-minute timeout is the only stop.
- Cleanup: removed the dead `claude/global/` snippets, `VERSION` (the plugin manifest is the source), the unused ADR template, the legacy-migration code in `maestro upgrade`, the stale `doctor` upstream-skills check, the local-settings comparison in the lint, and duplicated run-state and project-file docs. Deleted all merged `pagani/*` branches and builder worktrees.
- Renamed the stack to Bottega: repository and docs `BottegaStack`, plugin `bottega`, CLI and slash command `maestro`, env vars `BOTTEGA_*`, config `~/.config/bottega`, branches `bottega/<slug>`. No compatibility aliases; the `prototype/` research folder is removed.
- Run state moved out of the repo to a per-repo state directory in the system temp dir (`PAGANI_STATE_DIR` overrides it), shared by worktrees. `pagani start` creates the branch `pagani/<slug>` and the state directory; `pagani spec|check|gate|report` replace `pagani job`, which prints the replacement and exits 2. Nothing is written into the repo or a worktree.
- Human-readable records moved to chat and the PR or merge commit: the planner returns the SPEC, reviewers return findings, builders end with their report, and the default closeout is a PR whose body (or the merge-commit message) carries Done / Evidence / Claims. The Stop hook is driven by the todo list.
- Playbooks rewritten in pstack style: routing table, risk modifier, light path, the `loop` rule for external waits, and a `figure-it-out` fallback. Each playbook is a short numbered checklist copied into the todo list; every run ends with verbatim before/after evidence and claims labelled measured, inferred, or guessed.
- `principles` is now a short index; each of the 21 rules is its own `principle-<slug>` skill, so `principle <slug>` citations stay stable.
- `agents/master.md` shortened to about 130 lines, citing principles and skills instead of restating rules; `commands/pagani.md` regenerated.
- Shortened `review-code`, `implementation`, `interview`, `planning`, and `closeout` with the same report formats and decision options.
- New skills: `how` and `why` (read-only, evidence-based explanations), `figure-it-out` (one-off playbook), `create-verification-skill` (project `.claude/skills/verify-*`), and `automate-me` (personal mode skill from transcripts, after approval).
- `docs/SKILLS.md` and `docs/WORKFLOW.md` updated for the new skill inventory and rules.
- PaganiStack ships as the Claude Code plugin `pagani` (`.claude-plugin/plugin.json` plus `marketplace.json`, source `./`). It puts `bin/pagani` on `PATH`, provides the agents, `/pagani` and `/pagani-models`, every skill, and `hooks/hooks.json`; the installer, the copy mode, and the launcher are gone.
- Playbooks (`trivial`, `bugfix`, `feature`, `refactor`, `pr-babysit`) and a `low|standard|high` risk modifier replace lanes; the `playbooks` skill replaces `lanes`, and playbook and risk are tracked as todo items.
- Light path: `pagani build --here <slug> --task "<text>"` runs the headless builder in the current checkout with state in the state directory under `quick/<slug>/`; `pagani build --review <run> <task>` runs the read-only `review-code` agent on the third-party model and puts findings in `build/<task>.review2.md` in the state directory.
- Project files on demand: `pagani init` creates only `AGENTS.md`, `CLAUDE.md`, `scripts/check`, `.claude/settings.json`, the git exclude block, and the git hooks; `pagani seed <Name>` copies a template when a skill first needs it.
- `principles` skill with the named shared rules, and `/pagani-models`, which writes `~/.claude/rules/pagani-models.md`.
- `pr-babysit` playbook and a `loop`-based rule for waiting on external events instead of idling.
- CI (`.github/workflows/ci.yml`) runs the lint on Ubuntu and macOS, checks that the generated command is fresh, and validates the plugin manifests when `claude` is available.
- Claude Code is the only runtime (OpenCode, model variants, evals, network allowlist removed).
- Headless builder: `pagani build <run> <task>` runs the builder in the background with a budget, timeout, and slim tool set; `pagani build --status <run> [--every <s>]` prints one progress line, which the master posts via `Monitor`.
- The master runs as the main agent (`claude --agent master`) and answers pure questions without a run; the plugin's hooks carry the builder guard and Stop behaviour.
- Guards and hooks: builder guard, `Stop` hook (no ending a turn mid-pipeline unless a builder or check is running), pre-commit refusal of project files.
- Project files are excluded via `.git/info/exclude`, not committed; `/pagani` auto-initializes a project and fills `scripts/check`.
- Templates: `CODING_STANDARDS.md` moved into `AGENTS.md`; the PR template was dropped.
- Removed `claude-hook.sh` (auto-format, PreCompact handoff). Run your formatter inside `scripts/check`; `pagani upgrade` cleans old projects.

## 0.5.0
- Local automation: worktree prune, `upgrade`, dirty-tree gate, lane classify, exact cost, budget, dashboard, backup, skill evals, `untrusted-content`. Most of it was later removed.

## 0.4.0
- Opt-in format hook, gitleaks git hooks, PreCompact handoff, retro scan, skill-usage log, weekly timer.

## 0.3.x
- Lanes (`trivial` to `high-risk`), model variants, `pagani lint`, `job new`, `check`, `gate`, reviewer evals, `verify` scripts.

## 0.2.0 and 0.1.0
- Installer and CLI, `resources/` templates, Claude Code skill categories, P0/P1 skills, initial master/planner/builder/reviewer workflow.
