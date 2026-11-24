# Skills index

One line per bundled skill: `name (~SKILL.md tokens, +references loaded only when a step needs them)`, then when to use it. Read a skill at `../<name>/SKILL.md`. Ask the user before reading one no maestro trigger names.

## Understand
- `understand` (~1.6k, +12k refs): how code works, why it is shaped that way, recall of recent work, and catching the user up.

## Design and parallel work
- `architect` (~1.2k, +9k refs): sketch types and module shape before code that crosses a function boundary; scan mode finds deepening opportunities across the codebase (with deep-module vocabulary, GLOSSARY.md and ADR guides).
- `parallel` (~1.2k): fan out agents and return one result: coverage (slices), race (winner rule), bakeoff (pick a base, graft the rest; 2 runners, up to 4 plus a judge at high risk).
- `crossfire` (~1.9k): adversarial review in budgeted rounds that keeps only run-proven findings, then writes the fix brief for a fresh delegate (max 2 fix rounds). Solo at high risk, panel for contested designs, PR mode for a merge decision.
- `figure-it-out` (~1k): design a bespoke playbook when none fits.
- `wayfinder` (~1.1k): plan foggy work too big for one session as a map of decision tickets.

## Quality and review
- `correct` (~0.6k): make a mistake agents repeat in this repo impossible (architecture, types, lint, tests).
- `unslop` (~1.5k): cut AI tells from any writing.

## UI and design (agents write the code; the user checks the rendered UI)
- `frontend-design` (~2.4k): visual direction for new or reshaped UI.
- `interface-review` (~2.5k, +2.7k refs): UI problems a branch or PR introduced or regressed.
- `better-interface` (~2.3k, +0.8k refs): one ranked review across the domains below.
- `better-accessibility` (~2.8k, +6.5k refs): keyboard, focus, ARIA, forms, WCAG 2.2.
- `better-colors` (~2.0k, +7.9k refs): palettes, semantic tokens, contrast.
- `better-layout` (~2.2k, +2.7k refs): grouping, alignment, responsive structure.
- `better-typography` (~3.1k, +4.5k refs): type scale, spacing, wrapping.
- `better-ui` (~2.8k, +5.5k refs): surfaces, icons, motion values.
- `better-writing` (~2.4k, +1.0k refs): interface copy.

## Verification
- `create-verification-skill` (~1.7k, +1.4k refs): generate a project `verify-<app>` skill that drives the app through CLI, API, process, or tests.
- `maintain-verification-skill` (~1.3k): keep that skill and its feature map honest.

## PRs and run records
- `pr` (~1.9k, +2k refs): open a PR or stack, babysit it to merge-ready, land a verified stack, refresh an old PR, file follow-ups as issues.

## Setup
- `setup-maestro` (~0.9k): choose models and effort per role.

## Principles
19 principles in four files under `references/principles/` (core, architecture, verification, delegation), about 0.3k tokens each. The maestro delegate brief (`references/delegate.md`) indexes them; read a principle's section before applying it.
