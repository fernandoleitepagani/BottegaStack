# Recipes and pitfalls

Prompts worth copying, then the mistakes everyone makes once. Swap in your own paths and finish conditions. The recipes are deliberately informal. That's how they get typed in practice, and the skills read intent fine.

## Understand an unfamiliar subsystem

```text
/maestro how does this initialization work, and why did it break recently? don't change anything.
```

Mechanics first, history second. Explorers map the code and the git history, and the answer labels what was read versus inferred.

## Restate a noisy report before touching code

```text
/maestro read this thread. restate the underlying issue in your own words, in plain english. don't change any code yet.
```

A misreading shows up in the restatement, where it costs one message to correct. Keep your own theory to yourself until the agent has stated its own.

## Prototype before you pick

```text
/maestro prototype a few options for the settings layout. put them behind a switcher and tell me what to look at in each.
```

You pick from things that run, not from descriptions. The agent answers its own layout and timing questions along the way.

## Plan a big change

```text
/grill add team workspaces. grill me until we agree, then write the spec.
/tickets
```

You answer questions, not write specs. `/tickets` returns one ticket per session with its budget, subagent split, wave, and orchestrator model.

## Run the next ticket

```text
/clear
/model sonnet
/implement .bottega/plans/team-workspaces/tickets/T03-invite-flow.md
```

Use the model the ticket names. Tickets in the same wave can run at once in separate sessions and worktrees.

## Review a branch skeptically

```text
/maestro crossfire the whole branch, skeptically. don't change anything yet. no nitpicks unless it's an actual bug or regression in behavior.
```

The qualifiers do real work. "don't change anything yet" keeps it read-only, and the nitpick rule pre-filters the noise so the verified findings are worth your time.

## Fix a bug through a failing test

```text
/maestro repro the duplicate write first. if there's a cheap test path, write the failing test first. then fix and rerun.
```

"if there's a cheap test path" matters. Forcing a test through brittle mocks proves less than running the real command, and `/implement` is allowed to say so.

## Repro and fix a report with proof

```text
/maestro repro this with /verify-<app>. if it repros on main, fix it and show me the output as proof.
```

"if it repros on main" lets the run stop early when the bug is already gone. The output lets you check the fix before you read the diff.


## Stop correcting the same mistake

```text
/correct agents keep adding new config flags without registering them in the schema
```

The fix lands in the repo as architecture, a type, a lint, or a test, so the next agent can't make the mistake.

## Keep a run honest while you're away

```text
im going to bed, keep going autonomously until every fixture passes. do not stop. keep a decision log i can audit in the morning.
```

The full contract is on the [overnight page](./06-overnight.md). The short form works once the task and finish condition are already in the conversation.

## Redirect a drifting run

Steering prompts are one line:

```text
i said the goal is to repro. i did not ask for a fix yet.
```

```text
apply prove it works. show me the real output, not the build log.
```

```text
/unslop that, no emdashes
```

You rarely need more words. You need the right name, and [the principles page](./07-principles.md) is the vocabulary.

## Catch up on a chat you left running

```text
/maestro catch me up
```

Catch-up tells you in plain words what changed since your last message, then lists each call waiting on you with its pick, evidence, and risk. It changes nothing while it reports.

## The pitfalls

- **Enumerating steps in the prompt.** `/implement` already sequences explore, shape, build, review and gate. State the goal and constraints. Name a step only to override a default.
- **Skipping the plan for big work.** A multi-session change built in one session runs out of context halfway. Run `/grill` and `/tickets` first.
- **Answering the grilling passively.** "Sure, whatever you think" puts the agent's guesses in your spec. Push back, and say "I don't know" when you don't.
- **Clearing between `/grill` and `/tickets`.** The grilling is the context the tickets are cut from. Run them in one session.
- **Ignoring the ticket's model.** A sonnet-level orchestrator on an opus-level ticket misses design calls; the reverse wastes money.
- **A vague finish condition.** "make it better" gives `/loop` nothing to check. Give a command or artifact that can pass or fail.
- **Leading with your theory of the cause.** The agent searches wherever you pointed. Ask it to restate the problem first, then share your hunch.
- **Parallel tickets in one worktree.** They overwrite each other. One session and one worktree per ticket.
- **Looping before you trust the loop.** A loop that can't verify its own work only makes unchecked work faster. Get the verification skill working first.
- **Correcting the same mistake by hand.** A correction in chat helps one run. `/correct` fixes the repo so no later run repeats it.
- **Accepting every review comment.** Bots and humans both file real catches and noise. The review keeps only findings a rerun proves and lists what it dropped.
- **Reporting success off a green build.** A build proves it compiles. Ask for the real command, flow, stored value, or profile.

That's the guide. If you skipped ahead, go back to [setup](./01-setup.md) and run one real task. The habits stick from use, not from reading.

Back to the [guide index](./README.md).
