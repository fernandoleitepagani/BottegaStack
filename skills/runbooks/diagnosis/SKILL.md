---
name: diagnosis
description: Turn failed BottegaStack checks or review findings into a precise fix brief. Use when a review returns CHANGES or a deterministic check fails, before spawning a fresh builder.
---

# BottegaStack Diagnosis

A failed review or check is not a request to "try again". It is a diagnosis
problem. Find the cause, explain it precisely, then hand a fresh builder a brief
it can act on without guessing.

## Diagnosis loop

Redact secrets before showing commands or artifacts. Then:

1. **Build a red-capable loop.** The loop must drive the real bug path and assert
   the user's symptom. Prefer a failing test, then a curl/HTTP script, CLI
   invocation, headless browser, captured trace replay, minimal harness, fuzz
   loop, bisection, or differential run. A human-in-the-loop script is the last
   resort.
2. **Tighten it.** Make it faster, sharper, and deterministic. A 2-second
   deterministic loop is the goal; a 30-second flaky loop is barely better than
   none.
3. **Reproduce and minimise.** Confirm the user's failure, not a nearby one.
   Remove inputs, callers, config, and steps until every remaining element is
   load-bearing.
4. **Hypothesise.** Write 3–5 ranked, falsifiable hypotheses. State the
   prediction each one makes. Show the ranking to the user when possible.
5. **Instrument.** Change one variable at a time. Use a debugger or targeted logs
   with a unique prefix; never log everything.
6. **Fix and regression-test.** Add the failing test at the correct seam before
   the fix. If no correct seam exists, say so; that is an architecture finding.
7. **Clean up.** Remove debug instrumentation, delete throwaway prototypes, and
   re-run the original loop.

If you cannot build a loop, stop and say what you tried. Ask for access, a
redacted artifact, or permission to add temporary instrumentation. Do not
hypothesise without a loop.

This skill also owns the BottegaStack fix-brief contract, the max-two-rounds
rule, and the stall exit.

## Reproduce

1. Read the failing check output or the review reply.
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

## Write the fix brief

For every `CHANGES` finding or failed check, write the brief into the builder
prompt or pass it as the revision findings on stdin:

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
- Give it the review findings or the brief in its prompt, the task, and the
  branch.
- After the fix, re-run the deterministic checks.
- Re-run only the reviewers whose verdict was `CHANGES` and any reviewer whose
  area the fix touched.
- Max two fix rounds. After the second, escalate to the human with the
  outstanding findings.

## Test protection

Do not fix a failing test by changing the test. Fix the code, or escalate with
the evidence. An existing test is an evaluator input; editing, deleting,
skipping, or weakening it hides the failure instead of fixing it.

## Stall exit

Track the number of failing checks and blocking findings. Round 1 compares both
counts to the initial failing build. Later rounds compare to the previous round.
Stop after two consecutive comparisons with no decrease and escalate. Do not run
a third identical round.

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
- Running a third identical round when the failing checks and blocking findings
  did not decrease.
- Weakening a test to make it pass instead of fixing the code.
- Leaving debug instrumentation in the code.
