# Set up bottega

In this page you install the plugin, pick which models bottega uses, and run your first task. Setup is one command plus a short conversation.

## Install the plugin

In a shell, run:

```bash
claude plugin marketplace add <path-or-repo>
claude plugin install bottega@bottega
```

Claude Code prefixes plugin commands, so each command in this guide can also be typed with a `bottega:` prefix, such as `/bottega:maestro`. Start a new session after installing.

### Other harnesses (experimental)

For Antigravity CLI, Codex, or OpenCode, run the matching installer from the repo root:

```bash
./harnesses/antigravity/install.sh   # ~/.agents/skills/<name>
./harnesses/codex/install.sh         # ~/.codex/skills/<name>
./harnesses/opencode/install.sh      # ~/.config/opencode/skills/<name>
```

Skills install under their real names; the installer stops if one would replace a skill you already have. Pass `--uninstall` to remove the symlinks. See [`harnesses/README.md`](../../harnesses/README.md) for experimental status (#46) and how non-Claude harnesses dispatch subagents.

## Pick your models

The defaults need no setup. Roles map to 4 abstract tiers (`heavy`, `medium`, `standard`, `fast`) in [`skills/maestro/references/subagents.md`](../../skills/maestro/references/subagents.md) and translate per harness (Claude Code, Antigravity CLI, Codex, OpenCode) in [`skills/maestro/references/models.md`](../../skills/maestro/references/models.md):

- **orchestrator**: the session you type in. Each ticket names an abstract tier (`standard`, `medium`, or `heavy`), and you set your session model when starting that ticket.
- **explorer**: read-only mapping and research (`fast`).
- **implementer**: writes code and tests (`standard`; `medium` at high risk).
- **reviewer**: reviews the finished diff and runs repros (`standard`; `medium` or `heavy` at high risk).

To override a tier or role, write `~/.bottega/models.md` (or `~/.claude/rules/bottega-models.md` on Claude Code). Effort ceiling: never `xhigh` or `max`. Bottega's scripts make `.bottega/` ignore itself, so there is nothing to add to your git excludes.

## Add a verification skill

If your project has no scripted way to prove app behavior, run [`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md) once.

It writes `<project-skills-dir>/verify-<app>/` (`.claude/skills/` on Claude Code), a project-local skill that teaches agents to drive your app the way a user does. It proves the skill works once before handing it over. [Verify and ship](./05-verify-and-ship.md#create-a-project-verification-skill) covers it in depth.

If you're new to bottega, do this first. An agent that can check its own work keeps going until the check passes. An agent that can't hands every result back to you to check by hand. Of everything in this guide, the verification skill pays off the most.

A rule file you edit applies to new sessions.

## Keep the cost in check

bottega spends extra tokens on subagents and review. That's the price of the rigor. To spend fewer:

- Pick cheaper models or lower effort in the rule file. A strong model in the main chat with cheaper, faster models in the code roles is a good split.
- Lower a tier's model or effort in `~/.bottega/models.md`. `fast` and `standard` tiers cost far less than `heavy`.
- Run `standard`-tier tickets on your `standard` model. `/tickets` marks which ones need `medium` or `heavy`.
- Save `/maestro` for work that needs rigor. A small, obvious edit doesn't.

## Run your first task

Pick something real but small, and describe it the way you'd describe it to a colleague:

```text
/maestro add a --json flag to this command. text output stays byte-identical. verify both.
```

That fits one session, so `/maestro` routes it to `/implement` in direct mode. Watch the todo list: it shows what the orchestrator does itself and what it hands to explorers, an implementer, and a reviewer. The run ends at the final gate with the evidence for each check.

From here you can type normal follow-ups. To keep `/maestro` in effect for the whole project, add a one-line pointer to your `CLAUDE.md`, such as "Work in the `/maestro` style", and re-invoke `/maestro` when the chat drifts. Typing `/maestro` attaches the skill to one message, and it fades as the chat moves on.

Next: [Route work through `/maestro`](./02-maestro.md).
