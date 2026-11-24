# Skills index

One line per bundled skill: `name (~SKILL.md tokens, +references loaded only when a step needs them)`, then when to use it. Read a skill at `../<name>/SKILL.md`. Ask the user before reading one no maestro trigger names.

## Understand
- `how` (~0.6k, +1k refs): how code works, walkthroughs before a change, placement and ownership questions.
- `why` (~2.2k, +11k refs): why code is shaped this way, design rationale, regressions, postmortems. Git and `gh` evidence by default.
- `blast-radius` (~1k): what a change could break outside the diff, proven with a run.
- `recall` (~1.3k): rebuild recent working context from chat history and live state.
- `teach` (~1.4k): explain a body of work so a person understands it (runs `how` and `why`).
- `ketchup` (~1.6k): catch the user up on what changed and what decisions wait on them.

## Design and parallel work
- `architect` (~1.4k, +2.3k refs): sketch types and module shape before code that crosses a function boundary.
- `arena` (~1.1k): parallel candidates, pick a base, graft the best parts (normal: 2 runners; high risk: up to 4 plus a judge).
- `swarm` (~0.6k): fan out N workers for coverage, races, or partitions; one consolidated report.
- `crossfire` (~1.0k): adversarial review that keeps only run-proven findings. Solo at high risk, panel for contested designs.
- `figure-it-out` (~1k): design a bespoke playbook when none fits.
- `wayfinder` (~1.1k): plan foggy work too big for one session as a map of decision tickets.
- `domain-modeling` (~0.8k, +1.5k refs): sharpen domain terms, write `GLOSSARY.md` and ADRs.
- `codebase-design` (~1.6k, +1.6k refs): deep-module vocabulary for interfaces, seams, and testability.
- `improve-architecture` (~1.5k, +1.7k refs): whole-codebase scan for deepening opportunities, HTML report, then decide one.

## Quality and review
- `diagnosis` (~0.9k): turn a failed check or review findings into a fix brief; max 2 fix rounds.
- `no-comments` (~0.7k): comment review via the comment-sicko agent, then fix accepted findings.
- `tdd` (~0.8k): only when asked for TDD or a cheap local test path exists.
- `correct` (~0.6k): make a mistake agents repeat in this repo impossible (architecture, types, lint, tests).
- `unslop` (~1.5k): cut AI tells from any writing.
- `technical-writing` (~2.3k): docs, READMEs, PR bodies, commit messages.
- `benchmark-checklist` (~1.3k): vet a perf number before reporting or acting on it.

## Review and incidents
- `review-pr` (~0.5k): review a PR as a merge decision: intent, diff, CI, risk, tests, security, revert plan.
- `runbook` (~0.5k): structured investigation of an incident, alert, or unknown breakage.
- `data-analysis` (~0.3k): answer a data question from logs, CSVs, SQL, or metrics with the query shown.
- `library-reference` (~0.4k): document an internal library, CLI, or API for agents.
- `wizard` (~1.0k, +2.4k refs): a guided bash script for steps only the user can do.

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

## Run records and follow-ups
- `show-me-your-work` (~1.7k): decision trail for long or unattended runs.
- `file-followups` (~0.9k): file `.bottega/followups.md` items as GitHub issues after one confirmation.

## Setup and help
- `setup-maestro` (~1.4k): choose models and effort per role, install the status line.
- `maestro-help` (~3.4k, +1.6k refs): onboarding, and picking the right skill, playbook, or principle.

## Principles
21 `principle-<name>` skills, ~0.1k to 0.4k each. The maestro delegate brief (`references/delegate.md`) indexes them; read a leaf before applying it.
