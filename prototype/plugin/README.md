# Plugin prototype probe

Throwaway fixture for the PaganiStack stack-simplification research task. It
carries one of each component the report asks about:

- `bin/pagani-probe` — executable, expected on PATH inside a session.
- `agents/prototype-agent.md` — with `hooks:` in its own frontmatter.
- `hooks/hooks.json` — PreToolUse(Bash) and Stop hooks that append to
  `$PROTOTYPE_HOOK_LOG`.
- `commands/pagani.md` — used to discover the invocation name.
- `commands/probe-two.md` — second command, confirms bare-name aliasing.

The marketplace manifest lives one level up at
`prototype/.claude-plugin/marketplace.json`, with `source: "./plugin"`.

See `prototype/REPORT.md` for the answers, commands, and output excerpts.

Note: the agent-frontmatter `hooks:` block is deliberately present but is not
what makes the working hooks fire; plugin-level `hooks/hooks.json` does. The
report explains the negative result for agent-frontmatter hooks.

