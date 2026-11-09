# Plugin prototype report

Research only. No existing files were changed, and nothing is deleted.

- Claude Code: `2.1.319`
- Platform: Linux (`7.2.15-200.fc22.x86_64` prefix per environment; bash 5.x)
- Fixture: `prototype/plugin/` (plugin), `prototype/.claude-plugin/marketplace.json`
  (local marketplace with `source: "./plugin"`).
- Every session test used `CLAUDE_CONFIG_DIR=$(mktemp -d)` and
  `env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_CHILD_SESSION`
  so the user's real `~/.claude` commands (including an installed `/pagani`)
  could not pollute the result. Auth came from the inherited environment; no
  secrets are printed.
- `claude plugin validate prototype/plugin` and `claude plugin validate prototype`
  both print `Validation passed`.

Fixture components:

| Path | Purpose |
|---|---|
| `prototype/plugin/bin/pagani-probe` | Executable that must resolve by bare name |
| `prototype/plugin/agents/prototype-agent.md` | Agent with `hooks:` in its own frontmatter |
| `prototype/plugin/hooks/hooks.json` | PreToolUse(Bash) + Stop plugin hooks |
| `prototype/plugin/hooks/append.sh` | Appends `<event> <utc-timestamp>` to `$PROTOTYPE_HOOK_LOG` |
| `prototype/plugin/commands/pagani.md` | Command-name probe |
| `prototype/plugin/commands/probe-two.md` | Second command for bare-name aliasing |

---

## Q1 — Does a plugin `bin/` executable end up on PATH inside a session? — PASS

Command (`PLUGIN=$PWD/prototype/plugin`):

```bash
CLAUDE_CONFIG_DIR=$(mktemp -d) claude -p --plugin-dir "$PLUGIN" \
  --dangerously-skip-permissions --output-format json \
  "Use the Bash tool to run: command -v pagani-probe && pagani-probe hello. Then report the exact stdout of both commands."
```

Output excerpt:

```
/home/fernandolaptop/Projects/PaganiStack-pagani/001-stack-simplification/1/prototype/plugin/bin/pagani-probe
pagani-probe-ok args=hello
```

`command -v` resolved the bare name to the plugin's `bin/` file, and invoking it
by bare name ran the script. The same held for an installed copy (see Q5) with
no `--plugin-dir`: a session ran `pagani-probe installed` and got
`pagani-probe-ok args=installed`. After uninstall, the same command printed
`PROBE-NOT-FOUND`.

## Q2 — Can a plugin-provided agent be selected as the main agent? — PASS

Three forms were tried; all printed the agent's required token
`AGENT-SELECTED` as the start of the reply:

```bash
# Canonical, prefixed name
claude -p --plugin-dir "$PLUGIN" --agent "pagani-prototype:prototype-agent" \
  "Use the Bash tool to run: echo hi. Then reply with the token your agent instructions require."
# → "AGENT-SELECTED\n\n`hi`"

# Bare name
claude -p --plugin-dir "$PLUGIN" --agent "prototype-agent" \
  "Reply with the token your agent instructions require."
# → "AGENT-SELECTED"

# The `agent` setting (--settings file: {"agent":"pagani-prototype:prototype-agent"})
claude -p --plugin-dir "$PLUGIN" --settings /tmp/proto-agent-setting.json \
  "Reply with the token your agent instructions require."
# → "AGENT-SELECTED"
```

The session-init metadata lists the agent as `pagani-prototype:prototype-agent`,
i.e. the plugin name is the namespace. Both the namespace-qualified and the bare
name were accepted by `--agent`.

## Q3 — Do plugin hooks fire, and do plugin-agent frontmatter hooks fire? — PASS for `hooks.json`; NO for agent frontmatter

Plugin `hooks/hooks.json` (PreToolUse on `Bash`, and Stop) appended to
`$PROTOTYPE_HOOK_LOG`. Command:

```bash
PROTOTYPE_HOOK_LOG=/tmp/hooks.log claude -p --plugin-dir "$PLUGIN" \
  --dangerously-skip-permissions --output-format json \
  "Use the Bash tool to run: echo hi. Report its output."
cat /tmp/hooks.log
```

Log excerpt — both hook events fired:

```
plugin-PreToolUse 2026-11-09T16:44:31Z
plugin-Stop 2026-11-09T16:44:34Z
```

Agent-frontmatter `hooks:` did **not** fire. The plugin agent was exercised two
ways, with a fresh log each time; the log contained only the plugin-level lines
and never `agent-PreToolUse` / `agent-Stop`:

1. As the main agent: `claude -p --plugin-dir "$PLUGIN" --agent "pagani-prototype:prototype-agent" ...`
   (and again after switching the hook command from `${CLAUDE_PLUGIN_ROOT}` to an
   absolute path, to rule out a missing environment variable).
2. As a subagent: `claude -p ... "Use the Agent tool with subagent_type exactly
   'pagani-prototype:prototype-agent' ..."` — `subagent_stats.spawned` was `1`
   and `by_type` showed `pagani-prototype:prototype-agent`, but still only the
   plugin-level hook lines appeared.

Control experiment: the same `hooks:` block in a normal project agent
(`$T/.claude/agents/probe.md`) fired correctly once the workspace was trusted:

```
project-agent-PreToolUse 2026-11-09T16:50:10Z
project-agent-Stop 2026-11-09T16:50:17Z
```

It also fired when that project agent was dispatched as a subagent. So the
negative result is specific to hooks declared in a **plugin-provided agent's
frontmatter** in 2.1.319, not to the hook syntax: plugin-level `hooks/hooks.json`
works, project-agent frontmatter hooks work, plugin-agent frontmatter hooks did
not run in this build.

## Q4 — What is the plugin command's invocation name? — PASS

With an isolated config dir, session-init metadata lists the command as
**prefixed**:

```
pagani-like slash commands: ['pagani-prototype:pagani']
```

Direct invocation confirms both forms run it when unambiguous:

```bash
claude -p --plugin-dir "$PLUGIN" --output-format json "/pagani-prototype:pagani"
# → "COMMAND-PAGANI-RAN"
claude -p --plugin-dir "$PLUGIN" --output-format json "/pagani"
# → "COMMAND-PAGANI-RAN"

# second command, same pattern
claude -p --plugin-dir "$PLUGIN" --output-format json "/probe-two"
# → "COMMAND-PROBE-TWO"
claude -p --plugin-dir "$PLUGIN" --output-format json "/pagani-prototype:probe-two"
# → "COMMAND-PROBE-TWO"
```

So the **canonical listed name is `/<plugin>:<command>`** (`/pagani-prototype:pagani`).
The bare `/<command>` also resolves when it is unambiguous. Isolation mattered:
with the default config dir the init list also contained the user's installed
`pagani` command, which would have hidden the attribution.

## Q5 — How do install / update / uninstall work from a local marketplace? — PASS

All commands ran with `HOME=$(mktemp -d)` and
`CLAUDE_CONFIG_DIR=$HOME/.claude`, plus the `GIT_AUTHOR_*` / `GIT_COMMITTER_*`
identity variables. The real `~/.claude` was never used.

```bash
MKT=$PWD/prototype
claude plugin marketplace add "$MKT" --json
# {"command":"marketplace-add","outcome":"ok","marketplace":"pagani-prototype", ...}
claude plugin marketplace list --json
# [{"name":"pagani-prototype","source":"directory","path":".../prototype", ...}]

claude plugin install pagani-prototype@pagani-prototype --json -y
# {"command":"install","outcome":"ok","pluginId":"pagani-prototype@pagani-prototype","scope":"user", ...}
claude plugin list --json
# [{"id":"pagani-prototype@pagani-prototype","version":"0.0.1","enabled":true,
#   "installPath":"$HOME/.claude/plugins/cache/pagani-prototype/pagani-prototype/0.0.1", ...}]
```

Install copies the plugin into
`$CLAUDE_CONFIG_DIR/plugins/cache/<marketplace>/<plugin>/<version>/` and it loads
without `--plugin-dir` (Q1's installed-session evidence).

Update compares the cached version with the marketplace copy. With no change:

```bash
claude plugin update pagani-prototype@pagani-prototype --json -y
# {"updateOutcome":"up_to_date","oldVersion":"0.0.1","newVersion":"0.0.1", ...}
```

With a version bump (tested on a temp copy, 0.0.2 → 0.0.3):

```bash
claude plugin update pagani-prototype@pagani-prototype --json -y
# {"updateOutcome":"updated","oldVersion":"0.0.2","newVersion":"0.0.3",
#  "message":"Plugin \"pagani-prototype\" updated from 0.0.2 to 0.0.3 for scope user. Restart to apply changes."}
claude plugin list --json   # version 0.0.3
```

Uninstall and marketplace removal:

```bash
claude plugin uninstall pagani-prototype --json -y
# {"outcome":"ok","pluginId":"pagani-prototype@pagani-prototype","keptData":false, ...}
claude plugin list --json
# []

claude plugin marketplace remove pagani-prototype --json
# {"command":"marketplace-remove","outcome":"ok","marketplace":"pagani-prototype", ...}
claude plugin marketplace list --json
# []
```

After uninstall, a session could no longer resolve `pagani-probe`
(`PROBE-NOT-FOUND`). The versioned cache directory is left behind and marked
with `.orphaned_at`; `claude plugin prune` is the documented cleanup path.
`update` reports that a restart is required to apply changes.

---

## Conclusion

| Capability | Result |
|---|---|
| (1) `bin/` on PATH | PASS |
| (2) plugin agent selectable as main agent | PASS |
| (3) plugin `hooks/hooks.json` hooks fire | PASS |
| (3b) plugin-agent frontmatter hooks fire | NO (use `hooks/hooks.json`) |
| (4) command name | prefixed `/<plugin>:<command>`; bare name also resolves |
| (5) local marketplace install/update/uninstall | PASS |

Implication for PaganiStack: a plugin can ship the CLI (`bin/`), agents,
commands, and hooks, and it can be distributed from a local marketplace with
normal install/update/uninstall. Agent-frontmatter hooks should not be relied
on for a plugin-provided agent; declare hooks in the plugin's `hooks/hooks.json`
instead.

VERDICT: GO

---

## Plugin notes

PaganiStack now ships as the `pagani` plugin (`.claude-plugin/plugin.json` plus
`.claude-plugin/marketplace.json`, source `./`). The plugin provides:

- `bin/pagani` on PATH (the plugin loader adds the plugin's `bin/`; the copy in
  the plugin cache resolves its own `ROOT` and runs `resources/`, `scripts/lint.sh`
  and the rest correctly).
- Agents: `pagani:master`, `pagani:builder`, `pagani:explorer`, `pagani:planner`,
  `pagani:review-code` (bare `master` also resolves when unambiguous).
- Commands: `/pagani:pagani` and `/pagani:pagani-models` (bare `/pagani` and
  `/pagani-models` also resolve).
- Skills from every category directory listed in the manifest.
- Hooks from `hooks/hooks.json`: PreToolUse `Agent|Task` runs
  `pagani guard builder`; Stop runs `pagani guard stop`. Hooks declared in a
  plugin agent's own frontmatter do not fire in 2.1.319 (see Q3), so the master
  frontmatter no longer carries them.

A plugin cannot do what the old installer did:

- It does not merge keys into the user's global `~/.claude/settings.json`
  (permissions, model, `agent`, `env`). The user sets those by hand.
- It does not write `~/.claude/CLAUDE.md`.
- It does not install a launcher into `~/.local/bin`. The plugin's `bin/` is on
  PATH only inside a session. An old `~/.local/bin/pagani` launcher left by the
  previous installer shadows the plugin's copy, so remove it.
- It does not run the repo lint. `pagani doctor` runs `scripts/lint.sh` only
  when that file is next to the CLI (the plugin cache carries it).

Manual steps for a user:

1. `claude plugin marketplace add fernandoleitepagani/PaganiStack`
2. `claude plugin install pagani@pagani -y`
3. Start a new session (or `/reload-plugins`). Optionally set `"agent": "master"`
   in `~/.claude/settings.json` for `claude --agent master`.
4. Allow `Bash(pagani build:*)` in settings if the builder runs without prompts.
5. Run `pagani build --init` once to create `builder.env` for the headless builder.

Update with `claude plugin update pagani@pagani`; remove with
`claude plugin uninstall pagani` (and `claude plugin marketplace remove pagani`).
