# Reviewer evals

A small, growing set of cases for the review agents. The goal is to measure
recall (real bugs caught) and noise (false positives), not to score style.

## Cases

- `cases/001-off-by-one.md` — known bug, train
- `cases/002-missing-auth-check.md` — known bug, train
- `cases/003-swallowed-error.md` — known bug, train
- `cases/004-clean-small-refactor.md` — clean, train
- `cases/005-clean-docs.md` — clean, train
- `cases/006-clean-test-only.md` — clean, test
- `cases/007-sql-injection.md` — known bug, test
- `cases/008-clean-config.md` — clean, test

Add a case whenever an incident or revert happens. Keep the input small and the
expected result explicit. The `Expect`, `Keyword`, and `Split` fields live in
frontmatter and are stripped before the reviewer sees the case.

## Run

```bash
./evals/reviewer/run.sh
REVIEWER_CMD="opencode run --agent review-code" ./evals/reviewer/run.sh
```

It writes `results.tsv` and prints recall and noise for all cases and the train
split. A case is caught when the verdict matches `Expect` and the output contains
`Keyword`.

## Split

Keep a train set and a held-out test set. If the train score rises but the test
score stays flat, the reviewer is overfitting to the examples.
