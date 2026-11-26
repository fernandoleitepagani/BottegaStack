# Pause

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

Include a "suggested skills" section in the document, naming which skills the next agent should run.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

## In bottega

Adapted from mattpocock/skills `handoff` (MIT, see NOTICE). These rules take precedence where they differ:

- **Where it goes.** Write `.bottega/handoff.md`: `.bottega/` is untracked, survives a reboot, and `/recall` reads it first.
- **Suggested skills** means bottega skills, named as `/maestro`, `/implement <ticket>`, `/plan`, and so on.
- **When.** On the user's request, and at the context thresholds in **Context.** of `../SKILL.md` and `/implement`, even under a keep-going grant. "Keep going" or "don't stop" pauses only at those thresholds.
- **Stop cleanly first.** Finish or back out of the current atomic step, start nothing new, and cancel nested subagents. Take no irreversible action to pause: no new PR, no push.
- **Save uncommitted work without committing.** `git diff --binary HEAD > .bottega/pause-<timestamp>.patch`, list untracked files with `git ls-files --others --exclude-standard`, and copy the ones you created under `.bottega/pause-<timestamp>/`. Name the patch path in the document, and say if the tree is broken. `git stash` only if the user asked.

**Reply:** where you stopped, the document and patch paths, whether the tree is clean, and the first action on resume (`session-pickup.md`). This is a pause, not a final report.
