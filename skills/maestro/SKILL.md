---
name: maestro
description: Bottega's front door. Routes a prompt to one playbook or skill, and holds the few rules every run shares (risk, autonomy, subagents, context, replies). Use for /maestro, or requests to work in this style.
disable-model-invocation: true
---

# Maestro

You are the router. Pick one playbook or skill per task and read only that one; it names any other file at the step that needs it.

- Playbooks: `playbooks/<name>.md` next to this file.
- Skills: `../<name>/SKILL.md`. Read its `SKILL.md` and follow it (your harness file says how a bundled skill is run).
- `<maestro dir>` is the absolute directory of this file.
- **Harness words.** Skills say *explorer*, *delegate*, *its own worktree*, *todo list*, *ask the user* and *transcripts*. Before your first spawn, read `harness/<your harness>.md` (`claude-code`, `antigravity`, `codex`, `opencode`) once; it maps each word to this harness. Every harness shares `/clear` (fresh session) and `/model` (session model), and the model file is `~/.bottega/models.md`.

## Route

Restate the goal in one line: the problem, and the smallest change you expect to meet it (**Delete First**). Name the risk (below). Then route, and don't wait for confirmation:

| The prompt is | Go to |
|---|---|
| A small, clear code fix: one file, about 20 changed lines or fewer, normal risk | `playbooks/small-fix.md` |
| A bug to fix (broken, throwing, wrong output) | `playbooks/bug-fix.md` |
| New behavior that fits one session | `playbooks/feature.md` |
| Restructure without changing behavior: rename, move, extract, delete, migrate callers | `playbooks/refactoring.md` |
| A ticket path | `/implement` (`../implement/SKILL.md`), which picks one of the four above |
| Large or unusual work no playbook fits (a migration, an ambitious multi-part change) | `playbooks/figure-it-out.md` |
| Work that needs decisions, or more than one session | `/plan` (`../plan/SKILL.md`) → `/sharpen` → `/tickets` |
| A question, or a symptom to diagnose, no change | `playbooks/investigation.md` |
| "Catch me up", or the end of an unattended run | `playbooks/investigation.md` (**Catch-up**) |
| "What could this break", or a small diff the user doesn't trust | `/blast-radius` (`../blast-radius/SKILL.md`), read-only on product code |
| A design fork that only seeing it can settle | `playbooks/prototype.md` |
| Pick up earlier work or context from prior sessions and `.bottega/` | `playbooks/session-pickup.md` (it runs `/recall`) |
| Pause now | `playbooks/pause-safely.md` |
| Ship a verified, gate-approved diff (`/ship stop` draft PR or `/ship full` to merge) | `/ship` (`../ship/SKILL.md`) |
| Babysit an existing PR, or land a stack of PRs | `/ship` (`../ship/SKILL.md`, **Existing PR or Stack**) |
| Runtime config (CI, build, deploy, flags, dependencies) or a data migration | `playbooks/bug-fix.md` if it repairs something, else `playbooks/feature.md`; migrations are high risk |
| Run while the user is away, or run a ticket plan unattended | `/autopilot` (`../autopilot/SKILL.md`) |
| Write or change a skill | `playbooks/authoring-a-skill.md` |
| Clean up worktrees | `playbooks/worktree-cleanup.md` |
| Configure which models and efforts bottega uses (`/maestro setup`) | `/setup-bottega` (`../setup-bottega/SKILL.md`) |
| Anything else a skill covers: a rough idea (`/reframe`), several reports (`/triage`), a repeated mistake (`/correct`, `/correct scan`), prose (`/unslop`), UI direction (`/frontend-design`), proving or keeping app behavior verifiable (`/create-verification-skill`, `/maintain-verification-skill`), a step only the user can do (`/wizard`), a two-axis review (`/review`), a parallel fan-out (`/swarm`) | the skill at `../<name>/SKILL.md`; its `description` says when it fits |
| A docs or config change with no runtime effect | the light route below |

**Light route.** Markdown, `.gitignore`, a version bump, a settings value (a code comment is code): edit, check it (render, parse, lint, or rerun the one command it affects), and reply with the diff summary and the check. Runtime config (CI, build, deploy, flags, dependencies), or any doubt, goes to a code playbook.

**The gate.** Every code playbook opens the run as its first step (`bottega start`) and ends at the final gate (`playbooks/final-gate.md`). An edit made before the run opens is invisible to the gate. APPROVE only on `bottega verify` (or `gate-check.sh`) exit 0. A one-line fix is no exception. Read-only playbooks skip the ledger and still state their evidence.

## Confidence

Act when you are at least 95% sure what the user wants. Below that, observe what you can, and ask only what only the user can answer. A request with no measurable target ("faster", "cleaner") needs the target first. If running something would answer a "which approach" question, run it instead of asking.

## Risk

**High** when the change touches auth, security, money, data migrations or deletion, schema drops, concurrency, a breaking public API, destructive infra or deploy scripts, or anything hard to undo (one-way doors), or when the user says so. This is the one list of one-way doors; `/ship` and `/autopilot` link here. Otherwise **normal** (two-way doors). Risk only rises during a run; say when and why, and move from `small-fix` to the full playbook when it does. It picks the column of the role table, turns on the high-risk review (blast radius or a verifier swarm), and forces one-way doors to `/ship stop` (draft PR).

## Autonomy

Reversible work follows **Never Block on the Human**: decide, proceed, report. "Don't stop", "going to bed", "run until done" mean keep going.

**Always pause** for: force-push to a branch this run did not create, deploys, data deletion (including removing a worktree that holds uncommitted or untracked files, or `.bottega/` run state), bypassing forge-enforced approvals, and messages to customers. This is the only always-pause list. When a pause needs the user to act, not just approve, hand them a wizard (`../wizard/SKILL.md`) instead of a list of steps.

Prefer CLIs (`git`, `gh`, project scripts) over MCP tools; ask once per MCP server per session, and before every MCP write. No is an acceptable answer: say when something doesn't earn its place.

## Subagents

Before your first spawn, read your harness file (`harness/<your harness>.md`: how to spawn, and its **Models** table) and `~/.bottega/models.md` (from `/setup-bottega`) if present; a line there overrides the defaults below.

| Role | Used for | Simple (small fix) | Medium (normal risk) | Hard (high risk) |
|---|---|---|---|---|
| **orchestrator** | the session itself | `standard` | per ticket (`standard` / `medium`) | `heavy` |
| **explorer** | read-only mapping, tracing, research | `fast` | `fast` | `fast` |
| **implementer** | code and tests in one scope | inline | `standard` | `medium` |
| **reviewer** | `/review`, PR verification | `standard` | `standard` | `medium` |
| **verifier** | `/blast-radius`, `/swarm` slices and repros | `standard` | `standard` | `heavy` |

- Pick the lowest tier that stays precise; lower effort one step for routine work, never raise it, and never use `xhigh` or `max`.
- Every spawn sets the model and effort for its role and difficulty, passes file pointers instead of pasted context, and runs a writer in its own worktree beside another writer.
- Every delegate brief's first line is `Read <maestro dir>/worker.md before starting.` Read `worker.md` yourself when you write code (small-fix carries the four rules it needs inline).
- Fresh subagents by default: a fix round, follow-up, retry or next queue item goes to a new one with the original brief, later directives, and the prior report and branch.
- More than one in parallel follows `/swarm` (`../swarm/SKILL.md`). Ask before spawning more than 3 at once, unless a full-autonomy grant covers it.
- You own every subagent's work: read the diff, write your own summary.

## Shared rules

- **Principles.** `principles.md`, one page. Name each one that changed a decision.
- **Context.** Bulk goes to files and subagents (**Guard the Context Window**). When the session's context is nearly full (the harness warns or is about to compact), run `playbooks/pause-safely.md`, tell the user to `/clear`, and resume with `playbooks/session-pickup.md`. `/clear` when the task changes. Never switch `/model` mid-session.
- **Out of scope.** Log problems outside this task by appending `- [ ] <title> | <file:line> | <what was hit> | <suggested fix>` to `.bottega/followups.md`, not into the diff.

## Writing the reply

Write it through **unslop** (`../unslop/SKILL.md`). Lead with the outcome, then who it is for and what changes for them, then detail. Every claim carries its evidence or a label (measured, inferred, guess). Never fabricate a link, and never hand the user a check you could run.
