---
name: wayfinding
description: Plan a BottegaStack effort too big for one session as a local map of decision tickets. Use when the destination is foggy and the work needs several rounds of decisions before a spec or implementation can start.
---

# Bottega Wayfinder

Adapted from Matt Pocock's `wayfinder`, with the issue tracker replaced by local
markdown under `docs/wayfinding/<effort>/map/`.

Use this when the work is too big for one plan: the destination is not clear,
and several decisions must be settled before a spec can be written. For normal
features, skip this and use `planning`.

## Base skills

- Load `interview` for the question rounds. Work the design tree breadth-first.
- Load `domain-modeling` when a term needs sharpening or a GLOSSARY/ADR update.

## Plan, don't do

Wayfinder is planning. Each ticket resolves a decision, not a slice of code. The
map is done when the way to the destination is clear and nothing is left to
decide before someone builds it.

## The map

`docs/wayfinding/<effort>/map.md` is the low-resolution index:

```markdown
# Map: <effort>

## Destination
What reaching the end of this map looks like.

## Notes
Domain, skills to consult, standing preferences.

## Decisions so far
- [<closed ticket title>](map/01-<slug>.md): one-line gist.

## Not yet specified
In-scope fog that is not sharp enough to ticket yet.

## Out of scope
Work ruled beyond this destination.
```

Each ticket is a file under `docs/wayfinding/<effort>/map/`:

```markdown
# <NN>: <question title>

Type: research | prototype | interview | task
Status: open | claimed | closed
Blocked by: <ticket numbers/titles> or "none"

## Question
The decision or investigation this ticket resolves.

## Resolution
Filled when closed: the answer, the evidence, and what it unblocks.
```

## Ticket types

- **research** (AFK): read docs, APIs, or local resources to surface a fact.
  Use the `research` skill if it is available.
- **prototype** (HITL): make a cheap artifact to react to. Use the `prototype`
  skill if it is available.
- **interview** (HITL): conversation. Load `interview` and `domain-modeling`.
- **task** (HITL or AFK): manual work that must happen before a decision can be
  made, such as provisioning access or moving data. The agent does it if it can;
  otherwise it hands the human a precise checklist. Use `wizard` if the human
  must follow a sequence of manual steps.

## Fog of war

Do not chart what you cannot see yet. **Not yet specified** holds the suspected
questions that are not sharp enough to ticket. When a resolution makes one
specifiable, move it out of the fog and create a ticket.

Ticket when the question is sharp now, even if it is blocked. Leave it in the fog
when you cannot phrase it sharply yet.

## Out of scope

Work beyond the destination goes under **Out of scope**, not in the fog. It never
graduates unless the destination is redrawn.

## Chart the map

1. Name the destination. Load `interview` and `domain-modeling`; settle what the
   effort is finding its way to.
2. Map the frontier breadth-first. Surface the open decisions and the first steps
   that are takeable now. If there is no fog, the job is small enough for
   `planning`; stop and say so.
3. Write `map.md` with Destination, Notes, empty Decisions so far, and the fog
   under Not yet specified.
4. Create the tickets you can specify now. Write blocking edges after the tickets
   exist, so the references are real.
5. Fire research tickets in parallel if they are independent. Do not resolve
   decisions for the human.
6. Stop. Charting is one session's work.

## Work the map

1. Read `map.md`, not every ticket body.
2. Pick the first open, unblocked, unclaimed ticket. If the user named one, use
   it. Claim it by setting `Status: claimed`.
3. Resolve it as its type. Load the skills its Notes name.
4. Record the resolution in the ticket, set `Status: closed`, and add one line to
   Decisions so far.
5. Create newly surfaced tickets and wire their blockers. Graduate fog that is
   now sharp. Move anything beyond the destination to Out of scope.
6. Resolve one ticket per session, except research tickets, which can run in
   parallel.
