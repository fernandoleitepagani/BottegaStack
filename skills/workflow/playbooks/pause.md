# Pause and Resume
Use when work must stop mid-run and continue later. The note lives in `PLAN.md`, local only.
## Pause
1. **Write the note.** Run `maestro seed PLAN.md` (it keeps an existing file), then append a `## Paused: <slug>` section at the end of `PLAN.md`. Keep it local only; never pushed or committed unless the user asks.
2. **Record the state.** Include the branch (`<branch>`), the last step done, the next step to run, and every open question. State the risk and playbook in flight. Never copy secrets or tokens into the note.
3. **Copy the current task text.** Paste the task verbatim, not a paraphrase. The note must stand alone without the conversation.
4. **Confirm and stop.** Show the note, stop the builders and loop watchers, and ask with `AskUserQuestion` whether anything is left running.
## Resume
5. **Read the note.** Read `## Paused: <slug>` in `PLAN.md`; if it is missing, ask for the branch and task text instead of guessing.
6. **Rebuild from evidence.** Check out `<branch>`, run `git log --oneline <base>..HEAD` and `git status`, and compare them with the recorded last step. Treat a mismatch as ambiguity.
7. **Rebuild the todo list.** Recreate the playbook's steps as todos, mark finished steps completed, and mark the recorded next step `in_progress`.
8. **Continue or ask.** Resume at the next step on the recorded branch. Stop and ask with `AskUserQuestion` when the note, the log, and the branch disagree or an open question is unresolved.
## Reply
`Done: <paused at step / resumed at step>`
`Evidence: <verbatim PLAN.md note and git log>`
`Claims: measured | inferred | guessed`
## Gotchas
- Paraphrasing the task text instead of copying it.
- Pushing or committing the pause note.
- Resuming on a different branch than the note names.
- Guessing past a mismatch between the note and `git log`.
