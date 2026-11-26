# Bottega in Claude Code

Bottega's skills use harness-neutral words. Read this file once per session, before your first spawn, and map each word with the tables below. If a word has no row, use the plain meaning and say so.

## Subagents

| Bottega says | Claude Code |
|---|---|
| spawn an **explorer** (read-only) | `Agent` with `subagent_type: "Explore"`; the brief also says "do not edit files", and you check `git status` after |
| spawn a **delegate** (implementer, reviewer, verifier) | `Agent` with `subagent_type: "general-purpose"`; the brief's first line is `Read <maestro dir>/references/delegate.md before starting.` |
| in **its own worktree** | `isolation: "worktree"` |
| in the **background** | the default; you are notified when it finishes |
| the role's **model and effort** | `model` (`opus`, `sonnet`, `haiku`, `fable`) and `effort` (`low`, `medium`, `high`) on the `Agent` call |
| **inherit** | omit `model` |

## Tools and commands

| Bottega says | Claude Code |
|---|---|
| the **todo list** | `TodoWrite` when the session has it; otherwise keep the list in your reply |
| **ask the user** with options | `AskUserQuestion`; in `-p` mode, ask in plain text |
| **run a bundled skill** | `Read` `<skills dir>/<name>/SKILL.md` and follow it; the `Skill` tool refuses them (`disable-model-invocation: true`). Tell the user to type `/bottega:<name>` when a built-in command shares the name (`/plan`). |

## Paths

| Bottega says | Claude Code |
|---|---|
| **transcripts** | `~/.claude/projects/<slug>/<session>.jsonl`; slug = workspace path with `/` and `.` replaced by `-`; never read other projects |
| **project skills dir** | `.claude/skills/` |
| **worktrees** it creates | `.claude/worktrees/` (also in `git worktree list`) |
| **installed skills** | the plugin under `~/.claude/plugins/`; the newest copy has the highest `version` in its `.claude-plugin/plugin.json` |

## Manual-only skills

Every bottega skill sets `disable-model-invocation: true`, so none loads or triggers until `/maestro` or the user calls it.
