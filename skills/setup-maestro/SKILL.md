---
name: setup-maestro
description: Configure which models bottega uses per role and at what effort, and install the bottega status line. Writes an always-loaded rules file that overrides the skill defaults. Use for /setup-maestro, "configure bottega models", "bottega budget", or changing bottega's model choices.
---

# Setup maestro

Write `~/.claude/rules/bottega-models.md`, an always-loaded rule that sets bottega's model and effort per role, and install the bottega status line.

## Steps

### 1. Detect available models

The models a subagent accepts are `opus`, `sonnet`, and `haiku`. Effort is `low`, `medium`, or `high`. Never write `xhigh` or `max`, and never `high` on a non-haiku model.

### 2. Load current state

The default role table is the rule shape in step 5. If `~/.claude/rules/bottega-models.md` already exists, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from those defaults. A line whose role is not in step 5 is from a retired role. Drop it.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Use `AskUserQuestion`. Offer these three options with these exact labels, and name the current budget when the rule records one. With no rule, say that `standard` matches the skill defaults.

- `standard (the defaults)`
- `small (lowest effort everywhere)`
- `large (more effort on hard work)`

**(b) Apply it.** Build the working table from the defaults, and on a re-run keep any role the user changed by hand.

- `standard` keeps step 5 as written.
- `small` sets every opus and sonnet effort to `low`, normal and high risk alike. Haiku stays `high`.
- `large` sets opus and sonnet to `medium` in both columns. Never `high` on them.

**(c) Show the roles and confirm.** Show every role with its normal and high-risk value. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering `opus`, `sonnet`, and `haiku` with an effort. Use `AskUserQuestion`. Panel roles (`arena runners`, `architect runners`) are lists: one subagent runs per entry, so the list length sets the runner count. The normal list has 2 entries and no cross-judge. The high list has up to 4 entries and the `arena cross-judge` runs. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every value is one of the three models plus an allowed effort. If not, stop and ask again.

### 5. Write the rule

Write `~/.claude/rules/bottega-models.md` with a `# budget` line and one line per role, `role: <normal> | <high>`, using the labels the maestro skill uses. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# bottega model configuration. One line per role: `role: <normal risk> | <high risk>`.
# Delete a line to fall back to the skill default. Read by /maestro and the skills it routes to.
# budget: standard
orchestrator: opus low | opus medium
feature: sonnet low | sonnet medium
refactoring: sonnet low | sonnet medium
bug-fix: sonnet low | sonnet medium
perf-issue: sonnet low | sonnet medium
hillclimb: sonnet low | sonnet medium
reviewer: sonnet low | sonnet medium
diagnosis: sonnet low | sonnet medium
crossfire: none | sonnet medium
comment-sicko: sonnet low | sonnet medium
architecture explorer: haiku high | haiku high
how explorer: haiku high | haiku high
how explainer: opus low | opus medium
why investigators: haiku high | haiku high
why synthesizer: opus low | opus medium
swarm workers: haiku high | haiku high
verification workers: haiku high | haiku high
arena runners: sonnet low, haiku high | sonnet medium, sonnet medium, haiku high, haiku high
architect runners: sonnet low, haiku high | sonnet medium, sonnet medium, haiku high, haiku high
arena cross-judge: none | sonnet low
```

### 6. Install the status line

The status line shows model and effort, a context bar, prompt-cache warm or cold, and subagents running and done. It also writes `.bottega/status.json`, which the maestro handoff and cold-cache rules read.

1. Resolve `<abs dir>`, the absolute path of the `scripts/` folder next to this file.
2. Check the current value: `python3 <abs dir>/set-statusline.py --check`. It prints only the `statusLine` key, never the rest of `~/.claude/settings.json`.
3. Install it: `python3 <abs dir>/set-statusline.py`. It copies `statusline.py` to the stable path `~/.claude/bottega/statusline.py` (so plugin updates never break it) and sets only the `statusLine` key to run that copy, in an atomic write. Before changing anything it saves the whole `~/.claude/settings.json` to `~/.claude/settings.json.bottega-backup-<UTC YYYYmmdd-HHMMSS>`, and a non-bottega `statusLine` to `~/.claude/statusline.backup.json` (or `statusline.backup-<stamp>.json` when that file exists and differs). Backups are never overwritten. If settings.json does not exist, it creates it with only that key.
4. Bottega's scripts make `.bottega/` ignore itself through `.bottega/.gitignore`, so nothing is needed in global git config. Only if the user asks, offer to also add `.bottega/` to their global git excludes, and ask with `AskUserQuestion` before touching global git config.

Tell the user that restoring means copying the `statusLine` value from `~/.claude/statusline.backup.json` (or the newest `statusline.backup-<stamp>.json`) back into the `statusLine` key, or copying a `settings.json.bottega-backup-<stamp>` file over `~/.claude/settings.json`.

### 7. Confirm

Tell the user the rule and status line were written and that both apply to new sessions. Re-running this skill updates them. Add one tip: disable MCP servers you do not use, because every tool definition is re-sent with every message.

### 8. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, read `../create-verification-skill/SKILL.md` and follow it. On no, move on without pushing.

### 9. Doctor

Run `python3 <abs dir>/doctor.py`. It is read-only and prints one `ok`, `warn` or `FAIL` line per check with a fix hint. Report every FAIL and warn line with its fix. `/setup-maestro doctor` runs only this step.
