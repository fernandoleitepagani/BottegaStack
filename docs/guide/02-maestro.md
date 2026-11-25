# Route work through `/maestro`

`/maestro` is the front door. Type it with your goal and how you'll know it's done, and it sends the prompt to the right step. You can also skip it and call `/plan`, `/tickets` or `/implement` yourself.

![A dispatcher pulls a switch lever to route robots on rail handcars toward lit gates, under a /maestro departure board listing BUG FIX, FEATURE, and INVESTIGATION.](./images/router.jpg)

## Where each prompt goes

| You ask for | It goes to |
|---|---|
| Work with open decisions, or more than one session of work | `/plan`, then `/tickets` |
| A ticket, or a small clear change (a bug, a feature slice, a refactor) | `/implement` |
| A question ("how does X work", "why is it like this") or a symptom to diagnose | read-only exploration, no code change |
| A design fork you have to see to decide | a throwaway prototype |
| Work to run while you're away | `/autopilot` |
| Pause now, or resume earlier work | a handoff |
| Clean up old worktrees | the worktree cleanup rules |
| A docs or config edit with no runtime effect | the light route: edit, check, done |

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
