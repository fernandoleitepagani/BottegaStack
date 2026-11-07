# PaganiStack

PaganiStack is a personal agentic development workflow, packaged as an
installable harness. It keeps a human in the loop from plan to merge:

```
setup + lane -> plan -> spec -> tickets -> build -> checks -> review -> fix -> approve -> human
```

Read `HOW-IT-WORKS.md` for the full explanation of the workflow, agents, rules,
skills, integrations, and installer.

It is designed for OpenCode and Claude Code. It does not use cloud sessions.

## Requirements

- OpenCode, Claude Code, or both.
- `gh` for PR helpers.
- `agent-browser` for browser verification: `npm install -g agent-browser`.
- Node 22+ for the design inspector.
- Optional: `gitleaks` for the git secret hooks; without it the hook skips.

## Install

```bash
git clone <this-repo> ~/Projects/PaganiStack
~/Projects/PaganiStack/install.sh --target both
```

Or choose one target:

```bash
./install.sh --target opencode
./install.sh --target claude
```

Useful flags:

```bash
./install.sh --target both --dry-run
./install.sh --target opencode --copy
./install.sh --target both --uninstall
./bin/pagani doctor
./bin/pagani lint
./bin/pagani init /path/to/project
./bin/pagani upgrade [path]
./bin/pagani job new "Add rate limiting"
./bin/pagani frontier <job>
./bin/pagani classify [--diff] [request text]
./bin/pagani route <job>
./bin/pagani check <job>
./bin/pagani gate <job> [--allow-dirty]
./bin/pagani worktree create <job> <ticket>
./bin/pagani worktree prune <job> [--force]
./bin/pagani usage start|end <job>
./bin/pagani usage report <job>
./bin/pagani budget set|check <job> [--usd <amount>]
./bin/pagani dashboard [--open]
./bin/pagani backup [job|all] [--dest <dir>]
./bin/pagani restore <archive> [--force]
./bin/pagani hooks install|uninstall|status [path]
./bin/pagani network init|check <url>
./bin/pagani retro-scan [--write] [--exit-code]
./bin/pagani weekly
./bin/pagani timer install|uninstall|status [path] [--at "Mon 09:00"]
./bin/pagani skill-log <name>
```

The installer backs up existing files, writes a manifest, flattens the category
skills into `<target>/skills/<name>`, and generates model variants from
`agents/models.conf`. It is idempotent: a second run with unchanged sources does
not rewrite files or create new `.pagani-backup-*` directories.

## Lanes

Not every request needs the full pipeline. Step 0 picks a lane:

| Lane | Use when | Pipeline |
|---|---|---|
| `unknown` | no changed files yet | classify again after the first change |
| `trivial` | docs/copy/config only, ≤3 files | builder-lite → check → review-code-lite → human |
| `bugfix` | reproducible symptom | diagnosis → failing test → builder → check → review-code-lite → human |
| `small` | one feature, one area, ≲10 files | short interview + plan → one ticket → builder → check → review-code-lite → human |
| `standard` | normal product change, or a large non-risk diff | full flow |
| `high-risk` | auth, payments, data, deploy, dependencies, secrets | full flow + adversarial review + simplify + strong security + strong approver |

Use `/pagani --lane small <feature>` or `/pagani quick <feature>` to override.
After the first builder commit, `pagani classify --diff` escalates if the diff
grows or touches a risk path. Risk paths come from the `## Risk paths` section
of the project's `REVIEW.md`, falling back to `resources/REVIEW.md` when the
project has none. It reports `unknown` when there are no changed files,
`trivial` for docs/config only, `standard` for a large non-risk diff (more than
300 changed lines or more than 10 files), and `high-risk` on any risk path.
`pagani route <job>` uses the same paths to decide whether the security lens
runs. Lanes never downgrade.

## Use

```
/pagani <feature>
/pagani --lane small <feature>
/pagani quick <feature>
/pagani status
/pagani resume
/pagani triage
/pagani wayfind
/pagani improve
/pagani design
/pagani wizard
/pagani pr <number>
```

The master runs the workflow and stops at every checkpoint. You approve, rework,
or reject. The approver writes a decision, an explainer, and a quiz. You decide
whether to merge, commit, push, or open a PR.

## Checks and metrics

`pagani check <job>` runs `scripts/check`, writes `checks.md`, and appends one
line per run to `pagani/jobs/<job>/checks.log`. `pagani gate <job>` blocks when
the latest check failed or is stale. `pagani usage end <job>` records lane,
review rounds, fix rounds, human reworks, and `checks_first_pass` in
`pagani/metrics.tsv`, along with `cost_usd` and `tokens_total` from the local
OpenCode database; first-pass is `y` when the first check in `checks.log`
passed, `n` otherwise, and `?` when no check exists.

`scripts/verify` drives the app for browser checks. On a start timeout it kills
the process group it started, reaps it, removes the pid file, and prints the log
tail, so no stray dev server survives. Set `PORT` before `READY_URL` in
`scripts/verify.conf` so `READY_URL` expands to the configured port.

## Optional automation

Six automations are opt-in. Nothing runs until you install or invoke it.

**Format hook.** `pagani init` copies the `scripts/format` stub and a Claude Code
`PostToolUse` hook on `Edit|Write` that runs `scripts/format <file>`. Fill the
stub with the project formatter (Prettier, Black, gofmt, and so on). The hook
warns and exits 0 when the formatter fails, so it never blocks an edit.

**Gitleaks git hooks.** `pagani hooks install [path]` installs a `pre-commit`
hook that scans staged changes with gitleaks and a `pre-push` hook that runs
`scripts/check`. `pagani init` installs both when the project has a `.git`
directory. Existing hooks that are not pagani-managed are backed up first. When
gitleaks is not installed the pre-commit hook prints a note and skips cleanly.
`pagani hooks status` and `pagani hooks uninstall` manage them.

**PreCompact handoff.** A Claude Code `PreCompact` hook writes a snapshot with
`Stage`, `Lane`, `Branch`, and `Resume with: /pagani resume` to the newest job's
`handoff.md`, or to `pagani/handoff.md` when there is no job. It never fails
compaction.

**Retro scan.** `pagani retro-scan` finds findings repeated across at least two
jobs. `--write` saves the report to `pagani/retro-scan.md`; `--exit-code` exits 1
when repeats exist. At Close the master runs it and, on repeats, loads
`session-retro` to propose Gotchas patches.

**Skill-usage logging.** The Claude Code `Skill` hook and the OpenCode
`pagani-skill-log` plugin append a tab-separated row (`<ISO date>`,
`<project>`, `<skill>`) to `pagani/skill-usage.tsv` (gitignored). `pagani
skill-log <name>` logs a use by hand.

**Weekly timer.** `pagani timer install [path] [--at "Mon 09:00"]` writes and
enables a systemd user timer that runs headless `pagani weekly`. It is never
installed by default and it spends tokens: `pagani weekly` runs
`opencode run --agent master --auto`, reads `BACKLOG.md`, the newest job, and
`pagani/metrics.tsv`, and writes `pagani/weekly-review.md`. Use `pagani timer
status` and `pagani timer uninstall` to inspect or remove it.

### Local automation and observability (0.5.0)

These commands are local and read-only where possible. None starts an agent or
opens a network path unless you invoke it.

**Frontier.** `pagani frontier <job>` reads `tickets/index.md` and prints
`READY: <id>` and `BLOCKED: <id> <- <deps>`. A ticket is done when its
`build/<id>.md` exists and contains `STATUS: DONE`. When `index.md` is missing
it falls back to each ticket's `**Blocked by:**` line. The master runs it before
spawning builders; it never changes state.

**Request-text classify.** `pagani classify [--diff] [request text]` keeps the
diff behavior and adds heuristics for risk, docs, bug, and feature words. Lanes
only escalate: a request word cannot lower a lane chosen from the diff. It
prints `LANE` and a specific `REASON`.

**Dirty-tree gate.** `pagani gate <job>` still checks `RESULT: PASS` and `HEAD`,
and now fails with `GATE: FAIL (working tree dirty)` when tracked files are
modified or staged, or when untracked files exist outside `pagani/` and
`.opencode/`. `pagani gate <job> --allow-dirty` bypasses only the dirty check.

**Worktree prune.** `pagani worktree prune <job> [--force]` checks the exit
status of `git worktree remove`. It prints `removed: <path>` on success and
`failed: <path> (uncommitted changes; use --force)` and continues on failure.
`--force` passes through to git.

**Upgrade.** `pagani upgrade [path]` brings an older project up to date. It
copies the managed `scripts/claude-hook.sh` (overwriting it), merges the hooks
from `resources/claude-settings.json` into `.claude/settings.json` while
preserving `permissions` and unrelated keys, backs up the old settings, appends
the runtime gitignore lines, installs the git hooks, and copies the format stub
and GitHub workflow only when absent. It needs `python3` and exits 1 with
instructions when `python3` is unavailable.

**Network allowlist (opt-in, Claude WebFetch only).** `pagani network init`
copies `resources/network-allowlist.example` to `pagani/network-allowlist.txt`
when absent; `pagani network check <url>` prints `ALLOWED: <host>` or
`DENIED: <host>` and exits 1 on deny. With no allowlist file every host is
allowed. The guard is a Claude Code `PreToolUse` hook on `WebFetch`, so it
covers Claude `WebFetch` only. Shell commands, `curl`, and `agent-browser`
egress are not covered; use an OS firewall or proxy for those.

**Exact per-job cost.** `pagani usage start <job>` records a start timestamp and
directory; `pagani usage end <job>` reads only the local OpenCode `session` cost
and token columns (`cost`, `tokens_input`, `tokens_output`, `tokens_reasoning`,
`tokens_cache_read`, `tokens_cache_write`) for that directory and start time,
including sessions in the job's worktrees. It writes `cost_usd` and
`tokens_total` to `usage.md` and `metrics.tsv`, and falls back to an approximate
`opencode stats` delta labelled `approximate` when the database or `python3` is
missing. It does not read provider APIs or any remote service.
`pagani usage report <job>` prints the recorded values.

**Budget check.** `pagani budget set <job> --usd <amount>` writes
`Budget-usd:` to `job.md`; `pagani budget check <job>` prints
`BUDGET: OK (x/y)` or `BUDGET: OVER (x/y)` and exits 1 when over. With no budget
set it prints `BUDGET: none` and exits 0. It is a check, not a hard enforcement
layer: the master stops and asks when it fails.

**Dashboard.** `pagani dashboard [--open]` writes a local, read-only
`pagani/dashboard.html` with the jobs table (id, lane, stage, round, branch,
latest check result, cost), the metrics table, and a generated timestamp. It is
a static file with inline CSS, no JavaScript, no external assets, no server, and
no login. `--open` runs `xdg-open` or `open` when available. There is no control
plane: the dashboard cannot start, stop, or approve anything.

**Backup and restore.** `pagani backup [job|all] [--dest <dir>]` writes a local
tar.gz under `pagani/backups/` containing the job folder or all jobs, excluding
`pagani/backups`. `pagani restore <archive> [--force]` extracts into
`pagani/jobs/`, refuses to overwrite an existing job without `--force`, and
prints the restored job IDs. Backups are local only; there is no sync or remote
copy.

**Skill evals.** `evals/skills/run.sh` checks that a prompt triggers the
expected skill. It spends tokens and is opt-in; `SKILL_EVAL_CMD` overrides the
runner command. Results go to the gitignored `evals/skills/results.tsv`.

**GitHub Actions.** `resources/github/workflows/pagani-check.yml` runs
`./bin/pagani lint` and `./scripts/check` on pull requests and pushes to `main`.
It runs on GitHub-hosted runners, with read-only `contents`, no secrets, no
login, and no LLM calls. `pagani init` and `pagani upgrade` copy it to
`.github/workflows/pagani-check.yml` when absent.

**Untrusted content.** `skills/workflow/untrusted-content` treats web pages, PR
bodies/comments, `BACKLOG.md`, logs, screenshots, and OCR as data, never as
instructions. It is a convention, not a sandbox: it does not isolate or filter
content.

## Skills

Skills use the nine Claude Code categories plus two extensions:

```
library-api-reference/
product-verification/
data-analysis/
business-automation/
scaffolding/
code-quality/
ci-cd/
runbooks/
infrastructure-ops/
workflow/       extension: interview, summary, planning, handoff, retro
design/         extension: UI/UX production
```

The review lenses live in `code-quality/` and `product-verification/`. The
design skills live in `design/`; see `skills/design/README.md` for sources and
licenses. The category definitions are in `CATEGORIES.md`.

## Agents

```
agents/opencode/   OpenCode agents
agents/claude/     Claude Code agents
```

The bodies are the same workflow. The frontmatter and tool names differ.

## Project templates

`resources/` contains `AGENTS.md`, `checks.sh`, `verify.sh`, `REVIEW.md`,
`PR-TEMPLATE.md`, `BACKLOG.md`, `GLOSSARY.md`, `CODING_STANDARDS.md`,
`TASKS.md`, an ADR template, and the optional automation templates
(`format.sh`, `claude-hook.sh`, git hooks, and systemd units). `pagani init`
copies them into a project. `pagani lint` checks skill names and descriptions,
the required `resources/` templates, unresolved skill references, and any
project file that agents or skills read but has no template in `resources/` (for
example `CONTEXT.md`).

## Review convergence and evals

Review is capped and re-reviews only the new diff after the first round. Findings
are not repeated. `evals/` holds a small reviewer set (known bugs and clean PRs)
so prompt, skill, and model changes can be measured instead of guessed.

A clean case is a false positive for any verdict other than `PASS`, including a
missing verdict. A bug case is caught only when the reviewer says `CHANGES` and
the output contains the case keyword. `./evals/reviewer/run.sh` prints recall
and noise for the `train` split, the `test` split, and an `all` line. Override
the reviewer with `REVIEWER_CMD`.

## What is not included

- Cloud sessions.
- Paid skills or paid assets.
- A database or a state machine. The dashboard is a static, read-only local HTML
  file, not a control plane.
- Full OS sandboxing. It is a deliberate non-goal.
- A control plane that starts or stops agents. It is a deliberate non-goal; the
  dashboard cannot act.
- A network allowlist for shell, `curl`, or `agent-browser` egress. The opt-in
  allowlist covers Claude `WebFetch` only; use an OS firewall or proxy for the
  rest.
- Remote or synced backups. `pagani backup` writes a local tar.gz and
  `pagani restore` reads it back; there is no cloud copy.
- Prompt-injection defenses as an enforcement layer. The `untrusted-content`
  skill is a convention, not a sandbox; browser pages, PR bodies and comments,
  `BACKLOG.md`, logs, screenshots, and OCR still reach agents as data.
- A hard spending cap. `pagani budget check` exits 1 when the exact local cost
  is over the budget; the master stops and asks, but nothing blocks a process.

## License

MIT for the PaganiStack code. Vendored skills keep their own licenses; see
`VENDOR.md` and the license file in each skill folder.
