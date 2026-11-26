# Setup

Write the user's model file: which model and effort each role runs at, per difficulty. Adapted from pstack's `setup-pstack` (MIT, see NOTICE). Run it on `/maestro setup`, "configure bottega models", or a budget change. Re-running it updates the file.

**Difficulty** is the run's route: **simple** is the small-fix playbook (one file, about 20 lines, normal risk), **medium** is normal risk, **hard** is high risk. **Roles** are the ones in `<maestro dir>/references/subagents.md`: orchestrator, explorer, implementer, reviewer, verifier.

## 1. Detect models

List the model and effort values your harness's subagent tool accepts in this session (harness file, **Subagents**). That is the dependable source. When none can be detected, ask the user to paste what they have. Never write a model you have not confirmed. Effort never goes above `high` (no `xhigh`, no `max`).

## 2. Load the current file

The model file is `~/.bottega/models.md` on every harness.

If the file exists, its `# budget` line and role lines are the current choices. Otherwise start from the defaults in step 5, which are your harness's column of `<maestro dir>/references/models.md` (the example below shows Claude Code). Drop a line whose role is not in step 5 and say so.

## 3. Budget, then confirm

1. Ask for a budget with these labels (ask the user with options), naming the current one:
   - `large: the defaults`
   - `medium: one effort step lower`
   - `small: two effort steps lower`
2. Apply it on the ladder `high` > `medium` > `low`. A role already at `low` stays there. Keep any role the user set by hand on an earlier run.
3. Show the table (role × simple | medium | hard) and ask whether to accept it or change specific cells, offering only detected models. A cell may also say `inherit`, meaning the role runs on the session's model (omit `model` when spawning).

## 4. Validate

Every model is one step 1 detected, every effort is `high` or lower. If a choice fails, ask again.

## 5. Write the file

Overwrite the whole file so re-runs stay idempotent. No frontmatter. Shape, with the defaults:

```
# bottega models (written by /maestro setup; rerun it to change). One line per role:
# simple | medium | hard, each "<model> <effort>", "inherit", or "inline" (the orchestrator does it itself). Delete a line to use the default.
# budget: large
orchestrator: sonnet medium | sonnet medium | opus medium
explorer: haiku high | haiku high | haiku high
implementer: inline | sonnet medium | opus low
reviewer: sonnet medium | sonnet medium | opus low
verifier: sonnet medium | sonnet medium | opus medium
```

## 6. Confirm and offer

Say where the file was written and that it applies to new sessions; the orchestrator's own model is still the one the user picks for the session. Then, once: if the project has no `verify-<app>` skill, offer `/create-verification-skill` so agents can prove changes on the real app. On no, move on.

**Reply:** the budget, the table as written, any cell you replaced, and the file path.
