# Setup

## Requirements

- Claude Code with plugin support.
- `gh` for PR helpers.
- `python3` for `maestro upgrade` (settings merge).
- Optional: `gitleaks` for the secret pre-commit hook.
- Optional: `agent-browser` for browser checks.

## Install

BottegaStack ships as the Claude Code plugin `bottega`. Inside a session:

```
/plugin marketplace add fernandoleitepagani/BottegaStack
/plugin install bottega@bottega
```

Or from a shell:

```bash
claude plugin marketplace add fernandoleitepagani/BottegaStack
claude plugin install bottega@bottega -y
```

The plugin provides:

- `bin/maestro` on `PATH` inside a session.
- The agents `master`, `explorer`, `planner`, `builder`, and `review-code`
  (also reachable as `bottega:<name>`).
- The commands `/maestro` and `/maestro-models` (also
  `/<plugin>:<command>`).
- Every skill from the category directories listed in the plugin manifest.
- The hooks in `hooks/hooks.json`: PreToolUse `Agent|Task` runs
  `maestro guard builder`, and Stop runs `maestro guard stop`.

Update with `/plugin` or `claude plugin update bottega@bottega`. Uninstall with
`claude plugin uninstall bottega`; remove the marketplace with
`claude plugin marketplace remove bottega`.

### Manual steps

A plugin cannot change your global Claude Code config, so set these yourself:

- The plugin does not merge keys into `~/.claude/settings.json`. To start every
  session as the master and let it run builds without a prompt, add:

  ```json
  {
    "agent": "master",
    "permissions": { "allow": ["Bash(maestro:*)"] }
  }
  ```

  `claude --agent master` works without the `agent` key.
- The plugin does not write `~/.claude/CLAUDE.md`. Put global instructions
  there yourself.
- The plugin does not install a launcher into `~/.local/bin`. `maestro` is on
  `PATH` only inside a session.

### Builder key

The headless builder is global; nothing is copied into projects.

```bash
maestro build --init     # creates builder.env, then asks for your key (hidden)
maestro build --check    # verifies both without printing them
```

- `~/.config/bottega/builder.env` (mode 600) holds the endpoint and model names
  only. The defaults target OpenCode Go and `deepseek-v4.1-flash`.
- `~/.config/bottega/builder.key` (mode 600) holds the API key. It reaches
  `claude` through an `apiKeyHelper` (`maestro keyget`), so it is never in the
  builder's environment or argv. An `ANTHROPIC_AUTH_TOKEN=` line in
  `builder.env` still works as a fallback.

Without these files, `/maestro` falls back to the Claude `builder` subagent.

## Doctor

```bash
maestro doctor
```

`doctor` prints the runtime and tool versions, the skill count, `AGENTS.md` size, project Claude settings, hook status, config paths, and
then runs the repo lint when `scripts/lint.sh` sits beside the CLI. It also
prints security warnings, one line each:

- `gitleaks` is missing, so secret scanning is unavailable.
- `.env` is tracked by git.
- A manifest exists but there is no dependency-update config
  (`.github/dependabot.yml`, `renovate.json`, or `.renovaterc*`).
- `.github/workflows` exists but no workflow mentions `codeql`,
  `dependency-review`, `gitleaks`, `trivy`, or `osv-scanner`.

It is the release gate:

```bash
./scripts/validate.sh
```

`scripts/validate.sh` runs `./bin/maestro doctor`.

## Init a project

```bash
cd ~/Projects/my-project
maestro init
```

You normally never run this: the first `/maestro` request in a project runs it for
you (through `maestro start "<title>"`) and then asks you for the project's lint,
test, and build commands to fill in `scripts/check`. Run `maestro init` yourself
only to set a project up without starting a run.

`init` creates only what the workflow needs to start:

- `AGENTS.md` (with the coding standards).
- `CLAUDE.md` (imports `AGENTS.md`).
- `scripts/check`.
- `.claude/settings.json`.
- The managed block in `.git/info/exclude` and, when `.git` exists, the git
  hooks.

**None of these files is ever committed.** `init` lists them in
`.git/info/exclude` (local, shared by worktrees, never committed), so `git status`
stays clean, your `.gitignore` is not touched, and `maestro start` sees a clean
tree. The pre-commit hook also refuses to stage a newly added Bottega file. A file
your project already tracked (say its own `AGENTS.md`) is left alone and stays
tracked. `maestro worktree create` copies the files into each task worktree, since
untracked files are not part of a checkout.

`init` creates no run directory. Run state lives outside the repo; see
[Run state](#run-state).

## Stack detection

```bash
maestro stack
```

`maestro stack` reads the repo-root file names and manifest fields and prints
stable lines:

```
language: <name>
package-manager: <name>
commands: lint=<cmd> test=<cmd> build=<cmd>
frameworks: <list>
```

It reads only file names and manifest fields, never `.env` or secrets. It
prints `stack: unknown` when nothing is found. At Step 0 the master shows the
profile, confirms or corrects it with `AskUserQuestion`, and writes it into the
`## Stack` section of `AGENTS.md`.

## Project files on demand

Everything else is created only when a skill first needs it. `maestro seed <Name>`
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
maestro upgrade
```

`upgrade` refreshes `.claude/settings.json` without dropping your settings,
and re-applies the exclude block and git hooks. It does not create the on-demand
project files and never deletes the ones you have. It needs `python3` to merge
`.claude/settings.json`.

## Run state

A run is one execution of a playbook. Its id is the slug, its branch is
`bottega/<slug>`, and its state lives outside the repo:

```
STATE="${BOTTEGA_STATE_DIR:-${TMPDIR:-/tmp}/bottega-$(id -u)}/<repo-id>"
```

`<repo-id>` is `<repo basename>-<first 8 hex of sha1 of the realpath of
$(git rev-parse --git-common-dir)>`, so every worktree of a repo shares one
state directory. The directory is created mode 700.

```
$STATE/<slug>/            full run
  spec.md                 the approved SPEC
  tasks/<n>.md            text of each `### Task <n>` section
  build/<task>.*          prompt, run/rc/progress logs, builder report, reviews
  checks.log              one line per check plus its output
  checks.result           RESULT, HEAD, EXIT, SECONDS
$STATE/quick/<slug>/      light path (no run, spec, or worktree)
  run, rc, progress, prompt, report.md, builder.log, settings.json
$STATE/retro-scan.md      written by `maestro report --retro --write`
```

Nothing is written into the repo or a worktree. The chat and the PR (or merge
commit) carry the human-readable record: interview answers, summaries,
handoffs, decisions, reviews, and builder reports.

- `BOTTEGA_STATE_DIR` overrides the base directory. Set it to a persistent
  location if runs must survive a reboot or if `/tmp` has a small quota: the
  default sits under `${TMPDIR:-/tmp}`, which the system may clear on reboot or
  reclaim under pressure, and its size counts against that filesystem's quota.
  The branch, todo list, and chat/PR record survive regardless; only the spec,
  extracted tasks, build reports, and check results are lost.
- `maestro report --close <run>` removes a run's state directory; the master
  calls it after the closeout is confirmed.

## Headless builder (`maestro build`)

The builder runs as `claude -p --agent builder` on a third-party model through
an Anthropic-compatible endpoint.

```bash
maestro build <run> <task> [--revise <file|->] [--block|--wait]
maestro build --here <slug> --task "<text>" [--block|--wait]
maestro build --review <run> <task> [--block|--wait]
maestro build --status <run> [--every <seconds>]
```

- `--here` is the light path: it needs no run, SPEC, or worktree, builds in the
  current checkout on the current branch, and keeps state in
  `$STATE/quick/<slug>/` (`run`, `rc`, `progress`, `prompt`, `report.md`,
  `builder.log`, `settings.json`).
- `--review` runs the read-only `review-code` agent in the task worktree on the
  third-party model and puts the findings in
  `$STATE/<run>/build/<task>.review2.md`. It cannot edit or commit.
- `--block` waits until the build ends, for a background Bash task. `--wait`
  attaches to a running build with the same bounded wait. Without either, the
  call waits up to `BOTTEGA_BUILD_WAIT` seconds and then prints `RUNNING` and
  exits 5.
- Each run writes a settings profile (`build/<task>.settings.json`, no secrets)
  and passes it with `--settings`, so it outranks user and project settings. The
  profile blanks `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` in settings
  `env`.
- Effort routing: when `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/rules/bottega-models.md`
  exists, `build` and `--here` take the `builder` line's effort and `--review`
  takes the `second-opinion` line's effort, passed as `--effort
  low|medium|high`. A malformed line is ignored; without the file no `--effort`
  is passed. The file's contents are never printed.
- The only stop is the 30-minute builder timeout (`BOTTEGA_BUILD_TIMEOUT`,
  seconds, default 1800); `BOTTEGA_BUILD_WAIT` defaults to 540 seconds per call.
  There is no other limit.
- The builder gets a slim tool set (Bash, Edit, Glob, Grep, Read, Skill, Write,
  TodoWrite) and no MCP servers.
- `build/<task>.progress` gets one line per builder tool call; `maestro build`
  prints the last one while the build is still `RUNNING`, then prints `tokens: in
  <n> out <n>` and `steps: <n>` at the end.

## Hooks and worktrees

```bash
maestro hooks install|uninstall [path]
maestro worktree create <run> <task>
maestro worktree prune <run> [--force]
```

- `hooks` installs or removes the gitleaks pre-commit hook and the pre-push hook
  that runs `scripts/check`.
- `worktree create` creates one worktree per task for parallel builders and
  prints a port. `worktree prune` removes them; `--force` discards uncommitted
  changes.

## Troubleshooting

| Problem | Fix |
|---|---|
| `/maestro` not found | Check `/plugin` (the plugin is installed and enabled), start a new session, then run `maestro doctor`. |
| `maestro` not found in a session | The plugin puts `bin/maestro` on `PATH` only inside a session. Start a new session. |
| Skills not loading | The plugin manifest lists each category directory. Check `skills/<category>/<name>/SKILL.md`. |
| Checks always fail | Fill `scripts/check`; it exits 1 until configured. |
| `maestro gate` says stale | Run `maestro check <run>` after the latest commit. |
| `maestro gate` says dirty | Commit or stash changes, or use `--allow-dirty`. |
| `maestro doctor` reports an unresolved skill | Add the skill under `skills/<category>/<name>/` or fix the name in the agent. |
| Claude settings missing | Run `maestro init`. |
| `gitleaks` missing | Install it, or leave the hook to skip cleanly. |
| Git hooks missing | Run `maestro hooks install [path]`. |
| `maestro upgrade` fails | Install `python3`. |
| Context full | Load `session-handoff`, write `PLAN.md`, start a fresh session. |

## Claude smoke test

Run this by hand after installing the plugin.

1. `/plugin` lists `bottega`, and a new session shows the `/maestro` and
   `/maestro-models` commands.
2. `maestro --help` resolves inside a session and prints the usage.
3. `maestro doctor` shows `claude: yes`.
4. `python3 -m json.tool .claude/settings.json` succeeds in a project.
5. `/maestro status` loads the generated command and reads the todo list and
   current branch.
6. `maestro gate <run>` fails after an uncommitted edit and passes with
   `--allow-dirty`.
