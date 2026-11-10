---
name: why
description: Explain why a change or decision exists. Use when asked "why is this like this", why a line, feature, or decision changed, or before reverting or rewriting code; answer from git history, docs/adr, and job folders, and never invent history.
---

# Why it exists

Find the recorded reason. Read-only; never invent history.

## Sources, in order

1. `git blame -L <start>,<end> <file>` and `git log -p -- <file>` for the commit
   that introduced or changed the line.
2. `docs/adr/*.md` for accepted decisions.
3. `.agents/plans/<id>/` (`SPEC.md`, `job.md`, `build/`, `decision.md`, reviews) for
   intent and trade-offs.
4. The commit message, linked issue or PR, and tests that pin the behavior.

## Steps

1. Locate the line, symbol, or behavior and its blame commit.
2. Read the commit and message; follow the job or ADR it references.
3. Answer first: one or two sentences with the reason, then the evidence.
4. Cite each claim as `path:line`, a commit SHA, or a job/ADR file.
5. Label each claim measured (read in a file or commit), inferred (deduced from
   code), or guessed (no source). Keep guesses rare and named.

## Gotchas

- Inventing a plausible reason. If no commit, ADR, or job records it, say "no
  recorded reason" and label any explanation inferred.
- Blaming a line without reading the commit; a reformat hides the real change.
  Use `git log -S <string>` or `git blame -w -C` to skip whitespace and moves.
- Stopping at the code when `docs/adr` or the job folder states the trade-off.
- Answering with a history dump. Short answer first, then evidence.
