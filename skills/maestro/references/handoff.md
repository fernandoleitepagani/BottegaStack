# Handoff

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) - not the current workspace.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

## In bottega

Adapted from mattpocock/skills `handoff` (MIT, see NOTICE). These rules take precedence where they differ:

- **Where it goes.** Write `.bottega/handoff.md`, not the OS temp directory: `.bottega/` is untracked, survives a reboot, and `/recall` reads it first.
- **Suggested skills** means bottega skills, named as `/maestro`, `/implement <ticket>`, `/plan`, and so on.
- **When.** On the user's request, and at the context thresholds in **Context.** of `../SKILL.md` and `/implement`, even under a keep-going grant. "Keep going" or "don't stop" pauses only at those thresholds.
- **Stop cleanly first.** Finish or back out of the current atomic step, start nothing new, and cancel nested subagents. Take no irreversible action to pause: no new PR, no push.
- **Save uncommitted work without committing.** `git diff --binary HEAD > .bottega/pause-<timestamp>.patch`, list untracked files with `git ls-files --others --exclude-standard`, and copy the ones you created under `.bottega/pause-<timestamp>/`. Name the patch path in the document, and say if the tree is broken. `git stash` only if the user asked.

### Resume

1. Read `.bottega/handoff.md` first, then the active workspace's transcript at `~/.claude/projects/<slug>/<session>.jsonl` (slug: the workspace path with `/` and `.` replaced by `-`; never glob other projects), or a pushed branch. Reduce a long transcript in a subagent (**Guard the Context Window**).
2. Rebuild state from git (branch, worktree, what landed against the base) and treat the trail as authoritative; don't redo finished work or re-run the prior repro.
3. Route what remains (`/implement` for a ticket, `/plan` for an open decision), and verify inherited claims on the real artifact (**Prove It Works**).
4. Keep credit when the prior work is someone else's: build on their commits, keep authorship and co-author trailers, and change their PR in place only with the user's yes.

**Reply:** pause: where you stopped, the document and patch paths, whether the tree is clean, and the first action on resume. Resume: what you inherited versus redid, the resume point, and the outcome.
