### Session pickup

**You own the resume point. Read the prior trail, don't redo it.** Adapted from pstack's `poteto-mode` session-pickup playbook (MIT, see LICENSE).

1. Run `/recall` (`../../recall/SKILL.md`). It reads `.bottega/handoff.md` first, then the patch it names, then this workspace's transcripts, in a subagent, and returns a short brief. Never read transcripts from other projects.
2. Rebuild state from git: the branch and worktree, what already landed (`git log`, `git diff` against the base), open todos, decisions made. The trail is authoritative; don't re-derive it. Apply a saved `.bottega/pause-*.patch` when the work continues from it.
3. Name the resume point: compare what shipped with what was planned. Don't re-run the prior repro or redo finished work.
4. Route what remains to the matching playbook or skill (router **Route**), with its verdict: continue, ship a finished recommendation, ratify or override a prior conclusion, or postmortem a failed run. The routed playbook owns the rest, including opening a new run before any edit.
5. Verify inherited claims on the real artifact (**Prove It Works**). A passing prior self-report is not proof.
6. Keep credit when the prior work is someone else's: build on their commits, keep authorship and co-author trailers, and change their PR in place only with the user's yes.

**Reply:** where the prior agent stopped, what you inherited versus redid (ideally nothing redone), the resume point, and the outcome.
