---
name: recall
description: Rebuild compressed context from recent session transcripts and .bottega/ state when starting a fresh session on an ongoing or related problem. Read-only.
disable-model-invocation: true
---

# Recall

Use at the start of a fresh session (after `/clear` or on a new day) when picking up an ongoing thread, debugging a recurring subsystem, or checking what previous sessions already tried.

Do not edit any files.

## Procedure

1. **Locate sources (via a read-only `explorer` subagent).** Delegate the search so raw transcripts never bloat the orchestrator's context window:
   - Check repo-local `.bottega/` artifacts first (`handoff.md`, `followups.md`, `plans/*/spec.md`, `plans/*/PLAN.md`, `proofs.tsv`).
   - Locate recent session transcripts for this repo in the active harness's transcript store (e.g., `~/.claude/projects/`, `~/.gemini/antigravity-cli/brain/`, or harness-local logs), filtered to the requested topic, subsystem, or recent timeframe.
   - If no topic was given, summarize the most recent 2–3 sessions for this repo.
2. **Extract only load-bearing context:**
   - **Goal & current state:** What was being built or debugged and where it stopped.
   - **What was tried & ruled out:** Approaches, hypotheses, or fixes that failed (so this session does not repeat them).
   - **Settled decisions:** Constraints or user choices already agreed upon.
   - **Key files & commands:** Exact paths, symbols, or verification commands that mattered.
   - **Open threads:** Unfinished items or blockers.
3. **Budget the brief.** Return a tight, scannable brief (~500–1,000 tokens max). Cite the source file or session date for every claim; mark anything inferred.

Run the reply through `../unslop/SKILL.md`.
