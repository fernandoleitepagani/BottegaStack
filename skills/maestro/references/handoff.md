# Handoff

**You own the seam between sessions. Leave a checkpoint a cold-start agent can resume from, and when resuming, trust the trail instead of redoing it.** Two directions: **pause** (stop cleanly) and **resume** (pick up prior work).

## Pause

Explicit only, plus the handoff threshold in **Context.** of `../SKILL.md` and the context budget in `/implement`, an allowed automatic trigger even under a keep-going grant. On "keep going" or "don't stop", do not pause.

1. Stop at a safe boundary. Finish or back out of the current atomic step. Start nothing new and cancel nested subagents.
2. Take no irreversible action to pause: no new PR, no push.
3. Save uncommitted work without committing. Run `git diff --binary HEAD > .bottega/pause-<timestamp>.patch` and list untracked files with `git ls-files --others --exclude-standard`. Copy untracked files you created under `.bottega/pause-<timestamp>/`. `git stash` only if the user asked.
4. Write `.bottega/handoff.md` (untracked): intent, what you were doing, progress and what is verified, current state, next steps, key files, gotchas, the patch path, and a one-line note if the tree is broken. Point at a decision trail instead of duplicating it.

## Resume

1. **Find the trail.** `.bottega/handoff.md` first when it exists, then the active workspace's transcript at `~/.claude/projects/<slug>/<session>.jsonl` (slug = workspace path with `/` and `.` replaced by `-`; never glob across other projects), or a pushed branch. Parse a long transcript in a subagent and keep only the reduced timeline (**Guard the Context Window**).
2. **Rebuild state** from git: the branch and worktree, what landed (`git log`, `git diff` against the base), open todos, and decisions made. The trail is authoritative input; do not re-derive it.
3. **Name the resume point.** Compare shipped against planned. Do not re-run the prior repro or redo finished work.
4. **Route** the remaining work (`/implement` for a ticket, `/plan` for an open decision): continue, ship a finished recommendation, ratify or override a prior conclusion, or postmortem a failed run.
5. **Verify inherited claims** on the real artifact (**Prove It Works**). A passing self-report is not proof.
6. **Keep credit** when the prior work is someone else's (a teammate's PR or branch, another agent's thread): build on their commits instead of rewriting them, keep their authorship and existing co-author trailers, and credit them in the PR (`final-gate.md`, **Opening a PR**). Don't change their PR in place without the user's yes; a continuation goes on a new branch with their commits imported.

**Reply:** pause: where you are, what is on disk versus in your head, the patch path and whether the tree is clean, and the first action on resume (this is a pause, not a final report). Resume: where the prior agent stopped, what you inherited versus redid, the resume point, and the outcome.
