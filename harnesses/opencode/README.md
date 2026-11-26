# OpenCode Harness (Experimental, #46)

Everything in this directory is exclusive to **OpenCode**. Status: **experimental** (see [harnesses/README.md](../README.md#subagent-dispatch-across-harnesses) for subagent dispatch).

## Install

```bash
npx skills add fernandoleitepagani/BottegaStack -g -a opencode
```

Vercel's `skills` CLI installs all 20 skills into `~/.config/opencode/skills/`. Uninstall with `npx skills remove`.

## Subagents

Roles and tiers are in the router's **Subagents** table ([`skills/maestro/SKILL.md`](../../skills/maestro/SKILL.md#subagents)); this harness's models, spawn fields and paths are in [`skills/maestro/harness/opencode.md`](../../skills/maestro/harness/opencode.md).
