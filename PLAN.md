# PaganiStack Plan

PaganiStack is a workflow for shipping small, verified changes with an agent and
a human in the loop. It is deliberately narrow: plan, build, check, review,
approve, close. The job folder is the state; there is no database or state
machine.

## Why

Most agent workflows optimize for output. PaganiStack optimizes for a change a
human can trust:

- **A plan before code.** The agent asks questions and writes down the goal,
  users, edge cases, and acceptance criteria.
- **A ticket graph.** Work is split into vertical slices that each fit one fresh
  context and end in a verifiable state.
- **Deterministic checks.** Lint, typecheck, test, and build run before any
  reviewer sees the code.
- **Focused review.** Only the lenses the change needs run, in parallel, with
  fresh context.
- **A human decision.** The approver explains the change and quizzes the human.
  The human merges, reworks, or rejects.
- **A correction loop.** A retro turns repeated findings into a lint rule, test,
  skill edit, or `AGENTS.md` line.

The human is the final approver. The agent never pushes, merges, or deploys
without an explicit instruction.

## The core loop

```
setup + lane
  -> plan
  -> spec
  -> tickets
  -> build
  -> checks
  -> review
  -> fix
  -> approve
  -> human
  -> close
```

The full step detail and commands are in [HOW-IT-WORKS.md](HOW-IT-WORKS.md).
The entry point is [README.md](README.md).

## Lanes

Not every request needs the full pipeline. The master picks a lane at setup and
records it in `job.md`:

| Lane | Use when | What runs |
|---|---|---|
| `trivial` | docs, copy, config only; no behavior change | builder, checks, code review |
| `bugfix` | a reproducible symptom | diagnosis, failing test, one builder, checks, code review |
| `small` | one feature, one area | short interview, plan with acceptance criteria, one ticket, builder, checks, code review |
| `standard` | normal product change | full flow |
| `high-risk` | auth, payments, data, deploy, dependencies, secrets | full flow plus adversarial review, simplify, strong security, strong approver |

Lanes only escalate. A change that starts small and touches a risk path becomes
high-risk; it never quietly downgrades.

## Agents

| Agent | Role |
|---|---|
| `master` | Talks to the human, asks questions, runs checks, posts summaries, executes git only on request. |
| `explorer` | Cheap read-only search and log reading. |
| `planner` | Writes the plan, spec, and ticket graph. |
| `builder` | Implements exactly one ticket and writes a build report. |
| `review-code` | Correctness, simplicity, conventions, tests, spec fidelity. |
| `review-ui` | Visual consistency, responsive layout, contrast, design-system fit. |
| `review-ux` | Flows, states, copy, accessibility, mobile. |
| `review-security` | Access control, input, data exposure, secrets, dependencies. |
| `approver` | Final gate, explainer, and quiz. |

Models are chosen by role and lane. Planning, security, and approval use the
strong tier; search uses the cheap tier; builders and code review use the middle
tier. The installer generates the variants from `agents/models.conf`.

## Skills

Skills are the procedures the agents load. They use the nine Claude Code
categories plus `workflow/` and `design/`:

- `library-api-reference`
- `product-verification`
- `data-analysis`
- `business-automation`
- `scaffolding`
- `code-quality`
- `ci-cd`
- `runbooks`
- `infrastructure-ops`
- `workflow`
- `design`

The core workflow skills are `lanes`, `interview`, `planning`, `implementation`,
`verification`, `review-code`, `review-security`, `approval`, `summary`,
`closeout`, `session-handoff`, `session-retro`, `diagnosis`, and
`untrusted-content`. The rest are situational.

A skill is a folder with a `SKILL.md`. It should say when to trigger, what to
do, and what has gone wrong before. Vendored skills keep their own licenses;
see the vendored-skills table in [HOW-IT-WORKS.md](HOW-IT-WORKS.md).

## Job state

One folder per job. The folder is the state:

```
pagani/jobs/<id>/
  job.md              stage, round, lane, branch, base, budget
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

No `job.json`, no state machine, no router. The agent reads the folder and
continues from `Stage:`.

## Verification and review

Verification is the highest-value habit. The stack gives the agent:

- **Hands:** `scripts/check` and `scripts/verify` start, drive, and stop the app.
- **Eyes:** snapshots and screenshots through `agent-browser`.
- **Map:** `docs/FEATURE-MAP.md` says how to reach each feature and what proves
  it works.

Review is capped. After the first round, reviewers read only the new diff.
Findings are not repeated. A finding needs a file, line, and evidence. Risk
tiers decide how many humans approve.

## Safety and non-goals

- No cloud sessions.
- No paid skills or paid assets.
- No secrets in the repo.
- No push, merge, or deploy without explicit approval.
- Worktrees for parallel builders.
- Permission denies for destructive commands.

Deliberate non-goals:

- Full OS sandboxing.
- A control plane that starts or stops agents.
- A network allowlist for shell or `agent-browser` egress. The opt-in allowlist
  covers Claude `WebFetch` only.
- A hard spending cap. `pagani budget check` asks the master to stop.
- Remote backups. `pagani backup` is local.
- Prompt-injection enforcement. `untrusted-content` is a convention, not a
  sandbox.

## Start here

1. Install and run `pagani doctor`: [README.md](README.md).
2. Read the workflow and commands: [HOW-IT-WORKS.md](HOW-IT-WORKS.md).
3. Run one small job in a real project.
4. Add a UI change, then a security-sensitive change, once the simple loop
   feels right.
5. Add parallel worktrees only when you actually need them.

Keep the loop small. Add automation only when it removes a repeated human task.
