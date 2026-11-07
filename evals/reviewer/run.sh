#!/usr/bin/env bash
# Run the reviewer evals. The reviewer command is configurable:
#   REVIEWER_CMD="opencode run --agent review-code" ./run.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CASES="$ROOT/evals/reviewer/cases"
RESULTS="$ROOT/evals/reviewer/results.tsv"
REVIEWER_CMD="${REVIEWER_CMD:-opencode run --agent review-code}"

command -v opencode >/dev/null 2>&1 || {
  echo "opencode not found; set REVIEWER_CMD to your reviewer command" >&2
  exit 1
}

printf 'case\texpect\tverdict\tkeyword\tfound\tsplit\n' > "$RESULTS"

for case_file in "$CASES"/*.md; do
  [ -f "$case_file" ] || continue
  case_name="$(basename "$case_file" .md)"
  expect="$(sed -n 's/^Expect:[[:space:]]*//p' "$case_file" | head -1)"
  keyword="$(sed -n 's/^Keyword:[[:space:]]*//p' "$case_file" | head -1)"
  split="$(sed -n 's/^Split:[[:space:]]*//p' "$case_file" | head -1)"
  prompt="$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$case_file")"
  read -r -a cmd <<< "$REVIEWER_CMD"
  out="$("${cmd[@]}" "$prompt" 2>&1 || true)"
  verdict="$(printf '%s\n' "$out" | grep -m1 -E '^VERDICT:[[:space:]]*(PASS|CHANGES)' | sed 's/^VERDICT:[[:space:]]*//' || true)"
  found="no"
  if [ -n "$keyword" ] && printf '%s\n' "$out" | grep -qi -- "$keyword"; then
    found="yes"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$case_name" "$expect" "${verdict:-missing}" "$keyword" "$found" "$split" >> "$RESULTS"
  echo "$case_name: expect=$expect verdict=${verdict:-missing} keyword=$found"
done

echo
echo "== summary =="
awk -F'\t' '
  NR==1 { next }
  $2=="CHANGES" { bugs++; if ($5=="yes") caught++ }
  $2=="PASS" { clean++; if ($5=="yes") falsepos++ }
  { if ($6=="train") { t_bugs += ($2=="CHANGES"); t_caught += ($2=="CHANGES" && $5=="yes"); t_clean += ($2=="PASS"); t_false += ($2=="PASS" && $5=="yes") } }
  END {
    printf "bugs: %d, caught: %d, recall: %.0f%%\n", bugs, caught, bugs ? 100*caught/bugs : 0
    printf "clean: %d, false positives: %d, noise: %.0f%%\n", clean, falsepos, clean ? 100*falsepos/clean : 0
    printf "train recall: %.0f%%, train noise: %.0f%%\n", t_bugs ? 100*t_caught/t_bugs : 0, t_clean ? 100*t_false/t_clean : 0
  }
' "$RESULTS"
echo "results: $RESULTS"
