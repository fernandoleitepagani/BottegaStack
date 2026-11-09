# PaganiStack

PaganiStack is a personal agentic development workflow for Claude Code. It turns a request into a verified change and keeps a human in the loop.

The job folder is the state: `pagani/jobs/<id>/`. `job.md` holds only stage,
round, playbook, risk, branch, and base. There is no database, no cloud service,
and no state machine.

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
2. To start every session as the master and let it run builds without a prompt,
   add this to `~/.claude/settings.json`:

```json
{
  "agent": "master",
  "permissions": { "allow": ["Bash(pagani build:*)"] }
}
```

Then run `claude --agent master` (the `agent` setting also does this). Details,
including the manual steps a plugin cannot do: [docs/SETUP.md](docs/SETUP.md).

In a project there is nothing to set up: open Claude Code there and run
`/pagani <request>`. On first use it creates `AGENTS.md`, `CLAUDE.md`,
`scripts/check`, and `.claude/settings.json` (all excluded from git) and asks for
your lint, test, and build commands. Every other project file is created on
demand with `pagani seed <Name>`.

Questions are answered directly; only requests that change code start a job.
`/pagani` still works for `status`, `resume`, and forcing the workflow.

## Quick start

```
/pagani Add an estimated reading time to blog posts
```

The master picks a playbook and risk, creates the job, asks a few questions,
writes a `SPEC.md`, and stops for approval. You drive the rest with `approve`,
`rework <note>`, `reject`, or a question. `/pagani status` and `/pagani resume`
continue a job.

Small work skips the job folder: the master takes the light path on branch
`pagani/quick-<slug>` and runs
`pagani build --here <slug> --task "<text>"`.

Other skills are invoked directly by name, for example `/wizard`,
`/backlog-triage`, `/wayfinding`, `/improve-architecture`, and `/review-pr`.
`/pagani-models` writes the model routing rule for each role.

## Docs

- [docs/WORKFLOW.md](docs/WORKFLOW.md) — the 9 steps, playbooks, risk, agents, job folder, and why it is shaped this way.
- [docs/SKILLS.md](docs/SKILLS.md) — all skills, vendored sources.
- [docs/SETUP.md](docs/SETUP.md) — plugin install, `doctor`, `init`, `seed`, builder, hooks, troubleshooting.

## License

MIT for the PaganiStack code. Vendored skills keep their own licenses; see
[docs/SKILLS.md](docs/SKILLS.md) and the license file in each skill folder.
