# OpenCode Harness (Experimental, #46)

Everything in this directory is exclusive to **OpenCode**. Status: **experimental** (see [harnesses/README.md](../README.md#subagent-dispatch-across-harnesses) for subagent dispatch and symlink caveats).

## Install

```bash
./harnesses/opencode/install.sh
```

Symlinks all 17 skills into `~/.config/opencode/skills/<name>`. Uninstall with `./harnesses/opencode/install.sh --uninstall`.

## Subagents

See [`skills/maestro/references/subagents.md`](../../skills/maestro/references/subagents.md) and [`models.md`](../../skills/maestro/references/models.md) for the role and model-tier mapping (including free-first → OpenCode Go fallback for non-Anthropic models).
