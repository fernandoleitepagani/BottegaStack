---
description: Choose the model and effort each BottegaStack role uses and write ~/.claude/rules/bottega-models.md.
argument-hint: "[rerun to change model and effort routing]"
allowed-tools: Read, Write, Bash, AskUserQuestion
---

# Bottega Model Routing

Ask the user for a value and an effort for each BottegaStack role, then write
the routing rule file at
`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/rules/bottega-models.md`. No secrets, no
personal data.

## Roles and defaults

| Role | Default value | Default effort |
|---|---|---|
| explorer | haiku | low |
| trivial | haiku | low |
| builder | headless | medium |
| reviewer | sonnet | medium |
| reviewer-high-risk | opus | high |
| second-opinion | headless | medium |
| planner | `opus` (own model) | high |
| master | `opus` (own model) | medium |

A value is a Claude alias (`haiku`, `sonnet`, `opus`) or `headless`. `headless`
means the third-party headless builder or reviewer; a Claude alias means the
Claude subagent. `planner` and `master` keep their own model, written as their
agent's alias.

## Ask

Use `AskUserQuestion` for every role, in batches of at most four questions. Ask
the value and the effort separately, pre-selecting the default from the table.
Offer `haiku`, `sonnet`, `opus`, and `headless` for the value, and `low`,
`medium`, and `high` for the effort. If an answer is outside those sets, ask
again; the effort must be `low`, `medium`, or `high`. Keep
`reviewer-high-risk` at `opus, high` unless the user changes it.

## Write

Run `mkdir -p "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/rules"` if needed, then write
the file with the `Write` tool. One line per role as `role: value, effort`, in
this order, under 15 lines and with no extra keys:

```
# Bottega model routing (written by /maestro-models)
explorer: haiku, low
trivial: haiku, low
builder: headless, medium
reviewer: sonnet, medium
reviewer-high-risk: opus, high
second-opinion: headless, medium
planner: opus, high
master: opus, medium
```

Report the path written and the chosen values.
