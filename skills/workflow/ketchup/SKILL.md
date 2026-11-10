---
name: ketchup
description: Catch the user up on what changed in this chat since their last message, in plain words, and list every decision waiting on them with enough detail to decide from the reply alone. Use when the user says ketchup, catch me up, or returns to a long or unattended run.
---

# Ketchup

Adapted from pstack's `ketchup` (Lauren Tan, MIT). Catch the user up on what changed since their last message and lay out every call waiting on them so they can decide from your reply alone. Notifications and subagent results are not their messages. Assume they remember their last message and nothing after it.

Write the way one person catches up another: plain words, short sentences, no jargon (load `unslop`). Say what changed for the user, not how you did it: "the tests pass", not "CI is green". Leave out hashes, paths, commands, and counts unless the user needs one to act. Name each PR, branch, or agent by a name the user knows.

## Gather (read-only)

Do not change code, start a job, or post anything. Collect your own work since that message, subagent reports, and messages from others. Check the live state of each PR, CI run, build, or run this chat touched (`gh pr view`, `maestro report`, `maestro verify list <run>`, `maestro log <run>`). Check each number you show against its source and say so when you correct one.

An action item is a call only the user can take: a product choice, an approval, an irreversible action, or access you lack. Include any still waiting, even one raised before their last message. Work you can do yourself is not an action item. Never invent a call to fill the reply.

## Write the reply

Spend words on the calls, not the story.

1. One sentence that names what waits on the user, or says nothing does. If nothing happened and nothing waits, say so and stop.
2. What happened, under 100 words: one short bullet per thing the user asked for, saying whether it is done, running, failed, or not checked. Never mark done what still waits on the user.
3. The action items, each with: the call, your pick, what it changes for users, the evidence behind your pick, and its risk (say "low risk" when it is). Give the PR number or link. For several items sharing one call, state the call and pick once, then one bullet per item, riskiest first. For a choice between options, give every option with what it gets and what it costs.
4. One line naming any work left that you can do yourself.

Never cut items to hit a word count; the reply grows with the number of items.

## Gotchas

- Making up an action item. Only the user's calls count.
- Reporting a status you did not re-check.
- A reply that needs the transcript to make sense.
