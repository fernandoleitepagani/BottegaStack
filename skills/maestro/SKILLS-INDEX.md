# Skills index

One line per bundled skill: `name (~SKILL.md tokens, +references loaded only when a step needs them)`, then when to use it. Read a skill at `../<name>/SKILL.md`.

## Plan and build
- `reframe` (~0.5k): clarify a rough idea when you lack the exact technical vocabulary; outputs interpretations, ranked expert terms, analogies, and a crisp prompt.
- `plan` (~1.3k): grill the user one decision at a time into an agreed spec; map mode for efforts too big for one session.
- `sharpen` (~0.5k): strip vague adjectives from a prompt or spec into concrete, testable claims and explicit non-goals.
- `tickets` (~1.8k): split a spec into tickets that each fit one 300k-token orchestrator session, with the orchestrator and subagent split, parallel waves, and an opus- or sonnet-level orchestrator per ticket.
- `implement` (~1.3k): build one ticket or one small task: explore, shape, delegate, verify, review, final gate.
- `ship` (~0.7k): commit, open a PR, and either babysit CI/review bots to merge (full-send) or open a draft PR and stop (full-stop).

## Quality
- `correct` (~0.6k): make a mistake agents repeat in this repo impossible (architecture, types, lint, tests).
- `unslop` (~1.5k): cut AI tells from any writing.

## UI
- `frontend-design` (~2.0k): visual direction for new or reshaped UI. Agents write the code; the user checks the rendered UI.

## Verification
- `create-verification-skill` (~1.7k, +1.4k refs): generate a project `verify-<app>` skill that drives the app through CLI, API, process, or tests.
- `maintain-verification-skill` (~1.3k): keep that skill and its feature map honest.

## Principles
17 principles on one page, `references/principles.md` (~1.3k tokens).
