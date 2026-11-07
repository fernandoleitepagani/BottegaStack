#!/usr/bin/env bash
# Run the skill trigger evals.
#
# This runner is opt-in and spends tokens: every case starts an agent session.
# Run it only when you are changing a skill or a master prompt.
#   SKILL_EVAL_CMD="opencode run --agent master --auto" ./evals/skills/run.sh
#   SKILL_EVAL_CMD=/path/to/stub ./evals/skills/run.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CASES="$ROOT/evals/skills/cases"
RESULTS="$ROOT/evals/skills/results.tsv"
SKILL_EVAL_CMD="${SKILL_EVAL_CMD:-opencode run --agent master --auto}"

read -r -a cmd <<< "$SKILL_EVAL_CMD"
if ! command -v "${cmd[0]}" >/dev/null 2>&1; then
  echo "skill eval command not found: ${cmd[0]}" >&2
  echo "set SKILL_EVAL_CMD to the agent command" >&2
  exit 1
fi

printf 'case\texpect\tactual\toutcome\tsplit\n' > "$RESULTS"

passed=0
total=0

for case_file in "$CASES"/*.md; do
  [ -f "$case_file" ] || continue
  case_name="$(basename "$case_file" .md)"
  expect="$(sed -n 's/^ExpectSkill:[[:space:]]*//p' "$case_file" | head -1)"
  split="$(sed -n 's/^Split:[[:space:]]*//p' "$case_file" | head -1)"
  # The body, after the frontmatter, is the prompt sent to the agent.
  prompt="$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$case_file" \
    | sed -e 's/[[:space:]]*$//' | awk 'NF{p=1} p')"

  total=$((total + 1))
  if [ -z "$expect" ]; then
    printf '%s\t%s\t%s\t%s\t%s\n' "$case_name" "missing" "missing" "invalid" "${split:-unknown}" >> "$RESULTS"
    echo "$case_name: FAIL (missing ExpectSkill)"
    continue
  fi

  full_prompt="$prompt

Reply with exactly one line: SKILL: <name> - the single skill you would load first for this request. Do not load it."
  out="$("${cmd[@]}" "$full_prompt" 2>&1 || true)"
  actual="$(printf '%s\n' "$out" \
    | grep -m1 -Eo 'SKILL:[[:space:]]*[A-Za-z0-9._-]+' \
    | sed -E 's/^SKILL:[[:space:]]*//' || true)"
  actual_norm="$(printf '%s' "$actual" | tr '[:upper:]' '[:lower:]')"
  expect_norm="$(printf '%s' "$expect" | tr '[:upper:]' '[:lower:]')"

  if [ -n "$actual_norm" ] && [ "$actual_norm" = "$expect_norm" ]; then
    outcome="pass"
    passed=$((passed + 1))
  else
    outcome="fail"
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$case_name" "$expect" "${actual:-missing}" "$outcome" "${split:-unknown}" >> "$RESULTS"
  if [ "$outcome" = "pass" ]; then
    echo "$case_name: PASS (expect=$expect actual=$actual)"
  else
    echo "$case_name: FAIL (expect=$expect actual=${actual:-missing})"
  fi
done

echo
echo "== summary =="
awk -F'\t' -v passed="$passed" -v total="$total" '
  NR==1 { next }
  { n[$5]++; if ($4=="pass") p[$5]++ }
  END {
    if (total > 0) {
      printf "score: %d/%d (%d%%)\n", passed, total, 100*passed/total
    } else {
      print "score: 0/0 (no cases)"
    }
    for (s in n) {
      printf "%s: %d/%d\n", s, p[s], n[s]
    }
  }
' "$RESULTS"

echo "results: $RESULTS"
