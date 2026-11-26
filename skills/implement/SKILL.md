---
name: implement
description: "Run one ticket, or one small direct task, in a fresh session: load it, pick the playbook for its kind (small fix, bug fix, feature, refactoring), follow it to the final gate, and update the ticket. Use for /implement <ticket path>, or when /maestro routes a change that fits one session."
disable-model-invocation: true
---

# Implement

One ticket per fresh session. You orchestrate: you decide, brief, review, and prove. Subagents explore and write. `<maestro dir>` is `../maestro` from this file, as an absolute path.

## 1. Load

- **Ticket mode** (`/implement <path>`): read the ticket and the spec it belongs to. Check that every `Blocked by` ticket says `Status: done`; if one doesn't, stop and say which. Set the ticket to `Status: in-progress`. Its acceptance criteria are your conditions, its risk is your risk, and its **Orchestrator does** and **Subagents** sections are your plan and override the playbook where they differ. A change to that split goes in your reply with the reason.
- **No ticket:** route through maestro's table instead (`<maestro dir>/SKILL.md`, **Route**); the matching playbook runs without `/implement`.

## 2. Pick the playbook

By the ticket's kind, read one of these in `<maestro dir>/playbooks/` and follow it from step 1 (it opens the run):

| Kind | Playbook |
|---|---|
| One file, about 20 changed lines or fewer, normal risk | `small-fix.md` |
| Broken, throwing, or wrong behavior | `bug-fix.md` |
| New behavior | `feature.md` |
| Structure changes, behavior doesn't | `refactoring.md` |

A ticket that mixes kinds runs the structural part as Refactoring first, then the rest.

**Context.** When the session's context is nearly full, finish the current step and run `<maestro dir>/playbooks/pause-safely.md`.

## 3. Close the ticket

After the playbook's final gate:

- **Ticket mode:** tick the acceptance criteria that passed, set `Status: done` (or `blocked: <why>` on ESCALATE), and update the ticket's row in `PLAN.md`. List the tickets this one unblocked and the command to start each, with the model level each one names.

**Reply:** the playbook's reply, then the principles that changed a choice, and the next tickets.
