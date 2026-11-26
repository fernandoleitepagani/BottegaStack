# Harnesses

Bottega's 20 core skills under [`skills/`](../skills/) are harness-agnostic. Claude Code, Antigravity and Codex install bottega as a plugin with their own commands; OpenCode installs it with Vercel's `skills` CLI:

| Harness | Status | Install | Target |
|---|---|---|---|
| **Claude Code** | Supported | `claude plugin marketplace add fernandoleitepagani/BottegaStack` then `claude plugin install bottega@bottega` | `.claude-plugin/` (plugin + marketplace) |
| [**Antigravity CLI**](./antigravity/README.md) | Experimental (#46) | `agy plugin install https://github.com/fernandoleitepagani/BottegaStack` | root `plugin.json` |
| [**Codex**](./codex/README.md) | Experimental (#46) | `codex plugin marketplace add fernandoleitepagani/BottegaStack` then `codex plugin add bottega@bottega` | root `plugin.json` + `.agents/plugins/marketplace.json` |
| [**OpenCode**](./opencode/README.md) | Experimental (#46) | `npx skills add fernandoleitepagani/BottegaStack -g -a opencode` | `~/.config/opencode/skills/<name>` |

Abstract model tiers (`heavy`, `medium`, `standard`, `fast`) per role and difficulty are in the router's **Subagents** table ([`skills/maestro/SKILL.md`](../skills/maestro/SKILL.md#subagents)); each harness file under [`skills/maestro/harness/`](../skills/maestro/harness/) holds that harness's **Models** table.

## Subagent dispatch across harnesses

- **Every harness** uses its own native subagents; bottega ships no agent definition. Every delegate brief's first line is `Read <maestro dir>/worker.md before starting.`
- **One vocabulary.** Skills use harness-neutral words (explorer, delegate, its own worktree, todo list, fresh session, model file, transcripts). Each harness has one translation file under [`skills/maestro/harness/`](../skills/maestro/harness/) that maps them, the way pstack's `docs/harness/claude-code.md` does.
- **Manifests.** Claude Code reads `.claude-plugin/`; Antigravity and Codex read the root `plugin.json` (one file, as pstack's root `plugin.json`); Codex also reads `.agents/plugins/marketplace.json`.
- **OpenCode.** `npx skills add … -a opencode` installs each skill under its real name in one folder, so sibling links like `../implement/SKILL.md` resolve.
