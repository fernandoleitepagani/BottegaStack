# OpenCode Harness (Experimental, #46)

Everything in this directory is exclusive to **OpenCode**. Status: **experimental** (see [harnesses/README.md](../README.md#subagent-dispatch-across-harnesses) for subagent dispatch and symlink caveats).

## Install

```bash
./harnesses/opencode/install.sh
```

Symlinks all 20 skills into `~/.config/opencode/skills/<name>`. Uninstall with `./harnesses/opencode/install.sh --uninstall`.

## Subagents

Roles and tiers are in the router's **Subagents** table ([`skills/maestro/SKILL.md`](../../skills/maestro/SKILL.md#subagents)); this harness's models, spawn fields and paths are in [`skills/maestro/harness/opencode.md`](../../skills/maestro/harness/opencode.md).
