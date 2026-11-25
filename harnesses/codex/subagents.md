# Codex Subagent Mapping

When running Bottega in **Codex**, translate the abstract tiers in `skills/maestro/references/models.md` as follows:

| Abstract tier | Model & effort | Typical Bottega role |
|---|---|---|
| **`heavy`** | `sol` `high` | High-risk orchestrator, adversarial crossfire |
| **`medium`** | `sol` `medium` | Complex orchestrator, high-risk implementer/reviewer |
| **`standard`** | `sol` `low` or `terra` `medium` | Normal orchestrator, standard implementer/reviewer |
| **`fast`** | `luna` `high` | Explorers, codebase mapping, read-only fact-finding |

- Always pass the absolute path to `skills/maestro/SKILL.md` in subagent briefs.
- Isolate parallel writers in separate git worktrees.
