# Antigravity CLI Harness (Experimental, #46)

Everything in this directory is exclusive to **Antigravity CLI**. Status: **experimental** (see [harnesses/README.md](../README.md#subagent-dispatch-across-harnesses) for subagent dispatch and symlink caveats).

## Install

```bash
./harnesses/antigravity/install.sh
```

This symlinks every skill in `skills/` into `~/.agents/skills/<name>` so Antigravity CLI discovers them automatically (all 16 skills use the standard `SKILL.md` + YAML frontmatter format).

To uninstall:

```bash
./harnesses/antigravity/install.sh --uninstall
```

## Subagents

See [`skills/maestro/references/subagents.md`](../../skills/maestro/references/subagents.md) and [`models.md`](../../skills/maestro/references/models.md) for the role and model-tier mapping.
