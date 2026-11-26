# Bottega in OpenCode (experimental, #46)

Bottega's skills use harness-neutral words. Read this file once per session, before your first spawn, and map each word with the tables below. If a word has no row, use the plain meaning and say so. Rows marked *check* come from bottega's port notes, not from current OpenCode docs; confirm them against the tool before relying on them.

## Subagents

| Bottega says | OpenCode |
|---|---|
| spawn an **explorer** (read-only) | the native subagent (task) tool with a read-only agent; the brief says "do not edit files" (*check* the agent name) |
| spawn a **delegate** (implementer, reviewer, verifier) | the native subagent tool; the brief's first line is `Read <maestro dir>/worker.md before starting.` |
| in **its own worktree** | a separate git worktree per parallel writer |
| the role's **model and effort** | **Models** below, as `provider/model` |

## Models

| Tier | Model and effort |
|---|---|
| **`heavy`** | `opus` `medium` |
| **`medium`** | `opus` `low` |
| **`standard`** | `deepseek v4.1 flash`* |
| **`fast`** | `glm-5.3-flash`* |

Non-Anthropic models: try the free version first, then OpenCode Go's if it is unavailable or rate-limited.

Tiers per role and difficulty are in the router's **Subagents** table; `~/.bottega/models.md` overrides any cell.

## Tools and commands

| Bottega says | OpenCode |
|---|---|
| the **todo list** | OpenCode's todo tool when present; otherwise keep it in your reply |
| **ask the user** with options | ask in plain text, numbered options |
| **run a bundled skill** | read `<skills dir>/<name>/SKILL.md` and follow it |

## Paths

| Bottega says | OpenCode |
|---|---|
| **transcripts** | OpenCode's session storage under `~/.local/share/opencode/` (*check*) |
| **project skills dir** | `.opencode/skills/` (*check*) |
| **installed skills** | `~/.config/opencode/skills/<name>` (from `npx skills add fernandoleitepagani/BottegaStack -g -a opencode`) |

## Manual-only skills

Every bottega skill sets `disable-model-invocation: true`, so none loads or triggers until `/maestro` or the user calls it.
