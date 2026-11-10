# Autopilot
Use when the user gives a queue of items to run through one after another. Work serially, one item in flight, and stop at a ready local branch per item.
## Steps
1. **Capture the queue.** Take the list the user gives, verbatim. Run `maestro seed PLAN.md` (it keeps an existing file), then save the queue as a checklist under `## Current work` in `PLAN.md`: `- [ ] <item> — status: todo`. Keep `PLAN.md` local; never push it.
2. **Serialize.** Run exactly one item at a time: no parallel branches, no second builder while one item is open. Never start item N+1 before item N is ready or stopped.
3. **Route each item.** Load `playbooks`; match the item to a playbook and risk. On an ambiguous request, a missing detail, or a `high` risk classification, stop and ask with `AskUserQuestion` before starting.
4. **Run it end to end.** Run the matched playbook under `maestro start "<item>"` on its own branch (ask the user to name each, or have them create it; pass it with `--branch`), copying its steps into the todo list. Do not switch playbooks mid-item without asking.
5. **Stop at a ready local branch.** End each item with the checks and gates green, a local commit, and draft PR text (Done / Evidence / Claims, plus the acceptance mapping). Never push, merge, or open a PR; the human ships each branch.
6. **Stop and ask on trouble.** Stop the queue on any `BLOCKED` report, failing `./scripts/check` or `maestro gate`, `high` risk not already approved, or scope ambiguity. Report the item and ask with `AskUserQuestion`; do not skip ahead.
7. **Update the checklist.** After each item write its outcome back to `PLAN.md`: `- [x] <item> — branch <branch>, <ready|stopped: why>`. Leave unfinished items as `- [ ]` with their status.
8. **Report the table.** Finish with a table: item, branch, playbook, status, checks, and the one-line next step for the human. Include the queue total and how many are ready.
## Reply
`Done: <items ready, items stopped>`
`Evidence: <verbatim checks per branch, PLAN.md diff, git log per branch>`
`Claims: measured | inferred | guessed`
## Gotchas
- Opening a PR or pushing "to finish" an item.
- Running two items at once.
- Continuing past a BLOCKED, a red gate, or `high` risk.
- Forgetting to update the `PLAN.md` checklist.
- Skipping the PR draft text.
