# The bottega guide

bottega works best when you stop micromanaging the agent. You say what you want and how you'll know it's done. The agent grills you until the plan is clear, splits it into tickets that each fit one session, builds each ticket with subagents, and shows you the evidence.

Here's what you'll learn:

1. [Set up bottega](./01-setup.md). Install the plugin and pick your models.
2. [Route work through `/maestro`](./02-maestro.md). One front door that sends each prompt to the right step.
3. [Plan and split into tickets](./03-plan-and-tickets.md). `/plan` grills you into a spec, then `/tickets` turns it into session-sized tickets with roles, waves and models.
4. [Implement a ticket](./04-implement.md). `/implement` explores, shapes, delegates, reviews, and ends at the final gate.
5. [Verify and ship](./05-verify-and-ship.md). Prove behavior with real commands, then open a focused PR and drive it to merged.
6. [Run work while you sleep](./06-overnight.md). An overnight contract, a decision log you can audit, and a ticket plan run as a queue.
7. [Steer with principle names](./07-principles.md). The 17 names that redirect an agent mid-task.
8. [Make it yours](./08-make-it-yours.md). `/correct` for repeated mistakes, `/unslop`, and testing a skill change.
9. [Recipes and pitfalls](./09-recipes-and-pitfalls.md). Prompts to copy and mistakes to skip.

Read the pages in order the first time. After that, each page stands alone. `skills/maestro/SKILLS-INDEX.md` lists every skill in one line.

## If you only remember one thing

Give the agent a goal and a way to check it, in your own words:

```text
/maestro the export writes duplicate rows when a retry lands mid-run. repro first, then fix and verify.
```

That fits one session, so `/maestro` sends it straight to `/implement`. A bigger prompt ("add team workspaces") goes to `/plan` first, and you answer questions until the plan is yours.

Next: [Set up bottega](./01-setup.md).
