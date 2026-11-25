---
name: triage
description: Cluster multiple bug reports, issues, or PRs by shared root cause before planning or coding. Verifies which ones reproduce on main, flags non-repros, and routes each cluster to /plan, /tickets, or /implement. Read-only.
disable-model-invocation: true
---

# Triage

Use when working with **more than one** bug report, GitHub issue, PR, or `.bottega/followups.md` backlog item. Collapses N disparate items into shared root causes so you don't spawn duplicate fixes or collide on the same files.

Do not edit any product files.

## Procedure

1. **Collect the batch.** Gather the raw items from the prompt, `gh issue list`, `gh pr list`, or `.bottega/followups.md`. Number them clearly.
2. **Investigate in parallel (read-only `explorer` subagents).** Fan out read-only `explorer` subagents (following `../maestro/references/subagents.md` fan-out rules) to check each item against the current codebase on `main`:
   - Does it still reproduce or apply on `main`?
   - What is the likely root cause and file/symbol surface?
3. **Cluster by root cause.** Group items that share an underlying cause or write surface into 1–3 clusters instead of treating them as N isolated tasks.
4. **Output the triage table & next routes:**
   - **Clusters:** For each cluster, list the grouped item IDs, the shared root cause (with `file:line` citations), and the recommended next route:
     - Needs design decisions or >1 session → ready-to-run `/plan` prompt.
     - Clear multi-slice fix → `/tickets` handoff.
     - Single-session clear fix → direct `/implement` prompt.
   - **Non-repros / stale:** Items that no longer reproduce or are already fixed, with evidence so the user can close them.
   - **Dependencies:** Note any clusters that touch the same files and must be serialized.

Wait for the user to pick which cluster to run first (unless running unattended). Run the reply through `../unslop/SKILL.md`.
