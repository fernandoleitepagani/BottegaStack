# Antigravity CLI Harness

Everything in this directory is exclusive to **Antigravity CLI**.

## Install

```bash
./harnesses/antigravity/install.sh
```

This symlinks every skill in `skills/` into `~/.agents/skills/bottega-<name>` so Antigravity CLI discovers them automatically (all 12 skills use the standard `SKILL.md` + YAML frontmatter format).

To uninstall:

```bash
./harnesses/antigravity/install.sh --uninstall
```

## Subagents

See [`subagents.md`](./subagents.md) for the role-to-`invoke_subagent` mapping.
