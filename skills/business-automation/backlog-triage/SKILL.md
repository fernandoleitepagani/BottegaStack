---
name: backlog-triage
description: Move items in a local BACKLOG.md through a small state machine, verify them, grill if needed, and write an agent-ready brief. Use when you want to triage a backlog without an issue tracker.
---

# Pagani Triage

Adapted from Matt Pocock's `triage`, with the issue tracker replaced by a local
`BACKLOG.md`.

Use this when you keep a backlog file and want to decide what is ready for
PaganiStack. For a single request, skip this and start `/pagani <feature>`.

## States

Each item has one category and one state:

- Category: `bug` or `enhancement`.
- State: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`,
  `wontfix`.

`ready-for-agent` means the item has a brief and can start `/pagani`.
`ready-for-human` means it needs a person before an agent can start.
`wontfix` means it will not be actioned; record why.

## Backlog format

```markdown
# Backlog

## <item title>
Category: enhancement
State: needs-triage
Source: <link or note>

What the user asked for, verbatim.

### Triage notes
- Established:
- Needed:
```

Keep one item per `##` section. Add the brief under `### Brief` when the state
becomes `ready-for-agent`.

## Show what needs attention

Read `BACKLOG.md` and list, oldest first:

1. Items with no state.
2. Items in `needs-triage`.
3. Items in `needs-info` with new information since the last note.

Show a one-line summary per item. Let the user pick.

## Triage one item

1. Read the item, its notes, and the code. Use the project's glossary and ADRs.
2. Check redundancy: search by domain concept for an existing implementation. If
   it exists, set `wontfix` and point to where it lives.
3. Verify the claim. For a bug, reproduce it with the `diagnosis` loop. For an
   enhancement, confirm the current behaviour and the gap.
4. If the item is vague, load `interview` and `domain-modeling` and ask in rounds.
   Update the notes as decisions land.
5. Apply the outcome:
   - `ready-for-agent`: write a brief under `### Brief` with what to build,
     acceptance criteria, and verification. Then start `/pagani` with it.
   - `ready-for-human`: same brief, plus why it cannot be delegated.
   - `needs-info`: write the specific questions under `### Triage notes`.
   - `wontfix`: record why and stop.
6. Update `BACKLOG.md`.

## Rules

- Do not start implementation during triage. The output is a decision and a
  brief, not code.
- Do not ask the user for facts the repo can answer.
- Do not re-ask a question that is already answered in the notes.
- Every item has exactly one category and one state.

## Report

```
ITEM: <title>
STATE: <state>
NEXT: <brief written, question asked, or stopped>
```
