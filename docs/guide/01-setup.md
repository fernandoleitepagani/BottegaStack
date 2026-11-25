# Set up bottega

In this page you install the plugin, pick which models bottega uses, and run your first task. Setup is one command plus a short conversation.

## Install the plugin

In a shell, run:

```bash
claude plugin marketplace add <path-or-repo>
claude plugin install bottega@bottega
```

Claude Code prefixes plugin commands, so each command in this guide can also be typed with a `bottega:` prefix, such as `/bottega:maestro`. Start a new session after installing.

## Pick your models

The defaults need no setup. There are four roles in [`skills/maestro/references/subagents.md`](../../skills/maestro/references/subagents.md):

- **orchestrator**: the session you type in. Each ticket says whether it needs an opus-level or a sonnet-level orchestrator, and you set it with `/model` when you start that ticket.
- **explorer**: read-only mapping and research, `haiku` at high effort.
- **implementer**: writes code and tests, `sonnet` at low effort (medium at high risk).
- **reviewer**: reviews the finished diff and runs repros, `sonnet` at low effort (medium at high risk, and always for adversarial review).

To change a role, write `~/.claude/rules/bottega-models.md` yourself, one line per role you want to override: `role: <normal model effort> | <high model effort>`, for example `implementer: sonnet medium | sonnet medium`. Roles without a line keep the default. Never use `xhigh` or `max`, or `high` on anything but haiku. Bottega's scripts make `.bottega/` ignore itself, so there is nothing to add to your git excludes.

## Add a verification skill

If your project has no scripted way to prove app behavior, run [`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md) once.

It writes `.claude/skills/verify-<app>/`, a project-local skill that teaches agents to drive your app the way a user does. It proves the skill works once before handing it over. [Verify and ship](./05-verify-and-ship.md#create-a-project-verification-skill) covers it in depth.

If you're new to bottega, do this first. An agent that can check its own work keeps going until the check passes. An agent that can't hands every result back to you to check by hand. Of everything in this guide, the verification skill pays off the most.

A rule file you edit applies to new sessions.

## Keep the cost in check

bottega spends extra tokens on subagents and review. That's the price of the rigor. To spend fewer:

- Pick cheaper models or lower effort in the rule file. A strong model in the main chat with cheaper, faster models in the code roles is a good split.
- Lower a role's effort or model. `haiku` and `sonnet` at low effort cost far less than `opus`.
- Run sonnet-level tickets on sonnet. `/tickets` marks which ones need opus.
- Save `/maestro` for work that needs rigor. A small, obvious edit doesn't.

## Run your first task

Pick something real but small, and describe it the way you'd describe it to a colleague:

```text
/maestro add a --json flag to this command. text output stays byte-identical. verify both.
```

That fits one session, so `/maestro` routes it to `/implement` in direct mode. Watch the todo list: it shows what the orchestrator does itself and what it hands to explorers, an implementer, and a reviewer. The run ends at the final gate with the evidence for each check.

From here you can type normal follow-ups. To keep `/maestro` in effect for the whole project, add a one-line pointer to your `CLAUDE.md`, such as "Work in the `/maestro` style", and re-invoke `/maestro` when the chat drifts. Typing `/maestro` attaches the skill to one message, and it fades as the chat moves on.

Next: [Route work through `/maestro`](./02-maestro.md).
