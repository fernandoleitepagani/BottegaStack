#!/usr/bin/env bash
# Check the proof ledger before maestro's final gate.
#
# Usage:
#   gate-check.sh --start "<goal>" --condition "<condition>"... [ledger]
#       log a `run` row that opens this run, then one `condition` row per acceptance condition,
#       and snapshot the repo's dirty files so the check can tell which files this run changed
#   gate-check.sh [--risk normal|high] [--condition "<condition>"]... [--expect "<path or glob>"]...
#                 [--proof "<condition>" "<evidence>" <RESULT>]... [ledger]
#       log any late --condition rows, each --expect row (a file the change is meant to
#       touch) and each --proof row (RESULT is PASS, FAIL, INCONCLUSIVE or WAIVED), then
#       check this run's rows. One call does the whole step.
#
# The ledger defaults to .bottega/proofs.tsv. A check reads only the rows after the last
# `run` row, so an earlier run's proofs or crossfire verdict never count. A --proof
# condition must match a declared condition's text exactly. For each condition only its
# latest proof row counts, so a FAIL fixed and proven PASS approves; the FAIL stays in the
# ledger. A WAIVED row's evidence starts with `user:` and quotes the user's words.
#
# In a git repo, every file the run changed (see run-files.py) must match an --expect glob,
# so stray edits never ride along with an APPROVE. Files already dirty when the run opened
# and left alone don't count. Outside a git repo this check is skipped.
#
# Exit 0: APPROVE allowed. 1: must ESCALATE (a proof row is FAIL or INCONCLUSIVE, or
# crossfire's latest verdict is not PASS). 2: a step is missing (no run row, no declared
# condition, a condition with no proof row, a waiver without the user's words, a changed
# file no --expect covers, or no crossfire row at high risk), or a usage error.
set -u

here=$(cd "$(dirname "$0")" && pwd)
log="$here/../../show-me-your-work/scripts/log.sh"
files="$here/run-files.py"
risk=normal
start=""
proofs_in=""
nproofs=0
conds_in=""
expects_in=""
sep=$(printf '\037')
while [ $# -gt 0 ]; do
	case "$1" in
	--risk) [ $# -ge 2 ] || { echo "error: --risk needs normal or high" >&2; exit 2; }; risk="$2"; shift 2 ;;
	--proof)
		[ $# -ge 4 ] || { echo "error: --proof needs <condition> <evidence> <RESULT>" >&2; exit 2; }
		case "$4" in PASS|FAIL|INCONCLUSIVE|WAIVED) ;; *) echo "error: --proof RESULT is PASS, FAIL, INCONCLUSIVE or WAIVED" >&2; exit 2 ;; esac
		if [ "$4" = WAIVED ]; then
			case "$3" in user:*) ;; *) echo "error: a WAIVED --proof needs evidence starting with user: and the user's words" >&2; exit 2 ;; esac
		fi
		proofs_in="$proofs_in$2$sep$3$sep$4$sep"; nproofs=$((nproofs + 1)); shift 4 ;;
	--start) [ $# -ge 2 ] || { echo "error: --start needs the goal" >&2; exit 2; }; start="$2"; shift 2 ;;
	--condition) [ $# -ge 2 ] && [ -n "$2" ] || { echo "error: --condition needs the condition text" >&2; exit 2; }; conds_in="$conds_in$2$sep"; shift 2 ;;
	--expect) [ $# -ge 2 ] && [ -n "$2" ] || { echo "error: --expect needs a path or glob" >&2; exit 2; }; expects_in="$expects_in$2$sep"; shift 2 ;;
	-h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
	-*) echo "error: unknown option: $1" >&2; exit 2 ;;
	*) break ;;
	esac
done
ledger="${1:-.bottega/proofs.tsv}"
state=$(dirname "$ledger")
case "$risk" in normal|high) ;; *) echo "error: --risk is normal or high" >&2; exit 2 ;; esac

if [ -n "$start" ]; then
	[ -n "$conds_in" ] || { echo "error: --start needs at least one --condition (the run's acceptance conditions)" >&2; exit 2; }
	[ "$nproofs" -eq 0 ] || { echo "error: --start opens a run; log --proof rows in a later call" >&2; exit 2; }
	"$log" "$ledger" run "$start" "run start" "n/a" OPEN || exit 2
	python3 "$files" snapshot "$state" 2>/dev/null || true
fi

# Log any --condition rows, split back on the unit separator.
rest="$conds_in"
while [ -n "$rest" ]; do
	cond=${rest%%"$sep"*}; rest=${rest#*"$sep"}
	"$log" "$ledger" condition "$cond" "acceptance condition" "n/a" OPEN || exit 2
done
rest="$expects_in"
while [ -n "$rest" ]; do
	glob=${rest%%"$sep"*}; rest=${rest#*"$sep"}
	"$log" "$ledger" expect "$glob" "file the change touches" "n/a" OPEN || exit 2
done
if [ -n "$start" ]; then
	echo "run opened in $ledger"
	exit 0
fi

# Log the --proof rows first. Fields are joined with the unit separator, which no shell
# argument here contains in practice, and split back three at a time.
if [ "$nproofs" -gt 0 ]; then
	rest="$proofs_in"
	while [ -n "$rest" ]; do
		cond=${rest%%"$sep"*}; rest=${rest#*"$sep"}
		evid=${rest%%"$sep"*}; rest=${rest#*"$sep"}
		res=${rest%%"$sep"*}; rest=${rest#*"$sep"}
		"$log" "$ledger" proof "$cond" "gate-check --proof" "$evid" "$res" || exit 2
	done
fi

if [ ! -s "$ledger" ]; then
	echo "MISSING: no ledger at $ledger. Log one proof row per acceptance condition (see references/final-gate.md)."
	exit 2
fi

# This run's rows: everything after the last `run` row. No run row means no run to check.
if ! awk -F'\t' 'NR > 1 && $2 == "run" { found = 1 } END { exit !found }' "$ledger"; then
	echo "MISSING: no run row in $ledger. Open the run with --start \"<goal>\" --condition \"<condition>\"..., then log the --proof rows."
	exit 2
fi
rows=$(awk -F'\t' 'NR > 1 { if ($2 == "run") buf = ""; else buf = buf $0 "\n" } END { printf "%s", buf }' "$ledger")
count() { printf '%s' "$rows" | awk -F'\t' -v p="$1" -v r="$2" '$2 == p && (r == "" || $6 == r)' | grep -c . ; }

# Only the latest proof row per condition counts, so a FAIL that was fixed and proven again
# approves. Earlier rows stay in the ledger as the run's history.
latest=$(printf '%s' "$rows" | awk -F'\t' '$2 == "proof" { if (!($3 in last)) order[++n] = $3; last[$3] = $0 }
	END { for (i = 1; i <= n; i++) print last[order[i]] }')
lcount() { printf '%s' "$latest" | awk -F'\t' -v r="$1" 'r == "" || $6 == r' | grep -c . ; }
proofs=$(count proof "")
pass=$(lcount PASS)
fail=$(lcount FAIL)
inconclusive=$(lcount INCONCLUSIVE)
waived=$(lcount WAIVED)
crossfire=$(printf '%s' "$rows" | awk -F'\t' '$2 == "crossfire" { last = $6 } END { print last }')

missing=0
escalate=0
echo "proof rows: $proofs; latest per condition: PASS $pass, FAIL $fail, INCONCLUSIVE $inconclusive, WAIVED $waived"
if [ "$proofs" -eq 0 ]; then
	echo "MISSING: no proof rows for this run. Log one per acceptance condition, whatever the size of the change."
	missing=1
fi
conditions=$(count condition "")
if [ "$conditions" -eq 0 ]; then
	echo "MISSING: no acceptance conditions declared for this run. Add them with --condition \"<condition>\"."
	missing=1
fi
# Declared conditions with no proof row, and proof rows for undeclared conditions.
uncovered=$(printf '%s' "$rows" | awk -F'\t' '$2 == "condition" { c[$3] = 1; order[++n] = $3 } $2 == "proof" { p[$3] = 1 }
	END { for (i = 1; i <= n; i++) if (!(order[i] in p) && !(order[i] in seen)) { seen[order[i]] = 1; print order[i] } }')
if [ -n "$uncovered" ]; then
	echo "MISSING: declared condition(s) with no proof row (log PASS, FAIL, INCONCLUSIVE or WAIVED for each):"
	printf '%s\n' "$uncovered" | sed 's/^/  - /'
	missing=1
fi
undeclared=$(printf '%s' "$rows" | awk -F'\t' '$2 == "condition" { c[$3] = 1 } $2 == "proof" && !($3 in c) { print $3 }')
if [ -n "$undeclared" ]; then
	echo "note: proof row(s) for conditions never declared (declare them with --condition, or match the declared text):"
	printf '%s\n' "$undeclared" | sed 's/^/  - /'
fi
bad_waivers=$(printf '%s' "$latest" | awk -F'\t' '$6 == "WAIVED" && $5 !~ /^user:/' | grep -c .)
if [ "$bad_waivers" -gt 0 ]; then
	echo "MISSING: $bad_waivers WAIVED row(s) without the user's words. Evidence must start with user: and quote them."
	missing=1
fi
if [ "$fail" -gt 0 ] || [ "$inconclusive" -gt 0 ]; then
	echo "ESCALATE: $((fail + inconclusive)) condition(s) whose latest proof is FAIL or INCONCLUSIVE."
	escalate=1
fi
# Scope: every file this run changed must match an --expect glob. Skipped outside git.
if changed=$(python3 "$files" changed "$state" 2>/dev/null); then
	if [ -n "$changed" ]; then
		echo "files changed in this run:"
		printf '%s\n' "$changed" | sed 's/^/  - /'
		globs=$(printf '%s' "$rows" | awk -F'\t' '$2 == "expect" { print $3 }')
		if [ -z "$globs" ]; then
			echo "MISSING: no --expect declared. Name the files this change is meant to touch with --expect \"<path or glob>\"."
			missing=1
		else
			outside=$(printf '%s\n' "$globs" | {
				set --; while IFS= read -r g; do set -- "$@" "$g"; done
				printf '%s\n' "$changed" | python3 "$files" outside "$@"; })
			if [ -n "$outside" ]; then
				echo "MISSING: changed file(s) outside --expect. Revert them, or add them with --expect if the change needs them:"
				printf '%s\n' "$outside" | sed 's/^/  - /'
				missing=1
			fi
		fi
	fi
else
	echo "note: no git repo or no run snapshot, so the changed-files check was skipped."
fi
if [ "$risk" = high ]; then
	if [ -z "$crossfire" ]; then
		echo "MISSING: no crossfire row. High risk runs the crossfire skill on the finished diff, whatever its size."
		missing=1
	elif [ "$crossfire" != PASS ]; then
		echo "ESCALATE: crossfire's latest verdict is $crossfire."
		escalate=1
	else
		echo "crossfire: PASS"
	fi
fi

if [ "$missing" -eq 1 ]; then
	echo "gate-check: incomplete. Do the missing steps, then rerun."
	exit 2
elif [ "$escalate" -eq 1 ]; then
	echo "gate-check: ESCALATE"
	exit 1
fi
echo "gate-check: APPROVE allowed"
exit 0
