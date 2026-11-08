# How PaganiStack Works

PaganiStack gives an agent a job folder, a `SPEC.md` with a task graph,
deterministic checks, one reviewer, and a human decision. The job folder is the
state; there is no database or state machine.

## The workflow

```
0. SETUP     lane, job folder, branch
1. SPEC      interview -> SPEC.md                    [approve]
2. BUILD     one builder per ready task              [approve per wave]
3. CHECKS    pagani job check -> checks.md           (fail -> builder)
4. REVIEW    one review-code review (code, UI, UX, security) [summary]
5. FIX       review-code.md -> fresh builder -> checks -> re-review
6. APPROVAL  master -> decision.md + quiz (standard/high-risk)
7. HUMAN     approve, rework, or reject
8. CLOSE     retro, merge/commit/push/PR on request
```

### Step 0: Set up and choose a lane

The master reads `AGENTS.md`, `GLOSSARY.md` if present, and the risk paths in
`REVIEW.md`. It loads `lanes`, proposes a lane, and asks you to confirm or
override. It creates the job folder and branch and writes `Lane` and
`Lane-reason` to `job.md`.

If the project predates the current hooks, run `pagani upgrade` once. Run
`pagani network init` only if you want the opt-in Claude `WebFetch` allowlist.

### Step 1: SPEC

The master loads `interview`, explores first, and asks a small batch of
questions. It writes `interview.md` and asks the planner for one `SPEC.md`: the
behavior, the data shape, the failure cases, the acceptance criteria, and the
tracer-bullet task graph. Each task is a vertical slice that fits one fresh
context. Every task carries `Allowed files`, `Test first`, and `Done when`, and
`SPEC.md` carries `## Sensors`: what `scripts/check` covers, what `scripts/verify`
or `agent-browser` covers, and what neither covers. If a contract field is empty
or `## Sensors` is missing, the master asks the planner to revise before
approval. If the spec has open questions, the master asks you and revises. You
approve the spec and the first wave.

`trivial` and `bugfix` jobs skip the full spec, but a `bugfix` still writes a
failing test first. `small` jobs get a short interview and a short spec.
`standard` and `high-risk` jobs get the full pass.

### Step 2: Build

**Headless builder (Claude drives, a third-party model implements).** When
`pagani build --check` passes, the master creates the task worktree and runs
`pagani build <job> <task>`. It runs the Claude Code `builder` agent headless
(`claude -p`) on the model configured in `~/.config/pagani/builder.env`, then
prints the session id, report path, `STATUS`, and changed files. `review-code`
reviews the diff; on `CHANGES` the master writes the findings to a file and runs
`--revise <file>`, which resumes the same session. It allows two revisions (exit
4 after that) and the master escalates to the human. The builder never plans,
decides, troubleshoots, or orchestrates. While `/pagani` runs, a frontmatter
hook denies the Claude-model `builder` subagent whenever the headless builder is
configured; if it is not, the Claude `builder` is the fallback.

The master reads the task graph from `SPEC.md` and inspects the ready set before
building. It defaults to sequential. If two or more ready tasks touch disjoint
files and have no dependency between them, it runs that wave in parallel with
one worktree per task; parallel is preferred whenever it is safe. Sequential is
used when tasks share a file, a migration, or one needs another's output. Each
builder writes `build/<task>.md`. The master merges task branches into the job
branch and posts a wave summary.

A parallel wave joins with `ALL` by default: every task in the wave must pass
before the wave is merged. Do not merge partial results.

A builder is bounded by the task's `Allowed files`. If it needs another file, it
reports `BLOCKED`; the master does not widen the task itself. Existing tests are
evaluator inputs: the builder does not edit, delete, skip, or weaken one to make
the task pass. A genuine test change needs approval and is recorded under
`## Test changes` in the build report.

### Step 3: Checks

The master runs `pagani job check <job>`, which runs `scripts/check`, writes
`checks.md` with `RESULT`, `HEAD`, duration, exit code, and the output tail, and
appends one line per run to `checks.log`. A failure goes back to a fresh builder;
no reviewer runs on a failing build.

### Step 4: Review

The master runs `pagani job gate <job>` first. A failing, stale, or dirty gate
stops the review. It then spawns one `review-code` reviewer, which covers code,
UI, UX, and security in one pass and returns one verdict:

- **Code** — correctness, simplicity, conventions, tests, and spec fidelity.
- **UI** — visual consistency, design-system fit, spacing, responsive layout,
  contrast, and hover/focus/disabled/loading states.
- **UX** — flows, empty/loading/error states, copy, accessibility, keyboard and
  focus order, mobile, and edge cases.
- **Security** — access control, input handling, XSS, data exposure,
  payments/identity, abuse, secrets, dependencies, and sessions/auth.

The reviewer loads `verification` and uses `agent-browser` when the change has
UI, and loads `unslop` for copy. It writes `round-N/review-code.md` with one
`VERDICT` for the whole change. It checks the diff against each task's
`Allowed files`, the test-first evidence, the changed test files, and the blind
spots listed under `## Sensors`. An out-of-bounds edit, a task with no
red-before-green evidence (unless docs/config-only), or an unjustified test edit,
skip, or weakened assertion is `CHANGES`; an acceptance criterion that depends on
an uncovered area goes under Risks. The master posts the summary in chat; for
`standard` and `high-risk` it writes `summary.md` at this checkpoint.

### Step 5: Fix

If a review returns `CHANGES`, the master passes `round-N/review-code.md` and the
findings — the file and line, why it matters, how to fix it, and how to verify
it — to a fresh builder. It re-runs checks and re-runs the reviewer on the
affected area. Max two fix rounds. The master tracks the number of failing checks
and blocking findings each round; if neither decreased in two consecutive rounds,
it stops and escalates instead of running a third identical round.

### Step 6: Approval

The master loads `approval` and reads `SPEC.md`, the build reports, checks, and
reviews. It writes `decision.md` itself with `APPROVE` or `ESCALATE`, the
acceptance-criteria mapping, risks, and an explainer. For `standard` and
`high-risk` it adds a short quiz; `trivial`, `bugfix`, and `small` get the
explainer only. It then presents the decision and asks for the decision. The
quiz uses retrieval practice: no formatting hints, answers answerable from the
artifacts.

### Step 7: Human decision

You read the explainer, answer the quiz on `standard` and `high-risk` jobs, and
choose merge, commit, push, PR, rework, or reject. The master shows the exact
git command before running it and appends the decision to `## Human decision` in
`decision.md`.

Before it creates a branch, worktree, or PR, the master checks whether it already
exists (`git branch --list`, `git worktree list`, `gh pr view`) so a resume does
not duplicate a side effect.

### Step 8: Close

The master updates `job.md`, writes the final `summary.md` if it does not exist
yet, records the decision in `decision.md`, runs
`pagani job report --retro --exit-code`, and loads `session-retro` to propose one
environment change. On repeated findings it proposes Gotchas patches. It loads
`session-handoff` if the job continues elsewhere.

### Split runner

Job state is files in `pagani/jobs/<id>/`, so the runtimes can share a job:

1. Run Steps 0–1 in Claude Code.
2. In the same project, run `/pagani resume` in OpenCode for build, checks,
   review, and fix. `resume` continues from `Stage:` in `job.md`.
3. Optionally return to Claude Code at approval.

Both masters share the same entry rule: a feature request starts at Step 0,
`status` reads the newest `job.md`, and `resume` continues from `Stage:` without
redoing completed steps. Both default to sequential builds and prefer a parallel
wave when the ready tasks touch disjoint files.

## Lanes

| Lane | Use when | Pipeline |
|---|---|---|
| `trivial` | docs, copy, config only; ≤3 files; no risk path | builder-lite → check → review-code-lite → human |
| `bugfix` | a reproducible symptom | diagnosis → failing test → builder → check → review-code-lite → human |
| `small` | one feature, one area, ≲10 files | short interview → SPEC → one task → builder → check → review-code-lite → human |
| `standard` | normal product change | full flow |
| `high-risk` | auth, payments, data/schema, deploy/CI, dependencies, secrets | full flow + adversarial review + simplify + review-code-strong |

The master picks the lane at Step 0. After the first builder commit, compare
`git diff --stat <base>...HEAD` and `git diff --name-only <base>...HEAD` against
the risk paths in `REVIEW.md` and the lane's file limit. Escalate if the diff
grows or touches a risk path. Lanes never downgrade.

## Agents and models

| Agent | Role |
|---|---|
| `master` | Talks to you, asks questions, runs checks, posts summaries, writes `decision.md`, executes git only on request. |
| `explorer` | Cheap read-only search and log reading. |
| `planner` | Writes `SPEC.md` with the requirements, decisions, and tracer-bullet task graph. |
| `builder` | Implements exactly one task and writes `build/<task>.md`. |
| `review-code` | One reviewer for code, UI, UX, and security; one file, one verdict. |

The installer generates the `builder-lite`, `review-code-lite`, and
`review-code-strong` variants from `agents/models.conf`. The master picks the
variant by role and lane. Planning uses the strong model; the builder and
reviewer scale with risk and lane. The master uses the `deepseek-v4.1-flash`
`high` variant in OpenCode and Opus 5.5 at medium effort in Claude Code. There
is no separate security or approval variant.

## Skills

PaganiStack ships 34 skills in the Claude Code categories plus `workflow/`.
The core workflow skills are `lanes`, `interview`, `planning`, `implementation`,
`verification`, `review-code`, `approval`, `summary`, `closeout`,
`session-handoff`, `session-retro`, `diagnosis`, and `untrusted-content`. The
rest are situational.

The full inventory, the vendored-skills table, and the rules for adding a skill
are in [SKILLS.md](SKILLS.md). The installer flattens
`skills/<category>/<skill>` to `<target>/skills/<skill>` because both runtimes
discover skills at that depth.

Other skills are invoked directly by name, not through `/pagani`:

```
/wizard
/backlog-triage
/wayfinding
/improve-architecture
/review-pr
```

## Commands

PaganiStack has nine top-level commands: `install` (with `--uninstall`),
`doctor`, `init`, `upgrade`, `build`, `job`, `worktree`, `hooks`, and `network`.

```bash
./install.sh --target both
./bin/pagani install --uninstall
./bin/pagani doctor
./bin/pagani init [path]
./bin/pagani upgrade [path]

pagani job new "<title>"
pagani job check <job>
pagani job gate <job> [--allow-dirty]
pagani job report [--retro] [--write] [--exit-code]

pagani worktree create <job> <task>
pagani worktree prune <job> [--force]
pagani hooks install|uninstall [path]
pagani network init|check <url>
```

Setup, uninstall, and troubleshooting are in [SETUP.md](SETUP.md).

## Checks, review, and verification

`scripts/check` is the project check script. `pagani job check <job>` runs it and
writes `checks.md` plus `checks.log`. `pagani job gate <job>` fails when the latest
check failed, is stale, or the working tree is dirty.

`scripts/verify` is the app/browser driver. It reads `scripts/verify.conf`
(`START_CMD`, `READY_URL`, `PORT`) and derives a port from the worktree path
when `PORT` is not set. Use `doctor`, `start`, `snapshot`, `screenshot`, `flow
<name>`, and `stop`. On a start timeout it kills the process group it started,
removes the pid file, and prints the log tail.

`docs/FEATURE-MAP.md` tells the agent how to reach each feature, what seed data
or login it needs, and which flow proves it. If no flow covers an acceptance
criterion, the agent writes one and adds it to the map.

Review is capped at three rounds. After round 1, the reviewer reads only the new
diff. Findings are not repeated. A finding needs a file, line, and evidence.
Risk tiers decide how many humans approve: low is automated checks plus AI
review; medium is one person; high is two people, or the human reading the diff
when working solo.

## Job folder and state

```
pagani/jobs/<id>/
  job.md              stage, round, lane, branch, base (state only)
  interview.md
  SPEC.md
  build/<task>.md
  checks.md
  checks.log
  round-N/review-code.md
  summary.md
  decision.md         verdict, explainer, and ## Human decision
  handoff.md
```

The job folder is the source of truth. No JSON state machine, no `plan.md`, no
`tickets/`. `job.md` is state, not a checklist; the task list lives in `SPEC.md`.
`TASKS.md` is project-level only; there is no job-level copy. The final
`summary.md` is written once at close, or at review for `standard` and
`high-risk`. Every step still posts a short summary in chat.

## Context policy

```
ALWAYS     SPEC.md, AGENTS.md, GLOSSARY.md, current task
ON DEMAND  files, docs, skills, search results
COMPACTED  old turns, summarized at a natural break
ISOLATED   subagent work, returned as a short report
NEVER      secrets, raw logs, whole directories, unrelated files
```

## Project docs

`pagani init` creates three project-level docs:

- `SPEC.md` — product and technical requirements, and acceptance criteria.
- `ROADMAP.md` — ordered outcomes, dependencies, risks, and exit criteria.
- `TASKS.md` — current actionable work and validated status.

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
Shell, `curl`, and `agent-browser` egress are not covered. There is no exact cost
tracking, budget enforcement, or backup command.

**Deliberate non-goals:** full OS sandboxing and a control plane that starts or
stops agents. Untrusted content still reaches agents through browser pages, PR
bodies and comments, `BACKLOG.md`, logs, screenshots, and OCR; the
`untrusted-content` skill is a convention, not a sandbox. See
[RATIONALE.md](RATIONALE.md) for the trade-offs.

## Sources

The workflow and skills draw on `claude.dev`, Boris Cherny's public Claude Code
workflow, Anthropic's *Building effective agents*, Matt Pocock's skills, and the
vendored skills listed in [SKILLS.md](SKILLS.md). See the license files inside
each skill folder.
