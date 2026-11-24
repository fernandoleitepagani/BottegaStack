# Verify the result and open a PR

"It compiles" is not evidence. The [Prove It Works principle](../../skills/maestro/references/principles/verification.md) makes the agent check the real artifact before it reports success, and your job is to make "the real artifact" checkable. This page covers stating a finish condition, vetting a measured number, generating a verification skill for your app, opening the PR, and driving it to merged.

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

For a small diff you don't fully trust, ask for [`/crossfire`](../../skills/crossfire/SKILL.md). Its adversaries look for breakage outside the diff and prove the one fact the change is safe because of.

## Create a project verification skill

The CLI and API bullets above hide a real requirement. The agent needs a scripted way to run your app. If your project has one, great. If not, run:

```text
/create-verification-skill
```

[`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md) interviews the repository, not you. It works out what a user touches, how the app launches locally, what can drive it (an existing harness first, otherwise a PTY or plain HTTP), what evidence proves behavior, and whether two instances can run side by side. It asks you only what the code can't answer.

It writes `.claude/skills/verify-<app>/`, agent-facing instructions with exact Launch, Doctor, Drive, Evidence, and Cleanup sections, a Helpers section for any script it ships, plus a feature map under `features/` that indexes what the app does and what result proves each feature works. The skill ships a [worked feature-map example](../../skills/create-verification-skill/references/feature-map-example/) with a README index and one file per feature using the four required H2s. Before handing it over, the generator proves the skill once end to end: launch, doctor check, drive one feature, capture evidence, clean up, then confirm the evidence survived the cleanup. If that proof fails, don't use the output.

From then on, "verify it with the project's skill" is a step any agent can execute, in this repo, with no setup conversation. Name it in the prompt when you want the proof in a specific form:

```text
/maestro build the bulk-archive action. use /verify-<app> to verify your changes and show me the command output as proof. tell me what to look at in the UI.
```

```text
/maestro repro this with /verify-<app>. if it repros on main, fix it and show me the output as proof.
```

Once the verify skill works, a [`/parallel`](../../skills/parallel/SKILL.md) can split a full pass by feature-map entry and aggregate the results. A swarm of verifiers also confirms a perf win over a big enough sample, or fuzzes the app for regressions before a PR ships.

Treat the verification skill as infrastructure, not a one-off. Commit it, so every person and every agent on the team drives the app the same way. Then [mechanize it](../../skills/maestro/references/principles/core.md). When agents keep writing throwaway scripts to click through the app, ask for a small control CLI that the skill calls instead. Agents spend fewer tokens, and every run becomes repeatable. A CLI that agents use well has these traits:

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

[`/maintain-verification-skill`](../../skills/maintain-verification-skill/SKILL.md) audits the generated skill: one read-only source reader per feature in parallel (haiku workers), then one live pass that drives every mapped feature. It ends in exactly one of three outcomes. `clean` means full coverage and nothing to ship. `changed` means one PR of proven corrections, confined to the verification skill's own directory. `blocked` names the blocker. It never edits product code. If the live pass catches a product regression, it reports the regression instead of hiding it with a doc edit.

## Open the PR

```text
/maestro open the pr. small ordered commits, evidence in the description.
```

The [`pr` skill](../../skills/pr/SKILL.md) works from a worktree, rebases the work into small ordered commits, cleans the diff, unslops the prose, and returns the PR link. Five narrow PRs beat one fat one, and stacked follow-ups beat a growing branch.

## Drive the PR to merge-ready with `/pr` babysit

An open PR starts collecting blockers immediately. Checks fail, reviewers comment, trunk moves. Hand that churn to the [`pr` skill's babysit mode](../../skills/pr/SKILL.md):

```text
/maestro babysit this pr. get it green.
```

`/pr` babysit watches the PR with `gh` (`gh pr checks`, `gh pr view`, and the PR comments API) polled under `/loop`, and takes blockers in order: conflicts, then review threads, then CI. Every known fix batches into one push, so the checks restart once instead of after every fix. The comment triage is skeptical, because humans and bots file real catches and noise in the same list. A real finding gets a fix, and noise gets dismissed with the disproof posted on the thread. When all you want is status, ask smaller and Babysit answers without starting the loop:

```text
/maestro check on pr 123. anything outstanding?
```

`/pr` babysit stops at merge-ready. It never merges, even with everything green, because merging is a different decision.

## Land the stack with `/pr` land

Green is not the same as safe. When you're ready to land, say so:

```text
/maestro land the stack.
```

The [`pr` skill's land mode](../../skills/pr/SKILL.md) verifies each PR independently before it arms anything. One fresh agent per PR proves the behavior live, and the agent that judges a change is never the one that wrote it. Then Shipping lands only the contiguous verified run from the bottom, one PR at a time through GitHub with `gh`, and reports the first PR that breaks the chain. A verified PR sitting above an unverified one waits, because merging it would pull the gap in underneath.

Next: [Run work while you sleep](./07-overnight.md).
