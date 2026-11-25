# OpenCode Subagent Mapping

When running Bottega in **OpenCode**, translate the abstract tiers in `skills/maestro/references/models.md` as follows:

| Abstract tier | Model & effort | Typical Bottega role |
|---|---|---|
| **`heavy`** | `opus` `medium` | High-risk orchestrator, adversarial crossfire |
| **`medium`** | `opus` `low` | Complex orchestrator, high-risk implementer/reviewer |
| **`standard`** | `deepseek v4.1 flash` | Normal orchestrator, standard implementer/reviewer |
| **`fast`** | `glm-5.3-flash` | Explorers, codebase mapping, read-only fact-finding |

- **Non-Anthropic model routing:** For non-Anthropic models (`deepseek v4.1 flash`, `glm-5.3-flash`), **always try the free version first, then fall back to OpenCode Go's version** if rate-limited or unavailable.
- Always pass the absolute path to `skills/maestro/SKILL.md` in subagent briefs.
- Isolate parallel writers in separate git worktrees.
