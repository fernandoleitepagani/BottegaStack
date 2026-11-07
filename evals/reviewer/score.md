# Reviewer score

Run `./evals/reviewer/run.sh`. It writes `results.tsv` and prints recall and
noise per split.

| Case | Expected | Flagged? | Keyword | Split |
|---|---|---|---|---|
| 001-off-by-one | bug | | bounds | train |
| 002-missing-auth-check | bug | | ownership | train |
| 003-swallowed-error | bug | | catch | train |
| 004-clean-small-refactor | clean | | none | train |
| 005-clean-docs | clean | | none | train |
| 006-clean-test-only | clean | | none | test |
| 007-sql-injection | bug | | injection | test |
| 008-clean-config | clean | | none | test |

## Rule

A change to a reviewer prompt, skill, or model must not lower recall or raise
noise on the test split. If the gain is within noise, do not keep it.
