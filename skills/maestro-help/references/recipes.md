# Prompts worth copying

Swap in the real paths, skills, and done checks. Informal wording works.

## Understand

- `/maestro read <thread>. restate the underlying issue in your own words, in plain english.`
- `/maestro investigate why <symptom>. give me what we know, what data you used, and your best hypotheses. don't change any code yet.`
- `use /how to understand <subsystem>. then use /why to find out why it broke recently.`
- `/recall my work on <topic> from last week, then read <issue>.`
- `/teach me why you implemented it this way and not <other way>. what did you trade off?`
- `/maestro take over this branch. read the decision log, find what's done, and continue. don't redo finished work.`

## Build

- Bug: `/maestro <symptom>. repro first, then fix and verify.`
- Bug in an app: `/maestro repro this with /verify-<app>. if it repros on main, fix it and show me the command output as proof.`
- Bug with a cheap test: `/maestro repro <bug> first. if there's a cheap test path, /tdd it. then fix and rerun.`
- Feature: `/maestro add <behavior>. <current output> stays byte-identical. verify both.`
- Refactor: `/maestro move <code> into one module, zero behavior change. record the current output first and prove it's unchanged after.`
- Perf: `/maestro <operation> takes <time> on <fixture>. trace it, fix the measured cause, show me before and after.`

## Design and plan

- `/maestro prototype a few options for <feature>. describe each option's tradeoffs so I can compare.`
- `/maestro we need <feature>. /architect it first, and answer open questions with prototypes. let me review before proceeding.`
- `/maestro write a tutorial for how i would use <new package> first. then /teach me why it beats the current one.`
- `ask /arena for a second opinion on this thread and our approach.`
- `/maestro turn this design into a plan. small verifiable PRs, each with its own verification steps.`
- `/maestro plan the migration of <library> to <target>. small verifiable PRs. the result must match the original exactly, bugs included.`

## Review and ship

- `/crossfire the whole branch, but skeptically. don't change anything yet. no nitpicks unless it's a real bug or regression.` Read the Dropped list too.
- `/swarm check every package under <dir> against its check script. one worker per package. one report.`
- `/maestro open the pr. small ordered commits, evidence in the description.`
- `/maestro babysit this pr. get it green.` For status only: `/maestro check on pr <number>. anything outstanding?`
- `/maestro land the stack.`

## Away and back

- `/maestro im going to bed. <goal> in a fresh worktree off <base>. done means <checks>. keep a decision log. don't ask me before committing. /loop until done. if you're truly stuck after a few hours, stop and write up why.`
- `/show-me-your-work catch me up on what you did last night.` Read its Attention section first.
- `/ketchup` catches you up on this chat since your last message and lists every call that waits on you.
- `/maestro full autopilot on this queue. each item is independent.`
- `/maestro autopilot these changes, but don't merge. i'll land them.`
