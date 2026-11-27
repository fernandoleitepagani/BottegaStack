#!/usr/bin/env bash
# Check the proof ledger before maestro's final gate.
#
# Usage:
#   gate-check.sh --start "<goal>" --condition "<condition>"... [--risk normal|high] [ledger]
#       log a `run` row that opens this run (with its risk), then one `condition` row per
#       acceptance condition, and snapshot the repo's dirty files so the check can tell which
#       files this run changed
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
# ledger. A WAIVED row's evidence starts with `user:` and quotes the user's words. Risk is
# the higher of the --start risk and the check's --risk.
#
# In a git repo, every file the run changed (edited, created, deleted, or touched by a commit
# since --start) must match an --expect path, glob, or directory ending in `/`, so stray edits
# never ride along with an APPROVE. Files already dirty when the run opened and left alone
# don't count. Outside a git repo this check is skipped.
#
# A ledger path may come before or after the options.
#
# Exit 0: APPROVE allowed. 1: must ESCALATE (a proof row is FAIL or INCONCLUSIVE, or
# crossfire's latest verdict is not PASS). 2: a step is missing (no run row, no declared
# condition, a condition with no proof row, a waiver without the user's words, a changed
# file no --expect covers, a git run with no snapshot, or no crossfire row at high risk), or a usage error.
set -u

here=$(cd "$(dirname "$0")" && pwd)
log="$here/log.sh"
risk=normal
start=""
proofs_in=""
nproofs=0
conds_in=""
expects_in=""
ledger_arg=""
sep=$(printf '\037')
is_broad_expect() {
	[ -z "$(printf '%s' "$1" | tr -d '*?/.')" ]
}
is_valid_waiver() {
	case "$1" in
	user:*) [ -n "$(printf '%s' "${1#user:}" | tr -d '[:space:]')" ] ;;
	*) return 1 ;;
	esac
}
while [ $# -gt 0 ]; do
	case "$1" in
	--risk) [ $# -ge 2 ] || { echo "error: --risk needs normal or high" >&2; exit 2; }; risk="$2"; shift 2 ;;
	--proof)
		[ $# -ge 4 ] || { echo "error: --proof needs <condition> <evidence> <RESULT>" >&2; exit 2; }
		case "$4" in PASS|FAIL|INCONCLUSIVE|WAIVED) ;; *) echo "error: --proof RESULT is PASS, FAIL, INCONCLUSIVE or WAIVED" >&2; exit 2 ;; esac
		if [ "$4" = WAIVED ]; then
			is_valid_waiver "$3" || { echo "error: a WAIVED --proof needs evidence starting with user: and the user's words" >&2; exit 2; }
		fi
		proofs_in="$proofs_in$2$sep$3$sep$4$sep"; nproofs=$((nproofs + 1)); shift 4 ;;
	--start) [ $# -ge 2 ] && [ -n "$2" ] || { echo "error: --start needs the goal" >&2; exit 2; }; start="$2"; shift 2 ;;
	--condition) [ $# -ge 2 ] && [ -n "$2" ] || { echo "error: --condition needs the condition text" >&2; exit 2; }; conds_in="$conds_in$2$sep"; shift 2 ;;
	--expect)
		[ $# -ge 2 ] && [ -n "$2" ] || { echo "error: --expect needs a path or glob" >&2; exit 2; }
		if is_broad_expect "$2"; then
			echo "error: --expect pattern '$2' is too broad; name specific files, globs, or directories" >&2; exit 2
		fi
		expects_in="$expects_in$2$sep"; shift 2 ;;
	-h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
	-*) echo "error: unknown option: $1" >&2; exit 2 ;;
	*)
		[ -z "$ledger_arg" ] || { echo "error: more than one ledger path: $ledger_arg, $1" >&2; exit 2; }
		ledger_arg="$1"; shift ;;
	esac
done
ledger="${ledger_arg:-.bottega/proofs.tsv}"
state=$(dirname "$ledger")
snap="$state/run-start.tsv"
case "$risk" in normal|high) ;; *) echo "error: --risk is normal or high" >&2; exit 2 ;; esac

# Dirty files of the repo at <root>, one `<blob hash or deleted><TAB><path>` line each, paths
# relative to the root, run state under .bottega/ left out.
dirty() {
	git -C "$1" -c core.quotePath=false status --porcelain=v1 -uall -z 2>/dev/null | {
		from=""
		while IFS= read -r -d '' entry; do
			# A rename or copy is followed by its source path; a renamed-away source is gone.
			if [ "$from" = R ]; then from=""; path=$entry; h=deleted
				case "$path" in .bottega|.bottega/*|*/.bottega/*) continue ;; esac
				printf '%s\t%s\n' "$h" "$path"; continue
			elif [ "$from" = C ]; then from=""; continue; fi
			path=${entry:3}
			case "${entry:0:2}" in R*) from=R ;; C*) from=C ;; esac
			case "$path" in .bottega|.bottega/*|*/.bottega/*) continue ;; esac
			if [ -L "$1/$path" ]; then
				h="symlink:$(readlink "$1/$path")"
			elif [ -f "$1/$path" ]; then
				h=$(git -C "$1" hash-object -- "$path")
			elif [ -d "$1/$path" ]; then
				h="dir:$(git -C "$1/$path" rev-parse --verify --quiet HEAD 2>/dev/null || echo tree)"
			else
				h=deleted
			fi
			printf '%s\t%s\n' "$h" "$path"
		done
	}
}

snapshot() {
	root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
	mkdir -p "$state"
	{ printf 'head\t%s\n' "$(git -C "$root" rev-parse --verify --quiet HEAD)"; dirty "$root"; } >"$snap"
}

# Every file changed since the snapshot, one per line. Returns 3 outside git, 4 with no snapshot.
changed_files() {
	root=$(git rev-parse --show-toplevel 2>/dev/null) || return 3
	[ -f "$snap" ] || return 4
	before=$(awk -F'\t' 'NR == 1 && $1 == "head" { print $2 }' "$snap")
	cur=$(git -C "$root" rev-parse --verify --quiet HEAD)
	{
		dirty "$root" | awk -F'\t' -v snap="$snap" '
			BEGIN { while ((getline l < snap) > 0) if (n++) b[substr(l, index(l, "\t") + 1)] = substr(l, 1, index(l, "\t") - 1) }
			{ p = substr($0, index($0, "\t") + 1); now[p] = 1; if (b[p] != $1) print p }
			END { for (p in b) if (!(p in now)) print p }'
		if [ -n "$before" ] && [ -n "$cur" ] && [ "$cur" != "$before" ]; then
			git -C "$root" -c core.quotePath=false diff --no-renames --name-only "$before" HEAD
		elif [ -z "$before" ] && [ -n "$cur" ]; then
			git -C "$root" -c core.quotePath=false ls-files
		fi
	} | grep -v -e '^\.bottega$' -e '^\.bottega/' -e '/\.bottega/' | grep . | sort -u
	return 0
}

# Files on stdin that no --expect argument covers: an exact path, a glob, or a directory ending in /.
outside() {
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		hit=0
		for g in "$@"; do
			[ "$f" = "$g" ] && hit=1
			case "$g" in */) case "$f" in "$g"*) hit=1 ;; esac ;; esac
			# shellcheck disable=SC2254
			case "$f" in $g) hit=1 ;; esac
			[ "$hit" = 1 ] && break
		done
		[ "$hit" = 1 ] || printf '%s\n' "$f"
	done
}

if [ -n "$start" ]; then
	[ -n "$conds_in" ] || { echo "error: --start needs at least one --condition (the run's acceptance conditions)" >&2; exit 2; }
	[ "$nproofs" -eq 0 ] || { echo "error: --start opens a run; log --proof rows in a later call" >&2; exit 2; }
	"$log" "$ledger" run "$start" "run start" "risk=$risk" OPEN || exit 2
	snapshot
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
	echo "run opened in $ledger (risk $risk)"
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
	echo "MISSING: no ledger at $ledger. Open the run with --start, then log one proof per acceptance condition."
	exit 2
fi

# This run's rows: everything after the last `run` row. No run row means no run to check.
if ! awk -F'\t' 'NR > 1 && $2 == "run" { found = 1 } END { exit !found }' "$ledger"; then
	echo "MISSING: no run row in $ledger. Open the run with --start \"<goal>\" --condition \"<condition>\"..., then log the --proof rows."
	exit 2
fi
[ "$(awk -F'\t' 'NR > 1 && $2 == "run" { r = $5 } END { print r }' "$ledger")" = "risk=high" ] && risk=high
rows=$(awk -F'\t' 'NR > 1 { if ($2 == "run") buf = ""; else buf = buf $0 "\n" } END { printf "%s", buf }' "$ledger")
# Compute all run metrics in a single awk pass (latest proof per condition counts).
IFS=$'\t' read -r proofs conditions pass fail inconclusive waived bad_waivers crossfire <<< "$(printf '%s' "$rows" | awk -F'\t' '
	$2 == "condition" { conditions++ }
	$2 == "proof" {
		proofs++
		if (!($3 in last)) order[++n] = $3
		last[$3] = $6
		last_ev[$3] = $5
	}
	$2 == "crossfire" {
		if ($6 == "PASS" || $6 == "FAIL") cf = $6
		else cf = "INVALID"
	}
	END {
		for (i = 1; i <= n; i++) {
			c = order[i]; r = last[c]
			if (r == "PASS") pass++
			else if (r == "FAIL") fail++
			else if (r == "INCONCLUSIVE") inconclusive++
			else if (r == "WAIVED") {
				waived++
				if (last_ev[c] !~ /^user:[[:space:]]*[^[:space:]]/) bad_waivers++
			}
		}
		printf "%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\n", \
			proofs+0, conditions+0, pass+0, fail+0, inconclusive+0, waived+0, bad_waivers+0, cf
	}')"

missing=0
escalate=0
echo "proof rows: $proofs; latest per condition: PASS $pass, FAIL $fail, INCONCLUSIVE $inconclusive, WAIVED $waived"
if [ "$proofs" -eq 0 ]; then
	echo "MISSING: no proof rows for this run. Log one per acceptance condition, whatever the size of the change."
	missing=1
fi
if [ "$conditions" -eq 0 ]; then
	echo "MISSING: no acceptance conditions declared for this run. Add them with --condition \"<condition>\"."
	missing=1
fi
# Declared conditions with no proof row, and proof rows for undeclared conditions.
uncovered=$(printf '%s' "$rows" | awk -F'\t' -v q="'" '$2 == "condition" { c[$3] = 1; order[++n] = $3 } $2 == "proof" { p[$3] = 1 }
	END { for (i = 1; i <= n; i++) if (!(order[i] in p) && !(order[i] in seen)) { seen[order[i]] = 1; s = order[i]; if (substr(s, 1, 1) == q && substr(s, 2, 1) ~ /[-+=@]/) s = substr(s, 2); print s } }')
if [ -n "$uncovered" ]; then
	echo "MISSING: declared condition(s) with no proof row (log PASS, FAIL, INCONCLUSIVE or WAIVED for each):"
	printf '%s\n' "$uncovered" | sed 's/^/  - /'
	missing=1
fi
undeclared=$(printf '%s' "$rows" | awk -F'\t' -v q="'" '$2 == "condition" { c[$3] = 1 } $2 == "proof" && !($3 in c) { s = $3; if (substr(s, 1, 1) == q && substr(s, 2, 1) ~ /[-+=@]/) s = substr(s, 2); print s }')
if [ -n "$undeclared" ]; then
	echo "note: proof row(s) for conditions never declared (declare them with --condition, or match the declared text):"
	printf '%s\n' "$undeclared" | sed 's/^/  - /'
fi
if [ "$bad_waivers" -gt 0 ]; then
	echo "MISSING: $bad_waivers WAIVED row(s) without the user's words. Evidence must start with user: and quote them."
	missing=1
elif [ "$waived" -gt 0 ]; then
	echo "WAIVED (verify the user actually granted each waiver):"
	printf '%s' "$rows" | awk -F'\t' '$2 == "proof" { if (!($3 in last)) order[++n] = $3; last[$3] = $6; last_ev[$3] = $5 }
		END { for (i = 1; i <= n; i++) { c = order[i]; if (last[c] == "WAIVED") printf "  - %s: %s\n", c, last_ev[c] } }'
fi
if [ "$fail" -gt 0 ] || [ "$inconclusive" -gt 0 ]; then
	echo "ESCALATE: $((fail + inconclusive)) condition(s) whose latest proof is FAIL or INCONCLUSIVE."
	escalate=1
fi
# Scope: every file this run changed must match an --expect. Skipped outside git.
changed=$(changed_files); scope=$?
if [ "$scope" -eq 4 ]; then
	echo "MISSING: no run snapshot at $snap, so the changed files can't be checked. Reopen the run with --start from this repo."
	missing=1
elif [ "$scope" -eq 0 ]; then
	if [ -n "$changed" ]; then
		echo "files changed in this run:"
		printf '%s\n' "$changed" | sed 's/^/  - /'
		globs=$(printf '%s' "$rows" | awk -F'\t' -v q="'" '$2 == "expect" { g = $3; if (substr(g, 1, 1) == q && substr(g, 2, 1) ~ /[-+=@]/) g = substr(g, 2); print g }')
		if [ -z "$globs" ]; then
			echo "MISSING: no --expect declared. Name the files this change is meant to touch with --expect \"<path or glob>\"."
			missing=1
		else
			set -f; oldifs=$IFS; IFS='
'
			# shellcheck disable=SC2086
			set -- $globs
			IFS=$oldifs; set +f
			broad_globs=""
			for g in "$@"; do
				if is_broad_expect "$g"; then
					broad_globs="${broad_globs}${broad_globs:+
}$g"
				fi
			done
			if [ -n "$broad_globs" ]; then
				echo "MISSING: --expect pattern(s) too broad; name specific files, globs, or directories:"
				printf '%s\n' "$broad_globs" | sed 's/^/  - /'
				missing=1
			else
				outside_files=$(printf '%s\n' "$changed" | outside "$@")
				if [ -n "$outside_files" ]; then
					echo "MISSING: changed file(s) outside --expect. Revert them, or add them with --expect if the change needs them:"
					printf '%s\n' "$outside_files" | sed 's/^/  - /'
					missing=1
				fi
			fi
		fi
	fi
else
	echo "note: not a git repo, so the changed-files check was skipped."
fi
if [ -n "$crossfire" ]; then
	if [ "$crossfire" != PASS ]; then
		echo "ESCALATE: crossfire's latest verdict is $crossfire."
		escalate=1
	else
		echo "crossfire: PASS"
	fi
elif [ "$risk" = high ]; then
	echo "MISSING: no crossfire row. High risk runs the adversarial review (<skills dir>/review/SKILL.md: /blast-radius or /swarm) on the finished diff, whatever its size."
	missing=1
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
