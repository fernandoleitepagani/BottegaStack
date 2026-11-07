---
name: diagnosis
description: Turn failed PaganiStack checks or review findings into a precise fix brief. Use when a review returns CHANGES or a deterministic check fails, before spawning a fresh builder.
---

# PaganiStack Diagnosis

A failed review or check is not a request to "try again". It is a diagnosis
problem. Find the cause, explain it precisely, then hand a fresh builder a brief
it can act on without guessing.

## Base skill

Load `diagnosing-bugs` for the full loop: build a red-capable feedback loop,
reproduce, minimise, rank hypotheses, instrument, fix, regression test, cleanup.
This skill adds the PaganiStack fix-brief contract and the max-two-rounds rule.

## Reproduce

1. Read the failing check log or the review file.
2. Reproduce the failure locally. A fix without a reproduction is a guess.
3. If you cannot reproduce it, say what you tried and what is missing. Ask the
   user or the reviewer for the missing evidence.

## Minimise

- Reduce the failure to the smallest input, route, component, or command that
  still shows it.
- Identify the file and line where the behaviour diverges from the spec.
- Check whether the same cause appears in more than one finding. Group them.

## Hypothesise

Write down the cause in one sentence. If you have two plausible causes, test the
cheaper one first. Do not change code until the cause is stated.

## Write `fix.md`

For every `CHANGES` finding or failed check:

```markdown
# Fix round <N>

## Finding <ID> — [<reviewer or check>] <severity>

- **What is wrong:** the observed behaviour.
- **Why it matters:** the spec criterion, standard, or security impact.
- **Where:** `path:line` or the route/component.
- **How to fix:** the specific change. Name the function, pattern, or approach.
- **How to verify:** the command, page, or test that proves the fix.
- **Evidence:** the log line, screenshot, or diff hunk.
```

Rules:

- Be concise but precise. No vague "improve this" or "make it cleaner".
- One finding per section. Do not merge unrelated findings.
- If a finding is ambiguous, say what information is missing instead of
  inventing a fix.
- If the reviewer is wrong, say why with evidence and mark it `REBUTTAL`.

## Hand off

- Spawn a **fresh** builder for the affected ticket. Do not resume the failed
  builder.
- Give it `fix.md`, the ticket, and the branch.
- After the fix, re-run the deterministic checks.
- Re-run only the reviewers whose verdict was `CHANGES` and any reviewer whose
  area the fix touched.
- Max two fix rounds. After the second, escalate to the human with the
  outstanding findings.

## Report

```
FINDINGS: <count>
ROUND: <N> of 2
NEXT: <what the master should do>
```

## Gotchas

- Guessing before reproducing the failure.
- A fix without a red-capable feedback loop.
- Fixing a different failure than the one the user reported.
- No regression test at the correct seam.
- Leaving debug instrumentation in the code.
