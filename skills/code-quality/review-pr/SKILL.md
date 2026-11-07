---
name: review-pr
description: Review a pull request as a merge decision: intent, diff, CI, risk, tests, security, and revert plan. Use for PR-level review, not a single diff.
---

# Review PR

Review the PR as a change the team must live with, not just a diff.

## Gather

```bash
gh pr view <n>
gh pr diff <n>
gh pr checks <n>
```

Read the title, body, linked issue, review comments, `REVIEW.md`, `AGENTS.md`,
the spec, and the build report. If the PR is not on GitHub, use the local branch
diff.

## Check

- **Intent:** does it solve the stated problem, and only that?
- **Fit:** does it follow the system's patterns and boundaries?
- **Regressions:** what else could break?
- **Tests:** do they test external behavior and the real failure mode?
- **CI:** are the required checks green? If not, why?
- **Risk:** low, medium, or high. Does it touch auth, payments, data, deploy,
  schema, or dependencies?
- **Revert:** is there a clear way to undo it?
- **Security:** input, access, secrets, data exposure.
- **Scope:** anything unrelated or speculative?

## Output

`review-pr.md`:

```markdown
VERDICT: PASS | CHANGES

## Summary
## CI
## Findings
1. file:line — problem — why — suggested fix — evidence
## Risk
## Merge readiness
## For the human
```

Rules:

- A finding without evidence is a note.
- Do not merge. The human decides.
- If CI is red, the verdict is `CHANGES` unless the failure is unrelated and
  documented.
- If the PR is high risk, require two human approvals.

## Report

```
VERDICT: PASS | CHANGES
CI: <green|red|unknown>
RISK: <low|medium|high>
FINDINGS: <count>
```
