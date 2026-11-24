---
name: diagnosis
description: Turn failed check output or review findings into a precise fix brief for a fresh maestro-agent. Use when a check fails or a review returns findings, before spawning the fixer. Caps a task at 2 fix rounds.
disable-model-invocation: true
---

# Diagnosis

A failed check or review is a diagnosis problem, not a request to "try again". Find the cause, then hand a fresh `bottega:maestro-agent` a brief it can act on without guessing.

Input: the failed check output or the review findings, plus the task brief. Output: one fix brief per finding. The orchestrator spawns this as one `maestro-agent` (role: reviewer, diagnosis) with the `model` and `effort` from that role's line, and passes this file's path in the brief. It may add temporary instrumentation in its own worktree (`isolation: "worktree"`). It writes the brief, and a fresh delegate writes the fix. Redact secrets before quoting commands or logs.

## Loop

1. **Build a red-capable loop.** It must drive the real failure path and assert the reported symptom. Prefer a failing test, then a CLI or curl script, a minimal harness, a trace replay, bisection, or a differential run.
2. **Tighten it.** Make it fast and deterministic.
3. **Reproduce and minimise.** Confirm the reported failure, not a nearby one. Cut inputs, callers, config, and steps until each remaining one is load-bearing. Group findings that share a cause.
4. **Hypothesise.** State the cause in one sentence. With several candidates, rank 3 to 5 falsifiable ones and test the cheapest first. Do not change code before the cause is stated.
5. **Instrument.** Change one variable at a time. Use targeted logs with a unique prefix.
6. **Specify the regression test** at the correct seam, written before the fix. If no correct seam exists, say so. That is an architecture finding.
7. **Clean up.** The fixer removes debug instrumentation and reruns the original loop.

If you cannot build a loop, stop and report what you tried and what is missing. Do not hypothesise without one.

## Fix brief

One section per finding, never merged:

```markdown
# Fix round <N> of 2

Goal: <the user's goal, restated>

## Finding <ID> [<check or reviewer>] <severity>
- **What is wrong:** observed behavior.
- **Why it matters:** the acceptance condition, standard, or security impact.
- **Where:** `path:line` or command.
- **Cause:** the one-sentence hypothesis and the evidence for it.
- **How to fix:** the specific change. Name the function or approach.
- **How to verify:** the command that proves it, with expected output.
- **Evidence:** the log line or diff hunk.
```

Be precise. No "improve this". If a finding is ambiguous, say what is missing. If the reviewer is wrong, say why with evidence and mark it `REBUTTAL`.

## Rounds

- Spawn a **fresh** `maestro-agent` for the fix, with the original brief, this fix brief, the prior report, and the branch. Do not resume the failed agent.
- After the fix, rerun the failed checks and only the reviewers whose findings the fix touched.
- **At most 2 fix rounds per task.** A third failure is not a third round. Report ESCALATE to the maestro **Final gate** with the outstanding findings.
- **Stall exit.** Count failing checks and blocking findings. Round 1 compares to the initial failure, later rounds to the previous round. Two consecutive comparisons with no decrease means ESCALATE early.

## Test protection

Never fix a failing test by editing, deleting, skipping, or weakening it. Fix the code, or escalate with the evidence.

## Report

```
FINDINGS: <count>
ROUND: <N> of 2
NEXT: fix brief written | ESCALATE
```

## Gotchas

- Guessing before reproducing.
- Fixing a different failure than the reported one.
- No regression test at the correct seam.
- Leaving debug code behind.
