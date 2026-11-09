# Changelog

## Unreleased
- Removed `claude-hook.sh` (auto-format and PreCompact handoff). Run your formatter inside `scripts/check`; `pagani upgrade` removes the old script and hooks from projects.
- Project templates trimmed: `ROADMAP.md` and `TASKS.md` merge into `PLAN.md`, `CODING_STANDARDS.md` moves into `AGENTS.md`, and the PR template is gone. Existing projects keep their old files.
- Run the workflow without `/pagani`: `claude --agent master` or `"agent": "master"` in settings.
  Hooks (builder guard, Stop) now live in `master.md` frontmatter and the installer copies them
  into the generated `/pagani` command. The master answers pure questions without creating a job.

- `pagani build --status <job> [--every <seconds>]` prints one progress line
  (`Builders 2/5 done · 2 running · 1 queued`); the master runs it through
  `Monitor` once per wave and posts each line, replacing the `.progress` tail and
  the hand-written tally.

- New recommended install: `get.sh`, a one-liner (`curl -fsSL
  https://raw.githubusercontent.com/fernandoleitepagani/PaganiStack/main/get.sh | bash`)
  that needs only bash, curl, and tar, installs a self-contained copy, and keeps no
  clone. `PAGANI_REF` picks another ref. Cloning is now the contributor path.

- `pagani guard stop` no longer blocks while a background `pagani job check`,
  `scripts/check`, or a builder without a `.run` file is running, and ignores a
  `.run` file older than 360 minutes.

- `/pagani` sets a project up by itself: `pagani job new` runs `init` when the
  project files are missing, and the master fills in `scripts/check` with the
  project's real commands (confirmed with you) instead of leaving the failing stub.

- Nothing `pagani init` or `upgrade` creates in a project is committed any more. The
  files (AGENTS.md, scripts/, .claude/, pagani/, ...) are listed in
  `.git/info/exclude` instead of the project `.gitignore`, and the pre-commit hook
  refuses to stage a newly added one. `pagani worktree create` copies them into each
  task worktree because untracked files are not in a checkout. This also fixes
  `pagani job new` failing its clean-tree check after `init`.

- Removed the `build-runner` relay subagent. The master now runs
  `pagani build <job> <task> --block` itself as a background Bash task (the shell's
  exit is the completion notice) and follows `build/<task>.progress` with the
  `Monitor` tool. `--block` waits for the build to end; the builder is capped at 30
  minutes (`PAGANI_BUILD_TIMEOUT`). The `--wait` loop stays for foreground callers.

- Removed `evals/` (skill-trigger and reviewer suites). They were opt-in, ran once, and
  were not kept current.

- Removed the network allowlist: `pagani network`, `resources/network-allowlist.example`,
  and the `webfetch-guard` hook. It only covered Claude `WebFetch`, never shell or
  `agent-browser` egress. `pagani upgrade` rewrites an existing project's hooks, so
  the old `PreToolUse` `WebFetch` hook is dropped there.

- `pagani build` hardening, ported from cc-fleet's subagent lane: the API key now
  lives in `~/.config/pagani/builder.key` and reaches `claude` through an
  `apiKeyHelper` (`pagani keyget`), not the environment; each run passes a
  `--settings` profile that outranks user and project settings and blanks the auth
  env vars; builds have a budget (`--max-budget-usd`) and a timeout; the builder
  gets a slim tool set and no MCP servers; stream events are summarised into
  `build/<task>.progress` and the cost is reported.

- Simplification pass. Claude Code is now the only runtime: removed the OpenCode
  master, agents, commands, and installer target. Removed the vendored
  third-party skills `vercel-react-best-practices`, `skill-creator`, and
  `agent-browser` (install them separately if you want them). Removed
  `agents/models.conf` and the generated `builder-lite`, `review-code-lite`, and
  `review-code-strong` variants: the master passes the Agent tool's `model`
  parameter per call. A reinstall deletes the old variant files.
- Added a `Stop` hook (`pagani guard stop`) to the `/pagani` frontmatter. While a
  job's `Stage:` is `build`, `checks`, `review`, or `fix` and no builder is
  running, the master cannot end its turn between steps. `Stage` now has a fixed
  vocabulary the master writes to `job.md`.

- `pagani build` now starts the headless builder detached (`setsid`) and waits at
  most 9 minutes per call (`PAGANI_BUILD_WAIT`). A longer build returns `RUNNING`
  (exit 5) and the `build-runner` calls `pagani build <job> <task> --wait` until
  it finishes, so the Bash tool timeout can no longer kill a long build. A second
  call attaches to the running build instead of starting another.

- The master no longer stops after every step. It runs on its own and stops only
  at the lane's human checkpoints (SPEC approval, the final decision), on
  escalation, or on ambiguity.
- Builds run in a background `build-runner` subagent per task, so the agent panel
  shows what is running. The master keeps a `TodoWrite` item per task and posts a
  `Builders: N spawned · N running · N done` tally. `Bash(pagani build:*)` is
  allowed in the global settings (background subagents cannot answer prompts),
  and a copy install now unions permission lists when merging `settings.json`.

- Every lane now ends with the approval prompt (Step 6 and 7) through the native
  question UI. `trivial`, `bugfix`, and `small` only skip the quiz, so a small job
  can no longer close on a chat summary alone.

- Install is self-contained: `--copy` is the default, `--target auto` detects
  Claude Code and OpenCode, and the CLI plus resources are copied to
  `<config>/pagani/` so the clone can be deleted. `pagani upgrade --self`
  refreshes an installed copy. A copy install merges `settings.json` instead of
  overwriting it.
- Replaced `scripts/opencode-build` with the global `pagani build`, which runs
  the Claude Code `builder` agent headless (`claude -p`) on a third-party model
  from `~/.config/pagani/builder.env`. The `/pagani` command carries a
  frontmatter hook (`pagani guard builder`) that denies the Claude `builder`
  subagent only while the headless builder is configured. No per-project copy.

- `install` links `pagani` onto `PATH` (`~/.local/bin`), `bin/pagani` resolves its
  root through symlinks, `opencode-build` mirrors the job folder into the
  worktree, and every lane uses the OpenCode builder when the wrapper exists.
- Added `scripts/opencode-build` (installed by `pagani init`/`upgrade`): the Claude
  master runs the OpenCode `builder` agent (`opencode-go/deepseek-v4.1-flash#high`)
  headless per task, gets the session id, report path, and changed files back, and
  resumes the same session with review findings (`--revise`, max 2, then escalate). The model is set in `agents/opencode/builder.md` (`#high`); no env config. Claude
  plans, reviews, and approves; OpenCode only implements.
- Added `## Options considered` to the spec, finding examples to the reviewer,
  and a rule-placement hierarchy with harness-decay checks. Both masters now
  join parallel waves with `ALL` and share a context policy; closeout resumes
  idempotently. Renamed the design doc to `docs/RATIONALE.md` and tightened
  the stall-exit baseline and test-change wording.
- Added a hard task contract: every task names `Allowed files`, `Test first`, and
  `Done when`, and every `SPEC.md` names `## Sensors`. Builders treat existing
  tests as evaluator inputs, reviewers block out-of-bounds edits and unjustified
  test changes, and the fix loop stops after two rounds without a decrease.
- Verified the trim end to end: `bash -n`, `./scripts/validate.sh`, the help and
  install/uninstall dry-runs, a temp-project `init` and `job` smoke test, and
  the skill (8/8) and reviewer (100% recall, 0% noise) evals all pass.
- Added an explicit entry rule to both masters: a feature request starts at
  Step 0, `status` reads the newest job, and `resume` continues from `Stage:`.
  Builds default to sequential and run a parallel wave when the ready tasks
  touch disjoint files.
- Collapsed the model variants to `builder-lite`, `review-code-lite`, and
  `review-code-strong`; the master now runs `deepseek-v4.1-flash` high in
  OpenCode and Opus 5.5 medium in Claude Code.
- Removed the dashboard, usage snapshots, and metrics. `pagani job report` now
  accepts only `--retro`, `--write`, and `--exit-code`; the retro scan is kept.
- Trimmed the job artifacts: `job.md` is state only, and `human.md`, `fix.md`,
  job-level `TASKS.md`, and `round-N/summary.md` are gone. The approval quiz is
  mandatory only for `standard`/`high-risk`; the master posts summaries in chat
  and writes `summary.md` once at close.
- Deleted `GAPS.md`, `CATEGORIES.md`, and `VENDOR.md`; merged the useful
  category and vendor notes into the workflow doc.
- Simplified `README.md` and the docs around workflow, skills, usage, and
  concept.
- Removed duplicate repo copies: `scripts/claude-hook.sh` is now a symlink to
  `resources/claude-hook.sh`; `scripts/format` was removed.
- Removed empty `plugins/` and `pagani/` dirs, generated eval result files, and
  `.opencode/` plan artifacts; `.opencode/` is ignored.
- Added `pagani lint` checks for local doc links and `.claude/settings.json`
  hook parity.
- Removed the weekly timer, backup/restore, exact per-job cost, budget check,
  skill usage logging, and the GitHub Actions workflow. CI belongs to the target
  repository.
- The dashboard now shows jobs, checks, and metrics without a cost column.
- Merged duplicate skills into the custom ones: `grilling` into `interview`,
  `code-review` into `review-code`, `diagnosing-bugs` into `diagnosis`, `tdd`
  into `implementation`, and `pr` into `closeout`.
- Added skill eval cases for `interview`, `diagnosis`, and `implementation`.
- Replaced `plain-writing` with `unslop` and updated every call site.
- Removed the unused `ci-cd` skill and the `weekly-review` skill.
- Removed all five design skills (`design-taste-frontend`, `frontend-design`,
  `mobile-app-ui-design`, `openui`, `emil-design-eng`), the `design/` category,
  and the `/pagani design` command branch. Skills are now 37.
- Collapsed the CLI to eight top-level commands: `install` (with
  `--uninstall`), `doctor`, `init`, `upgrade`, `job`, `worktree`, `hooks`,
  `network`. `job` owns the lifecycle subcommands; `job report` merges status,
  dashboard, and retro; `doctor` absorbs lint. Removed `pr`, `worktree remove`,
  and `hooks status`.
- Removed the `job frontier`, `job classify`, and `job route` subcommands, and
  merged `uninstall` into `pagani install --uninstall`, which honors `--dry-run`.
- Replaced the `plan -> spec -> tickets` planning chain with one planner pass
  that writes `pagani/jobs/<id>/SPEC.md`, including the tracer-bullet task graph.
  Project templates are now `SPEC.md`, `ROADMAP.md`, and `TASKS.md`; the old
  plan template is gone, and `pagani init`/`pagani upgrade` create the new
  project docs.
- Collapsed the four review lenses into one `review-code` reviewer with code, UI,
  UX, and security checklists and one verdict. The master now loads `approval`,
  writes `decision.md`, and presents the explainer and quiz itself. Removed the
  `review-ui`, `review-ux`, `review-security`, and `approver` agents and skills;
  skills are now 34.
- Moved `HOW-IT-WORKS.md` to `docs/WORKFLOW.md` and `PLAN.md` to
  `docs/DESIGN.md`, added `docs/SKILLS.md` and `docs/SETUP.md`, shortened
  `README.md`, and added `scripts/validate.sh` as the release gate.
  `pagani doctor` now checks local links in `docs/*.md` and requires the four
  docs.
- Verified the simplified workflow end to end: syntax checks,
  `./scripts/validate.sh`, CLI help and dry-run install/uninstall, a
  temp-project `init`/`job` smoke test, and both eval suites (8/8 skill cases,
  100% reviewer recall with 0% noise).

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
- `GAPS.md` now includes a PLAN.md minimum-coverage table and 0.5.0 status for
  the P0–P3 gap list; README, HOW-IT-WORKS, PLAN, CATEGORIES, and VENDOR are
  synchronized.
- Added `resources/PLAN.md` (copied by `pagani init`) and a README
  compatibility matrix.

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
