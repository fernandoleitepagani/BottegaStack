---
name: session-handoff
description: Compact a PaganiStack session into a handoff document for a fresh agent. Use when the context is near full, the session is ending, or another machine will continue the job.
---

# Session Handoff

Write the smallest document that lets a fresh agent continue without rereading
the conversation.

## Where

`pagani/jobs/<id>/handoff.md`. If there is no job, write to the OS temp
directory and tell the user the path.

## Include

```markdown
# Handoff: <job>

## Goal
## Current stage
## What changed
## What is next
## Open questions
## Files to read
## Commands to run
## Suggested skills
```

## Rules

- Reference artifacts by path; do not duplicate `SPEC.md`, `build/<task>.md`, or
  review files.
- Redact secrets, tokens, and personal data.
- Name the exact next action.
- Name the skills the next agent should load.
- Keep it under one page.

## Report

```
HANDOFF: <path>
NEXT: <one line>
```
