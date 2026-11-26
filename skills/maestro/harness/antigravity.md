# Bottega in Antigravity CLI (experimental, #46)

Bottega's skills use harness-neutral words. Read this file once per session, before your first spawn, and map each word with the tables below. If a word has no row, use the plain meaning and say so. Rows marked *check* come from bottega's port notes, not from current Antigravity docs; confirm them against the tool before relying on them.

## Subagents

| Bottega says | Antigravity CLI |
|---|---|
| spawn an **explorer** (read-only) | the native subagent tool with `TypeName: research`, `Workspace: inherit`; the brief says "do not edit files" |
| spawn a **delegate** (implementer, reviewer, verifier) | `TypeName: self`, `Workspace: share`; the brief's first line is `Read <maestro dir>/worker.md before starting.` |
| in **its own worktree** | `Workspace: branch` |
| in the **background** | reactive wakeup; never poll |
| the role's **model and effort** | **Models** below |

## Models

| Tier | Model and effort |
|---|---|
| **`heavy`** | `neon` `medium` |
| **`medium`** | `neon` `low` |
| **`standard`** | `hydrogen` `medium` |
| **`fast`** | `hydrogen` `low` |

Tiers per role and difficulty are in the router's **Subagents** table; `~/.bottega/models.md` overrides any cell.

## Tools and commands

| Bottega says | Antigravity CLI |
|---|---|
| the **todo list** | the native task list if the session has one; otherwise keep it in your reply |
| **ask the user** with options | ask in plain text, numbered options |
| **run a bundled skill** | read `<skills dir>/<name>/SKILL.md` and follow it |

## Paths

| Bottega says | Antigravity CLI |
|---|---|
| **transcripts** | `~/.gemini/antigravity-cli/brain/` (*check*) |
| **project skills dir** | `.agents/skills/` |
| **installed skills** | the plugin under `~/.gemini/config/plugins/bottega/` (`agy plugin install`) |

## Manual-only skills

Every bottega skill sets `disable-model-invocation: true`, so none loads or triggers until `/maestro` or the user calls it.
