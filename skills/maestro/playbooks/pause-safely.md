### Pause safely

**You own a clean stop. Leave a checkpoint a cold-start agent can resume from.** This is explicit only, plus the Token-rules handoff threshold in the maestro `SKILL.md`, which is an allowed automatic trigger. On "keep going", "going to bed, keep going", or "don't stop", do not pause, except that a keep-going grant still hands off at the threshold.

1. Stop at a safe boundary. Finish the current atomic step or back out of it. Start nothing new, and cancel any nested subagents.
2. Take no irreversible action to pause. No PR and no push unless you already had one out.
3. Make the work durable. Do not commit. Save uncommitted work with `git diff > .bottega/pause-<timestamp>.patch`, and `git stash` only if the user asked. Note the patch path in the handoff. If the tree is broken, say so in the note in one line.
4. Write the resume note off-context. Capture intent, what you were doing, progress and what's verified, current state, next steps, key files, and gotchas. Write it to `.bottega/handoff.md` (untracked, never committed). The resume step reads it first (see the Session pickup playbook). If a show-me-your-work trail exists, point at it instead of duplicating it.

**Reply:** where you are in the loop, what's on disk versus still in your head (paths, no diff dumps), the patch you saved and whether the tree is clean, and the first action on resume. This is a pause, not a final report.
