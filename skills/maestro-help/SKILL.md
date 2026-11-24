---
name: maestro-help
description: Guides users through bottega setup, /maestro, and picking the skill, playbook, or principle for a task. Type /maestro-help with a question.
disable-model-invocation: true
---

# Maestro help

Answer the user's question about bottega, hand them a prompt they can send, and link the file the answer came from. For a help question, don't start the work. The user asked how, and a bottega run spends real tokens, so let them send the prompt.

A message that asks for work, such as "use bottega to fix this bug", is not a help question. Read [`maestro`](../maestro/SKILL.md), do the work under it, and mention once that a one-line `CLAUDE.md` pointer keeps it on.

This file maps questions to the skills and guide pages that hold the answers. Those files own the details. Read the file you route to before you quote it, and trust it when it disagrees with this map. The links here point into the installed plugin, which the user may not be able to open, so name the file's path in the bottega repo.

## Find out what they need

Infer the need from the message and the conversation. A named situation, such as "which skill reviews a PR?", goes straight to its section. If the need is still unclear, ask one multiple-choice question with these options, then answer only the section they pick:

- Get set up
- Start a task with `/maestro`
- Pick a skill for a situation
- Fix a run that went wrong
- Make bottega my own

Check the state that changes the answer, and mention it only when it does:

- No `~/.claude/rules/bottega-models.md` means `/setup-maestro` hasn't run for this user, so every role uses its default model.
- No `verify-*` skill or other app harness in the project means agents have no scripted way to drive the app. Mention `/create-verification-skill` when the question is about proving a change works.
- A `verify-*` skill whose feature map is stale means proofs may miss recent changes. Mention `/maintain-verification-skill` when the question touches that code.

When the model rule is missing and it matters, ask whether the user wants to pick a model for each role and a reasoning budget now. It matters when the user is new, the question is about setup or cost, or the answer depends on which models run. Ask at most once per chat. If the need is also unclear, ask both questions together. Offer two choices:

- Now: give them `/setup-maestro` to type, and answer their question too.
- Later: answer their question, and add one line saying every role keeps its default model until they run `/setup-maestro`.

## Get set up

1. Install from this repo with `claude plugin` (marketplace name `bottega`).
2. Run [`/setup-maestro`](../setup-maestro/SKILL.md). It asks for a reasoning budget, maps a model to each role, and writes a rule. The rule applies to new chats. Then it offers once to generate a verification skill for the project, unless the project already has one.
3. Start a real task with `/maestro`, a goal, and a check that can pass or fail.

Installing changes nothing until the user invokes a skill. Only `/setup-maestro` loads from the user's words. The [README](../../README.md) and [guide page 1](../../docs/guide/01-setup.md) have the details. Offer to word their first prompt with them, per [`references/prompting.md`](references/prompting.md).

If cost is the worry, say where the tokens go and how to spend fewer. bottega spends extra tokens on subagents and review panels. Rerun `/setup-maestro` and pick a smaller budget or cheaper models. A shorter panel list runs fewer subagents, one for each entry. Save `/maestro` for work that needs rigor.

Each command may take a `bottega:` prefix, such as `/bottega:maestro`. Other tools can read the skills, because they use the Agent Skills format. But most workflow skills, including `/maestro`, `/how`, `/why`, and `/teach`, spawn Claude Code subagents with per-role models, so those parts may not work there.

## Start a task with `/maestro`

`/maestro` matches the task to a playbook, copies the playbook's steps into the todo list, and runs the other skills as the steps need them. A step it skips stays in the list as `skip: <reason>`. A good prompt states the goal and how to tell it's done. It doesn't list skills, because a hand-written sequence tends to drop or reorder steps the playbook would keep. Read [`references/prompting.md`](references/prompting.md) before you help word one. [Guide page 2](../../docs/guide/02-maestro.md) has examples.

`/maestro` applies to the message that invokes it. To keep it on, add a one-line pointer to `CLAUDE.md` (for example, "Start every non-trivial task with /maestro") and re-invoke `/maestro` when the chat drifts. Mid-chat, "new task" makes it match a fresh playbook. `/maestro` already uses `maestro-agent` for the subagents its playbook steps spawn. To get the same style from a subagent of your own, spawn it with `subagent_type: "bottega:maestro-agent"`.

## Pick a skill

The default answer is `/maestro`, which runs most of the others when its steps need them. Name a skill directly when the user wants more or less of something than the playbook gives. Read the skill before you recommend it, and give one example prompt.

Read `../maestro/SKILLS-INDEX.md` (the full catalog, one line per skill) and pick from it.

The `principle-*` skills are covered under principles below.

Close calls:

- `/interface-review` covers only what a diff changed. `/better-interface` reviews a whole screen. The other `better-*` skills go deep on one domain.
- `/architect` shapes one change. `/improve-architecture` hunts across the whole codebase for what to deepen.
- `/how` explains what the code does. `/why` explains the reasons. `/teach` runs one or both and explains the result plainly.
- `/arena` gives every worker the same brief and merges the best parts. `/swarm` splits work into slices or a race and returns one report.
- `/architect` implements right after it settles the design. Add "with checkpoint" to review the design before it writes code.
- `/crossfire` reviews the diff. `/blast-radius` looks for breakage outside the diff and proves the one fact that makes the change safe.
- `/recall` rebuilds context across recent chats. `/ketchup` covers only this chat since the user's last message. Resuming one specific chat or branch is the Session pickup playbook.
- `/figure-it-out` designs one rigorous run. The Orchestrate playbook runs a program that spans days and many PRs. The Autonomous run playbook drives one task to a finish condition.

Not in bottega:

- `/loop` is a Claude Code built-in.
- bottega has no `/orchestrate` skill. Orchestrate is a `/maestro` playbook. If the slash menu shows `/orchestrate`, another plugin provides it.

## Playbooks and principles

Playbooks are step lists inside `/maestro`, not skills, so they have no slash command. Inside `/maestro`, describing the task picks one, and these phrases name one directly:

- "babysit this pr" or "check on pr 123" runs Babysit. It drives the PR to merge-ready and stops there. It doesn't merge unless the user asks to merge, land, or ship.
- "land the stack" runs Shipping.
- "take over this branch" runs Session pickup.
- "pause safely" runs Pause safely.
- "full autopilot on this queue" runs Autopilot in `land` mode. "autopilot, don't merge" runs it in `stack` mode.
- "run the eval playbook" runs Eval.

Without `/maestro`, a phrase such as "babysit this pr" may not run the playbook. The Playbooks section of [`maestro`](../maestro/SKILL.md) lists every playbook and when it applies. [Guide page 6](../../docs/guide/06-verify-and-ship.md) covers opening, babysitting, and landing a PR.

bottega has no planning skill. Claude Code's plan mode works alongside it. For work that spans phases or stacked PRs, asking `/maestro` for a plan runs the [Multi-phase plan playbook](../maestro/playbooks/multi-phase-plan.md), which writes the plan and doesn't implement it. For a design question, the Prototype playbook or `/architect` settles it in code first.

Principles are one-rule skills that `/maestro` reads and cites in its replies. The user rarely invokes one. They steer with the names instead, as in "apply prove it works. show me the real output." Typing `/principle-<name>` still loads one on demand. [Guide page 8](../../docs/guide/08-principles.md) lists them.

## Fix a run that went wrong

| Symptom | Fix |
|---|---|
| The mode stopped applying after a few turns | `/maestro` applies per message. Add the `CLAUDE.md` pointer, or start each task with `/maestro`. |
| A question got treated as the next step of the last task | Say "new task", or say the turn doesn't need the mode. |
| A new model choice had no effect | The rule from `/setup-maestro` applies to new chats. Start one. |
| Runs cost more than expected | See the cost paragraph under Get set up. |
| A skill didn't load on its own | Only `/setup-maestro` loads from the user's words. The others load when the user types them or when `/maestro` runs them, and it doesn't run every skill. |
| Parallel agents overwrote each other | Give each agent its own worktree, or run them as `Agent` calls with `isolation: "worktree"`. Worktrees share CPU, ports and disk, so cap fan-out. |
| An overnight run moved but finished nothing | `/loop` needs a check that can pass or fail, not a duration. See [guide page 7](../../docs/guide/07-overnight.md). |
| The reply claims success from a green build | Ask for the real command, flow, stored value, or profile. That's the prove-it-works principle. |

For a run that drifts, [`references/prompting.md`](references/prompting.md) has one-line steers. [Guide page 10](../../docs/guide/10-recipes-and-pitfalls.md) has more pitfalls and the recipes worth copying.

## Make bottega my own

- `/maestro write a skill for <workflow>` runs the Authoring playbook (`playbooks/authoring-a-skill.md`). The eval playbook tests a skill change blind.
- Fix a misbehaving skill in its own PR, not inside the feature work where it went wrong.

[Guide page 9](../../docs/guide/09-make-it-yours.md) covers each of these.

## PR checks

For PR checks, use `gh pr checks <n>`.

## Reply

Lead with the answer. Give at most one example prompt in a code block, adapted from [`references/recipes.md`](references/recipes.md) when one fits, then the link to that file. Keep it short unless the user asked for the whole map.
