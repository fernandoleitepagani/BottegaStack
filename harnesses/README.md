# Harnesses

Bottega's 16 core skills under [`skills/`](../skills/) are harness-agnostic. Each directory here holds the thin installer and adapter for a specific agent harness:

| Harness | Status | Install | Target |
|---|---|---|---|
| [**Claude Code**](./claude/README.md) | Supported | `claude plugin marketplace add <path-or-repo> && claude plugin install bottega@bottega` | Claude Code plugin (`./skills` + `maestro-agent.md`) |
| [**Antigravity CLI**](./antigravity/README.md) | Experimental (#46) | `./harnesses/antigravity/install.sh` | `~/.agents/skills/<name>` |
| [**Codex**](./codex/README.md) | Experimental (#46) | `./harnesses/codex/install.sh` | `~/.codex/skills/<name>` |
| [**OpenCode**](./opencode/README.md) | Experimental (#46) | `./harnesses/opencode/install.sh` | `~/.config/opencode/skills/<name>` |

Abstract model tiers (`heavy`, `medium`, `standard`, `fast`) and per-harness role mappings live in [`skills/maestro/references/models.md`](../skills/maestro/references/models.md) and [`skills/maestro/references/subagents.md`](../skills/maestro/references/subagents.md).

## Subagent dispatch across harnesses

- **Claude Code** ships [`harnesses/claude/agents/maestro-agent.md`](./claude/agents/maestro-agent.md) via `.claude-plugin/plugin.json`, so implementers and reviewers run as `subagent_type: "bottega:maestro-agent"` and explorers run as built-in `Explore`.
- **Antigravity CLI, Codex, and OpenCode (experimental)** do not ship a separate agent manifest. The orchestrator dispatches subagents with the harness's native subagent tool using the role/tier table in `subagents.md` + `models.md`, and prepends the absolute path to `skills/maestro/references/delegate.md` to every delegate brief.
- **Install layout:** Non-Claude installers symlink each skill under its real name (`<skills dir>/implement -> skills/implement`), so sibling links like `../implement/SKILL.md` resolve whether a harness follows the symlink or normalizes the path text. Because the names are unprefixed, an installer stops before linking anything if a skill of the same name already exists there and isn't a Bottega link. Older `bottega-<name>` links are removed on install and uninstall.
