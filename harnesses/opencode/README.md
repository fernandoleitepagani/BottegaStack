# OpenCode Harness

Everything in this directory is exclusive to **OpenCode**.

## Install

```bash
./harnesses/opencode/install.sh
```

Symlinks all 16 skills into `~/.config/opencode/skills/bottega-<name>`. Uninstall with `./harnesses/opencode/install.sh --uninstall`.

## Subagents

See [`skills/maestro/references/subagents.md`](../../skills/maestro/references/subagents.md) and [`models.md`](../../skills/maestro/references/models.md) for the role and model-tier mapping (including free-first → OpenCode Go fallback for non-Anthropic models).
