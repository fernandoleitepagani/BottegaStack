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

**platforms.** linux and macos only. the scripts need `bash`, `git`, `python3` (3.9 or later) and `node`, plus `gh` for the PR playbooks. native windows is not supported. under WSL, bottega runs as on linux.

## get started

two steps:

1. run [`/setup-maestro`](./skills/setup-maestro/SKILL.md). it shows each role with its model (`opus`, `sonnet`, `haiku`) and effort (`low`, `medium`, `high`), writes your choices to `~/.claude/rules/bottega-models.md`, and can set up the status line (it backs up `statusLine` in `~/.claude/settings.json` first).
2. use [`/maestro`](./skills/maestro/SKILL.md) whenever you're doing anything that requires rigor.

new here? the [bottega guide](./docs/guide/README.md) walks you through a first real task, from setup and prompting through verification and overnight runs. stuck, or unsure which skill fits? ask [`/maestro-help`](./skills/maestro-help/SKILL.md).

that's it. the other skills are situational, and `/maestro` uses them for you as needed. out of the box, code delegates run `sonnet` at low effort, judgment and prose run `opus` at low effort, and explorers and workers run `haiku` at high effort. every skill except `/setup-maestro` ships with `disable-model-invocation: true`, so none costs context until it runs. `/maestro` reads the catalog in [`skills/maestro/SKILLS-INDEX.md`](./skills/maestro/SKILLS-INDEX.md), picks candidates, asks you with `AskUserQuestion`, and only then reads the chosen skill.

## risk

each run states a risk level, `normal` or `high`, in its first message. risk only goes up during a run. high risk moves delegates up an effort tier, widens `/arena` to up to four runners with a cross-judge, and adds [`crossfire`](./skills/crossfire/SKILL.md) before the final gate.

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
<summary>the 20 playbooks</summary>

| playbook | for |
|---|---|
| [investigation](./skills/maestro/playbooks/investigation.md) | a read-only question. how does x work, why was y built this way, are we sure. |
| [bug fix](./skills/maestro/playbooks/bug-fix.md) | reproduce a defect, root-cause it, and fix with runtime evidence. |
| [perf](./skills/maestro/playbooks/perf-issue.md) | trace a measured slowness and improve it against a baseline. |
| [hillclimb](./skills/maestro/playbooks/hillclimb.md) | sustained, scientific improvement of one metric against a target, looping hypotheses with before/after measurement and one commit per accepted win. |
| [forensics](./skills/maestro/playbooks/forensics.md) | diagnose a symptom from live instrumentation or a captured profiling artifact. no fix. |
| [feature](./skills/maestro/playbooks/feature.md) | new or changed behavior, built from a named data shape. |
| [refactoring](./skills/maestro/playbooks/refactoring.md) | a behavior-preserving change to structure or shape. |
| [prototype](./skills/maestro/playbooks/prototype.md) | a throwaway sketch to make a design or behavioral decision cheaply, or to settle an empirical fork by observing it. |
| [authoring a skill](./skills/maestro/playbooks/authoring-a-skill.md) | writing or editing a SKILL.md. |
| [eval](./skills/maestro/playbooks/eval.md) | test how a skill or prompt change affects agent behavior, blinded. |
| [babysit](./skills/maestro/playbooks/babysit.md) | drive a pr to merge-ready: conflicts, review threads, ci. uses `gh` polled under `/loop`. |
| [shipping](./skills/maestro/playbooks/shipping.md) | independently verify a green stack, then land the contiguous verified run bottom-up through github with `gh`. |
| [autonomous run](./skills/maestro/playbooks/autonomous-run.md) | drive a long task to completion without stopping. |
| [orchestrate](./skills/maestro/playbooks/orchestrate.md) | a standing project handed to one coordinator chat: multi-day, many stacked prs, fleets of subagents. |
| [autopilot](./skills/maestro/playbooks/autopilot.md) | run independent prs with one owner per pr, swarm-verified. `land` mode merges them, `stack` mode hands verified prs to you. |
| [session pickup](./skills/maestro/playbooks/session-pickup.md) | resume or take over a prior agent's in-flight work. |
| [pause safely](./skills/maestro/playbooks/pause-safely.md) | suspend in-flight work cleanly so it can be resumed later. |
| [multi-phase plan](./skills/maestro/playbooks/multi-phase-plan.md) | work that spans phases or stacked PRs. |
| [worktree cleanup](./skills/maestro/playbooks/worktree-cleanup.md) | reclaim disk by pruning merged or abandoned worktrees, safety-gated. |
| [opening a pr](./skills/maestro/playbooks/opening-a-pr.md) | open a ready pr from small ordered commits with a conventional commits title and a briefing-style body. invoked at the end of every other playbook. |

</details>

when invoked it:

1. matches your task to a [playbook](./skills/maestro/playbooks/) and opens a todo list whose first items are its steps, copied in verbatim.
2. routes to the other skills as the steps fire.
3. when a check fails, runs [`diagnosis`](./skills/diagnosis/SKILL.md) and hands a fresh delegate the fix brief, up to 2 fix rounds.
4. writes unslopped replies framed for the consumer and the maintainer.

the full rules and playbooks live in [`skills/maestro/SKILL.md`](./skills/maestro/SKILL.md).

to keep `/maestro` in effect across turns, add a one-line pointer to your `CLAUDE.md` and re-invoke `/maestro` when the chat drifts. it works well with claude code's `/loop`: a loop prompt is plain text that reads the skill, for example `/loop 5m Read <abs path>/skills/maestro/SKILL.md and playbooks/babysit.md and continue the babysit playbook`.

## skills

[`/maestro`](./skills/maestro/SKILL.md) runs most of these for you when a step needs them (`how`, `why`, `architect`, `arena`, `swarm`, `crossfire`, `unslop`, `no-comments`, `technical-writing`, `tdd`, and the principles). the table below is for when you want one directly:

```
/how do we cancel runs? do we have an n+1 when we look up every run to cancel?
```

```
/crossfire review this pr.
```

<details>
<summary>all skills</summary>

| skill | use it when |
|---|---|
| [`/maestro`](./skills/maestro/SKILL.md) | default entry point for any non-trivial task. |
| [`/maestro-help`](./skills/maestro-help/SKILL.md) | you're new to bottega, or unsure which skill, playbook, or principle fits. finds out what you're trying to do, answers that part, and hands you a prompt to type. |
| [`/setup-maestro`](./skills/setup-maestro/SKILL.md) | you want to pick which models bottega uses per role. writes `~/.claude/rules/bottega-models.md` and can set up the status line. |
| [`/how`](./skills/how/SKILL.md) | you want a walkthrough of how a subsystem works. |
| [`/why`](./skills/why/SKILL.md) | you want to know why something was built this way. runs git and `gh` investigators in parallel; other evidence sources only when you approve that MCP server. |
| [`/recall`](./skills/recall/SKILL.md) | you're starting or resuming work and want your recent context on a topic rebuilt from your chat history, handed back as a tight current-state brief. |
| [`/ketchup`](./skills/ketchup/SKILL.md) | you want what changed in this chat since your last message, in plain words, with every item waiting on you listed and decidable from the reply alone. |
| [`/blast-radius`](./skills/blast-radius/SKILL.md) | you have a small-looking change and want to know what else it could break, with the one fact it's safe because of proven by running code. |
| [`/architect`](./skills/architect/SKILL.md) | you're about to write code that crosses a function boundary and want the caller's usage, types, and module shape settled first. |
| [`/arena`](./skills/arena/SKILL.md) | you want parallel attempts at the same thing, then to grab the best parts of each. normal risk runs 2 runners and no cross-judge; high risk runs up to 4 and one cross-judge. |
| [`/swarm`](./skills/swarm/SKILL.md) | you want N parallel workers across different slices or races, then one aggregated report. |
| [`/crossfire`](./skills/crossfire/SKILL.md) | you have a diff and want independent adversaries to try to break it, keeping only findings a rerun proves. |
| [`/diagnosis`](./skills/diagnosis/SKILL.md) | a check failed or a review returned findings. turns them into a precise fix brief for a fresh delegate. at most 2 fix rounds per task, then escalate. |
| [`/file-followups`](./skills/file-followups/SKILL.md) | a run left loose ends. lists them as proposed GitHub issues and files them with `gh` after one confirmation. |
| [`/wayfinder`](./skills/wayfinder/SKILL.md) | the destination is foggy and the work is too big for one session. charts a map of decision tickets and resolves them one at a time. |
| [`/correct`](./skills/correct/SKILL.md) | you keep correcting agents for the same mistakes. fixes each class at the highest level that works (architecture, then types, lint, and ci, then tests, with docs last). |
| [`/teach`](./skills/teach/SKILL.md) | you want to actually understand a change or subsystem. runs how + why and weaves one plain explanation. |
| [`/tdd`](./skills/tdd/SKILL.md) | you're fixing a bug and there's a cheap local test path. write the failing test first, then the fix. |
| [`/benchmark-checklist`](./skills/benchmark-checklist/SKILL.md) | you ran a benchmark or measured a speedup or regression. vets the number before you report or act on it. |
| [`/no-comments`](./skills/no-comments/SKILL.md) | strip comments before review; spawns Comment Sicko, fixes accepted findings, offers encodings for claimed constraints. |
| [`/figure-it-out`](./skills/figure-it-out/SKILL.md) | no bundled playbook fits. designs a rigorous, auditable playbook for the task. |
| [`/show-me-your-work`](./skills/show-me-your-work/SKILL.md) | you want a reviewable decision trail. logs decisions to a tsv you can commit. |
| [`/create-verification-skill`](./skills/create-verification-skill/SKILL.md) | your project has no scripted way to prove app behavior. generates a project-local `verify-<app>` skill with a feature map. |
| [`/maintain-verification-skill`](./skills/maintain-verification-skill/SKILL.md) | your verify skill's feature map has drifted from the app. source wave, one live pass, at most one PR of proven corrections. |
| [`/unslop`](./skills/unslop/SKILL.md) | you're cleaning up writing. removes AI tells. |
| [`/technical-writing`](./skills/technical-writing/SKILL.md) | layered doc standard for docs, RFCs, readmes, PR descriptions, commit messages. |

</details>

### examples

```
bug fix:           /maestro this pr has a subtle bug where the scroll drifts every 750ms even
                   when idle. repro first, then fix and verify.
perf:              /maestro a big list takes a second or two to load even though we virtualize.
                   run a cpu trace and tell me why.
feature:           /maestro build a small feature behind a feature flag. verify it really works.
prototype:         /maestro build two prototypes of the markdown renderer so we can compare.
overnight run:     /maestro i'm going to bed. land the stack even if ci flakes. i want
                   everything merged by morning.
babysit:           /maestro check on pr 123. anything outstanding?
how:               /how do we cancel runs? do we have an n+1 when we look up every run to cancel?
why:               /why is this feature flag not on yet?
architect:         design this instrumentation to be high signal with no false positives. /architect
                   this first.
arena:             /arena take my prompt to the arena verbatim. i want to compare their proposals
                   with yours.
swarm:             /swarm check every package under packages/ against its check.sh. one worker per
                   package. one report.
crossfire:         /crossfire review this pr.
tdd:               /tdd implement
unslop:            can we unslop and tighten the new changes?
follow-ups:        /file-followups that took too long. file what we learned.
wayfinder:         /wayfinder we need to move off the old billing system. i don't know where to start.
correct:           /correct
help:              /maestro-help which skill should i use to review this branch?
```

### from BottegaStack

| skill | use it when |
|---|---|
| `/domain-modeling` | you're naming domain terms or writing `GLOSSARY.md` and ADRs. |
| `/codebase-design` | you're designing a module's interface or deciding where a seam goes. |
| `/review-pr` | you want a PR reviewed as a merge decision. |
| `/improve-architecture` | you want the whole codebase scanned for modules worth deepening. |
| `/data-analysis` | you need a number from logs, CSVs, SQL, or metrics, with the query shown. |
| `/library-reference` | agents keep misusing an internal library, CLI, or API. |
| `/wizard` | a step only you can do (a dashboard, credentials, a cutover) needs a guided script. |
| `/interface-review` | you want the UI problems a diff introduced. |
| `/runbook` | an incident or alert has an unknown cause. |
| `/frontend-design` | you want a distinct visual direction for new UI. |
| `/better-interface` | you want one ranked review of a screen or flow. |
| `/better-accessibility`, `/better-colors`, `/better-layout`, `/better-typography`, `/better-ui`, `/better-writing` | you want one UI domain built or reviewed. agents write the code; you check the rendered result. |

## the `maestro-agent` and Comment Sicko subagents

[`/maestro`](./skills/maestro/SKILL.md) runs in the chat that receives it. that chat owns the playbook, the todo list, and every subagent spawn.

bottega also ships [`subagent_type: "bottega:maestro-agent"`](./agents/maestro-agent.md) as the wrapper for delegates spawned during a run. it reads the slim delegate brief at `skills/maestro/references/delegate.md` before doing any work. substituting `general-purpose` skips that read and drifts. do not spawn `maestro-agent` to run the playbook itself.

bottega also ships [Comment Sicko](./agents/comment-sicko.md), a read-only comment reviewer available as `subagent_type: "bottega:comment-sicko"`. usually invoke it through [`/no-comments`](./skills/no-comments/SKILL.md), not directly.

## principles

twenty-one short skills, one principle each. `maestro` reads their index at task start. the standalone files are there so other skills can reference a principle by name, and so the index can point at the full rule for each.

<details>
<summary>all twenty-one principles</summary>

| principle | group | rule |
|---|---|---|
| [delete-first](./skills/principle-delete-first/SKILL.md) | core | Remove before you build, and ship the smallest change that solves the problem. |
| [shape-before-logic](./skills/principle-shape-before-logic/SKILL.md) | architecture | Choose the data structure that encodes the domain before writing logic. |
| [redesign-from-first-principles](./skills/principle-redesign-from-first-principles/SKILL.md) | core | Redesign as if the requirement had been a foundational assumption from day one, instead of bolting it on. |
| [attack-the-premise](./skills/principle-attack-the-premise/SKILL.md) | core | Apply when two or more fixes that share one premise have failed the same gate. Write the premise down and test it directly before you write another fix that assumes it. |
| [minimize-reader-load](./skills/principle-minimize-reader-load/SKILL.md) | core | Count layers between question and answer, and hidden state in the reader's head; collapse one-caller wrappers and shrink mutable scope. |
| [outcome-oriented-execution](./skills/principle-outcome-oriented-execution/SKILL.md) | core | Apply during planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture; don't preserve smooth intermediate states with throwaway compatibility code. |
| [experience-first](./skills/principle-experience-first/SKILL.md) | core | Choose user delight over implementation convenience; ship fewer polished features over more rough ones. |
| [exhaust-the-design-space](./skills/principle-exhaust-the-design-space/SKILL.md) | core | Build 2-3 competing prototypes and compare side by side before committing. |
| [mechanize-it](./skills/principle-mechanize-it/SKILL.md) | core | Build the tool that does, proves, or enforces the work instead of hand work or more prose. |
| [boundary-discipline](./skills/principle-boundary-discipline/SKILL.md) | architecture | Concentrate guards at system boundaries (CLI, config, network, external APIs); trust internal types and keep business logic in pure functions. |
| [type-system-discipline](./skills/principle-type-system-discipline/SKILL.md) | architecture | Make illegal states unrepresentable, brand semantic primitives, parse external data at boundaries, exhaust variants, derive from authoritative schemas. |
| [make-operations-idempotent](./skills/principle-make-operations-idempotent/SKILL.md) | architecture | Converge to the same end state regardless of partial prior runs. |
| [migrate-callers-then-delete-legacy-apis](./skills/principle-migrate-callers-then-delete-legacy-apis/SKILL.md) | architecture | Migrate callers and delete the old API in the same wave instead of preserving compatibility layers. |
| [separate-before-serializing-shared-state](./skills/principle-separate-before-serializing-shared-state/SKILL.md) | architecture | Eliminate the sharing first; serialize structurally only when one shared writer is a real invariant. |
| [prove-it-works](./skills/principle-prove-it-works/SKILL.md) | verification | Apply after completing a task, before declaring done. Verify against the real artifact (run the feature, read the actual value, inspect the diff), not a proxy, self-report, or 'it compiles.'. |
| [fix-root-causes](./skills/principle-fix-root-causes/SKILL.md) | verification | Trace each symptom back to the first place the system went wrong and fix it there. A guard is a fix only when the state it handles is legitimate. |
| [sequence-verifiable-units](./skills/principle-sequence-verifiable-units/SKILL.md) | verification | Apply to multi-step work (sweeps, migrations, runs of similar edits) and to how you stack commits and PRs. Break work into small units that each end in a verifiable state, check each before the next, and order delivery so the sequence proves itself to a reviewer. |
| [test-behavior-not-implementation](./skills/principle-test-behavior-not-implementation/SKILL.md) | verification | Apply when you write, change, or keep a test. Assert what the code's users can observe, so the test fails when that behavior breaks and keeps passing when only the internals change. |
| [explain-the-number](./skills/principle-explain-the-number/SKILL.md) | verification | Apply before you trust, report, or act on a number you measured: a speedup, a regression, a throughput, a latency, or an eval result. Find what limits it, and rule out that it measured something other than the work you think. |
| [guard-the-context-window](./skills/principle-guard-the-context-window/SKILL.md) | delegation | Route bulk to subagents; keep summaries in the main thread, not raw payloads. |
| [never-block-on-the-human](./skills/principle-never-block-on-the-human/SKILL.md) | delegation | Proceed, present the result, let the human course-correct after the fact; reserve confirmation for irreversible actions. |

</details>

## not shipped here

bottega does not drive or screenshot a UI. where a change needs a visual check, the agent says what to look at and you check it; paste screenshots back if you want it to read them. pr watching uses `gh`, not a bundled watcher, so stack and queue handling and NDJSON output from the original are lost. there are no hooks and no planning skill beyond [`wayfinder`](./skills/wayfinder/SKILL.md) and the multi-phase plan playbook.

## make it yours

`maestro` is one person's style. you may not want exactly that.

models are configurable too. type [`/setup-maestro`](./skills/setup-maestro/SKILL.md). `/maestro` and the skills that spawn subagents read `~/.claude/rules/bottega-models.md` and falls back to the role defaults when a line is absent, so you override only what you want. when a default changes, a rule written before the change still pins the old default. delete those role lines, or the file, then run `/setup-maestro` again.

## license

MIT. original pstack by Lauren Tan (poteto). see [LICENSE](./LICENSE).

## credits

- the `better-*` skills and `interface-review` carry an MIT license from Jakub Krehel (see each skill's `LICENSE`).
- `codebase-design`, `domain-modeling`, and `wizard` carry an MIT license from Matt Pocock (see each skill's `LICENSE`).
- `frontend-design` is Anthropic's skill from [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design), kept verbatim under the Apache License 2.0 (see [its LICENSE.txt](./skills/frontend-design/LICENSE.txt)).
