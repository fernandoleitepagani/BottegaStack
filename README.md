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
./bin/pagani job new "Add rate limiting"
./bin/pagani classify --diff
./bin/pagani route <job>
./bin/pagani check <job>
./bin/pagani gate <job>
./bin/pagani usage start|end <job>
./bin/pagani hooks install|uninstall|status [path]
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
`pagani/metrics.tsv`; first-pass is `y` when the first check in `checks.log`
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
- A dashboard, a database, or a state machine.
- A full sandbox, network allowlist, or per-job spending cap. Use worktrees,
  permission denies, read-only tokens, and no secrets first.
- Backups of `pagani/jobs/`. It is gitignored and local to the machine. There is
  no snapshot, sync, or export.
- Prompt-injection defenses. Browser pages, PR bodies and comments,
  `BACKLOG.md`, and screenshots reach agents as data; nothing separates
  instructions from that data yet.

## License

MIT for the PaganiStack code. Vendored skills keep their own licenses; see
`VENDOR.md` and the license file in each skill folder.
