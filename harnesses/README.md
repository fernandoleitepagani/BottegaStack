# Harnesses

Bottega's 16 core skills under [`skills/`](../skills/) are harness-agnostic. Each directory here holds the thin installer and adapter for a specific agent harness:

| Harness | Status | Install | Target |
|---|---|---|---|
| **Claude Code** | Supported | `claude plugin marketplace add <path-or-repo> && claude plugin install bottega@bottega` | Claude Code plugin (`./skills`) |
| [**Antigravity CLI**](./antigravity/README.md) | Experimental (#46) | `./harnesses/antigravity/install.sh` | `~/.agents/skills/<name>` |
| [**Codex**](./codex/README.md) | Experimental (#46) | `./harnesses/codex/install.sh` | `~/.codex/skills/<name>` |
| [**OpenCode**](./opencode/README.md) | Experimental (#46) | `./harnesses/opencode/install.sh` | `~/.config/opencode/skills/<name>` |

Abstract model tiers (`heavy`, `medium`, `standard`, `fast`) and per-harness role mappings live in [`skills/maestro/references/models.md`](../skills/maestro/references/models.md) and [`skills/maestro/references/subagents.md`](../skills/maestro/references/subagents.md).

## Subagent dispatch across harnesses

- **Every harness** uses its own native subagents; bottega ships no agent definition. Every delegate brief's first line is `Read <maestro dir>/references/delegate.md before starting.`
- **One vocabulary.** Skills use harness-neutral words (explorer, delegate, its own worktree, todo list, fresh session, model file, transcripts). Each harness has one translation file under [`skills/maestro/harness/`](../skills/maestro/harness/) that maps them, the way pstack's `docs/harness/claude-code.md` does.
- **Install layout:** Non-Claude installers symlink each skill under its real name (`<skills dir>/implement -> skills/implement`), so sibling links like `../implement/SKILL.md` resolve whether a harness follows the symlink or normalizes the path text. Because the names are unprefixed, an installer stops before linking anything if a skill of the same name already exists there and isn't a Bottega link. Older `bottega-<name>` links are removed on install and uninstall.
