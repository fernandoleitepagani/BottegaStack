# Subagents: roles, types and tiers

Read before your first spawn. Concrete model + effort values come from `references/models.md` (the single source of truth across harnesses).

Difficulty is the run's route: **simple** is `playbooks/small-fix.md`, **medium** normal risk, **hard** high risk. The user's model file (`playbooks/setup.md`, written by `/maestro setup`) overrides any cell.

| Role | Used for | Simple | Medium | Hard |
|---|---|---|---|---|
| **orchestrator** | `/plan`, `/tickets`, `/implement`, `/maestro` (the session itself) | `standard` | per ticket (`standard` / `medium`) | `heavy` |
| **explorer** | read-only mapping, tracing, fact-finding, research questions | `fast` | `fast` | `fast` |
| **implementer** | writes code and tests in one scope; unattended PR owners | (inline) | `standard` | `medium` |
| **reviewer** | Spec and Standards review (`review.md`), PR verification | `standard` | `standard` | `medium` |
| **verifier** | blast-radius checks (`blast-radius.md`), swarm slices and repros (`swarm.md`) | `standard` | `standard` | `heavy` |

**Harness mapping.** How each role is spawned (explorer, delegate, its own worktree) is in `harness/<your harness>.md`; concrete model and effort values are in `references/models.md`.

**Orchestrator.** `/tickets` picks the lowest abstract tier (`heavy`, `medium`, `standard`, `fast`) that stays precise for both the orchestrator and every subagent. Without a ticket, use the orchestrator row in `references/models.md` (**Selection rule**). Never switch `/model` mid-session. Context limit: 300k tokens, ±10% (`/implement`).

**Fresh subagents by default.** New work (a fix round, a follow-up, a retry, the next queue item) goes to a fresh subagent with consolidated scope: the original brief, every later directive, and the prior agent's report and branch. Resume an existing subagent only when the work needs state that lives in it and is costly to move.

**Every spawn:** file pointers instead of pasted context, its own worktree beside another writer, and a delegate brief whose first line makes it read `<maestro dir>/references/delegate.md` (the harness file gives the exact line).

**Fan-out.** More than one parallel worker follows `swarm.md`. Before spawning more than 3 at once, ask the user, unless a full-autonomy grant covers it.
