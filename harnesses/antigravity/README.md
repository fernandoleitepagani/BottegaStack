# Antigravity CLI Harness (Experimental, #46)

Everything in this directory is exclusive to **Antigravity CLI**. Status: **experimental** (see [harnesses/README.md](../README.md#subagent-dispatch-across-harnesses) for subagent dispatch and symlink caveats).

## Install

```bash
./harnesses/antigravity/install.sh
```

This symlinks every skill in `skills/` into `~/.agents/skills/<name>` so Antigravity CLI discovers them automatically (all 20 skills use the standard `SKILL.md` + YAML frontmatter format).

To uninstall:

```bash
./harnesses/antigravity/install.sh --uninstall
```

## Subagents

Roles and tiers are in the router's **Subagents** table ([`skills/maestro/SKILL.md`](../../skills/maestro/SKILL.md#subagents)); this harness's models, spawn fields and paths are in [`skills/maestro/harness/antigravity.md`](../../skills/maestro/harness/antigravity.md).
