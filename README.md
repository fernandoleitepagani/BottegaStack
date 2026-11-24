# bottega

![Linux](https://img.shields.io/badge/Linux-supported-FCC624?logo=linux&logoColor=black) ![macOS](https://img.shields.io/badge/macOS-supported-000000?logo=apple&logoColor=white)

bottega is a Claude Code plugin that turns one agent into a small engineering team: playbooks for the common kinds of work, rigorous principles, and review and verification steps that make the agent prove what it claims.

**credit.** bottega is a Claude Code port of [pstack](https://github.com/cursor/plugins), the skill set written by [Lauren Tan (poteto)](https://x.com/poteto) for Cursor. The playbooks, principles, and most skill text come from her work, used under the MIT license (see [LICENSE](./LICENSE)). The port keeps her voice and ideas and changes only what Claude Code requires.

the goal is not to maximize lines of code. it's the opposite. bottega helps you write less, but higher quality code. if you want to go fast, go deep first. when you can go deep on one agent and trust it to write good, verifiable code, you can parallelize with confidence: start several agents with `/maestro` and they apply the same engineering principles.

## install

```bash
claude plugin marketplace add <path-or-repo>
claude plugin install bottega@bottega
```

start a new session afterwards. claude code prefixes plugin commands, so `/maestro` is also `/bottega:maestro`. bottega uses no hooks.

**platforms.** linux and macos only. the scripts need only `bash` and `git`, plus `gh` for the `pr` skill. python is used only by the developer lint and evals. native windows is not supported. under WSL, bottega runs as on linux.

## get started

two steps:

1. run [`/setup-maestro`](./skills/setup-maestro/SKILL.md). it shows each role with its model (`opus`, `sonnet`, `haiku`) and effort (`low`, `medium`, `high`), and writes your choices to `~/.claude/rules/bottega-models.md`.
2. use [`/maestro`](./skills/maestro/SKILL.md) whenever you're doing anything that requires rigor.

new here? the [bottega guide](./docs/guide/README.md) walks you through a first real task, from setup and prompting through verification and overnight runs.

that's it. the other skills are situational, and `/maestro` uses them for you as needed. out of the box, code delegates run `sonnet` at low effort, judgment and prose run `opus` at low effort, and explorers and workers run `haiku` at high effort. every skill except `/setup-maestro` ships with `disable-model-invocation: true`, so none costs context until it runs. `/maestro` reads the catalog in [`skills/maestro/SKILLS-INDEX.md`](./skills/maestro/SKILLS-INDEX.md), picks candidates, asks you with `AskUserQuestion`, and only then reads the chosen skill.

## risk

each run states a risk level, `normal` or `high`, in its first message. risk only goes up during a run. high risk moves delegates up an effort tier, widens `/parallel` to up to four runners with a cross-judge, and adds [`crossfire`](./skills/crossfire/SKILL.md) before the final gate.

## usage

use [`/maestro`](./skills/maestro/SKILL.md) at the start of a task. it reads your request, picks from a set of playbooks, and runs the other skills as the steps need them.

```
/maestro this pr has a subtle bug where the scroll drifts every 750ms even when idle. repro
first, then fix and verify.
```

```
/maestro i'm going to bed. land the stack even if ci flakes. i want everything merged by
morning.
```

<details>
<summary>the 8 playbooks</summary>

| playbook | for |
|---|---|
| [investigate](./skills/maestro/playbooks/investigate.md) | a read-only question (how, why, are we sure), or diagnosing a symptom from a running process or a captured profile. no fix. |
| [bug fix](./skills/maestro/playbooks/bug-fix.md) | reproduce a defect, root-cause it, and fix with runtime evidence. |
| [feature](./skills/maestro/playbooks/feature.md) | new or changed behavior, built from a named data shape. |
| [refactoring](./skills/maestro/playbooks/refactoring.md) | a behavior-preserving change to structure or shape. |
| [prototype](./skills/maestro/playbooks/prototype.md) | a throwaway sketch to make a design or behavioral decision cheaply, or to settle an empirical fork by observing it. |
| [unattended](./skills/maestro/playbooks/unattended.md) | work run without you watching: one task to an exit condition, a queue of PRs (land or stack), or a multi-day program. its permissions are spelled out. |
| [handoff](./skills/maestro/playbooks/handoff.md) | pause in-flight work cleanly, or resume a prior agent's work. |
| [worktree cleanup](./skills/maestro/playbooks/worktree-cleanup.md) | reclaim disk by pruning merged or abandoned worktrees, safety-gated. |

</details>

when invoked it:

1. matches your task to a [playbook](./skills/maestro/playbooks/) and opens a todo list whose first items are its steps, copied in verbatim.
2. routes to the other skills as the steps fire, and ends code changes at the final gate. if you pick `open a PR`, the [`pr`](./skills/pr/SKILL.md) skill takes it from there.
3. when a check fails, runs [`crossfire`](./skills/crossfire/SKILL.md)'s fix step and hands a fresh delegate the fix brief, up to 2 fix rounds.
4. writes unslopped replies framed for the consumer and the maintainer.

the full rules and playbooks live in [`skills/maestro/SKILL.md`](./skills/maestro/SKILL.md).

to keep `/maestro` in effect across turns, add a one-line pointer to your `CLAUDE.md` and re-invoke `/maestro` when the chat drifts. it works well with claude code's `/loop`: a loop prompt is plain text that reads the skill, for example `/loop 5m Read <abs path>/skills/pr/SKILL.md and continue babysit`.

## skills

[`/maestro`](./skills/maestro/SKILL.md) runs most of these for you when a step needs them (`understand`, `architect`, `parallel`, `crossfire`, `pr`, `unslop`, and the principles). the table below is for when you want one directly:

```
/understand how do we cancel runs? do we have an n+1 when we look up every run to cancel?
```

```
/crossfire review this pr.
```

<details>
<summary>all skills</summary>

| skill | use it when |
|---|---|
| [`/maestro`](./skills/maestro/SKILL.md) | default entry point for any non-trivial task. |
| [`/setup-maestro`](./skills/setup-maestro/SKILL.md) | you want to pick which models bottega uses per role. writes `~/.claude/rules/bottega-models.md`. |
| [`/understand`](./skills/understand/SKILL.md) | you want to know how something works (how mode), why it was built this way (why mode: git and `gh` investigators in parallel, other sources only with your approval), where your recent work stands (recall mode), or what changed in this chat and what waits on you (catch-up mode). |
| [`/architect`](./skills/architect/SKILL.md) | you're about to write code that crosses a function boundary and want the caller's usage, types, and module shape settled first. scan mode looks across the codebase for modules worth deepening. |
| [`/parallel`](./skills/parallel/SKILL.md) | you want parallel agents on one job: coverage across slices, a race with a winner rule, or a bakeoff that picks a base and grafts the best parts of the others. |
| [`/crossfire`](./skills/crossfire/SKILL.md) | you have a diff, a design, or a PR and want independent adversaries to try to break it, in up to 3 budgeted rounds, keeping only findings a rerun proves. each round's findings become a fix brief for a fresh delegate, at most 2 fix rounds. |
| [`/pr`](./skills/pr/SKILL.md) | open a PR or stack, babysit it to merge-ready, land a verified stack, refresh an old PR after deciding it still belongs, or file a run's follow-ups as GitHub issues after one confirmation. |
| [`/wayfinder`](./skills/wayfinder/SKILL.md) | the destination is foggy and the work is too big for one session. charts a map of decision tickets and resolves them one at a time. |
| [`/correct`](./skills/correct/SKILL.md) | you keep correcting agents for the same mistakes. fixes each class at the highest level that works (architecture, then types, lint, and ci, then tests, with docs last). |
| [`/figure-it-out`](./skills/figure-it-out/SKILL.md) | no bundled playbook fits. designs a rigorous, auditable playbook for the task. |
| [`/create-verification-skill`](./skills/create-verification-skill/SKILL.md) | your project has no scripted way to prove app behavior. generates a project-local `verify-<app>` skill with a feature map. |
| [`/maintain-verification-skill`](./skills/maintain-verification-skill/SKILL.md) | your verify skill's feature map has drifted from the app. source wave, one live pass, at most one PR of proven corrections. |
| [`/unslop`](./skills/unslop/SKILL.md) | you're cleaning up writing. removes AI tells. |

</details>

### examples

```
bug fix:           /maestro this pr has a subtle bug where the scroll drifts every 750ms even
                   when idle. repro first, then fix and verify.
feature:           /maestro build a small feature behind a feature flag. verify it really works.
prototype:         /maestro build two prototypes of the markdown renderer so we can compare.
overnight run:     /maestro i'm going to bed. land the stack even if ci flakes. i want
                   everything merged by morning.
babysit:           /maestro check on pr 123. anything outstanding?
understand:        /understand how do we cancel runs? do we have an n+1 when we look up every run to cancel?
                   /understand why is this feature flag not on yet?
architect:         design this instrumentation to be high signal with no false positives. /architect
                   this first.
arena:             /parallel take my prompt to the arena verbatim. i want to compare their proposals
                   with yours.
swarm:             /parallel check every package under packages/ against its check.sh. one worker per
                   package. one report.
crossfire:         /crossfire review this pr.
unslop:            can we unslop and tighten the new changes?
follow-ups:        /pr file the follow-ups from that run.
wayfinder:         /wayfinder we need to move off the old billing system. i don't know where to start.
correct:           /correct
```

### from BottegaStack

| skill | use it when |
|---|---|
| `/interface-review` | you want the UI problems a diff introduced. |
| `/frontend-design` | you want a distinct visual direction for new UI. |
| `/better-interface` | you want one ranked review of a screen or flow. |
| `/better-accessibility`, `/better-colors`, `/better-layout`, `/better-typography`, `/better-ui`, `/better-writing` | you want one UI domain built or reviewed. agents write the code; you check the rendered result. |

## the `maestro-agent` subagent

[`/maestro`](./skills/maestro/SKILL.md) runs in the chat that receives it. that chat owns the playbook, the todo list, and every subagent spawn.

bottega ships [`subagent_type: "bottega:maestro-agent"`](./agents/maestro-agent.md) as the wrapper for delegates spawned during a run. it reads the slim delegate brief at `skills/maestro/references/delegate.md` before doing any work, including the comments rule: no comments by default, four allowed cases, and a self-check on the diff before review. substituting `general-purpose` skips that read and drifts. do not spawn `maestro-agent` to run the playbook itself.

## principles

nineteen principles, grouped in four reference files under [`skills/maestro/references/principles/`](./skills/maestro/references/principles/) (core, architecture, verification, delegation). `maestro` reads their index at task start and reads a principle's section only when it applies.

<details>
<summary>all nineteen principles</summary>

| principle | group | rule |
|---|---|---|
| [delete-first](./skills/maestro/references/principles/core.md) | core | Remove before you build, and ship the smallest change that solves the problem. |
| [shape-before-logic](./skills/maestro/references/principles/core.md) | architecture | Choose the data structure that encodes the domain before writing logic. |
| [redesign-from-first-principles](./skills/maestro/references/principles/core.md) | core | Redesign as if the requirement had been a foundational assumption from day one, instead of bolting it on. |
| [attack-the-premise](./skills/maestro/references/principles/core.md) | core | Apply when two or more fixes that share one premise have failed the same gate. Write the premise down and test it directly before you write another fix that assumes it. |
| [minimize-reader-load](./skills/maestro/references/principles/core.md) | core | Count layers between question and answer, and hidden state in the reader's head; collapse one-caller wrappers and shrink mutable scope. |
| [outcome-oriented-execution](./skills/maestro/references/principles/core.md) | core | Apply during planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture; don't preserve smooth intermediate states with throwaway compatibility code. |
| [exhaust-the-design-space](./skills/maestro/references/principles/core.md) | core | Build 2-3 competing prototypes and compare side by side before committing. |
| [mechanize-it](./skills/maestro/references/principles/core.md) | core | Build the tool that does, proves, or enforces the work instead of hand work or more prose. |
| [boundary-discipline](./skills/maestro/references/principles/architecture.md) | architecture | Concentrate guards at system boundaries (CLI, config, network, external APIs); trust internal types and keep business logic in pure functions. |
| [type-system-discipline](./skills/maestro/references/principles/architecture.md) | architecture | Make illegal states unrepresentable, brand semantic primitives, parse external data at boundaries, exhaust variants, derive from authoritative schemas. |
| [make-operations-idempotent](./skills/maestro/references/principles/architecture.md) | architecture | Converge to the same end state regardless of partial prior runs. |
| [migrate-callers-then-delete-legacy-apis](./skills/maestro/references/principles/architecture.md) | architecture | Migrate callers and delete the old API in the same wave instead of preserving compatibility layers. |
| [separate-before-serializing-shared-state](./skills/maestro/references/principles/architecture.md) | architecture | Eliminate the sharing first; serialize structurally only when one shared writer is a real invariant. |
| [prove-it-works](./skills/maestro/references/principles/verification.md) | verification | Apply after completing a task, before declaring done. Verify against the real artifact (run the feature, read the actual value, inspect the diff), not a proxy, self-report, or 'it compiles.'. |
| [fix-root-causes](./skills/maestro/references/principles/verification.md) | verification | Trace each symptom back to the first place the system went wrong and fix it there. A guard is a fix only when the state it handles is legitimate. |
| [sequence-verifiable-units](./skills/maestro/references/principles/verification.md) | verification | Apply to multi-step work (sweeps, migrations, runs of similar edits) and to how you stack commits and PRs. Break work into small units that each end in a verifiable state, check each before the next, and order delivery so the sequence proves itself to a reviewer. |
| [test-behavior-not-implementation](./skills/maestro/references/principles/verification.md) | verification | Apply when you write, change, or keep a test. Assert what the code's users can observe, so the test fails when that behavior breaks and keeps passing when only the internals change. |
| [guard-the-context-window](./skills/maestro/references/principles/delegation.md) | delegation | Route bulk to subagents; keep summaries in the main thread, not raw payloads. |
| [never-block-on-the-human](./skills/maestro/references/principles/delegation.md) | delegation | Proceed, present the result, let the human course-correct after the fact; reserve confirmation for irreversible actions. |

</details>

## not shipped here

bottega does not drive or screenshot a UI. where a change needs a visual check, the agent says what to look at and you check it; paste screenshots back if you want it to read them. pr watching uses `gh`, not a bundled watcher, so stack and queue handling and NDJSON output from the original are lost. there are no hooks and no planning skill beyond [`wayfinder`](./skills/wayfinder/SKILL.md).

## make it yours

`maestro` is one person's style. you may not want exactly that.

models are configurable too. type [`/setup-maestro`](./skills/setup-maestro/SKILL.md). `/maestro` and the skills that spawn subagents read `~/.claude/rules/bottega-models.md` and falls back to the role defaults when a line is absent, so you override only what you want. when a default changes, a rule written before the change still pins the old default. delete those role lines, or the file, then run `/setup-maestro` again.

## license

MIT. original pstack by Lauren Tan (poteto). see [LICENSE](./LICENSE).

## credits

- the `better-*` skills and `interface-review` carry an MIT license from Jakub Krehel (see each skill's `LICENSE`).
- the deep-module vocabulary and the glossary and ADR guides under `skills/architect/references/codebase-design/` and `.../domain-modeling/` carry an MIT license from Matt Pocock (see each folder's `LICENSE`).
- `understand`, `pr`, `parallel`, and the `investigate`, `unattended`, and `handoff` playbooks are original works by the bottega author, written for this port and drawing on ideas from pstack.
- `frontend-design` is Anthropic's skill from [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design), adapted to bottega's skill paths under the Apache License 2.0 (see [its LICENSE.txt](./skills/frontend-design/LICENSE.txt)).
