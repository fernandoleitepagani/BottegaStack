---
name: setup-maestro
description: Configure which models bottega uses per role and at what effort. Writes an always-loaded rules file that overrides the skill defaults. Use for /setup-maestro, "configure bottega models", "bottega budget", or changing bottega's model choices.
---

# Setup maestro

Write `~/.claude/rules/bottega-models.md`, an always-loaded rule that sets bottega's model and effort per role.

## Steps

### 1. Detect available models

The models a subagent accepts are `opus`, `sonnet`, and `haiku`. Effort is `low`, `medium`, or `high`. Never write `xhigh` or `max`, and never `high` on a non-haiku model.

### 2. Load current state

The default role table is **Models per role** in `../maestro/references/subagents.md`. Read it now. If `~/.claude/rules/bottega-models.md` already exists, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from those defaults. A line whose role is not in that table is from a retired role. Drop it.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Use `AskUserQuestion`. Offer these three options with these exact labels, and name the current budget when the rule records one. With no rule, say that `standard` matches the skill defaults.

- `standard (the defaults)`
- `small (lowest effort everywhere)`
- `large (more effort on hard work)`

**(b) Apply it.** Build the working table from the defaults, and on a re-run keep any role the user changed by hand.

- `standard` keeps the table as written.
- `small` sets every opus and sonnet effort to `low`, normal and high risk alike. Haiku stays `high`.
- `large` sets opus and sonnet to `medium` in both columns. Never `high` on them.

**(c) Show the roles and confirm.** Show every role with its normal and high-risk value. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering `opus`, `sonnet`, and `haiku` with an effort. Use `AskUserQuestion`. Panel roles (`arena runners`, `architect runners`) are lists: one subagent runs per entry, so the list length sets the runner count. The normal list has 2 entries and no cross-judge. The high list has up to 4 entries and the `arena cross-judge` runs. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every value is one of the three models plus an allowed effort. If not, stop and ask again.

### 5. Write the rule

Write `~/.claude/rules/bottega-models.md` with a `# budget` line and one line per role of the table, in table order, `role: <normal> | <high>`, using the table's role labels. A panel role lists one entry per runner, comma-separated. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# bottega model configuration. One line per role: `role: <normal risk> | <high risk>`.
# Delete a line to fall back to the skill default. Read by /maestro and the skills it routes to.
# budget: standard
orchestrator: opus low | opus medium
arena runners: sonnet low, haiku high | sonnet medium, sonnet medium, haiku high, haiku high
```

### 6. Retire an old status line

Earlier bottega versions installed a status line. If `~/.claude/settings.json` has a `statusLine` whose command runs `~/.claude/bottega/statusline.py`, tell the user it is no longer maintained and still works on its own. Offer to restore their previous one from `~/.claude/statusline.backup.json` (or the newest `statusline.backup-<stamp>.json`), and change `settings.json` only on a yes, after saving a copy to `settings.json.bottega-backup-<UTC YYYYmmdd-HHMMSS>`.

### 7. Confirm

Tell the user the rule was written and applies to new sessions. Re-running this skill updates them. Add one tip: disable MCP servers you do not use, because every tool definition is re-sent with every message.

### 8. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, read `../create-verification-skill/SKILL.md` and follow it. On no, move on without pushing.
