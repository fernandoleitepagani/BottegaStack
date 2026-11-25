# Model Tiers

One global table mapping Bottega's four abstract tiers to each harness's concrete model + effort.

## Tier translation

| Abstract tier | Use when | Claude Code | Gemini / Antigravity CLI | Codex (future) |
|---|---|---|---|---|
| **`heavy`** | High-risk orchestrator, hard architecture, auth/security/concurrency, adversarial crossfire | `opus` `medium` | `neon` `medium` | TBD |
| **`medium`** | Complex multi-file orchestrator, tricky debugging, high-risk implementer/reviewer | `opus` `low` | `neon` `low` | TBD |
| **`standard`** | Normal orchestrator, standard implementers and reviewers | `sonnet` `medium` | `hydrogen` `medium` | TBD |
| **`fast`** | Explorers, codebase mapping, fact-finding, mechanical/read-only research | `haiku` `high` | `hydrogen` `low` | TBD |

## Selection rule (token & limit discipline)

When planning tickets (`/tickets`) or spawning subagents, **always pick the lowest abstract tier that remains as precise as needed**—never default to `heavy` when `standard` or `medium` will do:

- **Orchestrator:** `standard` for well-scoped normal-risk tickets; `medium` for multi-file coordination or tricky debugging; `heavy` for high risk, shared interfaces, migrations, auth, or concurrency.
- **Explorer:** `fast` by default.
- **Implementer / Reviewer:** `standard` for normal risk; `medium` (or `heavy` for adversarial crossfire) at high risk.

## Overrides & ceilings

- **User override:** `~/.bottega/models.md` (or `~/.claude/rules/bottega-models.md` on Claude Code) may override any tier or role with one line per entry.
- **Effort ceiling:** Never `xhigh` or `max`. Never raise effort above the table or the user's override file; you may lower effort one step for routine work.
