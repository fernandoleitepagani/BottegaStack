# Codex Harness (Experimental, #46)

Everything in this directory is exclusive to **Codex**. Status: **experimental** (see [harnesses/README.md](../README.md#subagent-dispatch-across-harnesses) for subagent dispatch and symlink caveats).

## Install

```bash
./harnesses/codex/install.sh
```

Symlinks all 16 skills into `~/.codex/skills/<name>`. Uninstall with `./harnesses/codex/install.sh --uninstall`.

## Subagents

See [`skills/maestro/references/subagents.md`](../../skills/maestro/references/subagents.md) and [`models.md`](../../skills/maestro/references/models.md) for the role and model-tier mapping.
