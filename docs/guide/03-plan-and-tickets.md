# Plan and split into tickets

For anything bigger than one session, bottega plans with you before it builds. `/plan` interviews you until the decisions are yours, then `/tickets` splits the result into tickets that each fit one fresh session. The grilling and slicing are adapted from Matt Pocock's skills ([mattpocock/skills](https://github.com/mattpocock/skills), MIT).

## `/plan`: get grilled

```text
/maestro add team workspaces. members share projects, owners manage billing.
```

The agent maps the code with explorers, then asks you questions in rounds. Each round asks everything that can be decided now, numbered, with a recommended answer you can accept with "yes". It looks facts up in the code instead of asking you. When a question needs seeing ("which layout?"), it builds a throwaway prototype and asks you to react.

Answer actively. Push back, and say "I don't know" when you don't: it goes into the spec as an open question with a default. Grilling ends when nothing is left to decide and you confirm you agree.

The spec lands in `.bottega/plans/<slug>/spec.md`: goal, done checks, decisions, data shape, test seams, out of scope, open questions. Read it. Anything in it you never said is a defect, so tell the agent to fix it.

Keep plan mode off: it pushes the agent to write a plan before the questions are done.

### Map mode, for work too big to settle at once

A migration or a new product can have more open questions than one session holds. `/plan` then charts a map, `.bottega/plans/<slug>/map.md`, with one question per line and what blocks each. Research questions get answered by explorers right away. After that you run `/plan map <slug>` once per session: it takes the next unblocked question, grills or prototypes it, and records the decision. When no questions remain, it writes the spec.

## `/tickets`: one ticket per session

```text
/tickets .bottega/plans/team-workspaces/spec.md
```

Run it in the same session as `/plan`, without `/clear`, so the grilling is still in context. Each ticket is a thin vertical slice (types, logic, interface and tests together) that you can check on its own. For every ticket you get:

- **Acceptance criteria** written as checks: a command and the output that proves it.
- **The split**: what the orchestrator does itself (decisions, reviews, checks, the gate), and a table of subagents with role, abstract tier, task, write scope, and which ones run together.
- **Blocked by and wave**: the tickets it needs first. Tickets that write the same file are serialized even when they don't depend on each other.
- **The orchestrator tier**: `heavy` for high risk, auth, concurrency, migrations, or shared interfaces across >3 modules; `medium` for open design calls or multi-file coordination; `standard` otherwise (translated per harness in its harness file's **Models** table).

It shows the breakdown as a table and asks whether the granularity and blocking edges are right before writing anything. Then it writes one file per ticket and a `PLAN.md` with the waves:

```text
Wave 1 (parallel): T01 schema and types, T02 invite email template
Wave 2: T03 invite flow (needs T01)
Wave 3: T04 billing owner role (needs T01, T03)
```

Tickets in one wave can run at the same time, each in its own session and git worktree.

Next: [Implement a ticket](./04-implement.md).
