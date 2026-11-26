# Antigravity CLI Harness (Experimental, #46)

Everything in this directory is exclusive to **Antigravity CLI**. Status: **experimental** (see [harnesses/README.md](../README.md#subagent-dispatch-across-harnesses) for subagent dispatch).

## Install

```bash
agy plugin install https://github.com/fernandoleitepagani/BottegaStack
```

It installs all 20 skills from the root `plugin.json`. Uninstall with `agy plugin uninstall bottega`.

## Subagents

Roles and tiers are in the router's **Subagents** table ([`skills/maestro/SKILL.md`](../../skills/maestro/SKILL.md#subagents)); this harness's models, spawn fields and paths are in [`skills/maestro/harness/antigravity.md`](../../skills/maestro/harness/antigravity.md).
