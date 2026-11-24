# Understand the code before changing it

Editing code you don't understand is how subtle regressions ship, and that's as true for the agent as for you. Agents usually fail in one of two ways. They misread what you want, or they don't have the context to do the work right. [What goes in a prompt](./02-maestro.md#what-goes-in-a-prompt) handles the first. This page handles the second.

bottega gives you three ways in. `/understand how` explains what the code does now. `/understand why` digs up the reasons it's shaped that way. `/understand recall` rebuilds your own recent context on a topic. Each one also makes the agent explain itself in words you can check. That's how you supervise an agent that may know the code better than you do.

![A detective studies a machine blueprint with a magnifying glass while robots fetch case files; the evidence board behind her links clues under /understand how and /understand why.](./images/understanding.jpg)

## Start with a read-only investigation

When the cause is unclear, ask for findings, not a fix:

```text
/maestro investigate why background jobs time out every few hours. give me what we know, what data you used, and your best hypotheses. don't change any code yet.
```

"don't change any code yet" routes this to the [Investigate playbook](../../skills/maestro/playbooks/investigate.md). It runs `/understand how`, adds `/understand why` for questions about motivation, and returns a cited explanation. For a choice between options, it returns a recommendation with a trade-offs table. Asking "what data you used" makes the agent separate its evidence from its guesses. When the findings point at a fix, start the fix as a new task.

## Trace behavior with `/understand how`

```text
/understand how do we dedupe notifications? is there an n+1 when we look up subscribers?
```

Ask the question you actually have. [`/understand`](../../skills/understand/SKILL.md) (how mode) reads the code and answers at the level of a senior engineer onboarding you onto the subsystem, with the runtime flow, the key types, and the non-obvious parts. For a big subsystem it fans out two to four read-only explorers first. For a narrow question it just reads and explains.

## Dig up history with `/understand why`

```text
/understand why was the retry limit set to five? does the reason still hold?
```

[`/understand`](../../skills/understand/SKILL.md) (why mode) starts from source control, then queries the issue tracker through `gh`, with git and `gh` investigators running in parallel. Other evidence categories, such as long-form docs, team chat, or observability, run only when you have approved that MCP server for the session. The report cites everything, separates direct evidence from inference, and says "appears to" when the record is thin. A null result gets reported too, because "nobody wrote down why" is itself an answer.

The two compose naturally. `do why first then how` is a good prompt when you suspect the history explains the mess.

## Rebuild your own context with `/understand recall`

```text
/understand recall catch me up on the export work from last week
```

[`/understand`](../../skills/understand/SKILL.md) (recall mode) mines your own recent chats plus the shared record (issues, prior fixes, errors still firing) and hands back a brief on where things stand and what's next. Your old chats hold context that a fresh agent lacks, so start new work on an old topic by loading it first, then hand over the new input:

```text
/understand recall my work on the virtualized list from yesterday, then read this bug report.
```

If you want to resume one specific chat, that's the Handoff playbook below, not `/understand recall`.

## Take over prior work with Handoff

When another agent (or you, last week) left a branch mid-flight:

```text
/maestro take over this branch. read the decision log, figure out what's done, and continue from there. don't redo finished work.
```

The [Handoff playbook](../../skills/maestro/playbooks/handoff.md) treats the prior trail as authoritative. It reconstructs the branch state and decisions, names the resume point, and verifies inherited claims against the original goal instead of re-deriving everything from scratch.

**Pitfall:** don't skip this page's skills because "the agent will read the code anyway." An agent that starts editing without a traced model tends to fix the symptom at the first plausible spot. `/understand how` first is cheaper than the second bug.

Next: [Design the change](./04-design.md).
