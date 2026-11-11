# Changelog

## Unreleased

- Fixes: when more than one `maestro` is on `PATH` (a plugin update can leave an older copy first), `maestro doctor` and the SessionStart `maestro tools hint` warn in PATH order, name every distinct copy with its plugin version, and mark the first as winning; with one copy nothing new is printed, and `BOTTEGA_NO_TOOL_HINT=1` still silences the hint (issue #20).

## 0.6.2 — 2026-11-11

- Fixes: a light-path slug (`maestro build --here`) resolves everywhere a run slug is accepted: `build --status`, `check`, `gate`, `build --here --revise` (resumes the same session, max two revisions, exit 4 on the third), and `verify record|waive|list`, with state staying in `$STATE/quick/<slug>/`; the headless `build --review --here` gate no longer reports `BLOCKED: checks stale or failing` for it; the light build summary prints `session` and `revisions`; and the playbooks and docs point light runs at `maestro check`/`maestro gate`, `maestro build --here --revise`, and `maestro build --status` (issue #8).

## 0.6.1 — 2026-11-11

- Fixes: the git pre-commit hook resolves `maestro` from `PATH`, the path recorded by `maestro hooks install`, then the newest plugin cache copy (portable version sort), and prints a warning instead of silently skipping the Bottega-file check when none is found (issue #3).
- Fixes: the headless builder defaults an empty `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`, or `CLAUDE_CODE_SUBAGENT_MODEL` to `ANTHROPIC_MODEL` (explicit values win), so the builder's Claude tier alias reaches the served model; `build --check` names an empty `ANTHROPIC_MODEL` and a space after `=`; a non-zero 0-token build or review prints the endpoint error on the console; the error-note helper uses `python3 -c` instead of a heredoc inside `$()`, so macOS bash 3.2 parses `bin/maestro`, and lint rejects that pattern (issue #4).
- `scripts/e2e.sh` (run by `scripts/validate.sh`, so by pre-push and CI) tests every `maestro` command in a throwaway repo with a stub `claude`. Builds now work on macOS: `nohup` when `setsid` is missing, and `gtimeout` or a perl alarm when `timeout` is missing.
- Claude Code only: removed the Codex `agents/openai.yaml` files and the OpenCode, Cursor, and Codex references; `builder.env.example` is endpoint-neutral (set any Anthropic-compatible `ANTHROPIC_BASE_URL` and model).
- Fixes: the Stop hook acts only while a run or light-path folder is open (logs in the state root no longer keep it on) and no longer uses a machine-wide `pgrep`; `maestro report --close` also closes light-path runs; the builder guard and the headless runner use the namespaced plugin agents (`bottega:builder`, `bottega:review-code`), so builds keep working without an old copy-install; `simplify` replies instead of writing `simplify.md`; CI installs the Claude CLI so `claude plugin validate` actually runs. Plugin hooks call `${CLAUDE_PLUGIN_ROOT}/bin/maestro` (hook shells have no plugin `bin/` on `PATH`), and lint fails if a bare `maestro` hook command returns.
- Fixes: `scripts/lint.sh` parses `hooks/hooks.json` as JSON and requires every hook command to start with `"${CLAUDE_PLUGIN_ROOT}/bin/maestro" `, and rejects any later bare `maestro` in a compound command; the old line scan missed a bare `maestro` off the `"command"` line, `/usr/local/bin/maestro`, and `$CLAUDE_PLUGIN_ROOT` without braces (issue #6).
- Fixes: `--help`/`-h` on every `maestro` command prints usage and exits 0 before it can write files, create run state, touch the network, or print the builder key (`build --init --help` from issue #2).
- Simpler: removed `maestro stack` (about 330 lines); at Step 0 the explorer reads the manifests once for both the `## Stack` section and `scripts/check`. The retro scan is a short awk over `findings.log` (`--write` removed). The three build paths share their wait, collect, and report helpers.
- The project pre-commit hook no longer runs `maestro doctor` (pre-push runs the checks); the project settings template allows `Bash(maestro:*)`. Plugin version 0.6.0.

## 0.6.0 — 2026-11-10

- CI fixes: bash 3.2 (macOS) compatibility (no `$(case)`, no associative arrays, safe empty-array expansion under `set -u`), restored `has_dependency_manifest` for `doctor`, e2e pins `XDG_CONFIG_HOME`.

- New user-invoked `teach` skill: teaches a topic or part of the codebase one idea at a time, with checks and small exercises.

- `maestro tools install [--yes]` installs missing rtk and gitleaks after asking; a SessionStart hook prints a one-line hint when they are missing (`BOTTEGA_NO_TOOL_HINT=1` silences it).

- New `design` skill category: `frontend-design` (Anthropic), `better-ui` and its siblings plus `interface-review` (jakubkrehel/skills), `agentation`, an original `animation` skill, and `web-design-guidelines` moved in. The builder uses `frontend-design`, `animation`, and `better-ui` for UI work.

- `/maestro` is a thin command that loads `agents/master.md` at run time; removed `scripts/gen-command.sh` and the generated copy.
- `maestro doctor` prints whether the optional `rtk` is installed; `docs/SETUP.md` gains a Token savings section (install, license, caveats).
- `orchestrate` (from pstack, rewritten, user-invoked only): coordinate a program of PR-sized units with a `PLAN.md` ledger, one owner and one reviewer-verifier per unit, `maestro gate --proof` per unit, live supervision, at most 3 builds in flight, and the user merging every PR. `maestro worktree create <run> <task> --branch <name> [--base <ref>]` creates a worktree on a user-named branch that `prune` never deletes.
- `autonomous-run` (from pstack, rewritten, user-invoked only): one task to a command-checkable exit condition, one verified change per iteration, reverted with `git revert` when it did not help, a `maestro log` row each time, an iteration and time cap, ends on a local branch.
- `architect` and `arena` (from pstack, rewritten, user-invoked only with `disable-model-invocation: true`): design twice before the SPEC, and compare 2 or 3 headless-builder candidates with a blind judge.
- From pstack (credited, rewritten): `show-me-your-work` (decision log via `maestro log`, kept in the temp state root), `ketchup`, `correct` (lint-first fixes for repeated findings; the retro and master Step 8 load it), the benchmark checklist inside `perf`, runtime and trace forensics inside `investigate`, and the comment pass inside `simplify`. `autopilot` logs a row per item.
- `eval` playbook (adapted from pstack): compare a variant of the stack or a skill against the installed one on the same task, with headless builders as candidates, a blind judge on the reviewer model, and a transcript check. `BOTTEGA_PLUGIN_DIR` makes the headless runner load a checkout of the stack with `--plugin-dir`.
- Proof gate: SPEC criteria are `AC<n>` with a `Proof:` line; `maestro verify record|waive|list` keeps rows in the run's state dir (PASS needs an evidence file and a reviewer, second-opinion, or master, never the builder; INCONCLUSIVE and stale rows fail) and `maestro gate <run> --proof` blocks approval until each criterion has a PASS for the current HEAD or a user-approved waiver. `create-verification-skill` now follows pstack's shape (Launch, Doctor, Drive, Evidence, Cleanup, per-feature map); new `maintain-verification-skill`.
- Trust log: `maestro report --close` appends one line (date, run, playbook, risk, fix rounds, checks, outcome) to `trust.log` in the temp state root; `maestro report --trust [n]` summarizes the last runs. Report only; nothing is switched on by it.
- Branches are yours: `maestro start` works on the branch you are on and only creates one with `--branch <name>`; task branches are `<branch>-<task>`, stay local and are never pushed; `worktree prune` deletes the merged ones (`git branch -d`, never forced) and keeps unmerged ones. The run branch and remotes are never touched.
- Principles trimmed from 21 to 15: `prove-it-works` absorbs `outcome-oriented-execution`, `laziness-protocol` absorbs `subtract-before-you-add`; `model-the-domain`, `escalate-after-two-fixes`, `stay-in-allowed-files`, and `no-secrets` are dropped (their rules live in `domain-modeling`, the master Step 5 text, the builder contract, and `untrusted-content`). `untrusted-content` gains the secrets rule.
- The 21 principles are now reference files inside the `principles` skill (`references/<slug>.md`) instead of 21 separate skills; citations keep the same slugs. Skills: 63 to 42.
- The quiz is shown in chat before the decision prompt and is never written to the PR body, a commit message, or a file.
- README banner and "what makes it different" section; `resources/verify.sh` temp names renamed to `bottega-verify`.
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
- Claude Code is the only runtime (other platforms, model variants, evals, network allowlist removed).
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
