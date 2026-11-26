# Harnesses

Bottega's 16 core skills under [`skills/`](../skills/) are harness-agnostic. Each directory here holds the thin installer and adapter for a specific agent harness:

| Harness | Install | Target |
|---|---|---|
| [**Claude Code**](./claude/README.md) | `claude plugin marketplace add <path-or-repo> && claude plugin install bottega@bottega` | Claude Code plugin (`./skills` + `maestro-agent.md`) |
| [**Antigravity CLI**](./antigravity/README.md) | `./harnesses/antigravity/install.sh` | `~/.agents/skills/bottega-<name>` |
| [**Codex**](./codex/README.md) | `./harnesses/codex/install.sh` | `~/.codex/skills/bottega-<name>` |
| [**OpenCode**](./opencode/README.md) | `./harnesses/opencode/install.sh` | `~/.config/opencode/skills/bottega-<name>` |

Abstract model tiers (`heavy`, `medium`, `standard`, `fast`) and per-harness role mappings live in [`skills/maestro/references/models.md`](../skills/maestro/references/models.md) and [`skills/maestro/references/subagents.md`](../skills/maestro/references/subagents.md).
