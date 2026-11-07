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

## Scoring

A clean case (`Expect: PASS`) is a false positive for **any** verdict other
than `PASS`, including when the reviewer prints no verdict (`missing`).
`Keyword: none` is ignored for clean cases.

A bug case (`Expect: CHANGES`) is caught only when the verdict is `CHANGES`
**and** the output contains the case's `Keyword` (case-insensitive).
`Keyword: none` means the case has no keyword requirement.

The runner prints recall (bug cases caught) and noise (clean-case false
positives) for the `train` split, the `test` split, and an `all` line.

## Run

```bash
./evals/reviewer/run.sh
REVIEWER_CMD="opencode run --agent review-code" ./evals/reviewer/run.sh
REVIEWER_CMD=/path/to/reviewer-stub ./evals/reviewer/run.sh
```

It writes `results.tsv` (ignored by git) and prints the scores. `REVIEWER_CMD`
overrides the reviewer command; the first word must exist on `PATH` (or be an
executable path). Any executable works, not only `opencode`.

## Split

Keep a train set and a held-out test set. If the train score rises but the test
score stays flat, the reviewer is overfitting to the examples.
