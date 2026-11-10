---
description: Choose the model each BottegaStack role uses and write ~/.claude/rules/bottega-models.md.
argument-hint: "[rerun to change model routing]"
allowed-tools: Read, Write, Bash, AskUserQuestion
---

# Bottega Model Routing

Ask the user which model each BottegaStack role uses, then write the routing rule
file. No secrets, no personal data.

## Roles and defaults

| Role | Default | Values |
|---|---|---|
| explorer | haiku | a Claude model alias or `headless` |
| builder | headless | a Claude model alias or `headless` |
| reviewer | sonnet | a Claude model alias or `headless` |
| second-opinion | headless | a Claude model alias or `headless` |
| trivial | haiku | a Claude model alias or `headless` |

`headless` means the third-party headless builder or reviewer; a Claude alias
(`haiku`, `sonnet`, `opus`) means the Claude subagent.

## Ask

Use `AskUserQuestion` for each role, pre-selecting its default. Offer the Claude
aliases and `headless`. If the user picks a value outside that set, ask again.

## Write

Run `mkdir -p ~/.claude/rules` if needed, then write
`~/.claude/rules/bottega-models.md` with the `Write` tool. Keep it under 15 lines,
with no secrets and no extra keys:

```markdown
# Bottega model routing (written by /maestro-models)
explorer: <value>
trivial: <value>
builder: <value>
reviewer: <value>
reviewer-high-risk: opus
second-opinion: <value>
```

Keep `reviewer-high-risk: opus` unless the user asks to change it. Report the
path written and the chosen values.
