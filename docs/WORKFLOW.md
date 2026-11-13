# How BottegaStack Works

BottegaStack gives an agent a run, a SPEC with a task graph, deterministic checks,
one reviewer, and a human decision. The branch is the run's identity and the
state directory holds its working files; the chat and the PR (or merge commit)
are the record. There is no database or state machine.

## The workflow

```
0. SETUP     playbook, risk, run branch, state directory (or the light path)
1. SPEC      interview -> SPEC (planner reply, saved by maestro spec) [approve]
2. BUILD     one builder per ready task              [approve per wave]
3. CHECKS    maestro check -> checks.result           (fail -> builder)
4. REVIEW    one review-code review (code, UI, UX, security) [summary]
5. FIX       review findings -> fresh builder -> checks -> re-review
6. APPROVAL  master -> decision + quiz (feature/refactor/high)
7. HUMAN     approve, rework, or reject
8. CLOSE     retro, PR or merge write-up
```

### Step 0: Set up and choose a playbook

The master reads `AGENTS.md`, `GLOSSARY.md` if present, and the risk paths in
`REVIEW.md` (a missing file means no risk paths). When `AGENTS.md` has no `## Stack`
section, the `explorer` reads the repo-root manifests and reports the language,
package manager, commands, and frameworks; the master confirms them with
`AskUserQuestion` and writes that section (and `scripts/check` if unconfigured). It loads `playbooks`, proposes a playbook and a risk
(`low`, `standard`, `high`), and asks you to confirm or override. It tracks
playbook and risk as todo items, then runs `maestro start "<title>"`, which uses your
current branch (or creates the one you name with `--branch <name>`) and the state directory `$STATE/<slug>/` and prints
`run:`, `branch:`, and `state:`. It auto-inits the project on first use and
requires a clean tree.

For `trivial` and small `bugfix` work it takes the light path instead: run
`maestro build --here <slug> --task "<text>" --block` on the current branch. That
creates no run, SPEC, or worktree; state lives in `$STATE/quick/<slug>/`. Pass
review findings back with `maestro build --here <slug> --revise <file|->` and
follow progress with `maestro build --status <slug>`.


### Step 1: SPEC

The master loads `interview`, explores first, and asks a small batch of
questions; the answers stay in chat. It spawns the planner, which returns the
SPEC as its final reply: the behavior, the data shape, the failure cases, the
acceptance criteria, and the tracer-bullet task graph. Each task is a vertical
slice that fits one fresh context. Every task carries `Allowed files`,
`Test first`, and `Done when`, and the SPEC carries `## Sensors`: what
`scripts/check` covers, what `scripts/verify` or `agent-browser` covers, and what
neither covers. If a contract field is empty or `## Sensors` is missing, the
master sends the SPEC back to the planner before approval. If the SPEC has open
questions, the master asks you and has it revised. On approval, the master saves
it with `maestro spec <slug>`, which extracts `tasks/<n>.md` and prints the task
count. You approve the spec and the first wave.

`trivial` runs skip this step. A `bugfix` still commits a failing test first.
`feature` and `refactor` runs get the full pass; `refactor` also runs as
expand-contract and keeps behaviour unchanged.

### Step 2: Build

**Autonomy.** The master runs on its own between human checkpoints (SPEC
approval and the final decision). It tracks the steps in the todo list
(`TodoWrite`, or `TaskCreate`/`TaskUpdate` when that tool is unavailable). A
`Stop` hook enforces it: mid-pipeline, with no builder or check running, the
master cannot end its turn while a todo item is open. It never waits for
"proceed" between steps. When the master escalates or a builder reports
`STATUS: BLOCKED`, it runs `maestro hold <run> "<reason>"` instead of completing
the remaining todos: that records the escalation in the state directory,
`maestro build --status` prints `HOLD: <reason>`, and the Stop hook lets the
session end. `maestro hold --clear <run>` clears it on resume.

**Light path.** `trivial` and small `bugfix` runs use the headless builder in the
current checkout through `maestro build --here <slug> --task "<text>"`, with state
in `$STATE/quick/<slug>/`. They still get the Step 6/7 decision prompt.

**Headless builder (Claude drives, a third-party model implements).** When
`maestro build --check` passes, the master creates the task worktree and runs
`maestro build <run> <task>`. It runs the Claude Code `builder` agent headless
(`claude -p`) on the model configured in `~/.config/bottega/builder.env`, then
prints the session id, report location, `STATUS`, `tokens: in <n> out <n>`,
`steps: <n>`, and changed files. The builder
ends its final reply with the report; `maestro build` extracts it into
`$STATE/<run>/build/<task>.report.md`. `review-code` reviews the diff; on
`CHANGES` the master passes the findings inline and runs `--revise <file|->`,
which resumes the same session. It allows two revisions (exit 4 after that) and
the master escalates to the human. The builder never plans, decides,
troubleshoots, or orchestrates. The plugin's `PreToolUse` hook denies the
Claude-model `builder` subagent whenever the headless builder is configured; if
it is not, the Claude `builder` is the fallback.

The master runs each build itself as a background Bash task
(`maestro build <run> <task> --block`), so no relay model is involved. It keeps a
`TodoWrite` item per task. Every headless build prints its own `progress:` lines
as tasks finish; a live view of a wave is `maestro watch <run>` in a pane, whose
piped output prints one line only on a count or state change. The master also
runs `maestro build --status <run>` (a one-shot reading) after each finished
build and moves to checks as soon as the wave has joined. A build stops at the 30-minute timeout (`BOTTEGA_BUILD_TIMEOUT`); that
is the only stop. Each build reports its token counts and step count.

The master reads the task graph from the saved SPEC and inspects the ready set
before building. It defaults to sequential. If two or more ready tasks touch
disjoint files and have no dependency between them, it runs that wave in parallel
with one worktree per task; parallel is preferred whenever it is safe. Sequential
is used when tasks share a file, a migration, or one needs another's output. Each
builder commits locally and ends its reply with the report. The master merges
task branches into the run branch and posts a wave summary.

A parallel wave joins with `ALL` by default: every task in the wave must pass
before the wave is merged. Do not merge partial results.

A builder is bounded by the task's `Allowed files`. If it needs another file, it
reports `BLOCKED`; the master does not widen the task itself. Existing tests are
evaluator inputs: the builder does not edit, delete, skip, or weaken one to make
the task pass. A genuine test change needs approval and is recorded under
`## Test changes` in the build report.

### Step 3: Checks

The master runs `maestro check <run>`, which runs `scripts/check`, writes
`checks.result` with `RESULT`, `HEAD`, exit code, and duration and appends one
line per run plus the output to `checks.log`, both in the state directory. The
light path uses the same `maestro check <slug>` and `maestro gate <slug>`. A
failure goes back to a fresh builder; no reviewer runs on a failing build.

### Step 4: Review

The master runs `maestro gate <run>` first. A failing, stale, or dirty gate stops
the review. For `low` risk it first runs `maestro build --review <run> <task>
--block` (on the light path `maestro build --review --here <slug> --block`) on the headless model: no findings means no Claude reviewer runs, and
any finding means the `review-code` reviewer below runs. `standard` and `high`
risk are unchanged. It then spawns one `review-code` reviewer, which covers code,
UI, UX, and security in one pass and returns one verdict:

- **Code** — correctness, simplicity, conventions, tests, and spec fidelity.
- **UI** — visual consistency, design-system fit, spacing, responsive layout,
  contrast, and hover/focus/disabled/loading states.
- **UX** — flows, empty/loading/error states, copy, accessibility, keyboard and
  focus order, mobile, and edge cases.
- **Security** — access control, input handling, XSS, data exposure,
  payments/identity, abuse, secrets, dependencies, and sessions/auth.

The reviewer loads `verification`, runs every `Proof:` line in the SPEC, and records each result with `maestro verify record`; `agent-browser` is for rendered checks when the change has
UI, and loads `unslop` for copy. It returns one `VERDICT` for the whole change as
its reply. It checks the diff against each task's `Allowed files`, the test-first
evidence, the changed test files, and the blind spots listed under `## Sensors`.
An out-of-bounds edit, a task with no red-before-green evidence (unless
docs/config-only), or an unjustified test edit, skip, or weakened assertion is
`CHANGES`; an acceptance criterion that depends on an uncovered area goes under
Risks. The master posts the summary in chat; for `feature`, `refactor`, and
`high` risk it posts the longer summary at this checkpoint.

For `high` risk the master also runs the second-opinion reviewer:
`maestro build --review <run> <task> --block` runs `review-code` headless on the
third-party model, read-only, and puts the findings in
`$STATE/<run>/build/<task>.review2.md`.

### Step 5: Fix

If a review returns `CHANGES`, the master passes the findings — the file and
line, why it matters, how to fix it, and how to verify it — to a fresh builder,
or on stdin to `maestro build <run> <task> --revise -` for a headless task. It
re-runs checks and re-runs the reviewer on the affected area. Max two fix rounds.
The master tracks the number of failing checks and blocking findings each round;
if neither decreased in two consecutive rounds, it stops and escalates instead
of running a third identical round.

### Step 6: Approval

The master loads `approval` and reads the SPEC, the builder reports, checks, and
review replies. It decides `APPROVE` or `ESCALATE` itself, with the
acceptance-criteria mapping, risks, and an explainer. For `feature`, `refactor`,
and `high` risk it adds a quiz; `trivial`, `bugfix`, and `low` risk get the
explainer only. In every playbook it then presents the decision and asks for it
through the native question UI; a chat summary alone never closes a run. The
quiz uses retrieval practice: no formatting hints, answers answerable from the
artifacts. It stays in chat and is never written to the PR body or a commit message.

### Step 7: Human decision

You read the explainer, answer the quiz where one applies, and choose merge,
commit, push, PR, rework, or reject. The master shows the exact git command
before running it. The decision is recorded in the PR body or the merge-commit
(commit) message, not in a file. Before offering merge or PR options, `closeout`
runs the `ship` checklist — CI green, security checks passed, an independent
`review-code` of the latest commit, review threads resolved, and manual testing
noted — and an unmet item blocks "Approve and merge" until it is fixed or you
explicitly waive it.

Before it creates a branch, worktree, or PR, the master checks whether it already
exists (`git branch --list`, `git worktree list`, `gh pr view`) so a resume does
not duplicate a side effect.

### Step 8: Close

The master runs `maestro report --retro --exit-code` and loads `session-retro` to
propose one environment change. If the scan exits 1, findings repeat across runs;
on repeated findings it proposes Gotchas patches. It loads `session-handoff` if
the run continues elsewhere. Once the PR or merge is confirmed, it runs
`maestro worktree prune <slug>` and `maestro report --close <slug>` to remove the
worktrees and the state directory, then stops.

A run paused instead of finished keeps its state. Closing with
`--outcome paused` still writes the one trust-log line but leaves the state
directory in place and writes a dated `paused` marker in it, so `maestro spec`,
`maestro build --status`, and `maestro verify list` still resolve the run and a
later session can resume from the saved spec, tasks, build records, and check
results. The hook treats a paused run as closed and stays silent. To continue it,
run `maestro resume <run>` first: it removes the `paused` marker and any `hold`
file, so the Stop hook tracks the run again. Closing again with `merged`, `pr`,
or `rejected` removes the directory as usual.

### Resume

Run state lives in the state directory and the todo list, so a new session can
continue a run. The entry rule: a feature request starts at Step 0, `status`
reads the todo list and current branch, and `resume` continues from the open todo
items without redoing completed steps; the same session can be picked up with
`claude --continue`. For a run closed with `--outcome paused`, the master runs
`maestro resume <slug>` first; a run that is not paused still has any hold
cleared and says so.

## Playbooks and risk

A playbook chooses the pipeline; risk is a modifier on top of it. The master
picks both at Step 0, tracks them in the todo list, and never downgrades either.
It copies the matched playbook's steps verbatim into the todo list; a skipped
step stays in the list with a one-line skip reason. Work that fits no playbook
loads `figure-it-out`, which proposes a one-off playbook and confirms it with
`AskUserQuestion` before running it.

| Playbook | Use when | Pipeline |
|---|---|---|
| `trivial` | docs, copy, comments, config-only; a few files; no risk path; no behaviour change | light path: headless builder → check → `review-code` → human |
| `bugfix` | a reproducible symptom | failing test first; the light path when small; otherwise builder → check → `review-code` → human |
| `feature` | normal product work | interview → SPEC → task graph → worktrees → full build/check/review |
| `refactor` | behaviour must not change | expand-contract; tests before and after; full build/check/review |
| `investigate` | a symptom with no clear fix | read-only: reproduce, test hypotheses with runtime evidence, report the cause and the next playbook — see [investigate.md](../skills/workflow/playbooks/investigate.md) |
| `perf` | a metric must improve against a target | baseline, profile, one change at a time, re-measure, keep only wins beyond noise — see [perf.md](../skills/workflow/playbooks/perf.md) |
| `prototype` | a question needs a working answer | throwaway on a branch you name, answer with evidence, decide, never merge — see [prototype.md](../skills/workflow/playbooks/prototype.md) |
| `ship` | an existing PR or branch needs merge-readiness checks | read-only checklist: CI, security, independent review, threads, manual testing; never merge or push without approval — see [ship.md](../skills/workflow/playbooks/ship.md) |
| `autopilot` | a queue of items to run end to end | one item at a time on its own branch, stop at a ready local branch, never push, merge, or open a PR — see [autopilot.md](../skills/workflow/playbooks/autopilot.md) |
| `pause` | stop a run and resume it later | write a local `PLAN.md` note; resume rebuilds the todo list from it — see [pause.md](../skills/workflow/playbooks/pause.md) |
| `eval` | compare two versions of the stack or a skill on the same task | headless builder candidates in clean temp repos, a blind judge on the reviewer model, a transcript check, a promote or keep decision — see [skills/workflow/playbooks/eval.md](../skills/workflow/playbooks/eval.md) |
| `pr-babysit` | an open PR needs CI or review follow-up | watch checks and comments read-only, fix through the light path, push only with approval — see [skills/workflow/playbooks/pr-babysit.md](../skills/workflow/playbooks/pr-babysit.md) |

Every playbook ends with the PR (or merge) write-up; the decision lives in that
text, not in a file.

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

Every run, including the light path, ends with a PR or merge write-up that pastes
the verbatim before/after evidence and labels each claim measured, inferred, or
guessed (principle `prove-it-works`).

## Agents and models

| Agent | Role |
|---|---|
| `master` | Talks to you, asks questions, runs checks, posts summaries, executes git only on request. |
| `explorer` | Cheap read-only search and log reading. |
| `planner` | Returns the SPEC with the requirements, decisions, and tracer-bullet task graph. |
| `builder` | Implements exactly one task and ends its reply with the report. |
| `review-code` | One reviewer for code, UI, UX, and security; one verdict as its reply. |

There are no tier variants of an agent. The master picks the model and effort per
call with the Agent tool's `model` and `effort` parameters; each agent's
frontmatter is the default. The plugin's `PreToolUse` hook denies a `bottega:`
agent call that omits `model` or `effort`, so the routing is not optional. The
routing comes from `~/.claude/rules/bottega-models.md` when present, written by
`/maestro-models`. Each line is `role: value, effort`, where `value` is a Claude
alias (`haiku`, `sonnet`, `opus`) or `headless`, and `effort` is `low`, `medium`,
or `high`:

```
explorer: haiku, low
trivial: haiku, low
builder: headless, medium
reviewer: sonnet, medium
reviewer-high-risk: opus, high
second-opinion: headless, medium
planner: opus, high
master: opus, medium
```

Without the file the same defaults apply; `master` keeps its own model. The
headless runner reads the `builder` line for `build` and `--here`, and the
`second-opinion` line for `--review`, passing only the effort as `--effort`; a
malformed line is ignored.

## Skills

BottegaStack ships 62 skills in the Claude Code categories plus `workflow/`. The
core workflow skills are `playbooks`, `principles`, `interview`, `planning`,
`implementation`, `verification`, `review-code`, `approval`, `summary`,
`closeout`, `session-handoff`, `session-retro`, `diagnosis`, and
`untrusted-content`. The rest are situational: `how` and `why` explain code and
decisions read-only, `figure-it-out` builds a one-off playbook,
`create-verification-skill` writes a project `verify-*` skill, and `automate-me`
drafts a personal mode skill from the user's transcripts after approval.
`interrogate` stress-tests a high-risk change and `blast-radius` maps what it can
break outside the diff; both are report-only. `linux-sysadmin`,
`podman-operator`, and `bash-scripting` live in the `sysadmin`, `containers`, and
`devops` categories and are adapted from ChrisTitusTech/titstack (MIT).
`trivial`, `bugfix`, `feature`, and `refactor` are sections in the `playbooks`
skill; the other playbooks are files beside it at
`skills/workflow/playbooks/<name>.md`.

The 15 principles are reference files under `principles/references/`; `principles` is
the index that keeps the citations stable. Agents and skills cite a principle
instead of restating a rule, which keeps `agents/master.md` at about 150 lines.

The inventory and the rules for adding a skill are in [SKILLS.md](SKILLS.md). The
plugin manifest lists each category directory; Claude Code discovers the skills
inside `skills/<category>/<name>/`, so they stay grouped by category.

Other skills are invoked directly by name, not through `/maestro`:

```
/wizard
/backlog-triage
/wayfinding
/improve-architecture
/review-pr
```

## Commands

BottegaStack has these top-level commands: `doctor`, `init`, `seed`,
`upgrade`, `start`, `hold`, `resume`, `spec`, `check`, `gate`, `verify`, `log`, `report`, `build`, `worktree`, `skills`, and
`hooks`. (`guard` and `keyget` are internal hook entry points, not user commands.)

```bash
maestro doctor
maestro init [path]
maestro seed <Name>
maestro upgrade [path]

maestro start "<title>"
maestro hold <run> "<reason>" | --clear <run>
maestro resume <run>
maestro spec <run> [file]
maestro check <run>
maestro gate <run> [--allow-dirty] [--proof]
maestro verify record <run> <AC> PASS|FAIL|INCONCLUSIVE --by <role> [--evidence <file>]
maestro verify waive <run> <AC> "<reason>"
maestro verify list <run>
maestro log <run> [<phase> <decision> <why> <evidence> <result>]
maestro report [--retro] [--exit-code]
maestro report --close <run> [--playbook <p>] [--risk <r>] [--outcome <o>]
maestro report --trust [n]
maestro report --finding <run> "<title>"

maestro build <run> <task> [--revise <file|->] [--block|--wait]
maestro build --here <slug> --task "<text>" [--revise <file|->] [--block|--wait]
maestro build --review <run> <task> [--block|--wait]
maestro build --review --here <slug> [--block|--wait]
maestro build --status <run>
maestro watch <run>
maestro watch --line
maestro build --init | --check

maestro worktree create <run> <task> [--branch <name> [--base <ref>]]
maestro worktree prune <run> [--force]
maestro hooks install|uninstall [path]

maestro skills list
maestro skills install <name>... | --all
maestro skills uninstall <name>... | --all

maestro tools install [--yes] | hint
```

Use `./bin/maestro` instead of `maestro` when running from a clone outside a
session. Setup and troubleshooting are in [SETUP.md](SETUP.md).

## Checks, review, and verification

`scripts/check` is the project check script. `maestro check <run>` runs it and
writes `checks.result` and `checks.log` in the state directory. `maestro gate
<run>` fails when the latest check failed, is stale, or the working tree is
dirty, and warns when a branch changes tests and non-tests but no test-only commit
precedes the first non-test commit.

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

## What the code enforces

The workflow is prose, but some rules are code. Each rule moves to the highest
level that can prevent it from recurring.

### Already enforced

- `maestro start` refuses a dirty tree, `main`, or a detached HEAD.
- `maestro check` writes `checks.result`; `maestro gate` fails on a failed or
  stale result, a dirty tree, or, with `--proof`, an unmet Proof criterion.
- `maestro verify record` refuses `--by builder` and a PASS without an evidence
  file; the latest row per criterion decides.

### Designed out

- Build progress is a log, not a polling rule: `events.tsv` feeds `maestro
  watch` and `build --status`.
- There is no separate progress file; the raw builder stream is the record.

### Hook

- `hooks/hooks.json` runs `maestro guard stop` on Stop and `maestro guard
  builder` on Agent/Task.
- The Stop hook keeps the turn going while a todo item is open. Once every item
  is complete, each open, non-held, non-paused run needs a passing
  `checks.result` and, when the SPEC has Proof criteria, a PASS/WAIVED row per
  criterion plus a reviewer or second-opinion row. The reason names the command
  that records the evidence.
- The builder guard denies a Bottega agent call that omits `model` or `effort`.

### Advisory

Later candidates, not enforced yet:

- SPEC-shape validation.
- An Allowed-files gate on builder writes.
- Push and merge hooks.
- Refusing more than three identical build rounds.

## Run state

A run's working files live in a per-repo state directory outside the repo; the branch,
the todo list, and the chat or PR carry the record. The layout, `BOTTEGA_STATE_DIR`,
and the reboot caveat are in [SETUP.md](SETUP.md#run-state). `PLAN.md` is
project-level only. Every step posts a short summary in chat.

## Context policy

```
ALWAYS     SPEC.md, AGENTS.md, GLOSSARY.md, current task
ON DEMAND  files, docs, skills, search results
COMPACTED  old turns, summarized at a natural break
ISOLATED   subagent work, returned as a short report
NEVER      secrets, raw logs, whole directories, unrelated files
```

## Project docs and files

Project files are created on demand with `maestro seed <Name>`; `maestro init`
writes only `AGENTS.md`, `CLAUDE.md`, `scripts/check`, `.claude/settings.json`, the
exclude block, and the git hooks. The list and destinations are in
[SETUP.md](SETUP.md#project-files-on-demand).

## Automation

Everything here is optional and local. Nothing starts an agent or a server.

- **Git hooks.** `maestro hooks install [path]` installs a gitleaks pre-commit
  hook and a pre-push hook that runs `scripts/check`. `maestro init` installs
  them when `.git` exists. A missing gitleaks is a clean skip.
- **CI.** `.github/workflows/ci.yml` runs `./scripts/validate.sh` and validates the plugin manifests with `claude plugin validate .`
  when `claude` is installed, on Ubuntu and macOS.
- **Doctor.** `maestro doctor` prints runtime and tool versions, the skill count,
  `AGENTS.md` size, hook status, and security warnings: gitleaks missing, `.env`
  tracked, no dependency-update config, and no CI security job. It then runs the
  repo lint and is the release gate.

## Safety and limits

- No cloud sessions.
- No paid skills or paid assets.
- No secrets in the repo. Do not read keys, tokens, password stores, or cloud
  credentials.
- Do not send repo content to unknown hosts.
- Worktrees for parallel builders; one port per worker.
- Permission denies for destructive commands. `maestro init` writes
  `.claude/settings.json` with allow/ask/deny rules for Claude Code.
- No push, merge, or deploy without explicit approval.
- Builders commit locally; they never push or merge.
- The human decides the merge.

**Not included:** there is no network allowlist or backup command. Builds report
`tokens:` and `steps:`; the only stop is the 30-minute builder timeout.

**Deliberate non-goals:** full OS sandboxing and a control plane that starts or
stops agents. Untrusted content still reaches agents through browser pages, PR
bodies and comments, `BACKLOG.md`, logs, screenshots, and OCR; the
`untrusted-content` skill is a convention, not a sandbox.

## Why it is shaped this way

BottegaStack optimizes for a change a human can trust, not for output: a spec
before code, vertical tasks that each fit one fresh context, deterministic checks
before any reviewer, one focused reviewer, and a human decision. A retro turns
repeated findings into a lint rule, test, skill edit, or `AGENTS.md` line.

Trade-offs:

- One reviewer can miss a specialist issue. The checklists and the `high` risk
  path (adversarial review, `simplify`, `review-code` on Opus, the second-opinion
  reviewer) cover it; run a specialist skill by name if needed.
- One planning pass can under-specify a large run. `feature` and `refactor` get
  the full interview, and the planner returns open questions.
- The master is busier (it decides approval and drafts the PR write-up); that
  removes a handoff.
- Parallel waves buy wall-clock time but use worktrees, ports, and merge work,
  so the master goes parallel only when ready tasks touch disjoint files.
- Harness decay: on a model upgrade, remove one component at a time on a branch,
  re-run a few real runs, and keep it only if it still earns its place.
- A repeated rule moves down the hierarchy until it sticks; see
  `## Rule placement` in [AGENTS.md](../AGENTS.md).

## Sources

The workflow and skills draw on `claude.dev`, Boris Cherny's public Claude Code
workflow, Anthropic's *Building effective agents*, Matt Pocock's skills, and the
vendored skills listed in [SKILLS.md](SKILLS.md). See the license files inside
each skill folder.
