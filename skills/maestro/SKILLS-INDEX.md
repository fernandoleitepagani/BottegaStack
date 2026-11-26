# Skills index

One line per bundled skill: `name (~SKILL.md tokens, +references loaded only when a step needs them)`, then when to use it. Read a skill at `../<name>/SKILL.md`.

## Plan and build
- `maestro` (~1.8k): front door and router; holds shared rules (risk, autonomy, subagents, context, replies) and dispatches to all other skills.
- `reframe` (~0.4k): clarify a rough idea when you lack the exact technical vocabulary; outputs interpretations, ranked expert terms, analogies, and a crisp prompt.
- `recall` (~0.4k): rebuild compressed context from recent session transcripts and `.bottega/` state when starting a fresh session on an ongoing problem.
- `triage` (~0.5k): cluster multiple bug reports, issues, or PRs by shared root cause, flag non-repros, and route each cluster to `/plan`, `/tickets`, or `/implement`.
- `plan` (~1.4k): grill the user one decision at a time into an agreed spec; map mode for efforts too big for one session.
- `sharpen` (~0.3k): strip vague adjectives from a prompt or spec into concrete, testable claims and explicit non-goals.
- `tickets` (~1.9k): split a spec into tickets that each fit one 300k-token orchestrator session, with the orchestrator and subagent split, parallel waves, and an abstract model tier (`heavy`, `medium`, `standard`, `fast`) per ticket.
- `implement` (~1.3k): build one ticket or one small task: explore, shape, delegate, verify, review, final gate.
- `ship` (~1.3k): commit, open a PR, and either babysit CI/review bots to merge (`/ship full`) or open a draft PR and stop (`/ship stop`).
- `autopilot` (~1.6k): run a task, ticket queue (`PLAN.md`), or standing program unattended until checkable exit conditions pass; asks upfront whether to auto-merge (`/ship full`) or stop at verified PRs (`/ship stop`).

## Quality
- `correct` (~0.6k): make a mistake agents repeat in this repo impossible (architecture, types, lint, tests).
- `garden` (~0.6k): periodic on-demand sampling audit of recent commits and `.bottega/followups.md` to spot repeated agent shortcuts and propose systemic fixes.
- `unslop` (~1.5k): cut AI tells from any writing.

## UI
- `frontend-design` (~2.0k): visual direction for new or reshaped UI. Agents write the code; the user checks the rendered UI.

## Verification
- `create-verification-skill` (~1.7k, +1.4k refs): generate a project `verify-<app>` skill that drives the app through CLI, API, process, or tests.
- `maintain-verification-skill` (~1.3k): keep that skill and its feature map honest.

## Human steps
- `wizard` (~1.1k, +template): write an interactive bash script that walks the user through steps only they can do (dashboards, credentials, CI secrets, a cutover) and writes the values where they belong.

## Principles
17 principles on one page, `references/principles.md` (~1.3k tokens).
