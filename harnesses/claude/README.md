# Claude Code Harness

Everything in this directory is exclusive to **Claude Code**.

- `agents/maestro-agent.md` — Delegate subagent definition loaded by `.claude-plugin/plugin.json`.
- `.claude-plugin/plugin.json` stays at the repository root because `claude plugin validate .` and `claude plugin install` require it there, pointing to `./skills` and `./harnesses/claude/agents/maestro-agent.md`.
- Note: In Claude Code, `/plan` may clash with the built-in plan mode command; use `/bottega:plan` if needed.
