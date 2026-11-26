# Bottega in Codex (experimental, #46)

Bottega's skills use harness-neutral words. Read this file once per session, before your first spawn, and map each word with the tables below. If a word has no row, use the plain meaning and say so. Rows marked *check* come from bottega's port notes, not from current Codex docs; confirm them against the tool before relying on them.

## Subagents

| Bottega says | Codex |
|---|---|
| spawn an **explorer** (read-only) | Codex's native subagent tool, read-only sandbox; the brief says "do not edit files" (*check* the tool name) |
| spawn a **delegate** (implementer, reviewer, verifier) | the native subagent tool; the brief's first line is `Read <maestro dir>/worker.md before starting.` |
| in **its own worktree** | a separate git worktree per parallel writer |
| the role's **model and effort** | **Models** below |

## Models

| Tier | Model and effort |
|---|---|
| **`heavy`** | `sol` `high` |
| **`medium`** | `sol` `medium` |
| **`standard`** | `sol` `low` or `terra` `medium` |
| **`fast`** | `luna` `high` |

Tiers per role and difficulty are in the router's **Subagents** table; `~/.bottega/models.md` overrides any cell.

## Tools and commands

| Bottega says | Codex |
|---|---|
| the **todo list** | Codex's plan tool when present; otherwise keep it in your reply |
| **ask the user** with options | ask in plain text, numbered options |
| **run a bundled skill** | read `<skills dir>/<name>/SKILL.md` and follow it |

## Paths

| Bottega says | Codex |
|---|---|
| **transcripts** | `~/.codex/sessions/` (*check*) |
| **project skills dir** | `.codex/skills/` (*check*) |
| **installed skills** | the plugin under `~/.codex/plugins/cache/bottega/` (`codex plugin add bottega@bottega`) |

## Manual-only skills

Every bottega skill sets `disable-model-invocation: true`, so none loads or triggers until `/maestro` or the user calls it.
