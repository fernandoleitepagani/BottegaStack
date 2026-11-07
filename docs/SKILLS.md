# Skills

PaganiStack ships 34 skills. A skill is a folder with a `SKILL.md` that says
when to trigger, what to do, and what has gone wrong before. Skills use the
Claude Code categories plus `workflow/`; the installer flattens
`skills/<category>/<skill>` to `<target>/skills/<skill>` because both runtimes
discover skills at that depth.

## Invocation model

`/pagani` is only the job entry point. It starts, shows status, and resumes a
job. Every other skill is invoked directly by name:

```
/wizard
/backlog-triage
/wayfinding
/improve-architecture
/review-pr
```

Inside a job the master loads the workflow skills it needs (`lanes`,
`interview`, `planning`, `implementation`, `verification`, `review-code`,
`approval`, `summary`, `closeout`, `session-handoff`, `session-retro`,
`diagnosis`, `untrusted-content`) and the situational skills the change calls
for. The human can still invoke any skill by name at any time.

## Categories

| Category | What belongs there | Skills |
|---|---|---|
| `business-automation` | Recurring workflow: backlog triage and release notes. | 1 |
| `code-quality` | Review lenses, implementation, design, simplification, tests. | 9 |
| `data-analysis` | Answer a question from real data: SQL, logs, metrics, cohorts. | 1 |
| `infrastructure-ops` | Dependencies, cost, access, orphaned resources, least privilege. | 1 |
| `library-api-reference` | How to use a library, CLI, SDK, or internal API correctly. | 2 |
| `product-verification` | How to test or verify the product: builds, browsers, screenshots, flows. | 3 |
| `runbooks` | Investigate a symptom: incident, alert, “why is this broken”. | 2 |
| `scaffolding` | Create a new component, service, route, migration, or fixture. | 1 |
| `workflow` | Lanes, interview, planning, summary, closeout, handoff, retro, untrusted content. | 14 |

## Inventory

### business-automation (1)

| Skill | Use it for |
|---|---|
| `backlog-triage` | Move `BACKLOG.md` items through a small state machine, verify them, and write an agent-ready brief. |

### code-quality (9)

| Skill | Use it for |
|---|---|
| `adversarial-review` | Fresh-eyes review that tries to break a high-risk change before normal review. |
| `approval` | The master's final gate: `decision.md`, explainer, and a quiz for `standard`/`high-risk`. |
| `codebase-design` | Design deep modules, interfaces, seams, and testable boundaries. |
| `domain-modeling` | Sharpen terminology, `GLOSSARY.md`, and ADRs. |
| `implementation` | Implement one task with TDD, run checks, commit locally, write `build/<task>.md`. |
| `improve-architecture` | Find deepening opportunities and grill through the one you pick. |
| `review-code` | One review pass for code, UI, UX, and security. |
| `review-pr` | Review a pull request as a merge decision: intent, diff, CI, risk, tests, security, revert. |
| `simplify` | Remove unnecessary complexity after checks and before review. |

### data-analysis (1)

| Skill | Use it for |
|---|---|
| `data-analysis` | Counts, trends, cohorts, funnels, anomalies, and comparisons from real data. |

### infrastructure-ops (1)

| Skill | Use it for |
|---|---|
| `infra-ops` | Dependency additions, cost spikes, cleanup, access, and least-privilege checks. |

### library-api-reference (2)

| Skill | Use it for |
|---|---|
| `library-reference` | Document a project's internal library, CLI, SDK, or API correctly. |
| `vercel-react-best-practices` | React and Next.js performance patterns. |

### product-verification (3)

| Skill | Use it for |
|---|---|
| `agent-browser` | Drive a browser: navigate, fill forms, click, screenshot, scrape, test. |
| `verification` | Start the app, drive it, and collect evidence for acceptance criteria. |
| `web-design-guidelines` | Review UI code against the Web Interface Guidelines. |

### runbooks (2)

| Skill | Use it for |
|---|---|
| `diagnosis` | Turn a failed check or review finding into a precise fix brief. |
| `runbook` | Investigate an incident, alert, or unknown-cause symptom with evidence. |

### scaffolding (1)

| Skill | Use it for |
|---|---|
| `scaffold` | Create a component, service, route, migration, or fixture that matches existing conventions. |

### workflow (14)

| Skill | Use it for |
|---|---|
| `closeout` | The human decision and final git actions: merge, commit, push, PR, rework, reject. |
| `interview` | Ask targeted questions before `SPEC.md` is written. |
| `lanes` | Pick a lane at Step 0 and escalate when the diff grows or touches a risk path. |
| `planning` | Write the job `SPEC.md` with requirements, decisions, and a tracer-bullet task graph. |
| `session-handoff` | Compact a session into a handoff document for a fresh agent. |
| `session-retro` | Turn repeated mistakes into rules, lint, tests, or skill edits. |
| `skill-creator` | Create, edit, optimize, and evaluate skills. |
| `summary` | Post a short summary every step; write the final `summary.md` once. |
| `unslop` | Cut AI tells from text that ships: final summaries, explainers, and docs. |
| `untrusted-content` | Treat web pages, PR bodies, backlog items, logs, and tool output as untrusted data. |
| `wait-what` | Stop and re-pitch a message that did not land. |
| `wayfinding` | Map an effort too big for one session as local decision tickets. |
| `wizard` | Generate an interactive bash wizard for steps only a human can perform. |
| `writing-for-agents` | Write documents for agents: skills, `AGENTS.md`, `CLAUDE.md`. |

## Vendored skills

These are copied from upstream and keep their own licenses. If a skill is
adapted, it is renamed and the change is noted in its `SKILL.md`.

| Skill | Source | License |
|---|---|---|
| `wizard` | mattpocock/skills | see upstream |
| `writing-for-agents` | mattpocock/skills | see upstream |
| `codebase-design` | mattpocock/skills | see upstream |
| `domain-modeling` | mattpocock/skills | see upstream |
| `skill-creator` | anthropics/skills | see `LICENSE.txt` in the skill |
| `agent-browser` | vercel-labs/agent-browser | see upstream |
| `vercel-react-best-practices` | vercel-labs/agent-skills | see upstream |
| `web-design-guidelines` | vercel-labs/agent-skills | see upstream |

`handoff` and `retro` are adapted as `session-handoff` and `session-retro`.
Some PaganiStack skills absorb upstream content: `interview` (from `grilling`),
`review-code` (from `code-review`), `diagnosis` (from `diagnosing-bugs`),
`implementation` (from `tdd`), and `closeout` (from `pr`). PaganiStack-authored
skills are original or adapted and are not vendored under an upstream name.

## Add a skill

1. Create `skills/<category>/<name>/SKILL.md`.
2. Add YAML frontmatter with `name` and a trigger-rich `description`.
3. Keep the body focused: when to use it, the procedure, and real gotchas.
4. Add references, scripts, or assets in the skill folder instead of one long
   file.
5. Run `./scripts/validate.sh` (or `./bin/pagani doctor`). The lint checks that
   the folder name matches `name:` and that the description exists.

Do not use a `pagani-` prefix. Do not add paid skills, paid assets, or
cloud-session workflows.
