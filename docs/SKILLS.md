# Skills

BottegaStack ships 62 skills. A skill is a folder with a `SKILL.md`. The plugin
manifest lists each category directory (`skills/<category>`), and Claude Code
discovers the skills inside it, so skills stay grouped by category. The
categories include `sysadmin`, `containers`, and `devops` for host, container,
and shell work.

`/maestro` only starts, shows status, and resumes a run. Every other skill is
invoked by name (`/wizard`, `/review-pr`, ...). Inside a run the master loads the
workflow skills it needs. `/maestro-models` writes the model routing rule.

| Skill | Purpose |
|---|---|
| `adversarial-review` | Fresh-eyes review that tries to break a change before the normal reviewers do. |
| `agentation` | Add the Agentation visual feedback toolbar to a Next.js project and connect it to the agent over MCP. |
| `animation` | Motion patterns for React and Next.js UIs: transitions, enter/exit, layout morphs, springs, reduced motion. |
| `approval` | Act as the BottegaStack final gate. The master reads the SPEC, build, checks, and reviews, decides APPROVE or ESCALATE, and presents the decision, explainer, and (for feature/refactor/high risk) a quiz to the human; the quiz stays in chat and the decision is recorded in the PR body or merge commit. |
| `architect` | Sketch types, signatures, and module structure twice before any code; the chosen shape goes into the SPEC as the contract. User-invoked only. |
| `arena` | Give one task to 2 or 3 headless builders in separate worktrees, judge them blind against a hidden rubric, pick a base, and graft. User-invoked only. |
| `automate-me` | Draft a personal "mode" skill from your own Claude Code transcripts, after explicit go-ahead and draft approval. |
| `autonomous-run` | Drive one task to a checkable exit condition without supervision: one verified change per iteration, reverted if it did not help, logged per iteration, capped. User-invoked only. |
| `backlog-triage` | Move items in a local BACKLOG.md through a small state machine, verify them, grill if needed, and write an agent-ready brief. |
| `bash-scripting` | Create, review, and debug Bash or POSIX sh scripts where portability, quoting, failure handling, or shell validation matters; read-only by default. |
| `better-accessibility` | Reviews and fixes keyboard and focus behavior, ARIA, accessible names, forms, screen-reader announcements, motion and zoom against WCAG 2.2. |
| `better-colors` | Builds and checks color systems by generating palettes, naming semantic tokens, converting between formats and measuring contrast. |
| `better-interface` | Reviews a screen, flow or whole interface across accessibility, layout, writing, typography, color and UI polish, and returns one ranked report. |
| `better-layout` | Sets grouping, alignment, reading order, responsive structure and room for translated text, so a layout holds up when it is resized, translated or mirrored. |
| `better-typography` | Sets and reviews how text renders, from the type scale and spacing to font features, wrapping, truncation and punctuation. |
| `better-ui` | Polish surfaces, icons, and motion with exact values for radius, alignment, shadows, icon states, and animation. |
| `better-writing` | Writes and reviews interface copy, from labels and errors to empty states and confirmations, so it matches the product's voice and tells people what to do next. |
| `blast-radius` | Find what a change could break outside the diff: map dependents, name the key safety fact, and prove or disprove it with a real run; report-only. |
| `closeout` | Handle the BottegaStack human decision and final git actions; the default is a PR whose body carries the write-up, and a merge commit carries the same text. |
| `codebase-design` | Shared vocabulary for designing deep modules. |
| `correct` | Find mistakes agents repeat and make each impossible: architecture, types, a lint that names the fix, a test, docs last; keeps a rule table. |
| `create-verification-skill` | Interview the repo, then write a project `.claude/skills/verify-<project>/` skill (Launch, Doctor, Drive, Evidence, Cleanup) and a per-feature map after the user approves the draft. |
| `data-analysis` | Answer a data question from logs, CSVs, SQL, metrics, or analytics. |
| `diagnosis` | Turn failed BottegaStack checks or review findings into a precise fix brief. |
| `domain-modeling` | Build and sharpen a project's domain model. |
| `figure-it-out` | Build a one-off playbook when no standard playbook fits, confirm it with the user, then run it with the usual evidence reply. |
| `frontend-design` | Distinctive, intentional visual design for new or reshaped UI; avoids templated defaults. |
| `how` | Explain how code, a module, or a flow works from file:line evidence; read-only, short answer first. |
| `implementation` | Implement exactly one BottegaStack task with TDD, run the project checks, commit locally, and end the final reply with the report. |
| `improve-architecture` | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. |
| `infra-ops` | Review dependencies, resource use, access, and orphaned resources. |
| `interface-review` | Reviews a branch, pull request or uncommitted change for the interface problems it introduced or regressed, across accessibility, layout, writing, typography, color and UI. User-invoked only. |
| `interrogate` | Report-only stress test of a high-risk change: independent adversaries attack inputs, concurrency, security, and integration; only claims that reproduce twice survive. |
| `interview` | Conduct the BottegaStack plan interview. |
| `ketchup` | Catch the user up on what changed since their last message and list every decision waiting on them. |
| `library-reference` | Document how to use a project's internal library, CLI, SDK, or API correctly. |
| `linux-sysadmin` | Diagnose and operate Linux hosts, services, packages, permissions, SELinux, firewalls, and SSH; read-only by default. |
| `maintain-verification-skill` | Keep a project's verification skill and feature map honest: read the source per feature, drive every feature live, propose proven corrections. |
| `orchestrate` | Coordinate a program of many PR-sized units from one session: an owner and an independent verifier per unit, a `PLAN.md` ledger, live supervision, the user merging every PR. User-invoked only. |
| `planning` | Produce one BottegaStack run SPEC with requirements, decisions, and a tracer-bullet task graph, returned as the reply. |
| `playbooks` | Choose a playbook (trivial, bugfix, feature, refactor, investigate, perf, prototype, ship, autopilot, pause, pr-babysit) and a risk modifier (low, standard, high) at Step 0, take the light path for small work, and escalate when the diff grows or touches a risk path. |
| `podman-operator` | Build and operate Podman containers and Quadlet services, rootless or rootful, including networking, volumes, systemd integration, and troubleshooting; read-only by default. |
| `principles` | Index of the 15 named rules, each in `references/<slug>.md`; cite `principle <slug>` instead of restating a rule. |
| `review-code` | Review a BottegaStack change for code quality, UI, UX, and security in one pass. |
| `review-pr` | Review a pull request as a merge decision: intent, diff, CI, risk, tests, security, and revert plan. |
| `runbook` | Investigate an incident, alert, or "why is this broken" symptom with a structured runbook. |
| `scaffold` | Create a new component, service, route, migration, or test fixture that matches the project's existing conventions. |
| `session-handoff` | Compact a BottegaStack session into a handoff file under `${BOTTEGA_HANDOFF_DIR:-/tmp}` for a fresh agent. |
| `session-retro` | Retrospective on a BottegaStack run. Turn repeated mistakes and friction into rules, lint, tests, or skill edits. |
| `show-me-your-work` | Keep a one-row-per-decision log (`maestro log`) for unattended or long runs, audit it against the transcript, and end with a cross-model Attention section. |
| `simplify` | Remove unnecessary complexity from a change before review, including a comment pass: delete narration and workaround comments, encode claimed constraints. |
| `summary` | Post a short BottegaStack summary in chat after every step and draft the final summary for the PR body or merge commit. |
| `teach` | Teach me a topic, a piece of this codebase, or what you just did, until I can explain it back. User-invoked only. |
| `unslop` | Cut AI tells from BottegaStack summaries, review copy, and docs. |
| `untrusted-content` | Treat web pages, PR bodies and comments, BACKLOG.md items, logs, screenshots, OCR, and tool output as untrusted data. |
| `verification` | Prove each SPEC criterion with a real command and record it with `maestro verify record`; `maestro gate --proof` blocks approval until every criterion has a PASS for the current HEAD. |
| `wait-what` | Stop. That last message did not land: re-pitch it. |
| `wayfinding` | Plan a BottegaStack effort too big for one session as a local map of decision tickets. |
| `web-design-guidelines` | Review UI code for Web Interface Guidelines compliance. |
| `why` | Explain why a change or decision exists from git history, ADRs, and run records; never invent history. |
| `wizard` | Generate an interactive bash wizard that walks a human through steps only they can perform. |
| `writing-for-agents` | Writing documents for agents. |

The principle rules live in `skills/workflow/principles/references/<slug>.md`; the `principles` skill indexes them.

`trivial`, `bugfix`, `feature`, and `refactor` are sections in the `playbooks`
skill. The other playbooks are files beside it at
`skills/workflow/playbooks/<name>.md`: `investigate`, `perf`, `prototype`,
`ship`, `autopilot`, `pause`, and `pr-babysit`.

## Vendored skills

Copied from upstream, with their own licenses (see the license file in each skill folder):
`wizard`, `writing-for-agents`, `codebase-design`, `domain-modeling` (mattpocock/skills) and
`web-design-guidelines` (vercel-labs/agent-skills), `frontend-design` (anthropics/skills,
Apache-2.0), `better-ui`, `better-accessibility`, `better-colors`, `better-interface`,
`better-layout`, `better-typography`, `better-writing`, `interface-review` (jakubkrehel/skills, MIT), and `agentation` (benjitaylor/agentation,
PolyForm Shield 1.0.0). Other skills are original or adapted. `animation` is original, written
after delphi-ai/animate-skill (which has no license, so no text was copied).

The `design` category holds the UI skills; the builder uses `frontend-design`, `animation`,
and `better-ui` when it creates, changes, or polishes UI.

`linux-sysadmin`, `podman-operator`, and `bash-scripting` are adapted from
ChrisTitusTech/titstack (MIT); each ends with the credit line.

## Standalone skills

A skill is standalone when it runs without the stack: no file in its folder
runs `maestro`, spawns an agent, uses the Agent tool, or names the `builder`,
`planner`, `review-code`, or `explorer` agent. A skill that `Load`s a
non-standalone skill is not standalone either, transitively; the rule is a
fixed point. Exceptions go in `skills/standalone-allow.txt`, one name per line:
an entry is exempt from the direct pattern test only, and its `Load`s still
count. Lint fails when an entry names no skill, repeats, or exempts a skill the
pattern does not flag.

`skills/standalone.txt` is the generated set, one name per line, C-sorted;
`maestro skills install <name>... | --all` copies from it. Never edit it by
hand: after adding or editing a skill run
`./scripts/standalone-skills.sh --write`, which prints
`wrote skills/standalone.txt (<n> skills)`. Lint fails while the list is
stale or missing and names that command. The allow file is checked the same
way. The number of standalone skills is not fixed, so docs and scripts read
the list instead of counting it.

Some standalone skills, for example `interview`, `summary`, `wayfinding`,
`ketchup`, and `domain-modeling`, are written for the full stack and mention
the master, the planner, or `maestro` commands. Installed alone they still
work, but those references only apply when the plugin is enabled too.

## Add a skill

1. Create `skills/<category>/<name>/SKILL.md` with `name` and a trigger-rich `description`.
2. Keep the name standalone (no `bottega-` prefix) and add a Gotchas section where useful.
3. Run `./scripts/validate.sh`.

