# PaganiStack Design

PaganiStack is a workflow for shipping small, verified changes with an agent and
a human in the loop. It is deliberately narrow: spec, build, check, review,
approve, close. The job folder is the state; there is no database or state
machine.

The step-by-step detail is in [WORKFLOW.md](WORKFLOW.md). This file explains why
the workflow is shaped this way, what the simplification removed, and what the
stack deliberately does not do.

## Why

Most agent workflows optimize for output. PaganiStack optimizes for a change a
human can trust:

- **A spec before code.** The agent asks questions and writes down the goal,
  users, edge cases, acceptance criteria, and a task graph.
- **A task graph.** Work is split into vertical slices that each fit one fresh
  context and end in a verifiable state.
- **Deterministic checks.** Lint, typecheck, test, and build run before any
  reviewer sees the code.
- **One focused review.** A single reviewer reads the diff with fresh context
  and checks code, UI, UX, and security.
- **A human decision.** The master explains the change and, on `standard` and
  `high-risk` jobs, quizzes the human. The human merges, reworks, or rejects.
- **A correction loop.** A retro turns repeated findings into a lint rule, test,
  skill edit, or `AGENTS.md` line.

The human is the final approver. The agent never pushes, merges, or deploys
without an explicit instruction.

## The core loop

```
setup + lane -> SPEC -> build -> checks -> review -> fix -> approval -> human decision -> close
```

Each step ends in an artifact in the job folder, so any runtime can resume from
`Stage:` in `job.md`.

## Simplification rationale

The first versions of PaganiStack grew by adding a step for every concern. That
made the pipeline thorough but slow to start, expensive to run, and hard to
reason about. The current design collapses the same guarantees into fewer
moving parts.

### One planning pass

The old flow ran `plan -> spec -> tickets`: three planning artifacts, three
checkpoints, and three chances to drift. Now `interview` gathers the facts and
`planner` writes one `SPEC.md` containing the requirements, decisions, and the
tracer-bullet task graph. The master reads the graph directly.

Why: a single artifact is easier for the human to approve, easier for builders to
follow, and impossible to leave half-updated. There is no `job frontier` command
because the graph is small enough to read.

### One reviewer

The old flow spawned separate `review-code`, `review-ui`, `review-ux`, and
`review-security` reviewers. They duplicated context loading, produced four
verdicts, and often disagreed about the same lines. Now one `review-code`
reviewer runs the four checklists in one pass and returns one verdict.

Why: most changes touch one or two areas. Loading four fresh contexts to say
"not applicable" in three of them wastes tokens and time. The checklists stay
separate inside the report, so a security-sensitive change still gets a security
review; it just happens in the same review.

### The master as approver

The old flow had a separate `approver` agent. It re-read artifacts the master had
already read, then handed the decision back to the master. Now the master loads
`approval`, writes `decision.md`, and presents the explainer and quiz itself.

Why: the master already holds the job context. A separate approver added a
handoff and a second model call without adding independence — it read the same
files.

### State-only `job.md` and lane-aware approval

`job.md` holds only `Stage`, `Round`, `Lane`, `Lane-reason`, `Branch`, and
`Base`. The checklist moved nowhere: `SPEC.md` carries the task graph and the
project-level `TASKS.md` carries long-run work. Duplicate job artifacts are gone:
the decision is appended to `decision.md`, the findings stay in the review file,
and the final `summary.md` is written once.

The quiz scales with the lane. `standard` and `high-risk` get 3-5 questions;
`trivial`, `bugfix`, and `small` get a short explainer and no quiz. The goal is
to spend the human's attention where the risk is, not on ceremony.

### Fewer commands

The CLI is eight top-level commands: `install` (with `--uninstall`), `doctor`,
`init`, `upgrade`, `job`, `worktree`, `hooks`, and `network`. `job` owns the
lifecycle subcommands. `doctor` absorbs lint. `install --uninstall` replaces a
separate `uninstall` command.

Why: a small command surface is easier to document, test, and remember. Commands
that only wrapped a shell one-liner (`frontier`, `classify`, `route`) were
removed; the master does those checks directly.

## What was deliberately removed

| Removed | Why |
|---|---|
| `plan.md`, `spec.md`, `tickets/` | Replaced by one job `SPEC.md` with a task graph. |
| `job frontier`, `job classify`, `job route` | The master reads `SPEC.md` and checks the diff directly. |
| Separate `uninstall` command | `pagani install --uninstall` keeps install and removal together. |
| Dashboard, usage snapshots, and metrics | `job.md`, `checks.md`, and the retro scan are the state; `pagani job report` reads them directly. |
| Duplicate artifacts | The decision lives in `decision.md`, findings in the review file, tasks in `SPEC.md` and the project `TASKS.md`, and the summary once at the job root. |
| `review-ui`, `review-ux`, `review-security` agents and skills | Folded into the `review-code` checklists. |
| `approver` agent and skill | The master writes `decision.md` and presents it. |
| Security and approval model variants | One reviewer, one approver; variants scale by lane instead. |
| Old project plan template | Project docs are `SPEC.md`, `ROADMAP.md`, and `TASKS.md`. |
| Design skills, `ci-cd`, `weekly-review` | Out of scope for a personal workflow. |

## Trade-offs

- **One reviewer can miss a specialist issue.** The checklists and the
  `high-risk` lane (adversarial review, `simplify`, `review-code-strong`) cover
  the gap. If a change needs a dedicated specialist, run that skill by name.
- **One planning pass can under-specify a large job.** `standard` and
  `high-risk` jobs still get the full interview, and the planner returns open
  questions instead of inventing answers.
- **The master is busier.** It now writes `decision.md` and runs the approval
  presentation. That is the cost of removing a handoff.
- **The CLI is smaller but less discoverable.** `pagani help` lists the
  supported surface; the docs explain the rest.

## Non-goals

- Full OS sandboxing.
- A control plane that starts or stops agents.
- A network allowlist for shell or `agent-browser` egress. The opt-in allowlist
  covers Claude `WebFetch` only.
- Cost tracking, a spending cap, backups, a weekly timer, or a GitHub Actions
  workflow. Those belong to the project, not the stack.
- Prompt-injection enforcement. `untrusted-content` is a convention, not a
  sandbox.
- Cloud sessions and paid skills.

## Start here

1. Install and run `pagani doctor`: [SETUP.md](SETUP.md).
2. Read the workflow and commands: [WORKFLOW.md](WORKFLOW.md).
3. Browse the skills: [SKILLS.md](SKILLS.md).
4. Run one small job in a real project.
5. Add a UI change, then a security-sensitive change, once the simple loop
   feels right.
6. Add parallel worktrees only when you actually need them.

Keep the loop small. Add automation only when it removes a repeated human task.
