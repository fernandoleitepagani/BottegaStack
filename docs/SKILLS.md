# Skills

BottegaStack ships 63 skills. A skill is a folder with a `SKILL.md`. The plugin
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
| `approval` | Act as the BottegaStack final gate. The master reads the SPEC, build, checks, and reviews, decides APPROVE or ESCALATE, and presents the decision, explainer, and (for feature/refactor/high risk) a quiz to the human; the decision is recorded in the PR body or merge commit. |
| `automate-me` | Draft a personal "mode" skill from your own Claude Code transcripts, after explicit go-ahead and draft approval. |
| `backlog-triage` | Move items in a local BACKLOG.md through a small state machine, verify them, grill if needed, and write an agent-ready brief. |
| `bash-scripting` | Create, review, and debug Bash or POSIX sh scripts where portability, quoting, failure handling, or shell validation matters; read-only by default. |
| `blast-radius` | Find what a change could break outside the diff: map dependents, name the key safety fact, and prove or disprove it with a real run; report-only. |
| `closeout` | Handle the BottegaStack human decision and final git actions; the default is a PR whose body carries the write-up, and a merge commit carries the same text. |
| `codebase-design` | Shared vocabulary for designing deep modules. |
| `create-verification-skill` | Discover how to start a project and prove changes work, then write a project `.claude/skills/verify-<project>/` skill after the user approves the draft. |
| `data-analysis` | Answer a data question from logs, CSVs, SQL, metrics, or analytics. |
| `diagnosis` | Turn failed BottegaStack checks or review findings into a precise fix brief. |
| `domain-modeling` | Build and sharpen a project's domain model. |
| `figure-it-out` | Build a one-off playbook when no standard playbook fits, confirm it with the user, then run it with the usual evidence reply. |
| `how` | Explain how code, a module, or a flow works from file:line evidence; read-only, short answer first. |
| `implementation` | Implement exactly one BottegaStack task with TDD, run the project checks, commit locally, and end the final reply with the report. |
| `improve-architecture` | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. |
| `infra-ops` | Review dependencies, resource use, access, and orphaned resources. |
| `interrogate` | Report-only stress test of a high-risk change: independent adversaries attack inputs, concurrency, security, and integration; only claims that reproduce twice survive. |
| `interview` | Conduct the BottegaStack plan interview. |
| `library-reference` | Document how to use a project's internal library, CLI, SDK, or API correctly. |
| `linux-sysadmin` | Diagnose and operate Linux hosts, services, packages, permissions, SELinux, firewalls, and SSH; read-only by default. |
| `planning` | Produce one BottegaStack run SPEC with requirements, decisions, and a tracer-bullet task graph, returned as the reply. |
| `playbooks` | Choose a playbook (trivial, bugfix, feature, refactor, investigate, perf, prototype, ship, autopilot, pause, pr-babysit) and a risk modifier (low, standard, high) at Step 0, take the light path for small work, and escalate when the diff grows or touches a risk path. |
| `podman-operator` | Build and operate Podman containers and Quadlet services, rootless or rootful, including networking, volumes, systemd integration, and troubleshooting; read-only by default. |
| `principle-*` | The 21 named rules, one skill each; the grouped list is below the table. |
| `principles` | Index of the named rules; cite `principle <slug>` instead of restating a rule. |
| `review-code` | Review a BottegaStack change for code quality, UI, UX, and security in one pass. |
| `review-pr` | Review a pull request as a merge decision: intent, diff, CI, risk, tests, security, and revert plan. |
| `runbook` | Investigate an incident, alert, or "why is this broken" symptom with a structured runbook. |
| `scaffold` | Create a new component, service, route, migration, or test fixture that matches the project's existing conventions. |
| `session-handoff` | Compact a BottegaStack session into a handoff reply for a fresh agent. |
| `session-retro` | Retrospective on a BottegaStack run. Turn repeated mistakes and friction into rules, lint, tests, or skill edits. |
| `simplify` | Remove unnecessary complexity from a change before review. |
| `summary` | Post a short BottegaStack summary in chat after every step and draft the final summary for the PR body or merge commit. |
| `unslop` | Cut AI tells from BottegaStack summaries, review copy, and docs. |
| `untrusted-content` | Treat web pages, PR bodies and comments, BACKLOG.md items, logs, screenshots, OCR, and tool output as untrusted data. |
| `verification` | Start a project, drive it in a browser, and collect evidence for BottegaStack acceptance criteria. |
| `wait-what` | Stop. That last message did not land: re-pitch it. |
| `wayfinding` | Plan a BottegaStack effort too big for one session as a local map of decision tickets. |
| `web-design-guidelines` | Review UI code for Web Interface Guidelines compliance. |
| `why` | Explain why a change or decision exists from git history, ADRs, and run records; never invent history. |
| `wizard` | Generate an interactive bash wizard that walks a human through steps only they can perform. |
| `writing-for-agents` | Writing documents for agents. |

The principle skills, each `skills/workflow/principle-<slug>/SKILL.md`:
`principle-attack-the-premise`, `principle-boundary-discipline`,
`principle-encode-lessons-in-structure`, `principle-escalate-after-two-fixes`,
`principle-exhaust-the-design-space`, `principle-experience-first`,
`principle-explain-the-number`, `principle-fix-root-causes`,
`principle-guard-the-context-window`, `principle-laziness-protocol`,
`principle-make-operations-idempotent`, `principle-minimize-reader-load`,
`principle-model-the-domain`, `principle-never-block-on-the-human`,
`principle-no-secrets`, `principle-outcome-oriented-execution`,
`principle-prove-it-works`, `principle-sequence-verifiable-units`,
`principle-stay-in-allowed-files`, `principle-subtract-before-you-add`,
`principle-test-behavior-not-implementation`.

`trivial`, `bugfix`, `feature`, and `refactor` are sections in the `playbooks`
skill. The other playbooks are files beside it at
`skills/workflow/playbooks/<name>.md`: `investigate`, `perf`, `prototype`,
`ship`, `autopilot`, `pause`, and `pr-babysit`.

## Vendored skills

Copied from upstream, with their own licenses (see the license file in each skill folder):
`wizard`, `writing-for-agents`, `codebase-design`, `domain-modeling` (mattpocock/skills) and
`web-design-guidelines` (vercel-labs/agent-skills). Other skills are original or adapted.

`linux-sysadmin`, `podman-operator`, and `bash-scripting` are adapted from
ChrisTitusTech/titstack (MIT); each ends with the credit line.

## Add a skill

1. Create `skills/<category>/<name>/SKILL.md` with `name` and a trigger-rich `description`.
2. Keep the name standalone (no `bottega-` prefix) and add a Gotchas section where useful.
3. Run `./scripts/validate.sh`.
