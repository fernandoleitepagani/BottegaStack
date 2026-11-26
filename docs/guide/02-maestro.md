# Route work through `/maestro`

`/maestro` is the front door. Type it with your goal and how you'll know it's done, and it sends the prompt to the right step. You can also skip it and call `/plan`, `/tickets` or `/implement` yourself.

![A dispatcher pulls a switch lever to route rail handcars toward lit gates under a /maestro departure board.](./images/router.jpg)

## Where each prompt goes

`/maestro` picks the route from your words, using the routing table in [`skills/maestro/SKILL.md`](../../skills/maestro/SKILL.md#route): big or open work goes to `/plan` then `/tickets`, a clear change to `/implement` (or the small-fix playbook for a one-file fix), a question to read-only exploration, work while you're away to `/autopilot`, and a docs-only edit to the light route. Every skill it can reach is in the README's skill table.

The first reply restates your goal, names the risk (`normal`, or `high` for auth, money, data, concurrency, public APIs, or anything hard to undo), and names the route.

## Write prompts it can act on

- **The goal**, in your words: "the export writes duplicate rows on retry".
- **The done check**: "the retry test passes and the export has no duplicates".
- **What you already know**, without leading: "started after last week's queue change".
- **Constraints**: "repro first", "don't change code yet", "keep the public API".

Follow-ups can be short: "continue", "do ticket 3", "new task: ...".

## What every run shares

- **Subagents do the bulk.** The orchestrator decides, writes briefs, reviews diffs, and runs the gate. Explorers read, implementers write, reviewers review.
- **Context is budgeted.** An orchestrator session stays under 300k tokens (±10%). Near the limit it writes a handoff, and you `/clear` and resume.
- **The final gate.** Every change ends in APPROVE or ESCALATE, decided by `gate-check.sh` from logged proofs, not by the agent's confidence.
- **Autonomy.** Reversible work goes ahead without asking. Force-pushes to branches the run didn't create, deploys, data deletion and customer messages always pause.

Next: [Plan and split into tickets](./03-plan-and-tickets.md).
