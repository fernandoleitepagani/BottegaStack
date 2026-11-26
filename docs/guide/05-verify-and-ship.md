# Verify the result and open a PR

"It compiles" is not evidence. The [Prove It Works principle](../../skills/maestro/principles.md#prove-it-works) makes the agent check the real artifact before it reports success, and your job is to make "the real artifact" checkable. This page covers stating a finish condition, running checks and the gate in one call (`bottega verify`), generating a verification skill for your app, and shipping via [`/ship`](../../skills/ship/SKILL.md) (either `/ship full` to watch CI and merge, or `/ship stop` to open a Draft PR).

Verification is the slowest step in most agent work, because it's the step that usually waits on a human. Make the agent able to do it, and you stop being the bottleneck. Skip it, and running more agents only gets you more unchecked work to review.

![A prototype plane flies a real test course while she times it with a stopwatch and robots film and checklist the run; the terminal reads verify: pass, evidence: captured.](./images/verification.jpg)

## State the finish condition up front

Put what done means in the first prompt, in whatever words fit:

```text
/maestro add json output to this command. text output stays byte-identical, the json parses, both run against the sample project. show me the evidence.
```

Now the agent has three checks it can run, not a mood to satisfy. When the reply comes back, it should carry the exact commands and outputs. If a check couldn't run, a good reply says "inconclusive". A confident reply without evidence is a warning sign.

Match the check to the change:

- A CLI change runs the real command.
- A UI change is not driven or screenshotted by the agent. It tells you exactly what to look at, and you check it. You can paste screenshots back for it to read.
- A parser or migration replays a saved input.
- A perf change compares before and after profiles.
- A storage change reads back the written value.

Ask for the proof as an artifact you can inspect yourself: the failing test and then the passing one, the command output, the trace, the stored value. If the fix already merged, ask for the same check again on main. An artifact beats a plausible explanation, because you can challenge it without replaying the whole run.

For a small diff you don't fully trust, ask "what could this break?". The agent runs a [blast-radius check](../../skills/blast-radius/SKILL.md): it looks for breakage outside the diff, names the one fact the change is safe because of, and proves it by running real code.

## Create a project verification skill

The CLI and API bullets above hide a real requirement. The agent needs a scripted way to run your app. If your project has one, great. If not, run:

```text
/create-verification-skill
```

[`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md) interviews the repository, not you. It works out what a user touches, how the app launches locally, what can drive it (an existing harness first, otherwise a PTY or plain HTTP), what evidence proves behavior, and whether two instances can run side by side. It asks you only what the code can't answer.

It writes `<project-skills-dir>/verify-<app>/` (`.claude/skills/` on Claude Code), agent-facing instructions with exact Launch, Doctor, Drive, Evidence, and Cleanup sections, a Helpers section for any script it ships, plus a feature map under `features/` that indexes what the app does and what result proves each feature works. The skill ships a [worked feature-map example](../../skills/create-verification-skill/references/feature-map-example/) with a README index and one file per feature using the four required H2s. Before handing it over, the generator proves the skill once end to end: launch, doctor check, drive one feature, capture evidence, clean up, then confirm the evidence survived the cleanup. If that proof fails, don't use the output.

From then on, "verify it with the project's skill" is a step any agent can execute, in this repo, with no setup conversation. Name it in the prompt when you want the proof in a specific form:

```text
/maestro build the bulk-archive action. use /verify-<app> to verify your changes and show me the command output as proof. tell me what to look at in the UI.
```

```text
/maestro repro this with /verify-<app>. if it repros on main, fix it and show me the output as proof.
```

Once the verify skill works, a ticket can give each feature-map entry its own reviewer subagent for a full pass, and the orchestrator merges their results.

Treat the verification skill as infrastructure, not a one-off. Commit it, so every person and every agent on the team drives the app the same way. Then [mechanize it](../../skills/maestro/principles.md#mechanize-it). When agents keep writing throwaway scripts to click through the app, ask for a small control CLI that the skill calls instead. Agents spend fewer tokens, and every run becomes repeatable. A CLI that agents use well has these traits:

- A few composable commands, each doing real work, rather than many thin ones.
- A `--dry-run` option on anything destructive.
- Subcommands that reveal features gradually instead of all at once.
- Error messages that say what to do instead.
- Rich `--help` text.
- Machine-readable output, such as JSON.

While you're there, make the dev setup repeatable too: seeded data, test users, and one command that brings the environment up the same way every time.

## Keep the verification skill honest

Apps change, and feature maps go out of date. Run this regularly, for example once a day from a `/loop` or a scheduled job, so nobody has to remember:

```text
/maintain-verification-skill
```

[`/maintain-verification-skill`](../../skills/maintain-verification-skill/SKILL.md) audits the generated skill: one read-only source reader per feature in parallel (haiku explorers), then one live pass that drives every mapped feature. It ends in exactly one of three outcomes. `clean` means full coverage and nothing to ship. `changed` means one PR of proven corrections, confined to the verification skill's own directory. `blocked` names the blocker. It never edits product code. If the live pass catches a product regression, it reports the regression instead of hiding it with a doc edit.

## Open the PR

```text
/maestro open the pr. small ordered commits, evidence in the description.
```

[`/ship`](../../skills/ship/SKILL.md) owns PR creation (`/ship stop` for a Draft PR, `/ship full` for a Ready PR + CI watching + merge): it works from a feature branch in small ordered Conventional Commits, runs the comments self-check, unslops the description, enforces the final gate and one-way-door checks via `bottega ship`, and returns the PR link. Five narrow PRs beat one fat one, and stacked follow-ups beat a growing branch.

## Watch the PR and land it

```text
/maestro babysit this pr. get it green.
/maestro land the stack.
```

[`/ship`](../../skills/ship/SKILL.md) (`/ship full`) takes blockers in order (conflicts, review threads, then CI), batches every fix into one push, and waits with `gh pr checks --watch` instead of polling. Review comments get a skeptical triage: a real finding gets a fix, and noise gets dismissed with the disproof on the thread. Landing verifies each PR with an agent that didn't write it, then merges bottom-up and reads each PR back to confirm it merged. Green is not the same as safe.

Next: [Run work while you sleep](./06-overnight.md).
