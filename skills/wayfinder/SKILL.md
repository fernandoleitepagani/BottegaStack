---
name: wayfinder
description: Plan work too big for one session as a map of decision tickets, then resolve them one at a time until the way to the destination is clear. Local files by default, GitHub issues on request.
disable-model-invocation: true
---

# Wayfinder

A loose idea has arrived, too big for one session, wrapped in fog. Wayfinder finds the way, it does not charge at the destination. It charts a **map** of **decision tickets** (questions whose resolution is a decision, not a slice of a build) and works them one at a time. The destination varies: a spec to hand off, a decision to lock before planning, or a change like a migration. Naming it is the first act, since it shapes every ticket.

## Plan, don't do

Each ticket resolves a decision. The map is done when nothing is left to decide. The pull to just do the work usually means you reached the edge of the map: hand off ([Feature playbook](../maestro/playbooks/feature.md)). A map's Notes may override this.

## Refer by name

Refer to every map and ticket by its title in anything the human reads, never a bare id or number. Put the link inside the name. Titles never contain labels or type prefixes. The type lives in the ticket's `type` field or label.

## Where the map lives

**Local (default).** Under `.bottega/wayfinder/<map-slug>/`: `map.md` and one `T-<nn>-<slug>.md` per ticket. Each ticket file starts with `type:`, `status: open|claimed|closed`, `blocked-by:` (ticket files). Closed means the answer is appended under `## Answer`. A ticket is **unblocked** when all blockers are closed. The **frontier** is open, unblocked, unclaimed tickets. Claim by setting `status: claimed` first.

**GitHub.** Only when the user names a repo. Map and tickets are issues (`gh issue create`, labels `wayfinder:map` and `wayfinder:<type>` only, tickets as sub-issues or linked in the map body, claim by `gh issue edit --add-assignee @me`). Ask once with `AskUserQuestion` listing the map and tickets to be created, then create them all. Create ids first, then wire references in a second pass.

## Map body

```markdown
## Destination
<what the end of this map looks like, one or two lines>
## Notes
<domain, skills to consult, standing preferences>
## Decisions so far
- [<closed ticket title>](link): <one-line gist>
## Not yet specified
<in-scope fog you cannot ticket yet>
## Out of scope
<work ruled beyond the destination, with why>
```

The map is an index. A decision lives in its ticket only. Open tickets are found by query, not listed. A ticket body is `## Question`, sized to one session.

## Ticket types

HITL needs a live human. The agent never answers the human's side.

- **Research** (AFK): a fact outside the working directory. A subagent resolves it with the **understand** skill (`../understand/SKILL.md`, how and why modes) plus docs, and records findings in the ticket.
- **Prototype** (HITL): a cheap concrete artifact to react to. Follow the Prototype playbook (`../maestro/playbooks/prototype.md`). Link it, do not paste it.
- **Grilling** (HITL, the default): conversation through `AskUserQuestion`, one question at a time.
- **Task** (HITL or AFK): manual work that unblocks a decision (sign up, provision, move data). Record what was done and resulting facts.

## Fog of war

Do not chart what you cannot see. If you can state a question sharply, make it a ticket, even if blocked. If you cannot, write it under **Not yet specified**, coarsely. Resolving a ticket graduates fog into tickets, one patch at a time. Work beyond the destination is **Out of scope**: close its ticket and leave one line with the reason. It never graduates.

## Chart the map

1. **Name the destination** by grilling the user via `AskUserQuestion`.
2. **Map the frontier** breadth-first. If no fog appears and one session suffices, skip the map and ask how to proceed.
3. Create the map: Destination and Notes filled, fog sketched.
4. Create the specifiable tickets, then wire blocking in a second pass.
5. Resolve `research` tickets in parallel with fresh subagents (role: explorer in `../maestro/references/subagents.md`; more than 3 follows its fan-out rule), results written into the ticket.
6. Stop. Charting resolves nothing by hand.

## Work through the map

Resolve at most one ticket per session, except research.

1. Load the map only, not every ticket.
2. Take the named ticket, else the first frontier ticket. Claim it first.
3. Resolve it by its type. Read related closed tickets on demand.
4. Record the answer, close the ticket, add a gist to Decisions so far.
5. Add new tickets, graduate fog, rule out-of-scope items, and update tickets the decision invalidated.
