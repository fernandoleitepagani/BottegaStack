# How PaganiStack Works

PaganiStack is a personal agentic development workflow, packaged as an
installable harness. It is not a framework and not a cloud service. It is a set
of agents, skills, commands, templates, and a small installer that keep a human
in the loop from a feature request to a reviewed, mergeable branch.

The short version:

```
/pagani <feature>
  -> plan -> spec -> tickets -> build -> checks -> review -> fix -> approve -> you decide
```

The long version is below.

## Contents

1. [What it is](#1-what-it-is)
2. [Quick start](#2-quick-start)
3. [Directory map](#3-directory-map)
4. [The workflow](#4-the-workflow)
5. [Job folder and state](#5-job-folder-and-state)
6. [Agents](#6-agents)
7. [Agent rules](#7-agent-rules)
8. [Skills](#8-skills)
9. [Commands and integrations](#9-commands-and-integrations)
10. [Review system](#10-review-system)
11. [Verification and checks](#11-verification-and-checks)
12. [Context and token management](#12-context-and-token-management)
13. [Installer and portability](#13-installer-and-portability)
14. [Safety and guardrails](#14-safety-and-guardrails)
15. [Customization](#15-customization)
16. [Troubleshooting](#16-troubleshooting)
17. [Sources and attribution](#17-sources-and-attribution)

---

## 1. What it is

Three layers:

| Layer | What it is |
|---|---|
| **Workflow** | The ten steps: plan, spec, tickets, build, checks, review, fix, approve, human decision, close. |
| **Harness** | The agents, skills, commands, resources, checks, and evals that make the workflow run. |
| **Kit** | The repo plus `install.sh`, which installs the harness into OpenCode, Claude Code, or both. |

The name stays **PaganiStack**. "Stack" is the brand; the thing itself is an
installable workflow and harness.

### Non-negotiables

- The human is the final approver.
- No cloud sessions.
- No paid skills or paid assets.
- No JSON state machine. The job folder is the state.
- One writer per file.
- Every agent gets a fresh context and a narrow task.
- No reviewer runs on a failing deterministic check.
- Nothing is pushed, merged, or deployed without an explicit instruction.

---

## 2. Quick start

```bash
git clone <this-repo> ~/Projects/PaganiStack
~/Projects/PaganiStack/install.sh --target both
~/Projects/PaganiStack/bin/pagani doctor
```

Then, in a project:

```bash
cd ~/Projects/my-project
~/Projects/PaganiStack/bin/pagani init
```

Then, in OpenCode or Claude Code:

```
/pagani Add an estimated reading time to blog posts
```

The master creates a job, asks questions, writes a plan, and stops for approval.
You drive the rest with `approve`, `rework <note>`, `reject`, or a question.

---

## 3. Directory map

```
PaganiStack/
  agents/
    opencode/            OpenCode agents: mode, model, steps, permissions
    claude/              Claude Code agents: name, description, tools, model
    models.conf          model tiers for generated variants
  commands/
    opencode/pagani.md   /pagani for OpenCode
    claude/pagani.md     /pagani for Claude Code
  skills/
    <category>/<skill>/SKILL.md
  resources/             project templates copied by `pagani init`
  evals/                 reviewer and skill evals
  bin/pagani             installer and helper CLI
  install.sh             thin wrapper around `bin/pagani install`
  CLAUDE.md              `@AGENTS.md` for Claude Code
  README.md              install and usage
  HOW-IT-WORKS.md        this file
  CATEGORIES.md          the nine-plus-two skill taxonomy
  PLAN.md                the workflow design
  GAPS.md                implemented, partial, and optional items
  VENDOR.md              upstream skill sources and licenses
  CHANGELOG.md
  VERSION
  LICENSE
```

Installed layout:

```
~/.config/opencode/       OpenCode target
  agents/
  skills/<name>/
  commands/pagani.md

~/.claude/                Claude Code target
  agents/
  skills/<name>/
  commands/pagani.md
```

The source is organized by category. The installer **flattens** it to
`skills/<name>/SKILL.md` because both runtimes discover skills at that depth.

---

## 4. The workflow

```
request
  |
  v
0. SETUP       classify lane, job folder, branch, usage start
  |
  v
1. PLAN        interview -> plan.md                  [you approve]
  |
  v
2. SPEC        spec.md                               [you approve]
  |
  v
3. TICKETS     tickets/index.md + one file per ticket [you approve]
  |
  v
4. BUILD       one builder per ticket, parallel when safe
  |            build/<ticket>.md                     [you approve per wave]
  v
5. CHECKS      pagani check -> checks.md              (fail -> builder)
  |
  v
6. REVIEW      code + ui/ux/security as needed
  |            round-N/review-*.md -> summary.md      [you see the summary]
  v
7. FIX         if CHANGES: fix.md -> fresh builder -> checks -> affected reviews
  |            max 2 fix rounds
  v
8. APPROVE     approver -> decision.md + explainer + quiz
  |
  v
9. HUMAN       you approve, rework, or reject
  |
  v
10. CLOSE      usage end, merge/commit/push/PR only on your instruction, retro
```

### Step 0: Set up and classify

The master reads `AGENTS.md`, `GLOSSARY.md` if it exists, and the
`## Risk paths` section of `REVIEW.md`. It loads the `lanes` skill, proposes a
lane, and asks you to confirm or override. It then runs `pagani job new` to
create the folder and branch, writes `Lane` and `Lane-reason` to `job.md`, and
runs `pagani usage start <job>`.

| Lane | Use when | Steps |
|---|---|---|
| `unknown` | no changed files yet | classify again after the first change |
| `trivial` | docs/copy/config only, ≤3 files, no risk path | setup → `builder-lite` → `pagani check` → `review-code-lite` → human |
| `bugfix` | reproducible symptom | setup → `diagnosis` → failing test → `builder` → check → `review-code-lite` (+ security on a risk path) → human |
| `small` | one feature, one area, ≲10 files | setup → short interview → `plan.md` with acceptance criteria → one ticket → `builder` → check → `review-code-lite` + routed lens → human |
| `standard` | normal product change, or a large non-risk diff (>300 changed lines or >10 files) | full flow |
| `high-risk` | auth, payments, data/schema, deploy/CI, installers, dependencies, secrets, or any risk path | full flow + adversarial review + simplify + strong security + strong approver; quiz mandatory |

After the first builder commit, run `pagani classify --diff`. If it suggests a
higher lane, escalate, update `job.md`, and tell the user in one line. Lanes
never downgrade. `pagani classify` and `pagani route` read risk paths from the
`## Risk paths` section of the project's `REVIEW.md`, falling back to
`resources/REVIEW.md` when the project has none. `pagani classify` reports
`unknown` for an empty diff, `high-risk` on any risk-path match, `trivial` for
docs/config only, `standard` for a large non-risk diff, and `small` otherwise.
`pagani route` uses the same risk paths to decide whether the security lens
runs; a large non-risk diff stays `standard`, not `high-risk`.

### Step 1: Plan

The master loads the `interview` skill. It explores the repository first, then
asks 3-5 questions at a time with the native question UI. It covers:

- problem and goal
- users and actors
- use cases and edge cases
- scope in/out
- constraints
- acceptance criteria
- UI/UX
- security/privacy
- testing
- rollout
- risks
- definition of done

The answers go to `interview.md`. The planner writes `plan.md`. The master posts
a summary and waits.

### Step 2: Spec

The planner writes `spec.md` using the adapted `to-spec` shape: problem,
solution, user stories, implementation decisions, testing decisions, acceptance
criteria, out of scope, assumptions. The master posts a summary and waits.

### Step 3: Tickets

The planner writes `tickets/index.md` and one file per tracer-bullet ticket.
Each ticket is a vertical slice, demoable or verifiable on its own, with blocking
edges. The master posts the graph and the first wave and waits.

### Step 4: Build

The master computes the ready frontier. It spawns one `builder` per ready
ticket. Parallel only when files are disjoint; one worktree per ticket when
parallel. Each builder writes `build/<ticket>.md`. The master merges ticket
branches into the job branch and posts a wave summary.

### Step 5: Checks

Deterministic checks are commands that return pass or fail without an LLM:
lint, typecheck, test, build, browser smoke. The master runs the commands in
`AGENTS.md`, writes `checks.md`, and fails the wave on a non-zero exit. Each run
also appends one line to `pagani/jobs/<job>/checks.log`
(`date`, `HEAD`, `PASS|FAIL`, exit code, duration). No reviewer runs on a
failing build.

### Step 6: Review

The master routes only the needed lenses:

| Lens | When |
|---|---|
| `review-code` | Always |
| `review-ui` | Diff touches components/styles/pages/templates, or the spec has UI criteria |
| `review-ux` | Flow, copy, states, accessibility, mobile, or UX criteria |
| `review-security` | Auth, permissions, payments, input, API routes, DB/storage, secrets, dependencies |

For high-risk changes, it also runs `adversarial-review` and `simplify`.

Reviewers run in parallel, fresh context, and do not see each other's files.
They write one file each. The master waits for all, writes
`round-N/summary.md`, and posts the short version.

### Step 7: Fix

If any review says `CHANGES`, the master loads `diagnosis`, writes `fix.md` with
what, why, where, how, how to verify, and evidence. A fresh builder fixes it.
The master re-runs checks and re-reviews only the affected lenses. Max two fix
rounds, then escalate.

### Step 8: Approve

The approver loads `approval`, reads the spec, builds, checks, reviews, and diff,
spot-checks at least one acceptance criterion, and writes `decision.md` with
`APPROVE` or `ESCALATE`, an explainer, and a quiz.

### Step 9: Human decision

The master loads `closeout`. It asks with the question UI:

- approve and merge
- approve and commit
- approve and push
- approve and open PR
- rework
- reject

It shows the exact git command and asks for confirmation before a push, merge,
or PR.

### Step 10: Close

The master updates `job.md`, records the decision in `human.md`, runs
`pagani usage end <job>` to append the lane, rounds, fix rounds, human reworks,
and `checks_first_pass` to `pagani/metrics.tsv`, runs
`pagani retro-scan --exit-code`, and loads `session-retro` to propose one
environment change. When the scan reports findings repeated across jobs, the
master loads `session-retro` and proposes Gotchas patches. It loads
`session-handoff` if the job will continue in another session.

### Split runner

Job state is files in `pagani/jobs/<id>/`, so the runtimes can share a job:

1. Run Steps 0-3 (setup, plan, spec, tickets) in Claude Code.
2. In the same project, run `/pagani resume` in OpenCode for build, checks,
   review, and fix.
3. Optionally return to Claude Code at `approve` for the strong approver.

Both masters read `Stage:` from `job.md` and never re-plan completed steps.

---

## 5. Job folder and state

```
pagani/jobs/<job-id>/
  job.md
  interview.md
  plan.md
  spec.md
  tickets/
    index.md
    01-<slug>.md
  build/
    01-<slug>.md
  checks.md
  round-1/
    review-code.md
    review-ui.md
    review-ux.md
    review-security.md
    summary.md
  fix-1.md
  decision.md
  human.md
  TASKS.md
  handoff.md
```

`job.md` is a plain checklist:

```markdown
# Job 001 — <feature>

Stage: review
Round: 1
Lane: standard
Lane-reason: normal product change
Branch: pagani/001-<slug>
Base: main

## Steps
- [x] plan
- [x] spec
- [x] tickets
- [x] build
- [x] checks
- [x] review
- [ ] approve
- [ ] human
```

No JSON, no database, no state machine. The folder is the state. `TASKS.md`
survives context compaction; `handoff.md` lets a fresh session continue.

Add `pagani/jobs/` to the project `.gitignore`. `pagani init` does this.

---

## 6. Agents

Both runtimes have the same nine roles.

| Agent | Role | Writes |
|---|---|---|
| `master` | Orchestrator. Talks to you, asks questions, runs checks, posts summaries, executes git only on request. | Job files, `checks.md`, `summary.md`, `fix.md`, `human.md`, `TASKS.md`, `handoff.md`. |
| `explorer` | Cheap read-only search and log reading. | A short report, no file. |
| `planner` | Three modes: `PLAN`, `SPEC`, `TICKETS`. | `plan.md`, `spec.md`, `tickets/`. |
| `builder` | Implements exactly one ticket. | Code + `build/<ticket>.md`. |
| `review-code` | Correctness, simplicity, conventions, tests, spec fidelity. | `round-N/review-code.md`. |
| `review-ui` | Visual consistency, responsive, contrast, design-system fit. | `round-N/review-ui.md`. |
| `review-ux` | Flows, states, copy, accessibility, mobile. | `round-N/review-ux.md`. |
| `review-security` | Access control, input, data exposure, secrets, dependencies. | `round-N/review-security.md`. |
| `approver` | Final gate + explainer + quiz. | `decision.md`. |

The installer generates tier variants from `agents/models.conf`:
`planner-std`, `planner-strong`, `builder-lite`, `builder-strong`,
`review-code-lite`, `review-code-strong`, `review-security-strong`,
`approver-strong`.

OpenCode agents live in `agents/opencode/` and use `mode`, `model`, `steps`, and
`permissions`. Claude Code agents live in `agents/claude/` and use `name`,
`description`, `tools`, and `model`.

The agent bodies are the same workflow. The procedures live in skills.

---

## 7. Agent rules

### Global

- The user is the final approver.
- Load the relevant skill before each procedure.
- After every step, write a summary and stop. The user approves before you
  advance.
- One writer per file.
- No reviewer on a failing deterministic check.
- Max two fix rounds.
- No cloud sessions.
- Check evidence before accepting a report.
- Never touch secrets, production data, deploy config, or user state.

### Subagents

- Fresh context per subagent.
- One task per subagent: one ticket per builder, one lens per reviewer.
- The prompt starts with the job folder and exact files. No conversation
  history.
- Each subagent writes one file and returns a short report. The master reads the
  file, not the chat.
- The master checks the artifact, diff, command output, or screenshot before
  accepting a report.
- No reviewer sees another review.
- Parallel only on disjoint files; one worktree per ticket; one port per worker.
- Max 3 builders, all routed reviewers, one job at a time.
- Max 2 fix rounds, max 3 builder attempts, max 1 plan revision.
- No cloud sessions.

### Model and effort routing

The installer generates variants from `agents/models.conf`.

| Role | trivial | bugfix | small | standard | high-risk |
|---|---|---|---|---|---|
| explorer | lite | lite | lite | lite | lite |
| planner | — | — | `planner-std` | `planner-strong` | `planner-strong` |
| builder | `builder-lite` | `builder` | `builder` | `builder` | `builder-strong` |
| review-code | `review-code-lite` | `review-code-lite` | `review-code-lite` | `review-code` | `review-code-strong` |
| review-ui / review-ux | base (lite) | — | base (lite) | base (lite) | base (lite) |
| review-security | risk path only | risk path only | risk path only | base (strong) | `review-security-strong` |
| approver | — | — | — | base (strong) | `approver-strong` |

Tiers:

- Claude Code: `haiku` (lite), `sonnet` (std), `opus` (strong).
- OpenCode: `opencode-go/glm-5.3-flash` (lite),
  `opencode-go/deepseek-v4.1-flash` (std),
  `opencode-go/deepseek-v4-pro` (strong);
  `opencode-go/glm-5.3` for strong code review.

Effort: low for mechanical work, medium for normal features, high for
verification/security/bugfixes, max only for autonomous hard tasks.

### Context rules

- One job at a time. A new job starts a new session.
- Do not change the model, effort, or MCP servers mid-job unless necessary.
- Use `TASKS.md` for long runs.
- Use `session-handoff` when context is near full.
- Use `/clear` between unrelated tasks, `/compact` at a natural break, and
  `/rewind` instead of correcting a wrong path.
- Run `pagani usage start <job>` at setup and `pagani usage end <job>` at close.

---

## 8. Skills

### Taxonomy

Nine Claude Code categories plus two extensions:

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
workflow/       extension: planning and session skills
design/         extension: UI/UX production
```

See `CATEGORIES.md` for what each category means and what belongs in it.

### All skills

**library-api-reference**

- `library-reference`
- `vercel-react-best-practices`

**product-verification**

- `verification`
- `review-ui`
- `review-ux`
- `web-design-guidelines`
- `agent-browser`

**data-analysis**

- `data-analysis`

**business-automation**

- `backlog-triage`
- `weekly-review`

**scaffolding**

- `scaffold`

**code-quality**

- `review-code`
- `review-security`
- `approval`
- `implementation`
- `codebase-design`
- `domain-modeling`
- `improve-architecture`
- `adversarial-review`
- `simplify`
- `review-pr`
- `tdd`
- `code-review`

**ci-cd**

- `pr`
- `ci-cd`

**runbooks**

- `diagnosis`
- `diagnosing-bugs`
- `runbook`

**infrastructure-ops**

- `infra-ops`

**workflow**

- `interview`
- `summary`
- `wait-what`
- `wayfinding`
- `planning`
- `plain-writing`
- `closeout`
- `session-handoff`
- `session-retro`
- `skill-creator`
- `grilling`
- `wizard`
- `writing-for-agents`

**design**

- `design-taste-frontend`
- `frontend-design`
- `mobile-app-ui-design`
- `openui`
- `emil-design-eng`

`web-design-guidelines` lives under product-verification because it is a
compliance pass, not a design generator.

### How skills load

An agent prompt says "Load the `interview` skill." The skill tool loads
`skills/<category>/<skill>/SKILL.md` from the source, or
`<target>/skills/<skill>/SKILL.md` after install. Skills are loaded on demand,
not all at startup.

### How to add a skill

1. Pick a category.
2. Create `skills/<category>/<name>/SKILL.md`.
3. Add frontmatter:

```markdown
---
name: <name>
description: <when to trigger this skill, written for the model>
---
```

4. Write the procedure. Put detailed reference in sibling files and point to
   them. Add a Gotchas section for the failures the agent will hit.
5. If the skill is adapted from upstream, rename it and note the source.
6. Run `./bin/pagani doctor` and `./install.sh --target both --dry-run`.

Do not add a paid skill or a skill that needs a paid asset.

---

## 9. Commands and integrations

### `/pagani`

```
/pagani <feature>          start a job
/pagani status             show the newest job
/pagani resume             continue from the current stage
/pagani triage             work the local BACKLOG.md
/pagani wayfind            chart a decision map for huge work
/pagani improve            architecture review
/pagani design             UI/UX design pass
/pagani wizard             human-only setup procedure
/pagani pr <number>        PR review
```

### Integrations

| Integration | What it does |
|---|---|
| OpenCode | Installs agents, skills, commands into `~/.config/opencode`. |
| Claude Code | Installs agents, skills, commands into `~/.claude`. |
| `gh` | `pagani pr` reads PR view, diff, and checks. |
| `agent-browser` | Browser verification for UI/UX and acceptance criteria. Install with `npm install -g agent-browser`. |
| Project `AGENTS.md` | Commands, conventions, verification recipe, gotchas. |
| `resources/checks.sh` | Deterministic checks. |
| `resources/verify.sh` | App/browser driver. |
| `evals/` | Reviewer and skill evals. |
| GitHub Actions | Opt-in `pagani-check` workflow: lint and `scripts/check` on GitHub runners, read-only `contents`, no secrets. |
| Claude `WebFetch` allowlist | Opt-in `pagani/network-allowlist.txt` guard; Claude `WebFetch` only. |
| `VENDOR.md` | Upstream skill sources and licenses. |

---

## 10. Review system

### Routing

Only the needed lenses run. Code always; UI for UI; UX for flows/copy/a11y;
security for auth/data/payments/input. High-risk changes add adversarial review
and simplify.

### Review convergence

- Max 3 rounds.
- After round 1, review only the new diff.
- Flag the class of bug so every instance is fixed.
- Do not repeat findings already posted.
- Drop style and cleanup findings from blocking.
- A blocking finding can be confirmed by a second reviewer before the builder is
  sent back.

### Risk tiers

| Risk | Examples | Human approvals |
|---|---|---|
| Low | Docs, copy, internal-only, additive behind a flag | Automated checks + AI review |
| Medium | Ordinary product changes, caching, auto-updater, system prompts | One person |
| High | Auth, payments, data, deploy, schema, installers | Two people |

### Evals

`evals/reviewer/` has known bugs and clean cases, plus a score sheet. Run the
reviewer against them after a prompt, skill, or model change. A clean case is a
false positive for any verdict other than `PASS`, including a missing verdict.
A bug case is caught only when the verdict is `CHANGES` and the output contains
the case keyword. The runner prints recall (bugs caught) and noise (clean-case
false positives) for the `train` split, the `test` split, and an `all` line.
`REVIEWER_CMD` overrides the reviewer command.

`evals/skills/` is for trigger and output tests for skills.

---

## 11. Verification and checks

Deterministic checks are the cheapest error filter. They run before review and
again before approval.

```bash
pagani check <job>     # runs scripts/check, writes checks.md with RESULT + HEAD
pagani gate <job>      # fails if checks are failing or stale
```

`pagani check` also appends one line per run to `pagani/jobs/<job>/checks.log`.
`pagani usage end <job>` reads the first line and records `checks_first_pass` as
`y` when that first check passed, `n` otherwise, or `?` when there is no log.

`pagani init` copies `resources/checks.sh` to `scripts/check`. Fill it with the
project's install, lint, typecheck, test, and build commands. It must exit 0
only when the branch is fit to review.

`scripts/verify` is the app/browser driver. It reads `scripts/verify.conf`
(`START_CMD`, `READY_URL`, `PORT`) and derives a port from the worktree path
when `PORT` is not set:

```bash
scripts/verify doctor
scripts/verify start
scripts/verify snapshot
scripts/verify screenshot /tmp/result.png
scripts/verify flow <name>
scripts/verify stop
```

`PORT` must come before `READY_URL` in `verify.conf` so `READY_URL` expands to
the configured port; `scripts/verify doctor` shows the resolved port. If the app
does not come up within `READY_TIMEOUT` seconds, `start` kills the process group
it started, reaps it, removes the pid file, prints the log tail, and exits
non-zero. No process from `START_CMD` is left behind. `stop` also removes the pid
file when the process is already gone.

`docs/FEATURE-MAP.md` tells the agent how to reach each feature, what seed data
or login it needs, and which flow proves it. If no flow covers an acceptance
criterion, the agent writes one and adds it to the map.

---

## 12. Context and token management

| Rule | Why |
|---|---|
| Keep `AGENTS.md` short, under ~200 lines | It loads every turn. Put gotchas, not obvious facts. |
| Progressive disclosure | Load detail only when needed. |
| `/clear` between tasks | A fresh context is cheaper than a polluted one. |
| `/compact` at a break | Keep continuity without the whole history. |
| `/rewind` instead of correcting | Do not carry a failed path forward. |
| Keep the cache warm | Do not change model, effort, or MCP mid-session. |
| Route subagents to cheap models | Search and logs do not need the strong model. |
| Use `TASKS.md` | It survives compaction. |
| Use `session-handoff` | A fresh session can continue. |
| Run `pagani usage start` / `end` | Capture exact per-job cost and tokens from the local OpenCode DB. |
| Check `pagani/metrics.tsv` | Lane, rounds, fixes, reworks, first-pass checks, cost, tokens. |
| Run `pagani budget check <job>` | Stop and ask when the exact cost is over budget. |

---

## 13. Installer and portability

```bash
./install.sh --target both
./install.sh --target opencode
./install.sh --target claude
./install.sh --target both --dry-run
./install.sh --target opencode --copy
./install.sh --target both --uninstall
```

`install.sh` is a thin wrapper around `bin/pagani install`. The CLI also has:

```bash
pagani doctor
pagani lint
pagani init [path]
pagani upgrade [path]
pagani job new "<title>"
pagani frontier <job>
pagani classify [--diff] [request text]
pagani route <job>
pagani check <job>
pagani gate <job> [--allow-dirty]
pagani worktree create <job> <ticket>
pagani worktree prune <job> [--force]
pagani worktree remove <path>
pagani usage start|end <job>
pagani usage report <job>
pagani usage [job]
pagani budget set|check <job> [--usd <amount>]
pagani dashboard [--open]
pagani backup [job|all] [--dest <dir>]
pagani restore <archive> [--force]
pagani status
pagani pr <number>
pagani hooks install|uninstall|status [path]
pagani network init|check <url>
pagani retro-scan [--write] [--exit-code]
pagani weekly
pagani timer install|uninstall|status [path] [--at "Mon 09:00"]
pagani skill-log <name>
```

### Optional automation

Six automations are opt-in. `pagani init` installs the format, PreCompact, and
skill-log hooks plus the git hooks; the weekly timer is separate.

- **Format hook.** `pagani init` copies `resources/format.sh` to
  `scripts/format` and writes a Claude Code `PostToolUse` hook on `Edit|Write`
  that runs `scripts/format <file>`. Replace the stub with the project
  formatter. A formatter failure prints a warning and exits 0, so it never
  blocks an edit.
- **Gitleaks git hooks.** `pagani hooks install [path]` copies a `pre-commit`
  hook that scans staged changes with gitleaks and a `pre-push` hook that runs
  `scripts/check`. `pagani init` installs both when the project has `.git`.
  Existing non-pagani hooks are backed up as
  `<hook>.pagani-backup-<stamp>` first. If gitleaks is not installed, the
  pre-commit hook prints a note and skips cleanly. `pagani hooks status` shows
  what is installed and `pagani hooks uninstall` removes only pagani-managed
  hooks.
- **PreCompact handoff.** A Claude Code `PreCompact` hook appends a
  `## PreCompact snapshot` section with `Stage`, `Lane`, `Branch`, and
  `Resume with: /pagani resume` to the newest job's `handoff.md`, or to
  `pagani/handoff.md` when there is no job. It never fails compaction.
- **Retro scan.** `pagani retro-scan` scans review and fix files across jobs and
  reports titles found in at least two jobs. `--write` saves
  `pagani/retro-scan.md`; `--exit-code` exits 1 when repeats exist. At Close the
  master runs it and, on repeats, loads `session-retro` to propose Gotchas
  patches.
- **Skill-usage logging.** The Claude Code `Skill` hook and the OpenCode
  `pagani-skill-log` plugin append tab-separated rows to
  `pagani/skill-usage.tsv` (gitignored): ISO date, project basename, skill.
  `pagani skill-log <name>` records a use manually. The plugin is installed by
  `./install.sh --target opencode`.
- **Weekly timer.** `pagani timer install [path] [--at "Mon 09:00"]` writes
  `pagani-weekly-<hash>.service` and `.timer` to the systemd user directory and
  enables the timer when `systemctl --user` works; otherwise it prints the
  manual enable command. The timer runs headless `pagani weekly`, which spends
  tokens: it runs `opencode run --agent master --auto`, reads `BACKLOG.md`, the
  newest job, and `pagani/metrics.tsv`, proposes at most five backlog items and
  one environment change, and writes `pagani/weekly-review.md`. Nothing is
  pushed, merged, deployed, or opened as a PR. `pagani timer status` and
  `pagani timer uninstall` inspect or remove it. It is never installed by
  default.

### Local automation and observability (0.5.0)

The 0.5.0 layer is local, read-only where possible, and opt-in where it spends
money or opens a network path. None of it starts an agent or a server.

- **Frontier.** `pagani frontier <job>` parses `tickets/index.md` lines of the
  form `- <id> — blocked by: <deps>` and prints `READY: <id>` or
  `BLOCKED: <id> <- <deps>`. A ticket is done when
  `build/<id>.md` exists and contains `STATUS: DONE`. Without `index.md` it
  falls back to each ticket's `**Blocked by:**` line. It only reads.
- **Request-text classify.** `pagani classify [--diff] [request text]` keeps the
  diff behavior and adds risk, docs, bug, and feature word heuristics. Lanes
  only escalate: a request word cannot lower a diff-based lane. It prints `LANE`
  and a specific `REASON`.
- **Dirty-tree gate.** `pagani gate <job>` fails with
  `GATE: FAIL (working tree dirty)` when tracked files are modified or staged,
  or when untracked files exist outside `pagani/` and `.opencode/`.
  `--allow-dirty` bypasses only the dirty check.
- **Worktree prune.** `pagani worktree prune <job> [--force]` checks the exit
  status of `git worktree remove`. Success prints `removed: <path>`; failure
  prints `failed: <path> (uncommitted changes; use --force)` and the command
  continues. `--force` passes through to git.
- **Upgrade.** `pagani upgrade [path]` copies the managed
  `scripts/claude-hook.sh` (overwriting it), merges the `hooks` object from
  `resources/claude-settings.json` into `.claude/settings.json` (preserving
  `permissions` and unrelated keys), backs up the old file, appends the runtime
  gitignore lines, installs the git hooks, and copies the format stub and GitHub
  workflow only when absent. It needs `python3`; without it, it prints
  instructions and exits 1.
- **Network allowlist (opt-in).** `pagani network init` copies
  `resources/network-allowlist.example` to `pagani/network-allowlist.txt` when
  absent. `pagani network check <url>` extracts the host, applies exact or
  `*.suffix` matching, and prints `ALLOWED: <host>` or `DENIED: <host>` (exit 1
  on deny). With no allowlist file every host is allowed. The guard is a Claude
  Code `PreToolUse` hook on `WebFetch`, so it covers Claude `WebFetch` only;
  shell commands, `curl`, and `agent-browser` egress are not covered. Use an OS
  firewall or proxy for those.
- **Exact per-job cost.** `pagani usage start <job>` records `START_MS`, the
  project directory, and the job worktree prefix. `pagani usage end <job>` reads
  only the local OpenCode `session` cost and token columns for that directory
  and start time, including sessions in the job's worktrees. It appends a
  `### job cost (exact)` section to `usage.md` and writes `cost_usd` and
  `tokens_total` to `metrics.tsv`. When the database or `python3` is missing it
  falls back to an `opencode stats --json --cost` delta labelled `approximate`.
  It reads no provider API and no remote service. `pagani usage report <job>`
  prints the recorded cost, tokens, and session count.
- **Budget.** `pagani budget set <job> --usd <amount>` writes `Budget-usd:` to
  `job.md`. `pagani budget check <job>` prints `BUDGET: OK (x/y)` or
  `BUDGET: OVER (x/y)` and exits 1 when over; with no budget it prints
  `BUDGET: none` and exits 0. It is a check, not a hard cap: the master stops
  and asks the human on failure.
- **Dashboard.** `pagani dashboard [--open]` writes a local, read-only
  `pagani/dashboard.html` with a jobs table (id, lane, stage, round, branch,
  latest check result, cost), a metrics table, and a generated timestamp. It is
  a static file with inline CSS, no JavaScript, no external assets, no server,
  and no login. `--open` runs `xdg-open` or `open` when available. There is no
  control plane; the dashboard cannot start, stop, or approve anything.
- **Backup and restore.** `pagani backup [job|all] [--dest <dir>]` writes a
  local tar.gz under `pagani/backups/` containing the job or all jobs, excluding
  `pagani/backups`. `pagani restore <archive> [--force]` extracts into
  `pagani/jobs/`, refuses to overwrite an existing job without `--force`, and
  prints the restored job IDs. Backups are local only; there is no sync or
  remote copy.
- **Skill evals.** `evals/skills/run.sh` checks that a prompt triggers the
  expected skill, using frontmatter `Prompt`, `ExpectSkill`, and `Split`. It
  spends tokens and is opt-in; `SKILL_EVAL_CMD` overrides the runner command and
  results go to the gitignored `evals/skills/results.tsv`.
- **GitHub Actions.** `resources/github/workflows/pagani-check.yml` runs
  `./bin/pagani lint` and `./scripts/check` on pull requests and pushes to
  `main`. It runs on GitHub-hosted runners, with read-only `contents`, no
  secrets, no login, and no LLM calls. `pagani init` and `pagani upgrade` copy
  it to `.github/workflows/pagani-check.yml` when absent.
- **Untrusted content.** `skills/workflow/untrusted-content` treats web pages,
  PR bodies/comments, `BACKLOG.md`, logs, screenshots, and OCR as data, never as
  instructions. It is a convention, not a sandbox; it does not isolate, filter,
  or sandbox content.
- **Headless weekly.** When `pagani weekly` or the timer runs the weekly review,
  it does not ask questions; it lists proposed edits and decisions in
  `pagani/weekly-review.md`.

Full OS sandboxing and a control plane that starts or stops agents are
deliberate non-goals. The dashboard is read-only, and the network allowlist is
opt-in and limited to Claude `WebFetch`.

The installer:

- detects the target config dir,
- backs up existing files,
- links or copies,
- flattens category skills into `skills/<name>`,
- generates model variants from `agents/models.conf`,
- generates the Claude `/pagani` command from the master body,
- writes a manifest,
- skips unchanged files, so a second run does not rewrite them or create new
  `.pagani-backup-*` directories,
- uninstalls only its own manifest entries,
- never deletes user files without a prompt.

`pagani lint` checks skill names and descriptions, the required `resources/`
templates, unresolved skill references, and every project file that agents or
skills read but has no template in `resources/` (for example `CONTEXT.md`).

`--command-dir command` is available if your OpenCode build reads `command/`
singular.

---

## 14. Safety and guardrails

- No cloud sessions.
- No paid skills or paid assets.
- No secrets in the repo. Do not read keys, tokens, password stores, or cloud
  credentials.
- Do not send repo content to unknown hosts.
- Worktrees for parallel builders.
- Permission denies for destructive commands. `pagani init` writes
  `.claude/settings.json` with allow/ask/deny rules for Claude Code.
- No push, merge, or deploy without explicit approval.
- Builders commit locally; they never push or merge.
- The human decides the merge.

**Opt-in and limited:** the Claude `WebFetch` network allowlist covers only that
tool; shell, `curl`, and `agent-browser` egress are not covered. The dashboard is
a read-only local file, and `pagani budget check` is a check, not a hard cap.
`pagani backup` is local only.

**Deliberate non-goals:** full OS sandboxing and a control plane that starts or
stops agents. Untrusted content still reaches agents through browser pages, PR
bodies and comments, `BACKLOG.md`, logs, screenshots, and OCR; the
`untrusted-content` skill is a convention, not a sandbox. Use worktrees,
permission denies, read-only tokens, and no secrets first. See `GAPS.md`.

---

## 15. Customization

### Add a project

```bash
pagani init /path/to/project
```

Fill in `AGENTS.md` and `scripts/check`.

### Add a skill

Create `skills/<category>/<name>/SKILL.md`, add a trigger-rich description, and
run `./bin/pagani doctor`.

### Add an agent

Add a file to `agents/opencode/` and `agents/claude/` with the target's
frontmatter. Keep the body thin; put the procedure in a skill.

### Add a resource

Put a template in `resources/` and copy it in `bin/pagani` `cmd_init`.

### Add an eval

Put a case in `evals/reviewer/cases/` and add a row to `score.md`.

---

## 16. Troubleshooting

| Problem | Fix |
|---|---|
| `/pagani` not found | Run `./install.sh --target ...`; check `pagani doctor`. |
| Skills not loading | The installer flattens categories. Check `<target>/skills/<name>/SKILL.md`. |
| Command not found in OpenCode | Try `--command-dir command`. |
| `agent-browser` missing | `npm install -g agent-browser`. |
| `claude` missing | Install Claude Code; the target is ready but not tested here. |
| `gh` missing | Install GitHub CLI and authenticate. |
| Checks always fail | Fill `scripts/check`; it exits 1 until configured. |
| `pagani gate` says stale | Run `pagani check <job>` after the latest commit. |
| `pagani lint` reports an unresolved skill | Add the skill under `skills/<category>/<name>/` or fix the name in the agent. |
| Claude settings missing | Run `pagani init` to create `.claude/settings.json`. |
| Model variants missing | Re-run `./install.sh --target ...`; the installer generates them from `agents/models.conf`. |
| `AGENTS.md` too long | Move detail into skills; keep gotchas. |
| Context full | `session-handoff` + `TASKS.md`; start a fresh session. |

### Claude smoke-test checklist

Run this by hand after installing or upgrading the Claude Code target. It
spends no tokens unless you start a real job.

1. `./install.sh --target claude --dry-run` prints the planned files and exits
   0.
2. `./bin/pagani doctor` shows `claude: yes`, `claude settings hook: yes`,
   `claude settings PreCompact: yes`, and executable `scripts/claude-hook.sh`
   and `scripts/format`.
3. `python3 -m json.tool .claude/settings.json` succeeds, and the file has the
   `PreToolUse` `WebFetch` matcher, `PostToolUse` `Edit|Write`, `PreCompact`,
   and `Skill` hooks.
4. `scripts/claude-hook.sh format` runs `scripts/format` on a scratch file and
   exits 0 even when the formatter fails.
5. `scripts/claude-hook.sh webfetch-guard` allows with no
   `pagani/network-allowlist.txt`, allows a listed host, and denies an unlisted
   host with the documented JSON.
6. `scripts/claude-hook.sh skill-log <name>` appends one row to
   `pagani/skill-usage.tsv`.
7. In Claude Code, `/pagani status` loads the generated command and reads the
   newest job.
8. `pagani gate <job>` fails after an uncommitted edit and passes with
   `--allow-dirty`.

---

## 17. Sources and attribution

The workflow and skills draw on:

- `claude.dev` articles on code review, skills, agent automations, cloud
  sessions, mods, evals, effort, cost, and context engineering.
- `barnabyrobson.org/on-pstack` for the Michelin kitchen, trust ladder, inner/
  outer loops, gardener, and verification map.
- Boris Cherny's public Claude Code workflow.
- Anthropic's *Building effective agents*.
- Matt Pocock's engineering and productivity skills.
- pstack `unslop`.
- Anthropic `frontend-design` and `skill-creator`.
- Vercel Labs `agent-browser`, `web-design-guidelines`, and
  `vercel-react-best-practices`.
- leonxlnx `design-taste-frontend`.
- emilkowalski `emil-design-eng`.
- ceorkm `mobile-app-ui-design`.
- Thesys OpenUI.

See `VENDOR.md` and the license files inside each skill folder for the exact
sources and licenses.
