---
name: session-handoff
description: Compact a BottegaStack session into a handoff for a fresh agent. Use when the context is near full, the session is ending, or another machine will continue the run.
---

# Session Handoff

Write the smallest handoff that lets a fresh agent continue without rereading
the conversation.

## Where

Return the handoff as your reply; it lives in chat, not in a file. When the run
continues in a new session, the master keeps it in the conversation and points
the next agent at the worktree, branch, and todo list.

## Include

```markdown
# Handoff: <run>

## Goal
## Current step
## What changed
## What is next
## Open questions
## Files to read
## Commands to run
## Suggested skills
```

## Rules

- Reference the branch, the SPEC reply, and the review verdicts; do not
  duplicate them.
- `PLAN.md` is the project-level file; do not copy it into the handoff.
- Redact secrets, tokens, and personal data.
- Name the exact next action.
- Name the skills the next agent should load.
- Keep it under one page.

## Report

```
HANDOFF: returned in this reply
NEXT: <one line>
```
