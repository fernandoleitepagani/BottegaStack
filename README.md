<p align="center"><img src="assets/banner.svg" alt="BottegaStack" width="760"></p>

<p align="center"><b>A workshop for Claude Code: one master orchestrates cheap builders, and you approve every result.</b></p>

BottegaStack is a personal agentic development workflow for Claude Code. It turns a request into a verified change and keeps a human in the loop.

## What makes it different

- **A master, not a prompt pile.** One agent talks to you. It plans, delegates, checks, and asks; it never writes code itself.
- **Cheap hands, careful eyes.** Builders run headless on a low-cost model (for example DeepSeek through OpenCode Go), in parallel git worktrees. Claude reviews only when the risk or a finding calls for it.
- **Your repo stays clean.** Run state lives in the system temp dir. The record is the chat and the PR or merge commit. No stage files, no database, nothing committed.
- **Hooks enforce it, not hope.** A todo-driven Stop hook keeps a run going; a guard blocks the wrong builder; checks must pass before any review.
- **Human gates only where they matter.** SPEC approval and the final decision; merge, push, and PR are never automatic.
- **Playbooks for real work.** `bugfix`, `feature`, `refactor`, `investigate`, `perf`, `prototype`, `ship`, `autopilot`, `pause`, `eval`, `pr-babysit`, plus 60+ skills including sysadmin, containers, and shell.

A run is one execution of a playbook. Its id is the branch slug, its branch is
the one you are on, and its state lives outside the checkout in a per-repo state
directory in the system temp dir, shared by worktrees. The chat and the PR (or
merge commit) are the human-readable record. There is no database, no cloud
service, and no state machine.

A playbook chooses the pipeline — `trivial`, `bugfix`, `feature`, `refactor`,
`investigate`, `perf`, `prototype`, `ship`, `autopilot`, `pause`, `eval`, and
`pr-babysit` — and a risk modifier (`low`, `standard`, `high`). At Step 0 the
master runs `maestro stack`, confirms the detected profile, and records it in
`AGENTS.md`. Model and effort for each role come from
`~/.claude/rules/bottega-models.md`, written by `/maestro-models`.

## Install

BottegaStack ships as the Claude Code plugin `bottega`. Inside a Claude Code
session:

```
/plugin marketplace add fernandoleitepagani/BottegaStack
/plugin install bottega@bottega
```

The plugin puts `maestro` on `PATH` for the session and provides the `master`
agent, the `/maestro` and `/maestro-models` commands, every skill, and the hooks.
Update with `/plugin` or `claude plugin update bottega@bottega`. Uninstall with
`claude plugin uninstall bottega`.

After installing:

1. In a session, run `maestro build --init` once to create the headless builder's
   `~/.config/bottega/builder.env` and key (both mode 600; the key is never
   printed). `maestro build --check` verifies them.
2. To start every session as the master and let it run maestro commands without a
   prompt, add this to `~/.claude/settings.json`:

```json
{
  "agent": "master",
  "permissions": { "allow": ["Bash(maestro:*)"] }
}
```

Then run `claude --agent master` (the `agent` setting also does this). Details,
including the manual steps a plugin cannot do: [docs/SETUP.md](docs/SETUP.md).

In a project there is nothing to set up: open Claude Code there and run
`/maestro <request>`. On first use it creates `AGENTS.md`, `CLAUDE.md`,
`scripts/check`, and `.claude/settings.json` (all excluded from git) and asks for
your lint, test, and build commands. Every other project file is created on
demand with `maestro seed <Name>`.

Questions are answered directly; only requests that change code start a run.
`/maestro` still works for `status`, `resume`, and forcing the workflow.

## Quick start

```
/maestro Add an estimated reading time to blog posts
```

The master picks a playbook and risk, runs `maestro start "<title>"` to create the
branch and state directory, asks a few questions, has the planner return the
SPEC, saves it with `maestro spec <slug>`, and stops for approval. You drive
the rest with `approve`, `rework <note>`, `reject`, or a question. `/maestro
status` and `/maestro resume` continue a run from the todo list and branch.

Small work skips the spec and worktree: the master takes the light path with
`maestro build --here <slug> --task "<text>"`; state lives in the state directory
under `quick/<slug>/`. `low` risk runs get a cheap headless first-pass review
before the Claude reviewer. Headless builds report `tokens: in <n> out <n>` and
`steps: <n>`; the only stop is the 30-minute builder timeout.

Other skills are invoked directly by name, for example `/wizard`,
`/backlog-triage`, `/wayfinding`, `/improve-architecture`, and `/review-pr`.
`/maestro-models` writes the model routing rule for each role.

## Docs

- [docs/WORKFLOW.md](docs/WORKFLOW.md) — the 9 steps, playbooks, cheap review, risk, effort routing, agents, run state, and why it is shaped this way.
- [docs/SKILLS.md](docs/SKILLS.md) — all skills, categories, vendored and adapted sources.
- [docs/SETUP.md](docs/SETUP.md) — plugin install, `doctor` security checks, `stack`, `init`, `seed`, builder, hooks, troubleshooting.

## License

MIT for the BottegaStack code. Vendored skills keep their own licenses; see
[docs/SKILLS.md](docs/SKILLS.md) and the license file in each skill folder.
