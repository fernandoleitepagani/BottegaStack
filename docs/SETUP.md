# Setup

## Requirements

- Claude Code.
- `gh` for PR helpers.
- Optional: `python3` for `pagani upgrade`.
- Optional: `gitleaks` for the secret pre-commit hook.
- Optional: `agent-browser` for browser checks.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/fernandoleitepagani/PaganiStack/main/get.sh | bash
pagani doctor
```

`get.sh` needs only `bash`, `curl`, and `tar` (Linux, macOS, Windows via WSL or Git
Bash). It downloads the `main` tarball to a temp dir, installs a self-contained copy
into `~/.claude` and the `pagani` launcher into `~/.local/bin`, then deletes the temp
dir. No git clone, no repo kept.

- Preview: `... | bash -s -- --dry-run`.
- Flags pass through: `... | bash -s -- --target claude`.
- `PAGANI_REF=<branch-or-tag>` installs another ref (default `main`).
- Update later with `pagani upgrade --self` (tarball-based, no `--from` needed).

Read before you pipe: this runs whatever is on `main` right now, and no checksum is
verified. Read <https://github.com/fernandoleitepagani/PaganiStack/blob/main/get.sh> first if that matters to you.

### Contributors / from a clone

```bash
git clone <this-repo> /tmp/PaganiStack
/tmp/PaganiStack/install.sh
pagani doctor
rm -rf /tmp/PaganiStack      # the install is self-contained
```

`install.sh` forwards to `bin/pagani install`. The target is `~/.claude` (`CLAUDE_CONFIG_DIR` is honored). The default mode is `--copy`: real files go into
each target, and the CLI with its resources goes to `<target>/pagani/`, so the
clone is not needed afterwards. `--link` symlinks into the clone instead (for
development). Preview with `--dry-run`, or skip prompts with `--yes`.

A copy install never overwrites `~/.claude/settings.json`: missing keys are added
and your existing ones (model, theme, permissions) are kept.

Update an installed copy without a clone: `pagani upgrade --self` (or
`--from <git-url-or-path>`).

The installer flattens `skills/<category>/<skill>` to
`<target>/skills/<skill>` because both runtimes discover skills at that depth.
Agents and commands are per-target; skills are shared.

There are no tier variants of an agent: the master picks the model per call with
the Agent tool's `model` parameter. The master runs on Opus 5.5 at medium effort.

## Uninstall

```bash
pagani install --uninstall   # or ./bin/pagani install --uninstall from a clone
```

Add `--dry-run` to print `would remove:` lines without deleting anything. Add


## Doctor

```bash
./bin/pagani doctor
```

`doctor` prints the runtime and tool versions, the skill count, missing upstream
skills, `AGENTS.md` size, project Claude settings, hook status, config paths, and
then runs the lint. It is the release gate:

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
you (through `pagani job new`) and then asks you for the project's lint, test, and
build commands to fill in `scripts/check`. Run `pagani init` yourself only to set a
project up without starting a job. It creates `SPEC.md`, `ROADMAP.md`, and `TASKS.md`, plus `AGENTS.md`,
`REVIEW.md`, `CODING_STANDARDS.md`, `GLOSSARY.md`, `BACKLOG.md`, `mistakes.md`,
`CLAUDE.md`, the `scripts/` check and verify stubs, `.claude/settings.json`,
`docs/FEATURE-MAP.md`, and the ADR template. It
installs the git hooks when `.git` exists.

**None of these files is ever committed.** `init` lists them in
`.git/info/exclude` (local, shared by worktrees, never committed), so `git status`
stays clean, your `.gitignore` is not touched, and `pagani job new` sees a clean
tree. The pre-commit hook also refuses to stage a newly added pagani file. A file
your project already tracked (say its own `AGENTS.md`) is left alone and stays
tracked. `pagani worktree create` copies the files into each task worktree, since
untracked files are not part of a checkout.

## Upgrade a project

```bash
cd ~/Projects/my-project
~/Projects/PaganiStack/bin/pagani upgrade
```

`upgrade` refreshes the Claude hook and settings without dropping your settings,
keeps an existing `scripts/format`, and creates `SPEC.md` and `ROADMAP.md` when
they are missing. It needs `python3` to merge `.claude/settings.json`.

## Headless builder (`pagani build`)

The builder runs as `claude -p --agent builder` on a third-party model through
an Anthropic-compatible endpoint. It is global: nothing is copied into projects.

```bash
pagani build --init     # creates builder.env, then asks for your key (hidden)
pagani build --check    # verifies both without printing them
```

- `~/.config/pagani/builder.env` (mode 600) holds the endpoint and model names
  only. The defaults target OpenCode Go and `deepseek-v4.1-flash`.
- `~/.config/pagani/builder.key` (mode 600) holds the API key. It reaches `claude`
  through an `apiKeyHelper` (`pagani keyget`), so it is never in the builder's
  environment or argv. An `ANTHROPIC_AUTH_TOKEN=` line in `builder.env` still works
  as a fallback.
- Each run writes a settings profile (`build/<task>.settings.json`, no secrets) and
  passes it with `--settings`, so it outranks user and project settings. The profile
  blanks `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` in settings `env`.
- Limits: `PAGANI_BUILD_BUDGET` (USD, default 10; Claude Code's own estimate for
  unknown models), `PAGANI_BUILD_TIMEOUT` (seconds, default 1800), and
  `PAGANI_BUILD_WAIT` (seconds per call, default 540).
- The builder gets a slim tool set (Bash, Edit, Glob, Grep, Read, Skill, Write,
  TodoWrite) and no MCP servers.
- `build/<task>.progress` gets one line per builder tool call; `pagani build`
  prints the last one while the build is still `RUNNING`, and the cost at the end.

Without the files, `/pagani` falls back to the Claude `builder` subagent.

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
| `/pagani` not found | Run `./install.sh --target ...`; check `pagani doctor`. |
| Skills not loading | The installer flattens categories. Check `<target>/skills/<name>/SKILL.md`. |
| Checks always fail | Fill `scripts/check`; it exits 1 until configured. |
| `pagani job gate` says stale | Run `pagani job check <job>` after the latest commit. |
| `pagani job gate` says dirty | Commit or stash changes, or use `--allow-dirty`. |
| `pagani doctor` reports an unresolved skill | Add the skill under `skills/<category>/<name>/` or fix the name in the agent. |
| Claude settings missing | Run `pagani init`. |
| Claude settings has no hooks | Run `pagani upgrade`. |
| `gitleaks` missing | Install it, or leave the hook to skip cleanly. |
| Git hooks missing | Run `pagani hooks install [path]`. |
| `pagani upgrade` fails | Install `python3`. |
| Context full | Load `session-handoff`, write `TASKS.md`, start a fresh session. |

## Claude smoke test

Run this by hand after installing or upgrading the Claude Code target.

1. `./install.sh --target claude --dry-run` exits 0.
2. `./bin/pagani doctor` shows `claude: yes`, the settings hooks, and executable
   `scripts/claude-hook.sh`.
3. `python3 -m json.tool .claude/settings.json` succeeds and the file has the
   `PostToolUse` `Edit|Write` and `PreCompact` hooks.
4. `scripts/claude-hook.sh format` runs `scripts/format` on a scratch file and
   exits 0 even when the formatter fails.
5. `/pagani status` loads the generated command and reads the newest job.
6. `pagani job gate <job>` fails after an uncommitted edit and passes with
   `--allow-dirty`.
