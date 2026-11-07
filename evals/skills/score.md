# Skill score

Run `./evals/skills/run.sh`. It writes `results.tsv` and prints pass/fail per
case plus an overall score. The runner is opt-in and spends tokens: each case
starts an agent session.

| Case | Expected skill | Split |
|---|---|---|
| 001-review-trigger | `review-code` | train |
| 002-verification-trigger | `verification` | train |
| 003-planning-trigger | `planning` | train |
| 004-closeout-trigger | `closeout` | test |
| 005-untrusted-trigger | `untrusted-content` | test |

## Scoring

A case passes only when the first `SKILL: <name>` line in the agent output
matches `ExpectSkill` exactly (case-insensitive). Missing output, a different
skill, or a malformed line is a fail.

The runner prints `score: <pass>/<total>` and a line per split. A perfect stub
run proves the harness works; it says nothing about the real agent.

## Rule

A change to a skill description, skill body, or master prompt must not lower the
`test` split. If the gain is within noise, do not keep it. Re-run the stub after
editing `run.sh` or a case, and run the real command before releasing a skill
change.
