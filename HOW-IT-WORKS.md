# How PaganiStack Works

PaganiStack is a personal development workflow. It gives an agent a job folder,
a plan, a ticket graph, deterministic checks, focused reviewers, and a human
decision. The job folder is the state; there is no database or state machine.

## Quick start

```bash
git clone <this-repo> ~/Projects/PaganiStack
~/Projects/PaganiStack/install.sh --target both
~/Projects/PaganiStack/bin/pagani doctor
```

In a project:

```bash
cd ~/Projects/my-project
~/Projects/PaganiStack/bin/pagani init
```

For an existing project, run `pagani upgrade` to update the current hooks and
managed files without dropping your settings.

Then, in OpenCode or Claude Code:

```
/pagani Add an estimated reading time to blog posts
```

## The workflow

```
0. SETUP      lane, job folder, branch, usage start
1. PLAN       interview -> plan.md                  [approve]
2. SPEC       spec.md                               [approve]
3. TICKETS    tickets/                              [approve]
4. BUILD      one builder per ready ticket          [approve per wave]
5. CHECKS     pagani check -> checks.md             (fail -> builder)
6. REVIEW     only the needed lenses                [summary]
7. FIX        fix.md -> fresh builder -> checks -> affected reviews
8. APPROVE    approver -> decision.md + quiz
9. HUMAN      approve, rework, or reject
10. CLOSE     usage end, dashboard, retro, merge/commit/push/PR on request
```

### Step 0: Set up and classify

The master reads `AGENTS.md`, `GLOSSARY.md` if present, and the risk paths in
`REVIEW.md`. It loads `lanes`, proposes a lane, and asks you to confirm or
override. It creates the job folder and branch, writes `Lane` and `Lane-reason`
to `job.md`, and starts the cost snapshot.

If the project predates the current hooks, run `pagani upgrade` once. Run
`pagani network init` only if you want the opt-in Claude `WebFetch` allowlist.

### Step 1: Plan

The master loads `interview`, explores first, and asks a small batch of
questions. It writes `interview.md` and asks the planner for `plan.md`. If the
plan has open questions, it asks you and revises. You approve the plan.

### Step 2: Spec

The planner writes `spec.md`: the behavior, the data shape, the failure cases,
and the acceptance criteria. You approve it.

### Step 3: Tickets

The planner writes `tickets/index.md` and one file per ticket. Each ticket is a
vertical slice that fits one fresh context. You approve the graph.

### Step 4: Build

The master runs `pagani frontier <job>` and spawns one builder per ready ticket.
Parallel only when files are disjoint; one worktree per ticket when parallel.
Each builder writes `build/<ticket>.md`. The master merges ticket branches into
the job branch and posts a wave summary.

### Step 5: Checks

The master runs `pagani check <job>`, which runs `scripts/check`, writes
`checks.md` with `RESULT`, `HEAD`, duration, exit code, and the output tail, and
appends one line per run to `checks.log`. A failure goes back to a fresh builder;
no reviewer runs on a failing build.

### Step 6: Review

The master runs `pagani gate <job>` first. A failing, stale, or dirty gate stops
the review. It runs `pagani route <job>` for a suggested lens set, then uses only
the needed lenses:

- `review-code` — always.
- `review-ui` — components, styles, pages, templates, or UI criteria.
- `review-ux` — flows, states, copy, accessibility, mobile, or UX criteria.
- `review-security` — auth, permissions, payments, input, API, data, secrets,
  dependencies, or security criteria.

Reviewers run in parallel with fresh context. Each writes one file. The master
writes `round-N/summary.md` and posts the summary.

### Step 7: Fix

If a review returns `CHANGES`, the master writes `fix.md` with the finding, the
file and line, why it matters, how to fix it, and how to verify it. It spawns a
fresh builder, re-runs checks, and re-runs only the affected reviewers. Max two
fix rounds.

### Step 8: Approve

The approver reads the spec, build, checks, and reviews. It writes `decision.md`
with `APPROVE` or `ESCALATE`, an explainer, and a short quiz. The quiz uses
retrieval practice: no formatting hints, answers answerable from the artifacts.

### Step 9: Human decision

You read the explainer, answer the quiz, and choose merge, commit, push, PR,
rework, or reject. The master shows the exact git command before running it.

### Step 10: Close

The master updates `job.md`, records the decision in `human.md`, runs
`pagani usage end <job>` and `pagani dashboard`, runs
`pagani retro-scan --exit-code`, and loads `session-retro` to propose one
environment change. On repeated findings it proposes Gotchas patches. It loads
`session-handoff` if the job continues elsewhere.

### Split runner

Job state is files in `pagani/jobs/<id>/`, so the runtimes can share a job:

1. Run Steps 0–3 in Claude Code.
2. In the same project, run `/pagani resume` in OpenCode for build, checks,
   review, and fix.
3. Optionally return to Claude Code at `approve` for the strong approver.

Both masters read `Stage:` from `job.md` and never re-plan completed steps.

## Lanes

| Lane | Use when | Pipeline |
|---|---|---|
| `trivial` | docs, copy, config only; ≤3 files; no risk path | builder-lite → check → review-code-lite → human |
| `bugfix` | a reproducible symptom | diagnosis → failing test → builder → check → review-code-lite → human |
| `small` | one feature, one area, ≲10 files | short interview → plan → one ticket → builder → check → review-code-lite → human |
| `standard` | normal product change | full flow |
| `high-risk` | auth, payments, data/schema, deploy/CI, dependencies, secrets | full flow + adversarial review + simplify + strong security + strong approver |

The master picks the lane at Step 0. `pagani classify` prints `unknown` when
there is no changed file; run it again after the first change. After the first
builder commit, `pagani classify --diff` escalates if the diff grows or touches
a risk path. Lanes never downgrade.

## Agents and models

| Agent | Role |
|---|---|
| `master` | Talks to you, asks questions, runs checks, posts summaries, executes git only on request. |
| `explorer` | Cheap read-only search and log reading. |
| `planner` | Writes `plan.md`, `spec.md`, and `tickets/`. |
| `builder` | Implements exactly one ticket and writes `build/<ticket>.md`. |
| `review-code` | Correctness, simplicity, conventions, tests, spec fidelity. |
| `review-ui` | Visual consistency, responsive layout, contrast, design-system fit. |
| `review-ux` | Flows, states, copy, accessibility, mobile. |
| `review-security` | Access control, input, data exposure, secrets, dependencies. |
| `approver` | Final gate, explainer, and quiz. |

The installer generates `lite`, `std`, and `strong` variants from
`agents/models.conf`. The master picks the variant by role and lane. Planning,
security, and approval use the strong tier; search uses the cheap tier.

## Skills

Skills use the nine Claude Code categories plus two extensions:

| Category | What belongs there |
|---|---|
| `library-api-reference` | How to use a library, CLI, SDK, or internal API correctly. |
| `product-verification` | How to test or verify the product: builds, browsers, screenshots, flows. |
| `data-analysis` | How to answer a question from real data: SQL, logs, metrics, cohorts. |
| `business-automation` | Recurring workflow: backlog triage, weekly review, release notes. |
| `scaffolding` | Create a new component, service, route, migration, or fixture. |
| `code-quality` | Review lenses, implementation, design, simplification, tests. |
| `ci-cd` | Checks, PR automation, merge queues, deploy, flags, rollback. |
| `runbooks` | Investigate a symptom: incident, alert, “why is this broken”. |
| `infrastructure-ops` | Dependencies, cost, access, orphaned resources, least privilege. |
| `workflow` | Lanes, interview, planning, summary, closeout, handoff, retro, untrusted content. |
| `design` | UI/UX production: art direction, layout, mobile, motion, polish. |

The core workflow skills are `lanes`, `interview`, `planning`, `implementation`,
`verification`, `review-code`, `review-security`, `approval`, `summary`,
`closeout`, `session-handoff`, `session-retro`, `diagnosis`, and
`untrusted-content`. The rest are situational.

The full skill list is the `skills/<category>/<skill>/SKILL.md` tree. The
installer flattens it to `<target>/skills/<skill>/SKILL.md` because both
runtimes discover skills at that depth.

### Vendored skills

These are copied from upstream and keep their own licenses. If a skill is
adapted, it is renamed and the change is noted in its `SKILL.md`.

| Skill | Source | License |
|---|---|---|
| `wizard` | mattpocock/skills | see upstream |
| `writing-for-agents` | mattpocock/skills | see upstream |
| `codebase-design` | mattpocock/skills | see upstream |
| `domain-modeling` | mattpocock/skills | see upstream |
| `skill-creator` | anthropics/skills | see `LICENSE.txt` in the skill |
| `agent-browser` | vercel-labs/agent-browser | see upstream |
| `vercel-react-best-practices` | vercel-labs/agent-skills | see upstream |
| `design-taste-frontend` | leonxlnx/taste-skill | see README/LICENSE in the skill |
| `frontend-design` | anthropics/skills | see `LICENSE.txt` in the skill |
| `web-design-guidelines` | vercel-labs/agent-skills | see upstream |
| `mobile-app-ui-design` | ceorkm/mobile-app-ui-design | MIT |
| `openui` | thesysdev/openui | see upstream |
| `emil-design-eng` | emilkowalski/skills | see LICENSE in the skill |

`handoff` and `retro` are adapted as `session-handoff` and `session-retro`.
Some PaganiStack skills absorb upstream content: `interview` (from `grilling`),
`review-code` (from `code-review`), `diagnosis` (from `diagnosing-bugs`),
`implementation` (from `tdd`), and `closeout` (from `pr`). PaganiStack-authored
skills are original or adapted and are not vendored under an upstream name.

### Add a skill

Create `skills/<category>/<name>/SKILL.md`, add a trigger-rich description, and
run `./bin/pagani doctor`. Keep the body focused on when to use the skill, the
procedure, and real gotchas.

## Commands

Setup and install:

```bash
./install.sh --target both
./bin/pagani doctor
./bin/pagani lint
./bin/pagani init [path]
./bin/pagani upgrade [path]
```

Jobs and review:

```bash
pagani job new "<title>"
pagani frontier <job>
pagani classify [--diff] [request text]
pagani route <job>
pagani status
pagani check <job>
pagani gate <job> [--allow-dirty]
pagani worktree create <job> <ticket>
pagani worktree prune <job> [--force]
pagani pr <number>
```

Automation:

```bash
pagani usage start|end <job>
pagani dashboard [--open]
pagani hooks install|uninstall|status [path]
pagani network init|check <url>
pagani retro-scan [--write] [--exit-code]
```

## Checks, review, and verification

`scripts/check` is the project check script. `pagani check <job>` runs it and
writes `checks.md` plus `checks.log`. `pagani gate <job>` fails when the latest
check failed, is stale, or the working tree is dirty.

`scripts/verify` is the app/browser driver. It reads `scripts/verify.conf`
(`START_CMD`, `READY_URL`, `PORT`) and derives a port from the worktree path
when `PORT` is not set. Use `doctor`, `start`, `snapshot`, `screenshot`, `flow
<name>`, and `stop`. On a start timeout it kills the process group it started,
removes the pid file, and prints the log tail.

`docs/FEATURE-MAP.md` tells the agent how to reach each feature, what seed data
or login it needs, and which flow proves it. If no flow covers an acceptance
criterion, the agent writes one and adds it to the map.

Review is capped at three rounds. After round 1, reviewers read only the new
diff. Findings are not repeated. A finding needs a file, line, and evidence.
Risk tiers decide how many humans approve: low is automated checks plus AI
review; medium is one person; high is two people, or the human reading the diff
when working solo.

## Job folder and state

```
pagani/jobs/<id>/
  job.md              stage, round, lane, branch, base
  interview.md
  plan.md
  spec.md
  tickets/
  build/
  checks.md
  checks.log
  round-N/
  fix-*.md
  decision.md
  human.md
  usage.md
  TASKS.md
  handoff.md
```

The job folder is the source of truth. No JSON state machine.

## Automation

Everything here is optional and local. Nothing starts an agent or a server.

- **Format hook.** A Claude Code `PostToolUse` hook runs `scripts/format` after
  an edit when the project provides it. `pagani init` copies a stub.
- **Git hooks.** `pagani hooks install [path]` installs a gitleaks pre-commit
  hook and a pre-push hook that runs `scripts/check`. `pagani init` installs
  them when `.git` exists. A missing gitleaks is a clean skip.
- **PreCompact handoff.** A Claude Code `PreCompact` hook writes a snapshot to
  the newest job's `handoff.md`, or `pagani/handoff.md`.
- **Network allowlist.** `pagani network init` enables an opt-in Claude
  `WebFetch` allowlist. Shell and `agent-browser` egress are not covered.
- **Dashboard.** `pagani dashboard` writes a local, read-only
  `pagani/dashboard.html` with jobs, checks, and metrics.
- **Usage snapshots.** `pagani usage start|end <job>` appends raw
  `opencode`/`ccusage` snapshots to `usage.md` and records lane, rounds, fixes,
  reworks, and first-pass checks in `metrics.tsv`. It does not calculate exact
  per-job cost.
- **Skill evals.** `evals/skills/run.sh` checks skill triggers. It spends tokens
  and is opt-in.

## Safety and limits

- No cloud sessions.
- No paid skills or paid assets.
- No secrets in the repo. Do not read keys, tokens, password stores, or cloud
  credentials.
- Do not send repo content to unknown hosts.
- Worktrees for parallel builders; one port per worker.
- Permission denies for destructive commands. `pagani init` writes
  `.claude/settings.json` with allow/ask/deny rules for Claude Code.
- No push, merge, or deploy without explicit approval.
- Builders commit locally; they never push or merge.
- The human decides the merge.

**Opt-in and limited:** the Claude `WebFetch` allowlist covers only that tool.
Shell, `curl`, and `agent-browser` egress are not covered. The dashboard is a
read-only local file. There is no exact cost tracking, budget enforcement, or
backup command.

**Deliberate non-goals:** full OS sandboxing and a control plane that starts or
stops agents. Untrusted content still reaches agents through browser pages, PR
bodies and comments, `BACKLOG.md`, logs, screenshots, and OCR; the
`untrusted-content` skill is a convention, not a sandbox.

## Troubleshooting

| Problem | Fix |
|---|---|
| `/pagani` not found | Run `./install.sh --target ...`; check `pagani doctor`. |
| Skills not loading | The installer flattens categories. Check `<target>/skills/<name>/SKILL.md`. |
| Checks always fail | Fill `scripts/check`; it exits 1 until configured. |
| `pagani gate` says stale | Run `pagani check <job>` after the latest commit. |
| `pagani gate` says dirty | Commit or stash changes, or use `--allow-dirty`. |
| `pagani lint` reports an unresolved skill | Add the skill under `skills/<category>/<name>/` or fix the name in the agent. |
| Claude settings missing | Run `pagani init`. |
| Claude settings has no hooks | Run `pagani upgrade`. |
| Model variants missing | Re-run `./install.sh --target ...`. |
| `gitleaks` missing | Install it, or leave the hook to skip cleanly. |
| Git hooks missing | Run `pagani hooks install [path]`. |
| `pagani upgrade` fails | Install `python3`. |
| Network check denies a host | Add it to `pagani/network-allowlist.txt`, or remove the file. |
| Dashboard is stale | Re-run `pagani dashboard`; it is a static file. |
| Context full | `session-handoff` + `TASKS.md`; start a fresh session. |

## Claude smoke test

Run this by hand after installing or upgrading the Claude Code target.

1. `./install.sh --target claude --dry-run` exits 0.
2. `./bin/pagani doctor` shows `claude: yes`, the settings hooks, and executable
   `scripts/claude-hook.sh`.
3. `python3 -m json.tool .claude/settings.json` succeeds and the file has the
   `PreToolUse` `WebFetch`, `PostToolUse` `Edit|Write`, and `PreCompact` hooks.
4. `scripts/claude-hook.sh format` runs `scripts/format` on a scratch file and
   exits 0 even when the formatter fails.
5. `scripts/claude-hook.sh webfetch-guard` allows with no allowlist, allows a
   listed host, and denies an unlisted host.
6. `/pagani status` loads the generated command and reads the newest job.
7. `pagani gate <job>` fails after an uncommitted edit and passes with
   `--allow-dirty`.

## Sources

The workflow and skills draw on `claude.dev`, Boris Cherny's public Claude Code
workflow, Anthropic's *Building effective agents*, Matt Pocock's skills, and the
vendored skills listed above. See the license files inside each skill folder.
