<p align="center"><img src="assets/banner.svg" alt="BottegaStack" width="760"></p>

<p align="center"><b>A workshop for Claude Code: one master orchestrates cheap builders, and you approve every result.</b></p>

BottegaStack is a personal agentic development workflow for Claude Code. It turns a request into a verified change and keeps a human in the loop.

## What makes it different

- **A master, not a prompt pile.** One agent talks to you. It plans, delegates, checks, and asks; it never writes code itself.
- **Cheap hands, careful eyes.** Builders run headless on a low-cost model (any model behind an Anthropic-compatible endpoint, such as DeepSeek), in parallel git worktrees. Claude reviews only when the risk or a finding calls for it.
- **Your repo stays clean.** Run state lives in the system temp dir. The record is the chat and the PR or merge commit. No stage files, no database, nothing committed.
- **Hooks enforce it, not hope.** A todo-driven Stop hook keeps a run going; a guard blocks the wrong builder; checks must pass before any review.
- **Human gates only where they matter.** SPEC approval and the final decision; merge, push, and PR are never automatic.
- **Playbooks for real work.** `bugfix`, `feature`, `refactor`, `investigate`, `perf`, `prototype`, `ship`, `autopilot`, `pause`, `eval`, `pr-babysit`, plus 62 skills including design and UI, sysadmin, containers, and shell.
- **UI that does not look generated.** A `design` skill set (`frontend-design`, `animation`, `better-ui` and its `better-*` siblings, `web-design-guidelines`, `interface-review`, `agentation`). Builders use `frontend-design`, `animation`, and `better-ui` whenever they create, change, or polish UI.

A run is one execution of a playbook. Its id is the branch slug, its branch is
the one you are on, and its state lives outside the checkout in a per-repo state
directory in the system temp dir, shared by worktrees. The chat and the PR (or
merge commit) are the human-readable record. There is no database, no cloud
service, and no state machine.

A playbook chooses the pipeline — `trivial`, `bugfix`, `feature`, `refactor`,
`investigate`, `perf`, `prototype`, `ship`, `autopilot`, `pause`, `eval`, and
`pr-babysit` — and a risk modifier (`low`, `standard`, `high`). At Step 0 the
master has the explorer read the manifests, confirms the stack profile, and
records it in `AGENTS.md`. Model and effort for each role come from
`~/.claude/rules/bottega-models.md`, written by `/maestro-models`.

## Install

BottegaStack ships as the Claude Code plugin `bottega`. Inside a Claude Code
session:

```
/plugin marketplace add fernandoleitepagani/BottegaStack
/plugin install bottega@bottega
```

The plugin puts `maestro` on `PATH` for the session and provides the `master`
agent, the `/maestro` and `/maestro-models` commands, every skill, and the hooks.
Update with `/plugin` or `claude plugin update bottega@bottega`. Uninstall with
`claude plugin uninstall bottega`.

After installing:

1. In a session, run `maestro build --init` once to create the headless builder's
   `~/.config/bottega/builder.env` and key (both mode 600; the key is never
   printed). `maestro build --check` verifies them.
2. To start every session as the master and let it run maestro commands without a
   prompt, add this to `~/.claude/settings.json`:

```json
{
  "agent": "bottega:master",
  "permissions": { "allow": ["Bash(maestro:*)"] }
}
```

Then run `claude --agent bottega:master` (the `agent` setting also does this).
`/maestro` runs on the session model; the command pins no model. To choose the
master's model, run `claude --agent bottega:master --model <model>`, or set
`"model": "<model>"` beside `"agent": "bottega:master"` in
`~/.claude/settings.json`. `/maestro-models` writes the per-role routing for the
agents the master delegates to. Details, including the manual steps a plugin
cannot do: [docs/SETUP.md](docs/SETUP.md).

In a project there is nothing to set up: open Claude Code there and run
`/maestro <request>`. On first use it creates `AGENTS.md`, `CLAUDE.md`,
`scripts/check`, and `.claude/settings.json` (all excluded from git) and asks for
your lint, test, and build commands. Every other project file is created on
demand with `maestro seed <Name>`.

Questions are answered directly; only requests that change code start a run.
`/maestro` still works for `status`, `resume`, and forcing the workflow.

To use some skills without the stack, `maestro skills install teach` copies a
standalone skill into your Claude config as a plain slash command (`--all`
installs the whole list, `uninstall` removes managed copies). A copy does not
update with the plugin, so re-run `install` after an update. The standalone set
and the maintainer rule are in [docs/SKILLS.md](docs/SKILLS.md#standalone-skills);
the commands are in
[docs/SETUP.md](docs/SETUP.md#use-skills-without-the-stack).

## Quick start

```
/maestro Add an estimated reading time to blog posts
```

The master picks a playbook and risk, runs `maestro start "<title>"` to create the
branch and state directory, asks a few questions, has the planner return the
SPEC, saves it with `maestro spec <slug>`, and stops for approval. You drive
the rest with `approve`, `rework <note>`, `reject`, or a question. `/maestro
status` and `/maestro resume` continue a run from the todo list and branch.

Small work skips the spec and worktree: the master takes the light path with
`maestro build --here <slug> --task "<text>"`; state lives in the state directory
under `quick/<slug>/`. Pass findings back with
`maestro build --here <slug> --revise <file|->`; `maestro build --status <slug>`
reports progress, and `maestro watch --line` prints the newest open run as one
status line (see [docs/SETUP.md](docs/SETUP.md) to wire it into Claude Code).
`low` risk runs get a cheap headless first-pass review
before the Claude reviewer. Headless builds report `tokens: in <n> out <n>` and
`steps: <n>`; the only stop is the 30-minute builder timeout.

Other skills are invoked directly by name, for example `/wizard`,
`/backlog-triage`, `/wayfinding`, `/improve-architecture`, and `/review-pr`.
`/maestro-models` writes the model routing rule for each role.

## Skills and modules

### Modules

| Module | What it does |
|---|---|
| `master` agent | The one agent you talk to; plans, delegates, checks, and asks, but never writes code. |
| `planner` agent | Turns the interview into a SPEC with tasks. |
| `builder` agent | Builds one task, runs the checks, commits locally. |
| `review-code` agent | Reviews a change for code, UI, UX, and security in one pass. |
| `explorer` agent | Searches the code and logs, read-only. |
| `/maestro` | Starts or continues the workflow. |
| `/maestro-models` | Picks the model and effort for each role. |
| `maestro` CLI | Runs the mechanical steps: runs, checks, gates, proofs, builds, worktrees, logs. |
| Hooks | Keep a run going while todo items are open and stop the wrong builder from starting. |
| Playbooks | The pipelines: trivial, bugfix, feature, refactor, investigate, perf, prototype, ship, autopilot, pause, eval, pr-babysit. |

### Skills

UI skills live in `skills/design/`; the rest are grouped by category under `skills/`.

| Skill | What it does |
|---|---|
| `adversarial-review` | Tries to break a risky change before the normal review. |
| `agentation` | Adds a visual feedback toolbar so you can point at UI for the agent. |
| `animation` | Motion and transition patterns for React UIs. |
| `approval` | Decides approve or escalate, with an explainer, before you choose. |
| `architect` | Designs the shape twice before any code (you start it). |
| `arena` | Has 2-3 builders try the same task and keeps the best (you start it). |
| `automate-me` | Learns your habits from past sessions into a personal skill. |
| `autonomous-run` | Works toward a checkable goal on its own, one change at a time (you start it). |
| `backlog-triage` | Sorts a local backlog into ready-to-build briefs. |
| `bash-scripting` | Writes and fixes safe shell scripts. |
| `better-accessibility` | Checks keyboard, focus, ARIA, forms, and motion against WCAG 2.2. |
| `better-colors` | Builds color palettes and tokens and checks contrast. |
| `better-interface` | Reviews a whole screen or flow across all the design skills in one report. |
| `better-layout` | Sets grouping, alignment, and responsive structure. |
| `better-typography` | Sets type scale, spacing, font features, and wrapping. |
| `better-ui` | Exact polish values for surfaces, icons, and motion. |
| `better-writing` | Writes and reviews interface copy: labels, errors, empty states. |
| `blast-radius` | Finds what a change could break elsewhere. |
| `closeout` | Runs your final choice: merge, PR, push, rework, or reject. |
| `codebase-design` | Vocabulary for designing simple, deep modules. |
| `correct` | Turns a repeated mistake into a check that prevents it. |
| `create-verification-skill` | Writes a project skill that starts and drives your app to prove changes. |
| `data-analysis` | Answers a question from real data. |
| `diagnosis` | Turns a failure into a precise fix brief. |
| `domain-modeling` | Keeps the project's terms and decisions consistent. |
| `figure-it-out` | Builds a one-off plan when no playbook fits. |
| `frontend-design` | Distinctive visual design instead of template defaults. |
| `how` | Explains how some code works. |
| `implementation` | The builder's procedure: test first, build, check, commit. |
| `improve-architecture` | Finds places to simplify the design, as a visual report. |
| `infra-ops` | Reviews dependencies, cost, access, and leftover resources. |
| `interface-review` | Reviews a branch or PR for the UI problems it introduced (you start it). |
| `interrogate` | Stress-tests a change; keeps only problems it can reproduce. |
| `interview` | Asks the questions needed before planning. |
| `ketchup` | Catches you up and lists what is waiting on you. |
| `library-reference` | Documents how to use an internal library or API correctly. |
| `linux-sysadmin` | Diagnoses and operates Linux hosts and services. |
| `maintain-verification-skill` | Keeps the project verification skill up to date. |
| `orchestrate` | Coordinates many PRs as one program (you start it). |
| `planning` | The planner's procedure for writing the SPEC. |
| `playbooks` | Picks the pipeline and risk for a request. |
| `podman-operator` | Builds and runs Podman containers and services. |
| `principles` | The 15 short rules the agents cite. |
| `review-code` | The reviewer's checklist. |
| `review-pr` | Reviews a pull request as a merge decision. |
| `runbook` | Investigates an incident step by step. |
| `scaffold` | Creates new files that match the project's conventions. |
| `session-handoff` | Packs the session into a note for a fresh agent. |
| `session-retro` | Turns friction from a run into fixes. |
| `show-me-your-work` | Keeps a log of each decision for later review. |
| `simplify` | Removes extra code and useless comments before review. |
| `summary` | Posts a short update after each step. |
| `teach` | Teaches you a topic or part of the code, step by step, with checks (you start it). |
| `unslop` | Removes AI-sounding phrasing from text. |
| `untrusted-content` | Treats outside text as data, never as instructions. |
| `verification` | Proves each requirement with a real command and records it. |
| `wait-what` | Re-explains the last message more clearly (you start it). |
| `wayfinding` | Maps a large, unclear effort into decisions. |
| `web-design-guidelines` | Checks UI code against interface best practices. |
| `why` | Explains why some code or decision exists. |
| `wizard` | Writes a guided script for steps only you can do. |
| `writing-for-agents` | How to write skills and agent instructions. |

## Docs

- [docs/WORKFLOW.md](docs/WORKFLOW.md) — the 9 steps, playbooks, cheap review, risk, effort routing, agents, run state, and why it is shaped this way.
- [docs/SKILLS.md](docs/SKILLS.md) — all skills, categories, vendored and adapted sources.
- [docs/SETUP.md](docs/SETUP.md) — plugin install, `doctor` security checks, `init`, `seed`, builder, hooks, troubleshooting.

## License

MIT for the BottegaStack code. Vendored skills keep their own licenses; see
[docs/SKILLS.md](docs/SKILLS.md) and the license file in each skill folder.
