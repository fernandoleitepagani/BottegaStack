# Subagents: roles, types and models

Read before your first spawn. This table is the only place models are chosen.

| Role | `subagent_type` | Used for | Normal | High |
|---|---|---|---|---|
| orchestrator | the session itself | `/grill`, `/tickets`, `/implement`, `/maestro` | per ticket: opus-level or sonnet-level | opus |
| explorer | `Explore` | read-only mapping, tracing, fact-finding, research questions | haiku high | haiku high |
| implementer | `bottega:maestro-agent` | writes code and tests in one scope; unattended PR owners | sonnet low | sonnet medium |
| reviewer | `bottega:maestro-agent` | reviews a finished diff, runs repros, adversarial review, PR verification | sonnet low | sonnet medium |

**Orchestrator.** The ticket names the level (`/tickets` step 5) and the user sets it with `/model` in the ticket's fresh session. Opus-level for high risk, open design decisions, shared interfaces, concurrency, migrations, auth or hard debugging; sonnet-level otherwise. Without a ticket, use opus. Never switch `/model` mid-session. Its context limit is 300k tokens, ±10% (`/implement`).

**Overrides.** `~/.claude/rules/bottega-models.md`, when the user writes one, holds one line per role: `role: <normal model effort> | <high model effort>`. A role with no line uses the table. Pass both `model` and `effort` on every spawn. A rejected model falls back to the role default; say so.

**Effort ceiling.** Never `xhigh` or `max`. Never `high` except on haiku. You may lower effort one step for routine work, never raise it above the table or the user's rule file.

**Adversarial review** (`review.md`) uses the reviewer's High column at any risk.

**Fresh subagents by default.** New work (a fix round, a follow-up, a retry, the next queue item) goes to a fresh subagent with consolidated scope: the original brief, every later directive, and the prior agent's report and branch. Resume an existing subagent only when the work needs state that lives in it and is costly to move (its uncommitted changes, a dev server or watcher it runs).

**Every spawn:** `run_in_background: true`, file pointers instead of pasted context, `isolation: "worktree"` beside another writer. Implementers and reviewers get the absolute path of the maestro `SKILL.md`.

**Fan-out ask.** Before spawning more than 3 agents at once, ask the user, unless a full-autonomy grant covers it.
