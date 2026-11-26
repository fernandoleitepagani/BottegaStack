---
name: maestro
description: Bottega's front door. Routes a prompt to one playbook or skill, and holds the few rules every run shares (risk, autonomy, subagents, context, replies). Use for /maestro, or requests to work in this style.
disable-model-invocation: true
---

# Maestro

You are the router. Pick one playbook or skill per task and read only that one; it names any shared reference at the step that needs it.

- Playbooks: `playbooks/<name>.md` next to this file.
- Skills: `../<name>/SKILL.md`. Read its `SKILL.md` and follow it (your harness file says how a bundled skill is run).
- Shared references: `references/<name>.md`, read only when a step names one.
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
| Work that needs decisions, or more than one session | `/plan` (`../plan/SKILL.md`) → `/sharpen` → `/tickets` |
| A question, or a symptom to diagnose, no change | `playbooks/investigation.md` |
| "Catch me up", or the end of an unattended run | `playbooks/investigation.md` (**Catch-up**) |
| "What could this break", or a small diff the user doesn't trust | `references/blast-radius.md`, read-only on product code |
| A design fork that only seeing it can settle | `playbooks/prototype.md` |
| Pick up earlier work or context from prior sessions and `.bottega/` | `playbooks/pickup.md` |
| Pause now | `playbooks/pause.md` |
| Ship a verified, gate-approved diff (`/ship stop` draft PR or `/ship full` to merge) | `/ship` (`../ship/SKILL.md`) |
| Run while the user is away, or run a ticket plan unattended | `/autopilot` (`../autopilot/SKILL.md`) |
| Write or change a skill | `playbooks/authoring-a-skill.md` |
| Clean up worktrees | `playbooks/worktree-cleanup.md` |
| Configure which models and efforts bottega uses (`/maestro setup`) | `playbooks/setup.md` |
| Anything else a skill covers: a rough idea (`/reframe`), several reports (`/triage`), a repeated mistake (`/correct`, `/correct scan`), prose (`/unslop`), UI direction (`/frontend-design`), proving or keeping app behavior verifiable (`/create-verification-skill`, `/maintain-verification-skill`), a step only the user can do (`/wizard`) | the skill at `../<name>/SKILL.md`; `SKILLS-INDEX.md` says when each fits |
| A docs or config change with no runtime effect | the light route below |

**Light route.** Markdown, `.gitignore`, a version bump, a settings value (a code comment is code): edit, check it (render, parse, lint, or rerun the one command it affects), and reply with the diff summary and the check. Runtime config (CI, build, deploy, flags, dependencies), or any doubt, goes to a code playbook.

**The gate.** Every code playbook opens the run as its first step (`bottega start`) and ends at the final gate (`references/final-gate.md`). An edit made before the run opens is invisible to the gate. APPROVE only on `bottega verify` (or `gate-check.sh`) exit 0. A one-line fix is no exception. Read-only playbooks skip the ledger and still state their evidence.

## Confidence

Act when you are at least 95% sure what the user wants. Below that, observe what you can, and ask only what only the user can answer. A request with no measurable target ("faster", "cleaner") needs the target first. If running something would answer a "which approach" question, run it instead of asking.

## Risk

**High** when the change touches auth, security, money, data migrations or deletion, concurrency, a public API, or anything hard to undo (one-way doors), or when the user says so. Otherwise **normal** (two-way doors). Risk only rises during a run; say when and why, and move from `small-fix` to the full playbook when it does. It picks the column of the role table, turns on the high-risk review (blast radius or a verifier swarm), and forces one-way doors to `/ship stop` (draft PR).

## Autonomy

Reversible work follows **Never Block on the Human**: decide, proceed, report. "Don't stop", "going to bed", "run until done" mean keep going.

**Always pause** for: force-push to a branch this run did not create, deploys, data deletion (including removing a worktree that holds uncommitted or untracked files, or `.bottega/` run state), bypassing forge-enforced approvals, and messages to customers. This is the only always-pause list. When a pause needs the user to act, not just approve, hand them a wizard (`../wizard/SKILL.md`) instead of a list of steps.

Prefer CLIs (`git`, `gh`, project scripts) over MCP tools; ask once per MCP server per session, and before every MCP write. No is an acceptable answer: say when something doesn't earn its place.

## Subagents

Before your first spawn, read `references/subagents.md`, your harness file, and `~/.bottega/models.md` (from `/maestro setup`) if present.

- Every spawn sets the model and effort for its role and difficulty, passes file pointers instead of pasted context, and runs a writer in its own worktree beside another writer.
- Every delegate brief starts with this file's absolute path, so the delegate reads this copy of `references/delegate.md` itself. Read `delegate.md` yourself only when you write code.
- Fresh subagents by default; more than one in parallel follows `references/swarm.md`.
- You own every subagent's work: read the diff, write your own summary.

## Shared rules

- **Principles.** `references/principles.md`, one page. Name each one that changed a decision.
- **Context.** Bulk goes to files and subagents (**Guard the Context Window**). An orchestrator session stops at 300k tokens, ±10%: past about 270k, run `playbooks/pause.md`, tell the user to `/clear`, and resume with `playbooks/pickup.md`. `/clear` when the task changes. Never switch `/model` mid-session.
- **Out of scope.** Log problems outside this task by appending `- [ ] <title> | <file:line> | <what was hit> | <suggested fix>` to `.bottega/followups.md`, not into the diff.
- **Repeated corrections.** Build the check that prevents them (**Mechanize It**, procedure in `../correct/SKILL.md`).
- **UI.** Agents never drive or screenshot a UI: name what the user should look at. Shipping a UI, IDE or CLI change uses the project's `verify-<app>` skill when one exists.
- **PRs.** Opening, watching, and landing PRs follow `../ship/SKILL.md`.

`SKILLS-INDEX.md` lists every skill and playbook with its size.

## Writing the reply

Write it through **unslop** (`../unslop/SKILL.md`). Lead with the outcome, then who it is for and what changes for them, then detail. Every claim carries its evidence or a label (measured, inferred, guess). Never fabricate a link, and never hand the user a check you could run.
