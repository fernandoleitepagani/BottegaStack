# Codex Harness (Experimental, #46)

Everything in this directory is exclusive to **Codex**. Status: **experimental** (see [harnesses/README.md](../README.md#subagent-dispatch-across-harnesses) for subagent dispatch).

## Install

```bash
codex plugin marketplace add fernandoleitepagani/BottegaStack
codex plugin add bottega@bottega
```

It installs all 20 skills from the root `plugin.json`. Uninstall with `codex plugin remove bottega@bottega`.

## Subagents

Roles and tiers are in the router's **Subagents** table ([`skills/maestro/SKILL.md`](../../skills/maestro/SKILL.md#subagents)); this harness's models, spawn fields and paths are in [`skills/maestro/harness/codex.md`](../../skills/maestro/harness/codex.md).
