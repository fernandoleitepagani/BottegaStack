---
name: plan
description: "Turn a prompt into a detailed, agreed spec by grilling the user one decision at a time. Map mode for efforts too big to settle in one session. Use for /plan, /bottega:plan, 'plan this', 'plan this with me', 'grill me', 'let us design', 'spec this out', 'help me plan', 'walk me through the design', 'architect this feature', or when /maestro routes multi-session work here. Hands off to /tickets."
disable-model-invocation: true
---

# Plan

Turn the user's prompt into a spec they agree with. You interview; the user decides. The spec records decisions the user made, never ones you made for them. A spec line the user never agreed to is a defect.

The grilling method is adapted from Matt Pocock's `grilling` and `to-spec` skills (github.com/mattpocock/skills, MIT).

`<maestro dir>` is `../maestro` from this file, as an absolute path. Roles and tiers come from `<maestro dir>/SKILL.md` (**Subagents**); models from your harness file.

## 0. Size it

Read the prompt and, through one or two explorer subagents (`<maestro dir>/playbooks/investigation.md`, **Briefing an explorer**), the code it touches. Then pick one:

- **Small.** It fits one session and has no open decisions. Say so, skip the spec, and route to the matching playbook through maestro's table (`<maestro dir>/SKILL.md`, **Route**).
- **Plan.** One grilling session can settle it. Continue with step 1.
- **Map.** Too many unknowns to settle in one session (a migration, a new subsystem, a product that does not exist yet). Go to **Map mode** below.

State your pick and why in one line. Don't wait for confirmation.

## 1. Grill

Keep built-in plan mode off: it pushes the agent to write a plan before the questions are done.

Work the decisions as a tree. A decision is on the **frontier** when every decision it depends on is settled.

1. **Each round, ask the whole frontier directly in chat.** Number each question. Give your recommended answer and its reason in one line each, worded so that "yes" accepts it. Do not call interactive form/question tools; just ask clearly in your reply and stop.
2. **Facts are not questions.** Anything the code, git, or docs can answer goes to an explorer subagent, never to the user. Ask the user only for product calls, preferences, priorities, and constraints.
3. **Ungrillable questions go to a prototype.** When the answer depends on seeing it (layout, feel, timing, which approach is faster), build a throwaway per `<maestro dir>/playbooks/prototype.md` and ask the user to react to it.
4. **Push back.** If an answer conflicts with the code, an earlier answer, or the goal, say so with the evidence and ask again. "I don't know" is a valid answer: record it as an open question with your default.
5. **Recompute the frontier** after each round and ask again. Grilling ends when the frontier is empty **and** the user confirms you share one understanding. Don't write the spec before that confirmation.

Cover at least: the goal and who it is for, what done looks like (checks you can run), scope and out of scope, the data shape, the interfaces that change, the test seams (where tests attach, preferring few, high ones; mocks only at system boundaries), risk (`normal` or `high`, per maestro **Risk**), and constraints (deadlines, dependencies, what must not change).

## 2. Write the spec

Run `/sharpen` (`../sharpen/SKILL.md`) on the settled requirements if any criterion is still vague, then write `.bottega/plans/<slug>/spec.md` (create `.bottega/` with a `.gitignore` containing `*` if missing). Use the user's words. No file paths or code snippets in the decisions: those belong to tickets.

```markdown
# <title>
Risk: normal | high

## Goal
<who it is for, the problem, the smallest change that meets it>
## Done when
- <a check someone can run, and what it prints>
## Decisions
1. <decision>: <why, in the user's words where possible>
## Data shape and interfaces
<types, states, contracts that change>
## Test seams
- <seam>: <what is asserted there>
## Out of scope
- <item>: <why>
## Open questions
- <question>: <default if unanswered>
```

Show the spec, ask the user to correct anything they did not say, and fix it. Then hand off: tell the user to run `/tickets .bottega/plans/<slug>/spec.md` in this same session. Don't `/clear` or compact between the plan and the tickets, so the grilling stays in context.

## Map mode

For efforts no single grilling session can settle. Adapted from Matt Pocock's `wayfinder` skill (MIT). Plan, don't build: each map ticket resolves a decision, not a slice of code.

1. **Name the destination** by grilling (step 1) until the end state is clear in one or two lines.
2. **Chart the map** at `.bottega/plans/<slug>/map.md`: `## Destination`, `## Decisions so far`, `## Questions` (one line each: `Q<nn> <title> | type: grill, prototype, or research | blocked-by: Q<nn>`), `## Not yet clear` (fog you can't phrase as a question yet), `## Out of scope`.
3. **Resolve research questions now,** in parallel, with explorer subagents. Write each answer under its question.
4. **One question per session after that.** The user runs `/plan map <slug>`: load the map only, take the first unblocked open question, resolve it (grill, or prototype), record the answer under `## Decisions so far`, and graduate fog into new questions. Stop.
5. **When no questions remain,** write `spec.md` from the map's decisions (step 2) and hand off to `/tickets`. A spec that still needs several sessions to build is fine: `/tickets` splits it.

**Reply:** the size you picked, then the grilling rounds, then the spec path and a summary of it, then the next command.
