# Skill categories

PaganiStack uses the nine categories the Claude Code team uses for internal
skills, plus two explicit extensions. The nine were built for engineering work;
they do not cover planning or UI/UX production, so `workflow/` and `design/` are
extensions, not replacements.

## The nine

### 1. library-api-reference

How to use a library, CLI, SDK, or internal API correctly: entry points,
examples, invariants, error modes, and gotchas. Use it when the agent would
otherwise guess at an API from names. Example: `library-reference`,
`vercel-react-best-practices`.

### 2. product-verification

How to test or verify that the product actually works: tests, builds, browser
drivers, screenshots, end-to-end flows. This is the highest-value category.
Example: `verification`, `review-ui`, `review-ux`, `web-design-guidelines`,
`agent-browser`.

### 3. data-analysis

How to answer a question from real data: SQL, DuckDB, pandas, logs, metrics,
cohorts, funnels, anomalies. The skill must name the canonical source, the query,
and the caveats. Example: `data-analysis`.

### 4. business-automation

How to turn a recurring workflow into one command: standups, weekly recaps,
ticket creation, backlog triage, release notes. These are simple instructions
with dependencies on other skills or tools. Example: `backlog-triage`,
`weekly-review`.

### 5. scaffolding

How to create a new component, service, route, migration, or test fixture that
matches the project. The skill should point at the closest existing example and
use the project's generator when one exists. Example: `scaffold`.

### 6. code-quality

How to keep code correct and reviewable: review lenses, implementation rules,
domain and codebase design, simplification, adversarial review, PR review, tests.
Example: `review-code`, `review-security`, `approval`, `implementation`,
`codebase-design`, `domain-modeling`, `improve-architecture`,
`adversarial-review`, `simplify`, `review-pr`, `tdd`, `code-review`.

### 7. ci-cd

How to set up, debug, and review the pipeline: checks, PR automation, merge
queues, deploy, feature flags, rollback. Example: `ci-cd`, `pr`.

### 8. runbooks

How to investigate a symptom: incident, alert, "why is this broken", on-call
triage. The output is a timeline, evidence, a cause, and a follow-up. Example:
`runbook`, `diagnosis`, `diagnosing-bugs`.

### 9. infrastructure-ops

How to change infrastructure safely: dependencies, cost, access, orphaned
resources, least privilege, dry runs, approval gates. Example: `infra-ops`.

## The two extensions

### 10. workflow

The planning and session skills that the nine do not cover: interview, summary,
wait-what, wayfinding, planning, plain-writing, closeout, handoff, retro, and
skill-creator. These are personal workflow skills, not team automation.

### 11. design

UI/UX production skills: art direction, typography, palette, layout, mobile
principles, generative UI, motion, and polish. Review remains in
`product-verification/` and `code-quality/`.

## Why the four you asked about matter

- **business-automation** is where a personal stack compounds. A weekly review
  and a backlog triage turn repeated work into a routine, and the routine can be
  measured. It is not about chatbots; it is about saving the human's attention.
- **scaffolding** is where consistency starts. If every new component is created
  from the closest existing example, the codebase stays navigable for agents and
  humans. If every agent invents a new layout, the codebase drifts.
- **runbooks** are where debugging becomes evidence. A runbook forces a symptom,
  a scope, hypotheses, and a timeline. It stops the agent from guessing and
  makes the next incident cheaper.
- **data-analysis** is where claims become numbers. A query, a source, and a
  caveat beat a plausible story. It is also the category that catches silent
  data bugs.

## What does not belong

- A skill that tries to do three categories at once.
- A skill that restates what the model already knows.
- A paid skill or a skill that needs a paid asset.
- A skill whose description does not say when to trigger it.
