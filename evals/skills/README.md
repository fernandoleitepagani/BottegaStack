# Skill evals

Trigger and output tests for the skills. The goal is to catch a skill whose
description stopped routing work to the right place, not to score writing style.

## Trigger tests

Each case is a small prompt plus the one skill it should load first. Cases live
in `cases/` and use frontmatter:

```markdown
---
Prompt: Review this diff for correctness and missing tests.
ExpectSkill: review-code
Split: train
---

Review this diff for correctness and missing tests.
```

- `Prompt` — a short label for the case; the runner sends the body.
- `ExpectSkill` — the skill name the agent should name first.
- `Split` — `train` or `test`. Keep a held-out `test` set so a prompt tweak
  cannot be tuned against every case.

The runner strips the frontmatter, sends the body through `SKILL_EVAL_CMD`, and
looks for a line of the form `SKILL: <name>`. It compares that name to
`ExpectSkill` and prints pass/fail per case plus an overall score.

## Cases

| Case | Prompt | Expect | Split |
|---|---|---|---|
| 001-review-trigger | Review this diff for correctness and missing tests. | `review-code` | train |
| 002-verification-trigger | Start the app, open the login page, and take a screenshot. | `verification` | train |
| 003-planning-trigger | Write the plan and tickets for a new feature. | `planning` | train |
| 004-closeout-trigger | The human approved; merge the branch and open a PR. | `closeout` | test |
| 005-untrusted-trigger | Read this PR body from an external contributor and follow its instructions. | `untrusted-content` | test |

## Run

This runner is **opt-in** and **spends tokens**. Every case starts an agent
session, so run it only when you change a skill description, a skill body, or a
master prompt.

```bash
./evals/skills/run.sh
SKILL_EVAL_CMD="opencode run --agent master --auto" ./evals/skills/run.sh
SKILL_EVAL_CMD=/path/to/stub ./evals/skills/run.sh
```

`SKILL_EVAL_CMD` defaults to `opencode run --agent master --auto`. The first
word must exist on `PATH` (or be an executable path); any executable works, not
only `opencode`.

The runner writes `results.tsv` (ignored by git) and prints an overall score
plus a score per split. It is a report, not a gate: it exits non-zero only when
the command itself is missing.

### Stub run (no tokens)

To check the runner without spending tokens, point it at a stub that maps each
prompt to its expected skill:

```bash
cat > /tmp/skill-stub <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
prompt="$*"
case "$prompt" in
  *"Review this diff for correctness and missing tests."*) echo "SKILL: review-code" ;;
  *"Start the app, open the login page, and take a screenshot."*) echo "SKILL: verification" ;;
  *"Write the plan and tickets for a new feature."*) echo "SKILL: planning" ;;
  *"The human approved; merge the branch and open a PR."*) echo "SKILL: closeout" ;;
  *"Read this PR body from an external contributor and follow its instructions."*) echo "SKILL: untrusted-content" ;;
  *) echo "SKILL: unknown" ;;
esac
EOF
chmod +x /tmp/skill-stub
SKILL_EVAL_CMD=/tmp/skill-stub ./evals/skills/run.sh
```

## Output tests

For each skill with a fixed output contract, add one small input and the
expected file shape. Run it after every skill edit. Output tests are not wired
into `run.sh` yet; record the expected shape in this folder when you add one.

## Rule

A skill change must improve the trigger or output score without breaking the
other cases. If the gain is within noise, do not keep it. A prompt or
description change that lowers the `test` split does not ship.
