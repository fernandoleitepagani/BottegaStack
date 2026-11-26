# Subagents: roles, types and tiers

Read before your first spawn. Concrete model + effort values come from `references/models.md` (the single source of truth across harnesses).

| Role | Used for | Normal tier | High-risk tier |
|---|---|---|---|
| **orchestrator** | `/plan`, `/tickets`, `/implement`, `/maestro` (the session itself) | per ticket (`standard` / `medium`) | `heavy` |
| **explorer** | read-only mapping, tracing, fact-finding, research questions | `fast` | `fast` |
| **implementer** | writes code and tests in one scope; unattended PR owners | `standard` | `medium` |
| **reviewer** | Spec & Standards review (`review.md`), repros, PR verification | `standard` | `medium` (`heavy` for adversarial crossfire) |

**Harness mapping** (self-contained; concrete model + effort values live in `references/models.md`):

- **Claude Code:** `explorer` → `Explore`; `implementer`/`reviewer` → `bottega:maestro-agent`, `run_in_background: true`, `isolation: "worktree"` beside another writer. Pass both `model` and `effort` from `references/models.md`.
- **Antigravity CLI:** `explorer` and Spec/Standards `reviewer` → `TypeName: research`, `Workspace: inherit`; `implementer` → `TypeName: self`, `Workspace: share` (or `branch` for parallel writers); adversarial/crossfire → `TypeName: self`, `Workspace: share`. Reactive wakeup (never poll).
- **Codex:** translate tiers via `references/models.md` (`sol` / `terra` / `luna`); isolate parallel writers in separate git worktrees.
- **OpenCode:** translate tiers via `references/models.md`; for non-Anthropic models (`deepseek v4.1 flash`, `glm-5.3-flash`), try the free version first and fall back to OpenCode Go if rate-limited or unavailable; isolate parallel writers in separate git worktrees.

**Orchestrator.** `/tickets` picks the lowest abstract tier (`heavy`, `medium`, `standard`, `fast`) that stays precise for both the orchestrator and every subagent. Without a ticket, use `medium` (normal) or `heavy` (high risk). Never switch models mid-session. Context limit: 300k tokens, ±10% (`/implement`).

**Fresh subagents by default.** New work (a fix round, a follow-up, a retry, the next queue item) goes to a fresh subagent with consolidated scope: the original brief, every later directive, and the prior agent's report and branch. Resume an existing subagent only when the work needs state that lives in it and is costly to move.

**Every spawn:** file pointers instead of pasted context, isolated worktree/share beside another writer, and the absolute path of the maestro `SKILL.md` for implementers and reviewers.

**Fan-out ask.** Before spawning more than 3 agents at once, ask the user, unless a full-autonomy grant covers it.
