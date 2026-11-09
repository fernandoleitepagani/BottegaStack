# Setup

## Requirements

- Claude Code with plugin support.
- `gh` for PR helpers.
- `python3` for `pagani upgrade` (settings merge).
- Optional: `gitleaks` for the secret pre-commit hook.
- Optional: `agent-browser` for browser checks.

## Install

PaganiStack ships as the Claude Code plugin `pagani`. Inside a session:

```
/plugin marketplace add fernandoleitepagani/PaganiStack
/plugin install pagani@pagani
```

Or from a shell:

```bash
claude plugin marketplace add fernandoleitepagani/PaganiStack
claude plugin install pagani@pagani -y
```

The plugin provides:

- `bin/pagani` on `PATH` inside a session.
- The agents `master`, `explorer`, `planner`, `builder`, and `review-code`
  (also reachable as `pagani:<name>`).
- The commands `/pagani` and `/pagani-models` (also
  `/<plugin>:<command>`).
- Every skill from the category directories listed in the plugin manifest.
- The hooks in `hooks/hooks.json`: PreToolUse `Agent|Task` runs
  `pagani guard builder`, and Stop runs `pagani guard stop`.

Update with `/plugin` or `claude plugin update pagani@pagani`. Uninstall with
`claude plugin uninstall pagani`; remove the marketplace with
`claude plugin marketplace remove pagani`.

### Manual steps

A plugin cannot change your global Claude Code config, so set these yourself:

- The plugin does not merge keys into `~/.claude/settings.json`. To start every
  session as the master and let it run builds without a prompt, add:

  ```json
  {
    "agent": "master",
    "permissions": { "allow": ["Bash(pagani build:*)"] }
  }
  ```

  `claude --agent master` works without the `agent` key.
- The plugin does not write `~/.claude/CLAUDE.md`. Put global instructions
  there yourself.
- The plugin does not install a launcher into `~/.local/bin`. `pagani` is on
  `PATH` only inside a session. Remove an old `~/.local/bin/pagani` left by the
  previous installer so it does not shadow the plugin's copy.

### Builder key

The headless builder is global; nothing is copied into projects.

```bash
pagani build --init     # creates builder.env, then asks for your key (hidden)
pagani build --check    # verifies both without printing them
```

- `~/.config/pagani/builder.env` (mode 600) holds the endpoint and model names
  only. The defaults target OpenCode Go and `deepseek-v4.1-flash`.
- `~/.config/pagani/builder.key` (mode 600) holds the API key. It reaches
  `claude` through an `apiKeyHelper` (`pagani keyget`), so it is never in the
  builder's environment or argv. An `ANTHROPIC_AUTH_TOKEN=` line in
  `builder.env` still works as a fallback.

Without these files, `/pagani` falls back to the Claude `builder` subagent.

## Doctor

```bash
pagani doctor
```

`doctor` prints the runtime and tool versions, the skill count, missing upstream
skills, `AGENTS.md` size, project Claude settings, hook status, config paths, and
then runs the repo lint when `scripts/lint.sh` sits beside the CLI. It is the
release gate:

```bash
./scripts/validate.sh
```

`scripts/validate.sh` runs `./bin/pagani doctor`.

## Init a project

```bash
cd ~/Projects/my-project
pagani init
```

You normally never run this: the first `/pagani` request in a project runs it for
you (through `pagani job new`) and then asks you for the project's lint, test,
and build commands to fill in `scripts/check`. Run `pagani init` yourself only to
set a project up without starting a job.

`init` creates only what the workflow needs to start:

- `AGENTS.md` (with the coding standards).
- `CLAUDE.md` (imports `AGENTS.md`).
- `scripts/check`.
- `.claude/settings.json`.
- `pagani/jobs/`.
- The managed block in `.git/info/exclude` and, when `.git` exists, the git
  hooks.

**None of these files is ever committed.** `init` lists them in
`.git/info/exclude` (local, shared by worktrees, never committed), so `git status`
stays clean, your `.gitignore` is not touched, and `pagani job new` sees a clean
tree. The pre-commit hook also refuses to stage a newly added pagani file. A file
your project already tracked (say its own `AGENTS.md`) is left alone and stays
tracked. `pagani worktree create` copies the files into each task worktree, since
untracked files are not part of a checkout.

## Project files on demand

Everything else is created only when a skill first needs it. `pagani seed <Name>`
copies one template from the plugin's `resources/` directory and is idempotent:
it prints `created:` or `kept:`.

| Name | Destination |
|---|---|
| `SPEC.md`, `PLAN.md`, `REVIEW.md`, `GLOSSARY.md`, `BACKLOG.md`, `mistakes.md` | the repo root |
| `FEATURE-MAP.md` | `docs/FEATURE-MAP.md` |
| `verify` | `scripts/verify` and `scripts/verify.conf` |

The skills seed what they use: `planning` seeds `SPEC.md` and `PLAN.md`,
`session-retro` seeds `mistakes.md`, `backlog-triage` seeds `BACKLOG.md`,
`domain-modeling` seeds `GLOSSARY.md`, and `verification` seeds `FEATURE-MAP.md`
and `verify`. A missing `REVIEW.md` means there are no risk paths; the master
seeds it only when a risk path is first needed.

## Upgrade a project

```bash
cd ~/Projects/my-project
pagani upgrade
```

`upgrade` refreshes `.claude/settings.json` without dropping your settings,
removes the retired `scripts/claude-hook.sh` and `scripts/opencode-build`, and
re-applies the exclude block and git hooks. It no longer creates the on-demand
project files and never deletes the ones you have. It needs `python3` to merge
`.claude/settings.json`.

## Headless builder (`pagani build`)

The builder runs as `claude -p --agent builder` on a third-party model through
an Anthropic-compatible endpoint.

```bash
pagani build <job> <task> [--revise <findings-file>] [--block]
pagani build --here <slug> --task "<text>" [--block]
pagani build --review <job> <task> [--block]
pagani build --status <job> [--every <seconds>]
```

- `--here` is the light path: it needs no job, SPEC, or worktree, builds in the
  current checkout on the current branch, and keeps state in
  `pagani/quick/<slug>/` (`run`, `rc`, `progress`, `prompt`, `report.md`,
  `builder.log`).
- `--review` runs the read-only `review-code` agent in the task worktree on the
  third-party model and writes findings to
  `pagani/jobs/<job>/build/<task>.review2.md`. It cannot edit or commit.
- `--block` waits until the build ends, for a background Bash task. Without it,
  the call waits up to `PAGANI_BUILD_WAIT` seconds and then prints `RUNNING` and
  exits 5.
- Each run writes a settings profile (`build/<task>.settings.json`, no secrets)
  and passes it with `--settings`, so it outranks user and project settings. The
  profile blanks `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` in settings
  `env`.
- Limits: `PAGANI_BUILD_BUDGET` (USD, default 10; Claude Code's own estimate for
  unknown models), `PAGANI_BUILD_TIMEOUT` (seconds, default 1800), and
  `PAGANI_BUILD_WAIT` (seconds per call, default 540).
- The builder gets a slim tool set (Bash, Edit, Glob, Grep, Read, Skill, Write,
  TodoWrite) and no MCP servers.
- `build/<task>.progress` gets one line per builder tool call; `pagani build`
  prints the last one while the build is still `RUNNING`, and the cost at the end.

## Hooks and worktrees

```bash
pagani hooks install|uninstall [path]
pagani worktree create <job> <task>
pagani worktree prune <job> [--force]
```

- `hooks` installs or removes the gitleaks pre-commit hook and the pre-push hook
  that runs `scripts/check`.
- `worktree create` creates one worktree per task for parallel builders and
  prints a port. `worktree prune` removes them; `--force` discards uncommitted
  changes.

## Troubleshooting

| Problem | Fix |
|---|---|
| `/pagani` not found | Check `/plugin` (the plugin is installed and enabled), start a new session, then run `pagani doctor`. |
| `pagani` not found in a session | The plugin puts `bin/pagani` on `PATH` only inside a session. Start a new session, and remove an old `~/.local/bin/pagani` that shadows it. |
| Skills not loading | The plugin manifest lists each category directory. Check `skills/<category>/<name>/SKILL.md`. |
| Checks always fail | Fill `scripts/check`; it exits 1 until configured. |
| `pagani job gate` says stale | Run `pagani job check <job>` after the latest commit. |
| `pagani job gate` says dirty | Commit or stash changes, or use `--allow-dirty`. |
| `pagani doctor` reports an unresolved skill | Add the skill under `skills/<category>/<name>/` or fix the name in the agent. |
| Claude settings missing | Run `pagani init`. |
| Claude settings has no hooks | Run `pagani upgrade` or reinstall the plugin. |
| `gitleaks` missing | Install it, or leave the hook to skip cleanly. |
| Git hooks missing | Run `pagani hooks install [path]`. |
| `pagani upgrade` fails | Install `python3`. |
| Context full | Load `session-handoff`, write `PLAN.md`, start a fresh session. |

## Claude smoke test

Run this by hand after installing the plugin.

1. `/plugin` lists `pagani`, and a new session shows the `/pagani` and
   `/pagani-models` commands.
2. `pagani --help` resolves inside a session and prints the usage.
3. `pagani doctor` shows `claude: yes`.
4. `python3 -m json.tool .claude/settings.json` succeeds in a project.
5. `/pagani status` loads the generated command and reads the newest job.
6. `pagani job gate <job>` fails after an uncommitted edit and passes with
   `--allow-dirty`.
