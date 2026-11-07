# Setup

## Requirements

- OpenCode, Claude Code, or both.
- `gh` for PR helpers.
- Optional: `python3` for `pagani upgrade`.
- Optional: `gitleaks` for the secret pre-commit hook.
- Optional: `agent-browser` for browser checks.

## Install

```bash
git clone <this-repo> ~/Projects/PaganiStack
~/Projects/PaganiStack/install.sh --target both
~/Projects/PaganiStack/bin/pagani doctor
```

`install.sh` forwards to `bin/pagani install`. Choose a target with
`--target opencode|claude|both`. The default mode is `--link`; use `--copy` to
copy files instead. Preview with `--dry-run`, or skip prompts with `--yes`.

The installer flattens `skills/<category>/<skill>` to
`<target>/skills/<skill>` because both runtimes discover skills at that depth.
Agents and commands are per-target; skills are shared.

## Uninstall

```bash
./bin/pagani install --uninstall
```

Add `--dry-run` to print `would remove:` lines without deleting anything. Add
`--target` to limit removal to one runtime.

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
~/Projects/PaganiStack/bin/pagani init
```

`pagani init` creates `SPEC.md`, `ROADMAP.md`, and `TASKS.md`, plus `AGENTS.md`,
`REVIEW.md`, `CODING_STANDARDS.md`, `GLOSSARY.md`, `BACKLOG.md`, `mistakes.md`,
`CLAUDE.md`, the `scripts/` check and verify stubs, `.claude/settings.json`,
`docs/FEATURE-MAP.md`, the ADR template, and the network-allowlist example. It
installs the git hooks when `.git` exists.

## Upgrade a project

```bash
cd ~/Projects/my-project
~/Projects/PaganiStack/bin/pagani upgrade
```

`upgrade` refreshes the Claude hook and settings without dropping your settings,
keeps an existing `scripts/format`, and creates `SPEC.md` and `ROADMAP.md` when
they are missing. It needs `python3` to merge `.claude/settings.json`.

## Hooks, network, and worktrees

```bash
pagani hooks install|uninstall [path]
pagani network init|check <url>
pagani worktree create <job> <task>
pagani worktree prune <job> [--force]
```

- `hooks` installs or removes the gitleaks pre-commit hook and the pre-push hook
  that runs `scripts/check`.
- `network init` creates the opt-in `pagani/network-allowlist.txt`. `network
  check <url>` reports allowed or denied. The allowlist covers only Claude
  `WebFetch`; shell, `curl`, and `agent-browser` egress are not covered.
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
| Model variants missing | Re-run `./install.sh --target ...`. |
| `gitleaks` missing | Install it, or leave the hook to skip cleanly. |
| Git hooks missing | Run `pagani hooks install [path]`. |
| `pagani upgrade` fails | Install `python3`. |
| Network check denies a host | Add it to `pagani/network-allowlist.txt`, or remove the file. |
| Dashboard is stale | Re-run `pagani job report --dashboard`; it is a static file. |
| Context full | Load `session-handoff`, write `TASKS.md`, start a fresh session. |

## Claude smoke test

Run this by hand after installing or upgrading the Claude Code target.

1. `./install.sh --target claude --dry-run` exits 0.
2. `./bin/pagani doctor` shows `claude: yes`, the settings hooks, and executable
   `scripts/claude-hook.sh`.
3. `python3 -m json.tool .claude/settings.json` succeeds and the file has the
   `PreToolUse` `WebFetch`, `PostToolUse` `Edit|Write`, and `PreCompact` hooks.
4. `scripts/claude-hook.sh format` runs `scripts/format` on a scratch file and
   exits 0 even when the formatter fails.
5. `scripts/claude-hook.sh webfetch-guard` allows with no allowlist, allows a
   listed host, and denies an unlisted host.
6. `/pagani status` loads the generated command and reads the newest job.
7. `pagani job gate <job>` fails after an uncommitted edit and passes with
   `--allow-dirty`.
