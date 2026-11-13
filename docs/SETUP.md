# Setup

## Requirements

- Claude Code with plugin support.
- `gh` for PR helpers.
- `python3` for `maestro upgrade` and `maestro statusline` (settings merge).
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
  `"${CLAUDE_PLUGIN_ROOT}/bin/maestro" guard builder`, Stop runs it with
  `guard stop`, and SessionStart runs it with `tools hint`. They use the plugin
  root because a hook shell has no plugin `bin/` on `PATH`. `guard stop` keeps
  the master running while a todo item is open, but when every open run is on
  hold (`maestro hold <run> "<reason>"`) it lets the session end and prints
  `run <slug> is on hold: <reason>`; `maestro resume <run>` clears a `paused`
  marker and any hold so it tracks the run again.

Update with `/plugin` or `claude plugin update bottega@bottega`. Uninstall with
`claude plugin uninstall bottega`; remove the marketplace with
`claude plugin marketplace remove bottega`.

### Manual steps

A plugin cannot change your global Claude Code config, so set these yourself:

- The plugin does not merge keys into `~/.claude/settings.json`. To start every
  session as the master and let it run builds without a prompt, add:

  ```json
  {
    "agent": "bottega:master",
    "permissions": { "allow": ["Bash(maestro:*)"] }
  }
  ```

  `claude --agent bottega:master` works without the `agent` key.
- `/maestro` runs on the session model: the command sets no `model` of its own.
  To start the master on a chosen model, run
  `claude --agent bottega:master --model <model>`, or set `"model": "<model>"`
  beside `"agent": "bottega:master"` in `~/.claude/settings.json`. Per-role model
  and effort routing for the agents the master delegates to is written by
  `/maestro-models` to `~/.claude/rules/bottega-models.md`; it does not change
  the session's own model.
- The plugin does not write `~/.claude/CLAUDE.md`. Put global instructions
  there yourself.
- The plugin does not install a launcher into `~/.local/bin`. `maestro` is on
  `PATH` only inside a session.
- The plugin does not configure the status line by itself. Run
  `maestro statusline install` to point it at the builder watcher. It prints
  the exact JSON it will merge, asks `Apply? [y/N]`, and `--yes` skips the
  prompt. It backs up `~/.claude/settings.json` to
  `settings.json.bak.<epoch>` first, keeps every other key, writes
  `~/.claude/statusline.sh` (mode 700, marker `# bottega-managed statusline`,
  an absolute path to this `maestro`), and sets `"refreshInterval": 10`; it
  never replaces a custom `statusLine.command`, and an unmanaged existing
  `statusline.sh` is refused. A second run prints `statusline: already
  installed` and writes nothing. `maestro statusline status` reports what is
  set and is read-only:

  ```
  statusLine: set
  refreshInterval: set (10)
  command: maestro
  maestro path: /path/to/plugin/bin/maestro (ok)
  ```

  The JSON it merges looks like:

  ```json
  {
    "statusLine": {
      "type": "command",
      "command": "/path/to/plugin/bin/maestro watch --line",
      "refreshInterval": 10
    }
  }
  ```

  The script calls the absolute path because whether Claude Code puts the
  plugin's `bin/` on a status-line shell's `PATH` or expands
  `${CLAUDE_PLUGIN_ROOT}` there is unverified: settling that needs an
  interactive session, and the absolute path works either way. Keep
  `refreshInterval` between 5 and 30 seconds.

  `maestro watch --line` reads Claude Code's JSON (`workspace.current_dir`) on
  stdin and prints `<done>/<total> tasks · ~<percent>% · ETA <minutes>m`, plus
  ` · stalled` when a running builder has logged no event for two minutes. It
  picks the newest open, non-paused run by `events.tsv` mtime. With fewer than
  three `steps.tsv` samples it prints only `<done>/<total> tasks`; outside a git
  repository, with no run, or with bad stdin it prints nothing. It always exits
  0.

  Each refresh is local and cheap: one `events.tsv` pass and one `steps.tsv`
  read, with no model call and no network, and it runs only while the session
  is open.

### Builder key

The headless builder is global; nothing is copied into projects.

```bash
maestro build --init     # creates builder.env, then asks for your key (hidden)
maestro build --check    # verifies both without printing them
```

- `~/.config/bottega/builder.env` (mode 600) holds the endpoint and model names
  only. Set `ANTHROPIC_BASE_URL` to any Anthropic-compatible endpoint and
  `ANTHROPIC_MODEL` to the model it serves. For OpenCode Go:

  ```bash
  ANTHROPIC_BASE_URL=https://opencode.ai/inference/go/anthropic
  ANTHROPIC_MODEL=<the model OpenCode Go serves>
  ```

  Use the base URL exactly as given, with no `/v1/messages` suffix. Any empty
  `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`,
  `ANTHROPIC_DEFAULT_HAIKU_MODEL`, or `CLAUDE_CODE_SUBAGENT_MODEL` defaults to
  `ANTHROPIC_MODEL` at build time, so the builder's Claude tier aliases reach
  the served model; an explicit value in `builder.env` wins. `maestro build
  --check` reports what is missing and any malformed line (such as a space
  after `=`).
- `~/.config/bottega/builder.key` (mode 600) holds the API key. It reaches
  `claude` through an `apiKeyHelper` (`maestro keyget`), so it is never in the
  builder's environment or argv. An `ANTHROPIC_AUTH_TOKEN=` line in
  `builder.env` still works as a fallback.

Without these files, `/maestro` falls back to the Claude `builder` subagent.

## Use skills without the stack

The plugin names every skill under `bottega:` and also brings the hooks and
agents. To get only some skills as plain slash commands (`/teach`, not
`/bottega:teach`), copy the standalone ones into your Claude config directory:

```bash
maestro skills list                 # each standalone skill and its status
maestro skills install teach        # also installs the standalone skills it Loads
maestro skills install --all        # the whole standalone list
maestro skills uninstall teach      # remove a managed copy
maestro skills uninstall --all
```

Copies go to `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/<name>/` and carry a
`.bottega-managed` marker, so `list`, `install`, and `uninstall` never touch a
skill you wrote yourself. `install` with no names installs nothing: it prints the
list and the hint. Re-running `maestro skills install <name>...` refreshes that
copy; `install` refuses an unmarked directory of the same name and installs
nothing.

A copy is a snapshot: it does not update when the plugin does. After a plugin
update, re-run `maestro skills install <name>...` (or `--all`) to refresh it.

Some standalone skills, for example `interview`, `summary`, `wayfinding`,
`ketchup`, and `domain-modeling`, are written for the full stack and mention
the master, the planner, or `maestro` commands. Installed alone they still
work, but those references only apply when the plugin is enabled too.

With the plugin also enabled, both `/teach` (the standalone copy) and
`/bottega:teach` (the plugin's own namespace) appear; they are the same skill.
`uninstall` removes only marked copies, so leaving the plugin enabled keeps the
namespaced one.

A managed copy of a skill that later leaves the standalone list cannot be
removed by name, because the name is now unknown or non-standalone; use
`maestro skills uninstall --all` to remove marked copies.

## Doctor

```bash
maestro doctor
```

`doctor` prints the plugin version (`version: <version>`), the runtime and tool versions (including whether the optional `rtk` is installed), the skill count, `AGENTS.md` size, project Claude settings, hook status, config paths, and
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

`scripts/validate.sh` runs `./bin/maestro doctor`, then `scripts/e2e.sh`: a
throwaway repo, a stub `claude` that logs its arguments, and about 37 checks over
runs, specs, checks, gates and proofs, every build path, the hooks, logs, close,
and worktrees. It prints `ok <step>` or `FAIL <step>`; `KEEP=1` keeps the temp dir.

## Token savings (optional)

[rtk](https://github.com/rtk-ai/rtk) is a separate tool, not part of the stack, that
compresses command output before the agent reads it: failing tests only, compact git
output, grouped `ls` and `grep`. Its hook rewrites shell commands (`git status` runs
as `rtk git status`); `Read`, `Grep`, and `Glob` pass through. The project claims
60-90% less command output, which is less than that off total tokens, and its
counts are estimates. `maestro doctor` prints `rtk: yes` or `rtk: no`.

Install it on each machine, outside the stack. `maestro tools install` does this
for you: it installs whatever is missing of rtk and gitleaks with brew, dnf, apt,
go, or cargo (rtk falls back to its downloaded installer, which you read first),
asks before each install, and offers `rtk init -g`. A SessionStart hook prints one
line when either tool is missing and never installs anything; set
`BOTTEGA_NO_TOOL_HINT=1` to silence it. By hand:

```bash
brew install rtk                 # or read, then run, the project's install.sh
rtk init -g                      # adds the hook to the global Claude Code config
rtk gain                         # after a session: shows what it saved
rtk bypass <command>             # run one command unfiltered
```

Restart Claude Code after `rtk init -g`. Another crate named `rtk` exists on
crates.io, so do not `cargo install rtk` blindly.

- **License:** the CLI is Apache-2.0; its pipeline engine and the optional proxy
  are BUSL-1.1 (source-available). `rtk-oss` ships only the Apache-2.0 code.
  Telemetry is off unless you run `rtk telemetry enable`. Leave the proxy and
  pipelines off: the proxy can route API calls and pipelines can send content
  to other models.
- **Headless builders** run `claude -p` with your user settings, so the global
  hook likely applies to them too. Confirm with `rtk gain` before and after one
  build.
- **Lost failure detail:** compressed test output can hide what a builder needs
  to fix a failure. If a builder starts guessing, run that command with
  `rtk bypass`.
- **Permission prompts:** a rewritten `rtk git status` may not match an allow rule
  such as `Bash(git status:*)`. Watch the first session for new prompts.
- **`maestro` output:** rtk rewrites only commands it knows, so `maestro check` and
  `maestro gate` should pass through unchanged. Check it once.

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
the one you are on, and its state lives outside the repo:

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
  events.tsv              build events: time run task role kind step
  build/<task>.*          prompt, run/rc logs, builder report, reviews
  checks/<sha>.result     RESULT, HEAD, EXIT, SECONDS for that commit
  checks/<sha>.log        that check's output
  checks.result           latest record, a copy of the newest checks/<sha>.result
  checks.log              one summary line per check
$STATE/quick/<slug>/      light path (no run, spec, or worktree)
  run, rc, events.tsv, prompt, report.md, builder.log, settings.json
$STATE/steps.tsv          history of finished rev-0 builds, for estimates
```

Nothing is written into the repo or a worktree. The chat and the PR (or merge
commit) carry the human-readable record: interview answers, summaries,
decisions, reviews, and builder reports. A session handoff is the one file:
`session-handoff` writes it to
`${BOTTEGA_HANDOFF_DIR:-/tmp}/<repo>-handoff-<slug>.md`.

- `BOTTEGA_STATE_DIR` overrides the base directory. Set it to a persistent
  location if runs must survive a reboot or if `/tmp` has a small quota: the
  default sits under `${TMPDIR:-/tmp}`, which the system may clear on reboot or
  reclaim under pressure, and its size counts against that filesystem's quota.
  The branch, todo list, and chat/PR record survive regardless; only the spec,
  extracted tasks, build reports, and check results are lost.
- `maestro report --close <run> [--playbook p --risk r --outcome o]` appends one
  line to the trust log (`trust.log` in the state root, so it lives in the temp
  dir and a reboot clears it), then removes the run's state directory; the master
  calls it after the closeout is confirmed. `maestro report --trust [n]` prints
  the last n runs (default 10) and a summary; it only reports.
- `maestro hold <run> "<reason>"` writes a `hold` file (timestamp and reason) in
  the run's state directory, or `$STATE/quick/<slug>/` on the light path;
  `maestro build --status` then prints `HOLD: <reason>`, and
  `maestro hold --clear <run>` removes it. `maestro resume <run>` removes both a
  `paused` marker and any hold.

## Headless builder (`maestro build`)

The builder runs as `claude -p --agent bottega:builder` on a third-party model through
an Anthropic-compatible endpoint.

```bash
maestro build <run> <task> [--revise <file|->] [--block|--wait]
maestro build --here <slug> --task "<text>" [--revise <file|->] [--block|--wait]
maestro build --review <run> <task> [--block|--wait]
maestro build --review --here <slug> [--block|--wait]
maestro build --status <run>
maestro watch <run>
maestro watch --line
```

- `--here` is the light path: it needs no run, SPEC, or worktree, builds in the
  current checkout on the current branch, and keeps state in
  `$STATE/quick/<slug>/` (`run`, `rc`, `events.tsv`, `prompt`, `report.md`,
  `builder.log`, `settings.json`).
- `--review` runs the read-only `review-code` agent in the task worktree on the
  third-party model and puts the findings in
  `$STATE/<run>/build/<task>.review2.md`. It cannot edit or commit. With
  `--here <slug>` it reviews the current checkout against the default branch and
  writes `$STATE/quick/<slug>/review.md`.
- `--block` waits until the build ends, for a background Bash task. `--wait`
  attaches to a running build with the same bounded wait. Without either, the
  call waits up to `BOTTEGA_BUILD_WAIT` seconds and then prints `RUNNING` and
  exits 5.
- Each run writes a settings profile (`build/<task>.settings.json`, no secrets)
  and passes it with `--settings`, so it outranks user and project settings. The
  profile blanks `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` in settings
  `env`.
- The profile pins `ANTHROPIC_MODEL` and maps every empty tier alias
  (`ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`,
  `ANTHROPIC_DEFAULT_HAIKU_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL`) to it, so the
  builder's Claude tier alias resolves to the served model. An explicit value in
  `builder.env` wins.
- A build or review that exits non-zero without spending tokens prints the first
  endpoint error line on the console; the full stream stays in `builder.log`.
- Effort routing: when `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/rules/bottega-models.md`
  exists, `build` and `--here` take the `builder` line's effort and `--review`
  takes the `second-opinion` line's effort, passed as `--effort
  low|medium|high`. A malformed line is ignored; without the file no `--effort`
  is passed. The file's contents are never printed.
- The only stop is the 30-minute builder timeout (`BOTTEGA_BUILD_TIMEOUT`,
  seconds, default 1800); `BOTTEGA_BUILD_WAIT` defaults to 540 seconds per call.
  There is no other limit.
- `BOTTEGA_PLUGIN_DIR=<checkout>` makes the headless runner load that checkout of
  the stack with `--plugin-dir`; the `eval` playbook uses it to run a variant.
- The builder gets a slim tool set (Bash, Edit, Glob, Grep, Read, Skill, Write,
  TodoWrite) and no MCP servers.
- The run's `events.tsv` gets one line per build event, with six tab-separated
  fields (`time run task role kind step`; `time` is epoch seconds): `start` when
  the builder starts (with `rev=<n>`), one `step` per tool call, and `end` with
  its exit code and report status. It replaces the old `.progress` files.
  `maestro build` prints the last
  step while the build is still `RUNNING`, then `tokens: in <n> out <n>` and
  `steps: <n>` (the number of `step` events) at the end.
- A first (rev-0) builder build that ends `STATUS: DONE` also appends a line to
  `$STATE/steps.tsv` (`time role path steps seconds`); failed builds and
  revisions add nothing. The file sits in the state root, so it outlives
  `report --close`.

## Lab

`maestro lab` is an opt-in end-to-end rehearsal of the real master. It never
runs from `scripts/check`, `scripts/validate.sh`, or CI: those drive every
command with a fake master and a stub builder, so they spend no model and use no
network. Run the lab by hand when you changed the master prompt, the playbooks,
or the workflow hooks.

```bash
maestro lab [trivial|bugfix|feature-fix|pause-resume] [--keep]
```

- The master runs on `sonnet` with `low` effort. It needs
  `CLAUDE_CODE_OAUTH_TOKEN` or `ANTHROPIC_API_KEY` in the environment; the lab
  passes it through unread and exits 3 when neither is set.
- The builder is stubbed (`lab/stub-claude`), so only the master calls a model.
  The scratch `builder.env` points at `http://stub.invalid`, so an unstubbed
  builder call fails fast instead of reaching a real endpoint.
- Everything is isolated: `HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`,
  `XDG_DATA_HOME`, `CLAUDE_CONFIG_DIR`, `BOTTEGA_STATE_DIR`, and `TMPDIR` move
  under one scratch directory, and the stub `claude` is first on `PATH`.
- With no scenario it runs all four. Each scenario has a fixture, a master
  prompt, a stub-builder side effect, and an `expect` assertion; a failed
  scenario stops the run with a non-zero exit.
- `--keep` prints the scratch path and keeps it for inspection. Without it the
  scratch directory is removed on exit.
- The master gets `--plugin-dir <checkout>` and `--strict-mcp-config`, plus a
  real allow list: `Read,Grep,Glob,Write,Edit,Skill,Agent,Task,TodoWrite`,
  `Bash(maestro:*)`, `Bash(git:*)`, and `Bash(./scripts/check:*)`. Shell
  commands outside that set are denied. The deny list is `Bash(git push:*)`,
  `Bash(gh:*)`, `WebFetch`, `WebSearch`, and `AskUserQuestion`.

## Hooks and worktrees

```bash
maestro hooks install|uninstall [path]
maestro worktree create <run> <task> [--branch <name> [--base <ref>]]
maestro worktree prune <run> [--force]
```

- `hooks` installs or removes the gitleaks pre-commit hook and the pre-push hook that runs `scripts/check`; the pre-commit hook resolves `maestro` from `PATH`, the install-time path, then the newest plugin cache copy, and warns instead of silently skipping the Bottega-file check.
- `worktree create` creates one worktree per task for parallel builders and
  prints a port. Checks and review can run in each worktree in parallel:
  `maestro check` records `checks/<sha>.result` per HEAD, so a check in one
  worktree never makes another's gate stale. `worktree prune` removes them and
  deletes their merged local task branches; `--force` discards uncommitted
  changes.

## Troubleshooting

| Problem | Fix |
|---|---|
| `/maestro` not found | Check `/plugin` (the plugin is installed and enabled), start a new session, then run `maestro doctor`. |
| `maestro` not found in a session | The plugin puts `bin/maestro` on `PATH` only inside a session. Start a new session. |
| Skills not loading | The plugin manifest lists each category directory. Check `skills/<category>/<name>/SKILL.md`. |
| Checks always fail | Fill `scripts/check`; it exits 1 until configured. |
| `maestro gate` says stale | Run `maestro check <run>` after the latest commit. |
| `maestro gate --proof` fails | A criterion has no PASS for the current HEAD: run its `Proof:` and `maestro verify record` it, or waive it with the user's approval. |
| `maestro gate` says dirty | Commit or stash changes, or use `--allow-dirty`. |
| `maestro doctor` reports an unresolved skill | Add the skill under `skills/<category>/<name>/` or fix the name in the agent. |
| Claude settings missing | Run `maestro init`. |
| `gitleaks` missing | Install it, or leave the hook to skip cleanly. |
| Git hooks missing | Run `maestro hooks install [path]`. |
| `maestro upgrade` fails | Install `python3`. |
| Context full | Load `session-handoff` (writes `${BOTTEGA_HANDOFF_DIR:-/tmp}/<repo>-handoff-<slug>.md`), write `PLAN.md`, start a fresh session. |

## Claude smoke test

Run this by hand after installing the plugin.

1. `/plugin` lists `bottega`, and a new session shows the `/maestro` and
   `/maestro-models` commands.
2. `maestro --help` resolves inside a session and prints the usage, and
   `maestro --version` prints `maestro <version>`.
3. `maestro doctor` shows `version: <version>` and `claude: yes`.
4. `python3 -m json.tool .claude/settings.json` succeeds in a project.
5. `/maestro status` loads the master prompt and reads the todo list and
   current branch.
6. `maestro gate <run>` fails after an uncommitted edit and passes with
   `--allow-dirty`.
