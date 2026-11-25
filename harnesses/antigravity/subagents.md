# Antigravity CLI Subagent Mapping

When running Bottega in **Antigravity CLI**, translate the abstract tiers in `skills/maestro/references/models.md` to Antigravity models + effort flags (`low`, `medium`, `high`):

| Abstract tier | Model | Effort | Typical Bottega role |
|---|---|---|---|
| **`heavy`** | `neon` | `medium` | High-risk orchestrator, adversarial crossfire |
| **`medium`** | `neon` | `low` | Complex orchestrator, high-risk implementer/reviewer |
| **`standard`** | `hydrogen` | `medium` | Normal orchestrator, standard implementer/reviewer |
| **`fast`** | `hydrogen` | `low` | Explorers, codebase mapping, read-only fact-finding |

## `invoke_subagent` mapping

| Bottega Role | `TypeName` | `Workspace` |
|---|---|---|
| **Explorer** | `research` | `inherit` |
| **Implementer** | `self` | `share` (or `branch` for parallel writers) |
| **Reviewer** (Spec / Standards) | `research` | `inherit` |
| **Adversarial / Crossfire** | `self` | `share` |

- Always pass the absolute path to `skills/maestro/SKILL.md` in the subagent `Prompt`.
- Antigravity CLI wakes you reactively when subagents finish; never poll.
