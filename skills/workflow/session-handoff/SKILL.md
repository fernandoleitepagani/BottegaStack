---
name: session-handoff
description: Compact a BottegaStack session into a handoff for a fresh agent. Use when the context is near full, the session is ending, or another machine will continue the run.
---

# Session Handoff

Write the smallest handoff that lets a fresh agent continue without rereading
the conversation.

## Where

Write the handoff to `${BOTTEGA_HANDOFF_DIR:-/tmp}/<repo>-handoff-<slug>.md`:
`<repo>` is the basename of `git rev-parse --show-toplevel`, `<slug>` the run
slug or a short task slug. Create the directory when `BOTTEGA_HANDOFF_DIR`
points at a missing one, and write with `umask 077` so the file is mode `600`;
overwriting an old handoff is fine. The file is disposable (`/tmp` may be
tmpfs) and can be regenerated from the resumed chat with `claude --continue`.

Reply with the path and one `NEXT:` line, so the next session starts with
`/bottega:maestro implement the run described in <path>`.

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
HANDOFF: <path>
NEXT: <one line>
```
