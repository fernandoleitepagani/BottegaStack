# Delegation principles

Read the section for a principle before applying it. Name each principle you applied in your report.

## Guard the Context Window

**Scope.** This principle owns how to keep bulk out of the thread. Maestro's **Token rules** only add the handoff threshold and session hygiene.

**Why:** Context overflow degrades reasoning quality, creates compression artifacts, and halts progress.

**Pattern:**
- **Route bulk to files and subagents.** Send large outputs to a file and read the tail. Give wide reads to a subagent and keep its summary, not the raw payload.
- **Size phases and cap scope.** Limit files per phase and set turn budgets.
- **Avoid repeated reads.** Read a file once, note what you need, and move on.
- **Count what the mechanism costs.** A fan-out or loop spends context on every spawn and every report, so budget for that before you start.

## Never Block on the Human

**Scope.** This principle is the autonomy rule for reversible work. Maestro's **Autonomy** section adds only the always-pause list for irreversible actions.

The human supervises asynchronously. Agents must stay unblocked. Make reasonable decisions, proceed, and let the human course-correct after the fact. Since code changes are reversible and reviewable, a wrong decision usually costs less than blocking.

- Proceed, then present. Do the work, show the result. Don't ask "should I do X?" Do X, explain why.
- Make the system self-healing. When you notice a problem, log it and fix it in the next round.
- Irreversible actions (force-push, delete production data, send external messages) still require confirmation.
- Reversible actions (write code, edit notes, split tasks) should proceed without blocking.
- Product direction comes from the human. Execution should not block.
