# PaganiStack Plan

**Status:** 0.2.0 implemented.
**Naming:** the stack is PaganiStack. The command is `/pagani`. Runtime state lives in `pagani/jobs/<job-id>/`. Job branches are `pagani/<job-id>`.

**What changed:** the installer, `resources/`, the nine-plus-two skill taxonomy, P0/P1 skills, review convergence, `review-pr`, evals, and Claude Code agents are in place. No paid skills, no cloud sessions.

---

## 1. The 11 steps

```
/pagani <feature>
  │
  ▼
0. SETUP            classify lane, job folder, branch, usage start
  │                 ⏸ lane confirmation
  ▼
1. FULL PLAN        master asks questions with the native question UI
  │                 planner writes plan.md                  ⏸ approve
  ▼
2. TO-SPEC          planner writes spec.md                  ⏸ approve
  ▼
3. TO-TICKETS       planner writes tickets/                 ⏸ approve
  ▼
4. IMPLEMENT        one builder per ticket, parallel when possible
  │                 builders write build/<ticket>.md        ⏸ approve per wave
  ▼
5. CHECKS           pagani check writes checks.md           (fail → back to builder)
  ▼
6. REVIEW           only the needed lenses, in parallel
  │                 review-code / review-ui / review-ux / review-security
  │                 wait for all → round-N/summary.md        ⏸ summary
  ▼
7. FIX              if any CHANGES: fix.md (what/why/how/where)
  │                 fresh builder → checks → affected reviewers
  │                 max 2 rounds
  ▼
8. APPROVER         approver writes decision.md
  │                 APPROVE | ESCALATE + explainer + quiz
  ▼
9. HUMAN            you read the explainer, answer the quiz, decide
  ▼
10. FINAL CODE      usage end, approve/reject/rework; merge/commit/push/PR on request
```

Lanes shorten the pipeline: `trivial`, `bugfix`, and `small` skip spec, the
tickets index, and the approver. `high-risk` adds adversarial review, simplify,
strong security, and a strong approver. See `skills/workflow/lanes/SKILL.md`.

---

## 2. The agents you already have

All base roles are filled. The installer generates tier variants from
`agents/models.conf`.

| File | Role | Writes | Model |
|---|---|---|---|
| `master.md` | Primary orchestrator. Runs the workflow, asks the questions, runs checks, posts summaries, executes git only on request. | `job.md`, `interview.md`, `checks.md`, `summary.md`, `fix.md`, `human.md`, `AGENTS.md`/`mistakes.md` with permission. | strong |
| `explorer.md` | Read-only search and log reading. | A short report. | lite |
| `planner.md` | Three modes: `PLAN`, `SPEC`, `TICKETS`. | `plan.md`, `spec.md`, `tickets/`. | strong (`planner-std` for small) |
| `builder.md` | Implements exactly one ticket, in its worktree or the job checkout. | Code + `build/<ticket>.md`. | std (`builder-lite`, `builder-strong`) |
| `review-code.md` | Correctness, simplicity, conventions, tests, spec fidelity. | `round-N/review-code.md`. | std (`review-code-lite`, `review-code-strong`) |
| `review-ui.md` | Visual consistency, responsive, contrast, design-system fit. | `round-N/review-ui.md`. | lite |
| `review-ux.md` | Flows, states, copy, accessibility, mobile. | `round-N/review-ux.md`. | lite |
| `review-security.md` | Access control, input, data exposure, secrets, dependencies. | `round-N/review-security.md`. | strong |
| `approver.md` | Final gate + explainer + quiz. | `decision.md`. | strong |

### The one new command

`commands/pagani.md` — the `/pagani` entry point. It selects the `master` agent and passes the request. No new agent.

### The skills folder

The agent files contain only the role, boundaries, permissions, inputs and
outputs, and the skill names to load. The procedures live in `skills/`.

**Existing skills used directly, without copying or renaming:**

`grilling`, `wizard`, `writing-for-agents`, `diagnosing-bugs`, `tdd`,
`codebase-design`, `domain-modeling`, `code-review`.

**Existing skill copied as-is (user-invoked):**

`wait-what`.

**PaganiStack skills, renamed because they are adapted:**

```
skills/
  library-api-reference/
    library-reference/
    vercel-react-best-practices/
  product-verification/
    verification/
    review-ui/
    review-ux/
    web-design-guidelines/
    agent-browser/
  data-analysis/
    data-analysis/
  business-automation/
    backlog-triage/
    weekly-review/
  scaffolding/
    scaffold/
  code-quality/
    review-code/
    review-security/
    approval/
    implementation/
    codebase-design/
    domain-modeling/
    improve-architecture/
    adversarial-review/
    simplify/
    review-pr/
    tdd/
    code-review/
  ci-cd/
    pr/
    ci-cd/
  runbooks/
    diagnosis/
    diagnosing-bugs/
    runbook/
  infrastructure-ops/
    infra-ops/
  workflow/
    interview/
    summary/
    wait-what/
    wayfinding/
    planning/
    plain-writing/
    closeout/
    session-handoff/
    session-retro/
    skill-creator/
    grilling/
    wizard/
    writing-for-agents/
  design/
    design-taste-frontend/
    frontend-design/
    mobile-app-ui-design/
    openui/
    emil-design-eng/
```

The nine categories are the Claude Code taxonomy. `workflow/` and `design/` are
explicit extensions because the nine do not cover planning or UI/UX production.
Review lenses live in `code-quality/` and `product-verification/`. The paid
`design-mobile-apps` skill is removed. See `skills/design/README.md` for design
sources and licenses.

Why this split:

- The upstream skills keep their names and stay upgradeable. `grilling`,
  `codebase-design`, `domain-modeling`, `diagnosing-bugs`, `tdd`, `code-review`,
  `wizard`, and `writing-for-agents` are used as they are.
- The PaganiStack-specific parts use standalone names and live under category
  folders. The original upstream name is never reused for changed content.
- A skill is loaded only when the agent calls it, so it does not bloat every
  agent's context.
- One skill serves several agents. `verification` is used by the builder,
  the UI reviewer, the UX reviewer, and the approver. `plain-writing` is used by
  the UX reviewer and the summary.

### Skills each agent loads

| Agent | Skills |
|---|---|
| `master` | `lanes`, `interview` (loads `grilling`, `domain-modeling`), `summary`, `diagnosis`, `closeout`, `session-retro`, `session-handoff`; optional `wizard`, `writing-for-agents`, `improve-architecture`, `review-pr`, `adversarial-review`, `simplify` |
| `explorer` | none; read-only search and log reading |
| `planner` | `planning`, `codebase-design`, `domain-modeling` |
| `builder` | `implementation`, `tdd`, `verification`; `diagnosing-bugs` when blocked |
| `review-code` | `review-code`, `code-review`, `codebase-design`, `verification` |
| `review-ui` | `review-ui`, `web-design-guidelines`, `verification` |
| `review-ux` | `review-ux`, `web-design-guidelines`, `plain-writing`, `verification` |
| `review-security` | `review-security` |
| `approver` | `approval`, `verification` |

Category skills (`library-reference`, `data-analysis`, `weekly-review`,
`scaffold`, `ci-cd`, `runbook`, `infra-ops`, `review-pr`, `adversarial-review`,
`simplify`, `agent-browser`, `vercel-react-best-practices`) are loaded on demand
by the master or the relevant agent.

Optional command branches:

- `/pagani triage` uses `backlog-triage`.
- `/pagani wayfind` uses `wayfinding`.
- `/pagani improve` uses `improve-architecture`.
- `/pagani design` uses `design-taste-frontend`, `frontend-design`, and `mobile-app-ui-design`.
- `/pagani pr <n>` uses `review-pr`, `gh pr view`, `gh pr diff`, and `gh pr checks`.
- `/pagani wizard` uses `wizard`.

---

## 3. The job folder

```
pagani/jobs/<job-id>/
  job.md
  interview.md
  plan.md
  spec.md
  tickets/
    index.md
    01-<slug>.md
    02-<slug>.md
  build/
    01-<slug>.md
    02-<slug>.md
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
```

`job.md` is a markdown checklist, not JSON:

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

## Reviews
- [x] code
- [ ] ui
- [x] ux
- [ ] security
```

Add `pagani/jobs/` to the project `.gitignore`.

---

## 4. Step details

### Step 1 — Full plan (interactive)

The master does this, not the planner. It is the only step that talks to you.

1. Read `AGENTS.md`, `GLOSSARY.md`, and the code the request touches.
2. Ask questions with the native `question` tool, 3–5 at a time. Every question
   has options where possible and always allows a free-form answer.
3. Keep asking until every category is answered or explicitly accepted as an
   assumption. Write the answers to `interview.md`.
4. Spawn `planner` with `MODE: PLAN`. It writes `plan.md`.
5. If `plan.md` has open questions, ask them and re-run the planner.
6. Post the plan summary. Wait for `approve`.

**Question checklist** (from the resources you sent):

- Problem and goal: what problem, why now, what success looks like.
- Users and actors: who, signed in/out, roles, permissions.
- Use cases: primary flow, alternate flows, empty/loading/error states, edge
  cases, first run, repeat use.
- Scope: in, out, what must not change.
- Constraints: stack, dependencies, backwards compatibility, performance,
  accessibility, i18n, data model, API contracts.
- Acceptance criteria: observable behaviour and how to verify each.
- UI/UX: layout, copy, responsive, interaction, design system, existing
  patterns.
- Security and privacy: auth, input, data exposure, secrets, abuse, storage.
- Testing: what tests, which seams, fixtures, browser checks.
- Rollout: schema, feature flags, deploy, rollback.
- Risks and unknowns: what could go wrong, what we do not know.
- Definition of done: what must be true before merge.

Do not ask what the repo already answers. Do not ask twenty questions at once.
If the request is small, keep the plan short.

### Step 2 — to-spec

`planner` with `MODE: SPEC` reads `plan.md` and writes `spec.md` using the
`to-spec` template:

- Problem statement
- Solution
- User stories
- Implementation decisions
- Testing decisions
- Acceptance criteria
- Out of scope
- Assumptions

The master posts the spec summary and waits.

### Step 3 — to-tickets

`planner` with `MODE: TICKETS` reads `spec.md` and writes:

- `tickets/index.md` — the graph, blocking edges, and waves.
- `tickets/<NN>-<slug>.md` — one tracer-bullet ticket per file.

Ticket rules: vertical slice, demoable or verifiable on its own, fits one fresh
context window, prefactoring first, blocking edges declared, no cycles. Wide
refactors use expand–contract.

The master posts the graph and the first wave. Waits for `approve`.

### Step 4 — Implement

1. Compute the ready frontier from `tickets/index.md`.
2. Parallel when the ready tickets touch disjoint files; sequential when they
   share a file, a migration, or one needs another's output.
3. For a parallel wave, the master creates one worktree per ticket:
   `git worktree add -b pagani/<job-id>/<ticket> ../<repo>-pagani/<job-id>/<ticket> pagani/<job-id>`.
   For sequential tickets, the job checkout is enough.
4. Spawn one `builder` per ticket. One ticket per builder. Each gets the job
   folder, ticket path, worktree, and branch.
5. Wait for the wave. Read `build/<ticket>.md`.
6. Merge each ticket branch into `pagani/<job-id>`. Run the checks.
7. Post the wave summary. Wait for `approve`.

If a builder is `BLOCKED`, stop and ask. Do not paper over it.

### Step 5 — Deterministic checks

This is the step you asked about. A **deterministic check** is a command that
returns pass or fail without an LLM judging. It is the cheapest error filter and
the reason reviewers never see a broken build.

Examples:

- `npm run lint`
- `npm run typecheck`
- `npm test`
- `npm run build`
- a browser smoke test, if the project has one
- `cargo test`, `go test ./...`, `pytest`, `make check`, depending on the stack

How it works here:

1. The exact commands live in the project `AGENTS.md`. No new script is needed.
   If the project already has `scripts/check` or `make check`, use it.
2. After each build wave, the master runs them in the job checkout.
3. It writes `checks.md` with the command, exit code, and a short output.
4. If any command fails, the master writes `fix.md` with the log and sends a
   fresh builder back. No reviewer runs.
5. If all pass, the review step starts.
6. The builder runs the checks before reporting too, but the master's run is the
   independent one. The approver runs them again before approving.

Why it matters: it catches objective errors before an LLM spends tokens reading
code, it gives the reviewers a clean baseline, and it gives you evidence that the
change actually builds and tests. This is the "give the agent a way to verify its
own work" principle from Boris Cherny and Anthropic.

### Step 6 — Review

The master routes only the needed lenses:

| Lens | Run when |
|---|---|
| `review-code` | Always. |
| `review-ui` | The diff touches components, styles, pages, templates, or the spec has UI criteria. |
| `review-ux` | The change affects a flow, copy, loading/empty/error states, accessibility, mobile, or the spec has UX criteria. |
| `review-security` | The diff touches auth, permissions, payments, user input, API routes, database/storage, secrets, dependencies, or the spec has security requirements. |

If unsure, the master asks you with the `question` tool.

The chosen reviewers run in parallel, fresh context, and do not see each other's
files. Each writes one file with:

```markdown
VERDICT: PASS | CHANGES

## Summary
## Findings
1. file:line — problem — why — suggested fix — evidence
## Verified
## Risks
```

The master waits for all, writes `round-N/summary.md`, and posts the summary.

### Step 7 — Fix

If any review is `CHANGES`, the master writes `fix.md`. It is concise but
precise, and for every finding it says:

- what is wrong,
- why it matters,
- where the fix belongs (file:line),
- how to fix it,
- how to verify the fix,
- the evidence.

Then it spawns a **fresh** builder for the affected ticket. It does not resume
the failed builder. It re-runs the deterministic checks, then re-runs only the
reviewers whose verdict was `CHANGES` and any reviewer whose area the fix
touched. Max two rounds. After two, it escalates to you with the outstanding
findings.

### Step 8 — Approver

The approver reads the plan, spec, tickets, builds, checks, every review, and the
diff. It spot-checks at least one acceptance criterion itself. It writes
`decision.md`:

```markdown
APPROVE | ESCALATE

## Why
## Acceptance criteria
## Risks
## Explainer
### What changed
### How it works
### Why these choices
### What to inspect
## Quiz
1. Question?
   Answer: ...
## For the human
```

It escalates money, auth, permissions, deploy/CI, schema, email, production
writes, new dependencies, and product/business assumptions. It never merges.

### Step 9 — Human decision

The master shows the decision, the explainer, and the quiz. You answer the quiz
if you want; it is there to make sure you understand the change before merging.
Then you choose:

- **Approve and merge** — merge `pagani/<job-id>` into the base.
- **Approve and commit** — commit remaining changes with a message.
- **Approve and push** — push `pagani/<job-id>`.
- **Approve and open PR** — push and create a PR.
- **Rework** — give feedback; a fresh builder addresses it, then checks and
  reviews run again.
- **Reject** — stop, keep the branch and artifacts.

The master shows the exact git command before running a push, merge, or PR. It
never does one without your explicit instruction.

### Step 10 — Close

- Update `job.md`.
- Run only the action you chose.
- If the job produced a reusable lesson, propose one line for `AGENTS.md` or
  `mistakes.md`. Ask before editing.
- Tell you what merged, what remains, and where the artifacts are.

---

## 5. How the agents interact

```
you ── /pagani <feature> ──▶ master
                              │
                              ├─ question UI (plan interview, checkpoints)
                              ├─ planner  MODE: PLAN     → plan.md
                              ├─ planner  MODE: SPEC     → spec.md
                              ├─ planner  MODE: TICKETS  → tickets/
                              ├─ builder  × ticket       → build/<ticket>.md
                              ├─ checks (shell)          → checks.md
                              ├─ review-* (parallel)     → round-N/review-*.md
                              ├─ fix.md → builder         (max 2)
                              ├─ approver                → decision.md
                              └─ you: approve / rework / reject
```

- You talk only to the master.
- The master spawns subagents, reads their files, and posts summaries.
- Each agent loads its skill(s) at the start; the skill holds the procedure, the
  agent file holds the role and permissions.
- Subagents write exactly one output each.
- The master writes only orchestration files.
- The job folder is the state; no JSON, no database, no scripts.

---

## 6. The summary contract

After every step, the master posts:

1. **What changed** — files, behaviour, artifacts.
2. **How it works** — the mechanism in plain language.
3. **Why this choice** — the trade-off and the rejected alternative.
4. **Evidence** — the command, output, screenshot, or file:line.
5. **Risks / open questions.**
6. **Next step** — or the decision you need.

It stops and waits. You say `approve`, `rework <note>`, `reject`, `stop`, or ask
a question. This is how you stay in the loop without reading every diff.

---

## 7. Error and hallucination controls

- Interactive plan with explicit use cases, edge cases, and acceptance criteria.
- Spec with testable acceptance criteria.
- Builder runs the checks; master re-runs them independently.
- Reviewers run the checks themselves.
- Four independent lenses, only the needed ones.
- Fresh context per agent.
- Wait for all reviews before fixing.
- Findings require evidence.
- Fix brief says what, why, how, and where.
- Max two fix rounds.
- Approver spot-checks the acceptance criteria.
- Cross-family models: DeepSeek implements, GLM reviews, DeepSeek high for
  security/approval.
- You make the final decision.
- At the end, write the correction into `AGENTS.md` or `mistakes.md`.

No separate verifier, router, dashboard, backlog, issue intake, or cost
tracking. Add them only if the pain is real.

---

## 8. Integration

The installer is the source of truth. It installs skills, agents, and commands
into OpenCode, Claude Code, or both:

```bash
./install.sh --target both
./install.sh --target opencode --dry-run
./bin/pagani doctor
./bin/pagani init /path/to/project
```

The skills source is organized by category, but both runtimes discover
`skills/<name>/SKILL.md`, so the installer flattens the category folders into
`<target>/skills/<name>`. It backs up existing files and writes a manifest for
`--uninstall`.

Agents and commands are per-target:

```
agents/opencode/   agents/claude/
commands/opencode/ commands/claude/
```

If your OpenCode build reads `command/` singular, pass
`--command-dir command` to the installer.

Each project still needs a good `AGENTS.md` with the exact commands. `pagani
init` copies the templates.

```markdown
## Commands
- install: ...
- dev: ...
- lint: ...
- typecheck: ...
- test: ...
- build: ...
- browser check: ...
```

Without those commands, the deterministic checks step cannot run.

---

## 9. Build order

The files are already written. Do this to validate:

1. Symlink the agents and the command, and flatten the skills with the command
   in section 8.
2. Pick one small feature in a real project.
3. Run `/pagani <feature>`.
4. Go through plan → spec → tickets → build → checks → code review → your
   approval. Stop there.
5. If the flow feels right, run another job with a UI change so `review-ui` and
   `review-ux` are used.
6. Then run a security-sensitive change so `review-security` is used.
7. Only then add worktrees for parallel jobs, if you actually need them.

Do not add more agents until the simple loop is proven.

---

## 10. What this deliberately does not have

- No `job.json`.
- No Python.
- No state machine.
- No state-machine scripts; the installer and helper CLI are plain bash.
- No router.
- No dashboard.
- No issue tracker. The optional `backlog-triage` uses a local `BACKLOG.md`.
- No issue intake.
- No automatic per-job cost attribution; `pagani usage` prints runtime stats.
- No per-task worktrees unless you run a parallel wave.

The job folder and `job.md` are enough.

---

## 11. Personal stack readiness

Implemented in 0.2.0–0.3.0:

- installer, backups, uninstall, `pagani doctor`, and `pagani lint`
- `resources/` project templates and `pagani init`
- real `scripts/verify` start/stop/flow and `docs/FEATURE-MAP.md`
- lanes and generated model variants
- `pagani job new`, `classify`, `check`, `gate`, and `usage start|end`
- review convergence, `REVIEW.md`, and `review-pr`
- evals with diffs, `run.sh`, recall/noise, and train/test
- `TASKS.md`, `session-handoff`, and `session-retro`
- worktrees, PR helpers, and usage/status commands
- Claude Code agent files, `.claude/settings.json`, and generated `/pagani`
  command

Still partial/optional: full sandbox, network allowlist, per-job spending caps,
backups of `pagani/jobs/`, and prompt-injection defenses. See `GAPS.md`.

The design skills live under `skills/design/`; see
`skills/design/README.md` for sources and licenses. The category explanations
are in `CATEGORIES.md`.
