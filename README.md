# PaganiStack

PaganiStack is a personal agentic development workflow for Claude Code. It turns a request into a verified change and keeps a human in the loop.

A run is one execution of a playbook. Its id is the branch slug, its branch is
`pagani/<slug>`, and its state lives outside the checkout in a per-repo state
directory in the system temp dir, shared by worktrees. The chat and the PR (or
merge commit) are the human-readable record. There is no database, no cloud
service, and no state machine.

## Install

PaganiStack ships as the Claude Code plugin `pagani`. Inside a Claude Code
session:

```
/plugin marketplace add fernandoleitepagani/PaganiStack
/plugin install pagani@pagani
```

The plugin puts `pagani` on `PATH` for the session and provides the `master`
agent, the `/pagani` and `/pagani-models` commands, every skill, and the hooks.
Update with `/plugin` or `claude plugin update pagani@pagani`. Uninstall with
`claude plugin uninstall pagani`.

After installing:

1. In a session, run `pagani build --init` once to create the headless builder's
   `~/.config/pagani/builder.env` and key (both mode 600; the key is never
   printed). `pagani build --check` verifies them.
2. To start every session as the master and let it run pagani commands without a
   prompt, add this to `~/.claude/settings.json`:

```json
{
  "agent": "master",
  "permissions": { "allow": ["Bash(pagani:*)"] }
}
```

Then run `claude --agent master` (the `agent` setting also does this). Details,
including the manual steps a plugin cannot do: [docs/SETUP.md](docs/SETUP.md).

In a project there is nothing to set up: open Claude Code there and run
`/pagani <request>`. On first use it creates `AGENTS.md`, `CLAUDE.md`,
`scripts/check`, and `.claude/settings.json` (all excluded from git) and asks for
your lint, test, and build commands. Every other project file is created on
demand with `pagani seed <Name>`.

Questions are answered directly; only requests that change code start a run.
`/pagani` still works for `status`, `resume`, and forcing the workflow.

## Quick start

```
/pagani Add an estimated reading time to blog posts
```

The master picks a playbook and risk, runs `pagani start "<title>"` to create the
branch and state directory, asks a few questions, has the planner return the
SPEC, saves it with `pagani spec <slug>`, and stops for approval. You drive
the rest with `approve`, `rework <note>`, `reject`, or a question. `/pagani
status` and `/pagani resume` continue a run from the todo list and branch.

Small work skips the spec and worktree: the master takes the light path with
`pagani build --here <slug> --task "<text>"`; state lives in the state directory
under `quick/<slug>/`.

Other skills are invoked directly by name, for example `/wizard`,
`/backlog-triage`, `/wayfinding`, `/improve-architecture`, and `/review-pr`.
`/pagani-models` writes the model routing rule for each role.

## Docs

- [docs/WORKFLOW.md](docs/WORKFLOW.md) — the 9 steps, playbooks, risk, agents, run state, and why it is shaped this way.
- [docs/SKILLS.md](docs/SKILLS.md) — all skills, vendored sources.
- [docs/SETUP.md](docs/SETUP.md) — plugin install, `doctor`, `init`, `seed`, builder, hooks, troubleshooting.

## License

MIT for the PaganiStack code. Vendored skills keep their own licenses; see
[docs/SKILLS.md](docs/SKILLS.md) and the license file in each skill folder.
