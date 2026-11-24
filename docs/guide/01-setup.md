# Set up bottega

In this page you install the plugin, pick which models bottega uses, and run your first task. Setup is one command plus a short conversation.

## Install the plugin

In a shell, run:

```bash
claude plugin marketplace add <path-or-repo>
claude plugin install bottega@bottega
```

Claude Code prefixes plugin commands, so each command in this guide can also be typed with a `bottega:` prefix, such as `/bottega:setup-maestro`. Start a new session after installing.

## Pick your models

Run:

```text
/setup-maestro
```

[`/setup-maestro`](../../skills/setup-maestro/SKILL.md) shows you each role (code delegates, judgment, explorers, the review panels) with its model and effort, and asks what you want. Answer the questions. It writes `~/.claude/rules/bottega-models.md`, a small rule `/maestro` and the skills that spawn subagents read. Bottega's scripts make `.bottega/` ignore itself, so there is nothing to add to your git excludes.

Models are `opus`, `sonnet`, and `haiku`. Each role also takes an effort: `low`, `medium`, or `high`. The defaults are cheap on purpose. Code delegates run `sonnet` at low effort, judgment and prose run `opus` at low effort, and explorers and workers run `haiku` at high effort. High-risk runs move code delegates to `sonnet` medium and judgment to `opus` medium. The "Models per role" table in [`skills/maestro/references/subagents.md`](../../skills/maestro/references/subagents.md) has the full list.

You only override what you care about. A role with no line in the rule keeps the skill's default. To restore a default, delete that role's line. A rerun of `/setup-maestro` keeps any role whose value differs from the default. When a default changes, a rule written before the change still pins the old default, so delete those role lines, or delete the file, then run `/setup-maestro` again.

A model that Claude Code rejects falls back to the role default. For a panel role the value is a list, and one subagent runs per entry, so the list length sets the panel size. Setup also configures `swarm workers`, the default model for every `/swarm` worker.

## Accept the verification offers, or don't

At the end of setup, `/setup-maestro` looks for a way to prove app behavior in your project, either a `verify-*` skill or an existing harness. If it finds neither, it offers once to generate one with [`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md).

Say yes and it writes `.claude/skills/verify-<app>/`, a project-local skill that teaches agents to drive your app the way a user does. It proves the skill works once before handing it over. Say no and setup moves on. You can run `/create-verification-skill` yourself any time. [Verify and ship](./06-verify-and-ship.md#create-a-project-verification-skill) covers it in depth.

If you're new to bottega, say yes. An agent that can check its own work keeps going until the check passes. An agent that can't hands every result back to you to check by hand. Of everything in this guide, the verification skill pays off the most.

After setup, start a new chat. The model rule applies to new sessions.

## Keep the cost in check

bottega spends extra tokens on subagents and review panels. That's the price of the rigor. To spend fewer:

- Rerun `/setup-maestro` and pick cheaper models or lower effort. A strong model in the main chat with cheaper, faster models in the code roles is a good split.
- Lower a role's effort or model. `haiku` and `sonnet` at low effort cost far less than `opus`.
- Shorten a panel list. Each entry runs one subagent.
- Save `/maestro` for work that needs rigor. A small, obvious edit doesn't.

## Run your first task

Pick something real but small, and describe it the way you'd describe it to a colleague:

```text
/maestro add a --json flag to this command. text output stays byte-identical. verify both.
```

Watch the todo list. Its first items are the matched playbook's steps copied in, the Feature playbook for this prompt. If `/maestro` skips a step, the step stays in the list with `skip: <reason>`, so you can see what it chose not to do.

From here you can type normal follow-ups. To keep `/maestro` in effect for the whole project, add a one-line pointer to your `CLAUDE.md`, such as "Work in the `/maestro` style", and re-invoke `/maestro` when the chat drifts. Typing `/maestro` attaches the skill to one message, and it fades as the chat moves on.

Next: [Route work through `/maestro`](./02-maestro.md).
