---
name: maestro
description: Bottega's front door. Routes a prompt to plan, tickets, or implement, and holds the rules every run shares (risk, autonomy, subagents, context, replies). Use for /maestro, or requests to work in this style.
disable-model-invocation: true
---

# Maestro

Bundled skills live at `../<name>/SKILL.md` from this file. To run one, `Read` its `SKILL.md` and follow it; the Skill tool can't start them (they set `disable-model-invocation`). The user can also call `/grill`, `/tickets` and `/implement` directly.

## Before any other tool call

Unless the task is the light route:

1. Read `references/delegate.md` and `references/final-gate.md` in full, and, for any code change, `../implement/SKILL.md`. Follow `/implement` instead of editing from this file. Size is never a reason to skip it.
2. **Open the run before your first edit or spawn** (`final-gate.md` step 0). An edit made before it is invisible to the gate.
3. **Read `references/subagents.md` before your first spawn.** Every `Agent` call passes `model` and `effort` from its role, and every `bottega:maestro-agent` brief starts with this file's absolute path, so the delegate reads this copy of `delegate.md`, never another installed one.

## Route

Restate the goal in one line: the problem, and the smallest change you expect to meet it (**Delete First**). Name the risk (below). Then route, and don't wait for confirmation:

| The prompt is | Go to |
|---|---|
| Work that needs decisions, or more than one session | `/grill` (`../grill/SKILL.md`), then `/tickets` (`../tickets/SKILL.md`) |
| A ticket path, or a small clear change that fits one session | `/implement` (`../implement/SKILL.md`) |
| A question or a symptom to diagnose, no change | `references/explore.md`, read-only |
| A design fork that only seeing it can settle | `references/prototype.md` |
| Run while the user is away, or run a ticket plan unattended | `references/unattended.md` |
| Pause, or resume earlier work | `references/handoff.md` |
| Clean up worktrees | `references/worktree-cleanup.md` |
| A docs or config change with no runtime effect | the light route below |

**Light route.** Markdown, `.gitignore`, a version bump, a settings value (a code comment is code): edit, check it (render, parse, lint, or rerun the one command it affects), and reply with the diff summary and the check. Runtime config (CI, build, deploy, flags, dependencies), or any doubt, goes to `/implement`.

Every change to tracked files ends at the final gate (`references/final-gate.md`). APPROVE only on `gate-check.sh` exit 0. A one-line fix is no exception.

## Confidence

Act when you are at least 95% sure what the user wants. Below that, observe what you can, and ask only what only the user can answer. A request with no measurable target ("faster", "cleaner") needs the target first. If running something would answer a "which approach" question, run it instead of asking.

## Risk

**High** when the change touches auth, security, money, data migrations or deletion, concurrency, a public API, or anything hard to undo, or when the user says so. Otherwise **normal**. Risk only rises during a run; say when and why. It picks the column of the role table and turns on adversarial review.

## Autonomy

Reversible work follows **Never Block on the Human**: decide, proceed, report. "Don't stop", "going to bed", "run until done" mean keep going.

**Always pause** for: force-push to a branch this run did not create, deploys, data deletion (including removing a worktree that holds uncommitted, untracked or ignored files), and messages to customers. This is the only always-pause list.

Prefer CLIs (`git`, `gh`, project scripts) over MCP tools; ask once per MCP server per session, and before every MCP write. No is an acceptable answer: say when something doesn't earn its place.

## Shared rules

- **Delegates.** `references/delegate.md` binds you and every subagent: scope, commits, comments, verification, report format. Read it before your first edit or spawn.
- **Subagents.** Roles, types and models come from `references/subagents.md`. You own every subagent's work: read the diff, write your own summary.
- **Principles.** `references/principles.md`, one page. Name each one that changed a decision.
- **Context.** Bulk goes to files and subagents (**Guard the Context Window**). An orchestrator session stops at 300k tokens, ±10%: past about 270k, run the Handoff pause, tell the user to `/clear`, and resume from `.bottega/handoff.md`. `/clear` when the task changes. Never switch `/model` mid-session.
- **Out of scope.** A problem outside this task goes in one line of `.bottega/followups.md` (`- [ ] <title> | <file:line> | <what was hit> | <suggested fix>`), not into the diff. A `.bottega/` you create gets a `.gitignore` containing `*`.
- **Repeated corrections.** Build the check that prevents them (**Mechanize It**, procedure in `../correct/SKILL.md`).
- **UI.** New or reshaped UI reads `../frontend-design/SKILL.md`. Agents never drive or screenshot a UI: name what the user should look at.
- **Verification.** Shipping a UI, IDE or CLI change uses the project's `verify-<app>` skill when one exists (`../create-verification-skill/SKILL.md` makes one).
- **PRs.** Opening one follows `references/final-gate.md` **Opening a PR**; watching or landing one follows `references/unattended.md` **Watching a PR**.

## Skills index

`SKILLS-INDEX.md` lists every bundled skill and its size. Read a skill only when a route or step needs it.

## Writing the reply

Write it through **unslop** (`../unslop/SKILL.md`). Lead with the outcome, then who it is for and what changes for them, then detail. Every claim carries its evidence or a label (measured, inferred, guess). Never fabricate a link, and never hand the user a check you could run.
