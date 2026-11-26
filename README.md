# bottega

![Linux](https://img.shields.io/badge/Linux-supported-FCC624?logo=linux&logoColor=black) ![macOS](https://img.shields.io/badge/macOS-supported-000000?logo=apple&logoColor=white)

bottega is an agent workflow plugin for Claude Code (with experimental Antigravity CLI, Codex and OpenCode ports, #46) for one workflow: **plan, split into tickets, implement**. You write a prompt. The agent grills you until the plan is clear, splits it into tickets that each fit one fresh session, says what the orchestrator does and what each subagent does, orders the tickets into parallel waves, assigns an abstract model tier (`heavy`, `medium`, `standard`, `fast`) for each, then builds them one session at a time and proves every result.

**credit.** bottega started as a Claude Code port of [pstack](https://github.com/cursor/plugins), the skill set written by [Lauren Tan (poteto)](https://x.com/poteto) for Cursor. The principles and much of the rule text come from her work, used under the MIT license (see [LICENSE](./LICENSE)). The grilling, spec, ticket-slicing and map ideas are adapted from Matt Pocock's [skills](https://github.com/mattpocock/skills) (MIT).

The goal is not more code. It's less code, of higher quality, that you can trust enough to run in parallel.

## install

**Claude Code:**

```bash
claude plugin marketplace add <path-or-repo>
claude plugin install bottega@bottega
```

Start a new session afterwards. Claude Code prefixes plugin commands, so `/plan` is also `/bottega:plan`; use the prefix when Claude Code's built-in `/plan` clashes (built-in plan mode stays off during grilling). bottega uses no hooks.

**Antigravity CLI, Codex, and OpenCode (experimental, #46):** run the harness installer (`./harnesses/antigravity/install.sh`, `./harnesses/codex/install.sh`, or `./harnesses/opencode/install.sh`). See [`harnesses/`](./harnesses/) for status and subagent dispatch notes.

**platforms.** Linux and macOS only. The scripts need only `bash` and `git`, plus `gh` for opening and watching PRs. Native Windows is not supported; under WSL, bottega runs as on Linux.

## the workflow

```
/maestro <prompt>          routes the prompt; big work goes to /plan
/plan                      grills you one decision at a time, writes .bottega/plans/<slug>/spec.md
/tickets                   one ticket per session (300k tokens ±10%), roles, waves, models → PLAN.md
/clear, /model <level>     a fresh session per ticket, with the model the ticket names
/implement <ticket>        explore, shape, delegate, verify, review, final gate
```

Small, clear changes skip the plan: `/maestro fix the off-by-one in pagination` goes straight to `/implement`.

Each ticket file carries:

- what to build (one vertical slice) and acceptance criteria written as runnable checks
- a budget for the orchestrator's own context (300k, ±10%, subagents excluded), itemized
- what the orchestrator does itself, and a table of subagents: role (explorer, implementer, reviewer), abstract tier, task, write scope, and which run together
- blocked by and wave: `PLAN.md` lists which tickets can run in parallel and which must wait
- the orchestrator tier (`heavy`, `medium`, or `standard`, translated per harness in [`models.md`](./skills/maestro/references/models.md)) and why

New here? The [bottega guide](./docs/guide/README.md) walks through it with real prompts.

## skills

16 skills. Each sets `disable-model-invocation: true`, so none costs context until it runs. [`SKILLS-INDEX.md`](./skills/maestro/SKILLS-INDEX.md) lists them with sizes.

| skill | use it when |
|---|---|
| [`/maestro`](./skills/maestro/SKILL.md) | the front door: routes a prompt and holds the shared rules (risk, autonomy, subagents, context). |
| [`/reframe`](./skills/reframe/SKILL.md) | you know what you want but lack the exact technical vocabulary. Outputs interpretations, ranked expert terms, analogies, and a crisp prompt. |
| [`/recall`](./skills/recall/SKILL.md) | starting a fresh session on an ongoing or related problem; rebuilds compressed context from recent session transcripts and `.bottega/` state. |
| [`/triage`](./skills/triage/SKILL.md) | working with more than one bug report, issue, or PR; clusters by shared root cause, flags non-repros, and routes each cluster. |
| [`/plan`](./skills/plan/SKILL.md) | work needs decisions or more than one session. Grills you into a spec; map mode for efforts too big to settle at once. |
| [`/sharpen`](./skills/sharpen/SKILL.md) | strip vague adjectives from a prompt or spec into concrete, testable claims and explicit non-goals. |
| [`/tickets`](./skills/tickets/SKILL.md) | you have a spec and want session-sized tickets with roles, waves and abstract model tiers. |
| [`/implement`](./skills/implement/SKILL.md) | you have a ticket, or a change that fits one session. Picks the playbook for its kind: small fix, bug fix, feature or refactoring. |
| [`/ship`](./skills/ship/SKILL.md) | commit, open a PR, and either babysit CI/review bots to merge (`/ship full`) or open a Draft PR and stop (`/ship stop`). |
| [`/autopilot`](./skills/autopilot/SKILL.md) | run a task, ticket queue (`PLAN.md`), or standing program unattended until checkable exit conditions pass; asks upfront whether to auto-merge or stop at verified PRs. |
| [`/correct`](./skills/correct/SKILL.md) | you keep correcting agents for the same mistake. Fixes each class at the highest level that works: architecture, then types and lint, then tests, docs last. `/correct scan` audits recent commits without editing. |
| [`/unslop`](./skills/unslop/SKILL.md) | you're cleaning up writing. Removes AI tells. |
| [`/frontend-design`](./skills/frontend-design/SKILL.md) | you want a distinct visual direction for new UI. Agents write the code; you check the rendered result. |
| [`/create-verification-skill`](./skills/create-verification-skill/SKILL.md) | your project has no scripted way to prove app behavior. Generates a `verify-<app>` skill with a feature map. |
| [`/maintain-verification-skill`](./skills/maintain-verification-skill/SKILL.md) | your verify skill's feature map has drifted from the app. |
| [`/wizard`](./skills/wizard/SKILL.md) | a step needs your hands: a dashboard, an API key, a CI secret, a cutover. Writes a script that walks you through it and saves the values. |

`/maestro` is a router: it picks one **playbook** per task from [`skills/maestro/playbooks/`](./skills/maestro/playbooks/) and loads only that one (small fix, bug fix, feature, refactoring, investigation, prototype, pause, pickup, worktree cleanup, setup, authoring a skill). Shared steps live in [`skills/maestro/references/`](./skills/maestro/references/) and load only at the step that names them: the final gate, review, blast radius, swarm, the delegate brief, the role table, model tiers and the principles.

## risk and the final gate

Each run states a risk, `normal` or `high`, and risk only goes up during a run. High risk raises subagent effort and hardens the review: a small diff gets a blast-radius check that proves the one fact it's safe because of, a larger one a swarm of verifiers, and a finding counts only when a run proves it.

Every change ends at the final gate. `gate-check.sh` reads the logged proofs in `.bottega/proofs.tsv` and decides: APPROVE only on exit 0, otherwise ESCALATE. A waiver needs your words. Fix rounds stop at 2.

## delegates

Implementers, reviewers and verifiers are the harness's own general-purpose subagents. Each brief's first line makes the delegate read `skills/maestro/references/delegate.md` before any work: scope, commits, the no-comments rule and its self-check, verification, and the report format. Explorers are the harness's read-only subagents. The per-harness names live in [`skills/maestro/harness/`](./skills/maestro/harness/).

## models

Roles use 4 abstract tiers (`heavy`, `medium`, `standard`, `fast`) translated per harness in [`skills/maestro/references/models.md`](./skills/maestro/references/models.md) and [`skills/maestro/references/subagents.md`](./skills/maestro/references/subagents.md).

| role | simple (small fix) | medium (normal risk) | hard (high risk) |
|---|---|---|---|
| orchestrator | `standard` | `standard` or `medium` (per ticket) | `heavy` |
| explorer | `fast` | `fast` | `fast` |
| implementer | (inline) | `standard` | `medium` |
| reviewer | `standard` | `standard` | `medium` |
| verifier | `standard` | `standard` | `heavy` |

Run `/maestro setup` to pick a model and effort for every role at each difficulty; it writes `~/.bottega/models.md`, the one model file every harness reads. Effort ceiling: never `xhigh` or `max`.

## principles

17 principles on one page: [`skills/maestro/references/principles.md`](./skills/maestro/references/principles.md). Agents name each one that changed a decision, and you can use the names to steer ([guide](./docs/guide/07-principles.md)).

## not shipped here

bottega does not drive or screenshot a UI: the agent says what to look at and you check it. PR watching uses `gh`, not a bundled watcher. There are no hooks and no compiled binary (only the thin Bash wrapper [`skills/maestro/scripts/bottega`](./skills/maestro/scripts/bottega) around `gate-check.sh`, `log.sh`, and `worktree-audit.sh`). Plans and tickets live in `.bottega/` (untracked) unless you ask for GitHub issues.

## license

MIT. Original pstack by Lauren Tan (poteto). See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).

## credits

- `plan` and `tickets` adapt the grilling, `to-spec`, `to-tickets` and `wayfinder` ideas from Matt Pocock's [mattpocock/skills](https://github.com/mattpocock/skills) (MIT), rewritten for bottega. `wizard` and its `template.sh` library are adapted from the same repo's `wizard` skill.
- The `/autopilot` skill and the investigation playbook are original works by the bottega author, drawing on pstack. The prototype and pause playbooks and the two-axis review adapt Matt Pocock's `prototype`, `handoff` and `code-review`. The playbook layout and the pickup, worktree-cleanup, authoring-a-skill and setup playbooks, plus the blast-radius and swarm references, adapt pstack's `poteto-mode` playbooks and skills.
- `frontend-design` is Anthropic's skill from [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design), adapted under the Apache License 2.0 (see [its LICENSE.txt](./skills/frontend-design/LICENSE.txt)).
