# Model Tiers

One global table mapping Bottega's four abstract tiers to each harness's concrete model + effort.

## Tier translation

| Abstract tier | Use when | Claude Code | Gemini / Antigravity CLI | Codex | OpenCode |
|---|---|---|---|---|---|
| **`heavy`** | High-risk orchestrator, hard architecture, auth/security/concurrency, high-risk verifier | `opus` `medium` | `neon` `medium` | `sol` `high` | `opus` `medium` |
| **`medium`** | Complex multi-file orchestrator, tricky debugging, high-risk implementer/reviewer | `opus` `low` | `neon` `low` | `sol` `medium` | `opus` `low` |
| **`standard`** | Normal orchestrator, standard implementers and reviewers | `sonnet` `medium` | `hydrogen` `medium` | `sol` `low` or `terra` `medium` | `deepseek v4.1 flash`* |
| **`fast`** | Explorers, codebase mapping, fact-finding, mechanical/read-only research | `haiku` `high` | `hydrogen` `low` | `luna` `high` | `glm-5.3-flash`* |

*\*OpenCode non-Anthropic models: always try the **free** version first, then fall back to **OpenCode Go's** version if unavailable or rate-limited.*

## Selection rule (token & limit discipline)

When planning tickets (`/tickets`) or spawning subagents, **always pick the lowest abstract tier that remains as precise as needed**; never default to `heavy` when `standard` or `medium` will do:

- **Orchestrator:** `standard` for well-scoped normal-risk tickets; `medium` for multi-file coordination or tricky debugging; `heavy` for high risk, shared interfaces, migrations, auth, or concurrency.
- **Explorer:** `fast` by default.
- **Implementer / Reviewer:** `standard` for normal risk; `medium` at high risk.
- **Verifier** (blast radius, swarm slices): `standard` for normal risk; `heavy` at high risk.

## Overrides & ceilings

- **User override:** `/maestro setup` (`playbooks/setup.md`) writes `~/.bottega/models.md`, with a model and effort per role and difficulty.
- **Effort ceiling:** Never `xhigh` or `max`. Never raise effort above the table or the user's override file; you may lower effort one step for routine work.
