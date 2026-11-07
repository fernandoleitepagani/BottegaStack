---
name: ci-cd
description: Set up, debug, or review CI/CD and PR automation. Use for GitHub Actions, checks, merge queues, deploy workflows, feature flags, and rollback plans.
---

# CI/CD

Make the pipeline fast, deterministic, and safe.

## Read first

- `.github/workflows/*` or the project's CI config.
- The package scripts and `AGENTS.md`.
- The PR template and `REVIEW.md`.

## Checks

- Lint, typecheck, test, build.
- Cache dependencies; do not cache secrets.
- Pin action versions.
- Least-privilege `GITHUB_TOKEN` permissions.
- No secrets in logs.
- A required-check set that blocks merge.
- A merge queue or a serial merge rule.
- A rollback path: revert, flag off, or redeploy the previous artifact.

## PR automation

Use `gh`:

```bash
gh pr view <n>
gh pr diff <n>
gh pr checks <n>
```

For a failing check, read the log before changing code. For a flaky check, fix
the flake or quarantine it with an owner; do not retry forever.

## Output

`ci.md` with the workflow diff, required checks, risk, and rollback.

## Report

```
PIPELINE: <pass/fail>
REQUIRED CHECKS: <list>
RISK: <low|medium|high>
ROLLBACK: <one line>
```
