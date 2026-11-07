#!/usr/bin/env bash
# Run the reviewer evals.
#   REVIEWER_CMD="opencode run --agent review-code" ./run.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CASES="$ROOT/evals/reviewer/cases"
RESULTS="$ROOT/evals/reviewer/results.tsv"
REVIEWER_CMD="${REVIEWER_CMD:-opencode run --agent review-code}"

read -r -a cmd <<< "$REVIEWER_CMD"
if ! command -v "${cmd[0]}" >/dev/null 2>&1; then
  echo "reviewer command not found: ${cmd[0]}" >&2
  echo "set REVIEWER_CMD to the reviewer command" >&2
  exit 1
fi

printf 'case\texpect\tverdict\tkeyword\toutcome\tsplit\n' > "$RESULTS"

for case_file in "$CASES"/*.md; do
  [ -f "$case_file" ] || continue
  case_name="$(basename "$case_file" .md)"
  expect="$(sed -n 's/^Expect:[[:space:]]*//p' "$case_file" | head -1)"
  keyword="$(sed -n 's/^Keyword:[[:space:]]*//p' "$case_file" | head -1)"
  split="$(sed -n 's/^Split:[[:space:]]*//p' "$case_file" | head -1)"
  prompt="$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$case_file")"
  out="$("${cmd[@]}" "$prompt" 2>&1 || true)"
  verdict="$(printf '%s\n' "$out" | grep -m1 -E '^VERDICT:[[:space:]]*(PASS|CHANGES)' | sed -E 's/^VERDICT:[[:space:]]*(PASS|CHANGES).*/\1/' || true)"
  outcome="miss"
  if [ "$expect" = "PASS" ]; then
    if [ "$verdict" = "PASS" ]; then outcome="clean"; else outcome="false-positive"; fi
  else
    if [ "$verdict" = "CHANGES" ]; then
      if [ -z "$keyword" ] || [ "$keyword" = "none" ] || printf '%s\n' "$out" | grep -qiF -- "$keyword"; then
        outcome="caught"
      else
        outcome="miss-no-keyword"
      fi
    fi
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$case_name" "$expect" "${verdict:-missing}" "$keyword" "$outcome" "$split" >> "$RESULTS"
  echo "$case_name: expect=$expect verdict=${verdict:-missing} outcome=$outcome"
done

echo
echo "== summary =="
awk -F'\t' '
  NR==1 { next }
  $2=="CHANGES" { bugs[$6]++; if ($5=="caught") caught[$6]++ }
  $2=="PASS" { clean[$6]++; if ($5=="false-positive") fp[$6]++ }
  END {
    order[1]="train"; order[2]="test"
    for (i=1; i<=2; i++) {
      s=order[i]
      printf "%s: recall=%.0f%% (%d/%d), noise=%.0f%% (%d/%d)\n", \
        s, bugs[s]?100*caught[s]/bugs[s]:0, caught[s], bugs[s], \
        clean[s]?100*fp[s]/clean[s]:0, fp[s], clean[s]
    }
    tb=0; tc=0; tn=0; tf=0
    for (s in bugs) { tb+=bugs[s]; tc+=caught[s] }
    for (s in clean) { tn+=clean[s]; tf+=fp[s] }
    printf "all: recall=%.0f%% (%d/%d), noise=%.0f%% (%d/%d)\n", \
      tb?100*tc/tb:0, tc, tb, tn?100*tf/tn:0, tf, tn
  }
' "$RESULTS"

echo "results: $RESULTS"
