# How PaganiStack Works

PaganiStack gives an agent a job folder, a `SPEC.md` with a task graph,
deterministic checks, one reviewer, and a human decision. The job folder is the
state; there is no database or state machine.

## The workflow

```
0. SETUP     playbook, risk, job folder, branch (or the light path)
1. SPEC      interview -> SPEC.md                    [approve]
2. BUILD     one builder per ready task              [approve per wave]
3. CHECKS    pagani job check -> checks.md           (fail -> builder)
4. REVIEW    one review-code review (code, UI, UX, security) [summary]
5. FIX       review-code.md -> fresh builder -> checks -> re-review
6. APPROVAL  master -> decision.md + quiz (feature/refactor/high)
7. HUMAN     approve, rework, or reject
8. CLOSE     retro, merge/commit/push/PR on request
```

### Step 0: Set up and choose a playbook

The master reads `AGENTS.md`, `GLOSSARY.md` if present, and the risk paths in
`REVIEW.md` (a missing file means no risk paths). It loads `playbooks`, proposes
a playbook (`trivial`, `bugfix`, `feature`, `refactor`, `pr-babysit`) and a risk
(`low`, `standard`, `high`), and asks you to confirm or override. It creates the
job folder and branch and writes `Playbook` and `Risk` to `job.md`.

For `trivial` and small `bugfix` work it takes the light path instead: branch
`.agents/quick-<slug>`, then `pagani build --here <slug> --task "<text>" --block`.
That creates no job folder, SPEC, or worktree; state lives in
`.agents/quick/<slug>/`.

If the project predates the current hooks, run `pagani upgrade` once.

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

`trivial` jobs skip this step. A `bugfix` still writes a failing test first.
`feature` and `refactor` jobs get the full pass; `refactor` also runs as
expand-contract and keeps behaviour unchanged.

### Step 2: Build

**Autonomy.** The master runs on its own between human checkpoints (SPEC
approval and the final decision). A `Stop` hook enforces it: mid-pipeline, with
no builder running, the master cannot end its turn. It never waits for "proceed"
between steps.

**Light path.** `trivial` and small `bugfix` jobs run the headless builder in the
current checkout through `pagani build --here <slug> --task "<text>"`, with state
in `.agents/quick/<slug>/`. They still get the Step 6/7 decision prompt.

**Headless builder (Claude drives, a third-party model implements).** When
`pagani build --check` passes, the master creates the task worktree and runs
`pagani build <job> <task>`. It runs the Claude Code `builder` agent headless
(`claude -p`) on the model configured in `~/.config/pagani/builder.env`, then
prints the session id, report path, `STATUS`, and changed files. `review-code`
reviews the diff; on `CHANGES` the master writes the findings to a file and runs
`--revise <file>`, which resumes the same session. It allows two revisions (exit
4 after that) and the master escalates to the human. The builder never plans,
decides, troubleshoots, or orchestrates. The `/pagani` `PreToolUse` hook denies
the Claude-model `builder` subagent whenever the headless builder is configured;
if it is not, the Claude `builder` is the fallback.

The master runs each build itself as a background Bash task
(`pagani build <job> <task> --block`), so no relay model is involved. It keeps a
`TodoWrite` item per task and, once per wave, runs
`pagani build --status <job> --every 180` through `Monitor`, posting each line
(`Builders 2/5 done · 2 running · 1 queued`) unchanged; without `Monitor` it runs
`--status` once per finished build. It moves to checks as soon as the wave has
joined. A build is capped at 30 minutes (`PAGANI_BUILD_TIMEOUT`).

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
`feature`, `refactor`, and `high` risk it writes `summary.md` at this checkpoint.

For `high` risk the master also runs the second-opinion reviewer:
`pagani build --review <job> <task> --block` runs `review-code` headless on the
third-party model, read-only, and writes findings to
`.agents/plans/<job>/build/<task>.review2.md`.

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
acceptance-criteria mapping, risks, and an explainer. For `feature`, `refactor`,
and `high` risk it adds a quiz; `trivial`, `bugfix`, and `low` risk get the
explainer only. In every playbook it then presents the decision and asks for it
through the native question UI; a chat summary alone never closes a job. The
quiz uses retrieval practice: no formatting hints, answers answerable from the
artifacts.

### Step 7: Human decision

You read the explainer, answer the quiz where one applies, and choose merge,
commit, push, PR, rework, or reject. The master shows the exact git command
before running it and appends the decision to `## Human decision` in
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

### Resume

Job state is files in `.agents/plans/<id>/`, so any new session can continue a job.
The entry rule: a feature request starts at Step 0, `status` reads the newest
`job.md`, and `resume` continues from `Stage:` without redoing completed steps.
The master defaults to sequential builds and prefers a parallel wave when the
ready tasks touch disjoint files.

## Playbooks and risk

A playbook chooses the pipeline; risk is a modifier on top of it. The master
picks both at Step 0, writes them to `job.md`, and never downgrades either. It
copies the matched playbook's steps verbatim into `TodoWrite`; a skipped step
stays in the list with a one-line skip reason. Work that fits no playbook loads
`figure-it-out`, which proposes a one-off playbook and confirms it with
`AskUserQuestion` before running it.

| Playbook | Use when | Pipeline |
|---|---|---|
| `trivial` | docs, copy, comments, config-only; a few files; no risk path; no behaviour change | light path: headless builder → check → `review-code` → human |
| `bugfix` | a reproducible symptom | failing test first; the light path when small; otherwise builder → check → `review-code` → human |
| `feature` | normal product work | interview → SPEC → task graph → worktrees → full build/check/review |
| `refactor` | behaviour must not change | expand-contract; tests before and after; full build/check/review |
| `pr-babysit` | an open PR needs CI or review follow-up | watch checks and comments read-only, fix through the light path, push only with approval — see [skills/workflow/playbooks/pr-babysit.md](../skills/workflow/playbooks/pr-babysit.md) |

| Risk | Use when |
|---|---|
| `low` | internal, reversible, no risk path |
| `standard` | normal product change; the default |
| `high` | auth, payments, data/schema/migrations, deploy/CI config, installers, dependency changes, secrets handling, or any path under `## Risk paths` in `REVIEW.md` |

After the first builder commit, compare `git diff --stat <base>...HEAD` and
`git diff --name-only <base>...HEAD` against the risk paths and the playbook's
scope. Escalate the risk if the diff grows (roughly 300 changed lines) or touches
a risk path. Risk only escalates.

When the master waits on something outside the session (CI, a long build), it
loads the `loop` skill with a stated interval and a maximum number of checks
instead of idling, and stops as soon as the condition is met or the cap is
reached.

Every job, including the light path, ends with a reply that pastes the verbatim
before/after evidence and labels each claim measured, inferred, or guessed
(principle `prove-it-works`).

## Agents and models

| Agent | Role |
|---|---|
| `master` | Talks to you, asks questions, runs checks, posts summaries, writes `decision.md`, executes git only on request. |
| `explorer` | Cheap read-only search and log reading. |
| `planner` | Writes `SPEC.md` with the requirements, decisions, and tracer-bullet task graph. |
| `builder` | Implements exactly one task and writes `build/<task>.md`. |
| `review-code` | One reviewer for code, UI, UX, and security; one file, one verdict. |

There are no tier variants of an agent. The master picks the model per call with
the Agent tool's `model` parameter; each agent's frontmatter `model:` is the
default. The routing comes from `~/.claude/rules/pagani-models.md` when present,
written by `/pagani-models`. Otherwise the defaults are explorer `haiku`, trivial
`haiku`, reviewer `sonnet`, high-risk reviewer `opus`, and builder `headless`.
`planner` and `master` keep their own models.

## Skills

PaganiStack ships 58 skills in the Claude Code categories plus `workflow/`. The
core workflow skills are `playbooks`, `principles`, `interview`, `planning`,
`implementation`, `verification`, `review-code`, `approval`, `summary`,
`closeout`, `session-handoff`, `session-retro`, `diagnosis`, and
`untrusted-content`. The rest are situational: `how` and `why` explain code and
decisions read-only, `figure-it-out` builds a one-off playbook,
`create-verification-skill` writes a project `verify-*` skill, and `automate-me`
drafts a personal mode skill from the user's transcripts after approval.

Each of the 21 principles is its own `principle-<slug>` skill; `principles` is
the index that keeps the citations stable. Agents and skills cite a principle
instead of restating a rule, which keeps `agents/master.md` at about 130 lines.

The inventory and the rules for adding a skill are in [SKILLS.md](SKILLS.md). The
plugin manifest lists each category directory; Claude Code discovers the skills
inside `skills/<category>/<name>/`, so they stay grouped by category.

Other skills are invoked directly by name, not through `/pagani`:

```
/wizard
/backlog-triage
/wayfinding
/improve-architecture
/review-pr
```

## Commands

PaganiStack has eight top-level commands: `doctor`, `init`, `seed`, `upgrade`,
`build`, `job`, `worktree`, and `hooks`. (`guard` and `keyget` are internal hook
entry points, not user commands.)

```bash
pagani doctor
pagani init [path]
pagani seed <Name>
pagani upgrade [path]
pagani build <job> <task> [--revise <findings-file>] [--block]
pagani build --here <slug> --task "<text>" [--block]
pagani build --review <job> <task> [--block]
pagani build --status <job> [--every <seconds>]
pagani build --init | --check

pagani job new "<title>"
pagani job check <job>
pagani job gate <job> [--allow-dirty]
pagani job report [--retro] [--write] [--exit-code]

pagani worktree create <job> <task>
pagani worktree prune <job> [--force]
pagani hooks install|uninstall [path]
```

Use `./bin/pagani` instead of `pagani` when running from a clone outside a
session. Setup and troubleshooting are in [SETUP.md](SETUP.md).

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
Risk decides how much review runs: `low` is automated checks plus AI review,
`standard` is the default, and `high` adds adversarial review, `simplify`, the
high-risk reviewer model, the second-opinion reviewer, and a mandatory quiz. The
human still makes the final decision.

## Job folder and state

```
.agents/plans/<id>/
  job.md              stage, round, playbook, risk, branch, base (state only)
  interview.md
  SPEC.md
  build/<task>.md
  build/<task>.review2.md
  checks.md
  checks.log
  round-N/review-code.md
  summary.md
  decision.md         verdict, explainer, and ## Human decision
  handoff.md

.agents/quick/<slug>/
  run, rc, progress, prompt, report.md, builder.log
```

The job folder is the source of truth. No JSON state machine, no `plan.md`, no
`tickets/`. `job.md` is state, not a checklist; the task list lives in `SPEC.md`.
`PLAN.md` is project-level only; there is no job-level copy. The final
`summary.md` is written once at close, or at review for `feature`, `refactor`,
and `high` risk. Every step still posts a short summary in chat.

## Context policy

```
ALWAYS     SPEC.md, AGENTS.md, GLOSSARY.md, current task
ON DEMAND  files, docs, skills, search results
COMPACTED  old turns, summarized at a natural break
ISOLATED   subagent work, returned as a short report
NEVER      secrets, raw logs, whole directories, unrelated files
```

## Project docs and files

Project files are created on demand. `pagani init` writes only `AGENTS.md`,
`CLAUDE.md`, `scripts/check`, `.claude/settings.json`, `.agents/plans`, the exclude
block, and the git hooks. Everything else is seeded only when a skill first needs
it, with `pagani seed <Name>` (idempotent; prints `created:` or `kept:`):

- `SPEC.md` and `PLAN.md` — product and technical requirements, and ordered
  outcomes, dependencies, risks, and validated status.
- `REVIEW.md` — the risk paths. A missing file means no risk paths.
- `GLOSSARY.md` — the project's domain language.
- `BACKLOG.md`, `mistakes.md` — backlog items and repeated lessons.
- `docs/FEATURE-MAP.md` — how to reach and verify each feature.
- `scripts/verify` and `scripts/verify.conf` — the browser driver.

## Automation

Everything here is optional and local. Nothing starts an agent or a server.

- **Git hooks.** `pagani hooks install [path]` installs a gitleaks pre-commit
  hook and a pre-push hook that runs `scripts/check`. `pagani init` installs
  them when `.git` exists. A missing gitleaks is a clean skip.
- **CI.** `.github/workflows/ci.yml` runs `./scripts/validate.sh`, checks that
  the committed `commands/pagani.md` is fresh (`scripts/gen-command.sh
  --check`), and validates the plugin manifests with `claude plugin validate .`
  when `claude` is installed, on Ubuntu and macOS.

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

**Not included:** there is no network allowlist, exact cost tracking, budget
enforcement, or backup command.

**Deliberate non-goals:** full OS sandboxing and a control plane that starts or
stops agents. Untrusted content still reaches agents through browser pages, PR
bodies and comments, `BACKLOG.md`, logs, screenshots, and OCR; the
`untrusted-content` skill is a convention, not a sandbox.

## Why it is shaped this way

PaganiStack optimizes for a change a human can trust, not for output: a spec
before code, vertical tasks that each fit one fresh context, deterministic checks
before any reviewer, one focused reviewer, and a human decision. A retro turns
repeated findings into a lint rule, test, skill edit, or `AGENTS.md` line.

Trade-offs:

- One reviewer can miss a specialist issue. The checklists and the `high` risk
  path (adversarial review, `simplify`, `review-code` on Opus, the second-opinion
  reviewer) cover it; run a specialist skill by name if needed.
- One planning pass can under-specify a large job. `feature` and `refactor` get
  the full interview, and the planner returns open questions.
- The master is busier (it writes `decision.md`); that removes a handoff.
- Parallel waves buy wall-clock time but cost worktrees, ports, and merge work,
  so the master goes parallel only when ready tasks touch disjoint files.
- Harness decay: on a model upgrade, remove one component at a time on a branch,
  re-run a few real jobs, and keep it only if it still earns its place.
- A repeated rule moves down the hierarchy until it sticks; see
  `## Rule placement` in [AGENTS.md](../AGENTS.md).

## Sources

The workflow and skills draw on `claude.dev`, Boris Cherny's public Claude Code
workflow, Anthropic's *Building effective agents*, Matt Pocock's skills, and the
vendored skills listed in [SKILLS.md](SKILLS.md). See the license files inside
each skill folder.
