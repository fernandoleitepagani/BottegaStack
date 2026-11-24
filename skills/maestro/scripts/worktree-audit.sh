#!/usr/bin/env bash
# Worktree prune audit. Classifies every git worktree by size, merge state,
# uncommitted work, remote/PR state, and the most recent chat that operated in
# it. Emits a table sorted by size with a suggested bucket. Never deletes or
# changes a worktree; deletion stays a human-gated step in the playbook. Its one
# write is a best-effort `git fetch` of the base ref, so MERGED is current.
#
# Usage: worktree-audit.sh [-b|--base <ref>] [--no-sizes] [repo-path]
#   --no-sizes skips `du`, the slow part on worktrees with large dependency trees,
#   for a quick look at merge, PR and chat state. SIZE shows "-" and rows sort by age.
#   repo-path defaults to the current repo.
#   -b sets the ref the MERGED column checks against (e.g. origin/integration).
#   Without it the base is origin/HEAD, then origin/main, then origin/master.
#   origin/HEAD is the remote's default branch, not necessarily the branch PRs
#   merge into; pass -b when they differ.
set -u

base=""
sizes=1
while [ $# -gt 0 ]; do
	case "$1" in
	-b|--base) [ $# -ge 2 ] || { echo "error: $1 needs a ref" >&2; exit 2; }; base="$2"; shift 2 ;;
	--no-sizes) sizes=0; shift ;;
	-h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
	-*) echo "error: unknown option: $1" >&2; exit 2 ;;
	*) break ;;
	esac
done

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$repo" ] && { echo "not in a git repo; pass a repo path" >&2; exit 1; }
cd "$repo" || exit 1
git rev-parse --git-dir >/dev/null 2>&1 || { echo "error: not a git repo: $repo" >&2; exit 1; }

# Main worktree is the first entry; everything else is a candidate. Claude Code
# worktrees (.claude/worktrees/) appear here too, since git lists them.
main_wt=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')

if [ -z "$base" ]; then
	for cand in "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" origin/main origin/master; do
		[ -n "$cand" ] && git rev-parse --verify --quiet "$cand^{commit}" >/dev/null && { base="$cand"; break; }
	done
	[ -z "$base" ] && { echo "error: no base ref (origin/HEAD, origin/main, origin/master all missing); pass -b <ref>" >&2; exit 1; }
	echo "warn: no -b given; MERGED checks against $base" >&2
fi

# The base drives the merge check. The fetch is best-effort (stale is fine for
# a first pass) and runs before the check, since -b may name a branch not
# fetched yet. The explicit refspec creates it even in a single-branch clone.
case "$base" in
origin/*) git fetch origin "+refs/heads/${base#origin/}:refs/remotes/$base" --quiet 2>/dev/null \
	|| echo "warn: could not fetch $base; merged column may be stale" >&2 ;;
esac
git rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1 || { echo "error: base ref not found: $base" >&2; exit 1; }

# GNU coreutils (Linux, Homebrew gnubin) reads `stat -f` as file system status
# and `date -r` as a file, so pick the stat and date flags once.
if stat -c %Y / >/dev/null 2>&1; then
	stat_fmt=(-c '%Y %n'); fmt_day() { date -d "@$1" '+%Y-%m-%d'; }
else
	stat_fmt=(-f '%m %N'); fmt_day() { date -r "$1" '+%Y-%m-%d'; }
fi

# PR state by branch, fetched once as "<branch><TAB>#<number>/<state>" lines with a
# lowercase state, through gh's built-in --jq (no separate jq needed). Empty when gh
# cannot read this repo's PRs.
prs=$(mktemp)
trap 'rm -f "$prs"' EXIT
gh pr list --author "@me" --state all --limit 1000 --json number,state,headRefName \
	--jq '.[] | "\(.headRefName)\t#\(.number)/\(.state | ascii_downcase)"' > "$prs" 2>/dev/null || : > "$prs"

# Transcripts dir: ~/.claude/projects/<slug>/ holds <session>.jsonl, with
# subagents in <session>/subagents/. The slug is the workspace path with "/" and
# "." replaced by "-".
slug=$(printf '%s' "$main_wt" | sed 's#[/.]#-#g')
transcripts="$HOME/.claude/projects/$slug"
if command -v rg >/dev/null 2>&1; then
	grep_files() { rg -lF -e "$1/" -e "$1\"" "$2" 2>/dev/null; }
else
	grep_files() { grep -rlF -e "$1/" -e "$1\"" "$2" 2>/dev/null; }
fi
now=$(date +%s)

echo "# base: $base"
printf "SIZE\tAGE\tMERGED\tDIRTY\tREMOTE\tPR\tLAST_CHAT\tBUCKET\tWORKTREE\n"

git worktree list --porcelain | awk '/^worktree /{print $2}' | while read -r wt; do
	[ "$wt" = "$main_wt" ] && continue

	size=-
	[ "$sizes" -eq 1 ] && size=$(du -sh "$wt" 2>/dev/null | awk '{print $1}')
	head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
	head_ts=$(git -C "$wt" log -1 --format='%ct' HEAD 2>/dev/null || echo 0)
	age=$([ "$head_ts" -gt 0 ] 2>/dev/null && echo "$(( (now - head_ts) / 86400 ))d" || echo "?")

	# Squash-merged branches are not ancestors of the base, so PR state is the
	# real signal; merge-base only catches fast-forward/rebase merges.
	git merge-base --is-ancestor "$head" "$base" 2>/dev/null && merged=YES || merged=no

	# Distinguish real WIP (tracked edits) from disposable untracked scratch.
	porcelain=$(git -C "$wt" status --porcelain 2>/dev/null)
	if [ -z "$porcelain" ]; then dirty=clean
	elif printf '%s\n' "$porcelain" | grep -qv '^??'; then
		dirty="wip:$(printf '%s\n' "$porcelain" | grep -cv '^??')"
	else dirty="scratch:$(printf '%s\n' "$porcelain" | grep -c '^??')"; fi

	branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
	if [ -z "$branch" ]; then remote=detached
	elif git -C "$wt" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
		[ "$(git -C "$wt" rev-parse "origin/$branch" 2>/dev/null)" = "$head" ] \
			&& remote=pushed \
			|| remote="ahead$(git -C "$wt" rev-list --count "origin/$branch..HEAD" 2>/dev/null)"
	else remote=no-remote; fi

	pr=$([ -n "$branch" ] && awk -F'\t' -v b="$branch" '$1 == b { print $2; exit }' "$prs")
	[ -z "$pr" ] && pr="-"

	# Most recent chat whose transcript operated in this worktree. Match path
	# followed by "/" or a quote so feat-482 does not match feat-482-r37.
	last="-"; last_ts=0
	if [ -d "$transcripts" ]; then
		f=$(grep_files "$wt" "$transcripts" \
			| xargs stat "${stat_fmt[@]}" 2>/dev/null | sort -rn | head -1)
		if [ -n "$f" ]; then last_ts=$(echo "$f" | awk '{print $1}')
			last=$(fmt_day "$last_ts" 2>/dev/null); fi
	fi
	recent=$([ "$last_ts" -gt 0 ] 2>/dev/null && [ $(( (now - last_ts) / 86400 )) -le 4 ] && echo yes || echo no)

	case "$dirty" in wip:*) bucket=hold-wip ;; *)
		case "$pr" in */open|*/draft) bucket=hold-open-pr ;; *)
			# Safe only when the work is in the base or a merged PR, and no local
			# commit is missing from the remote. A closed, unmerged PR is review.
			if [ "$recent" = yes ]; then bucket=verify-recent-chat
			elif case "$remote" in ahead*) true ;; *) false ;; esac; then bucket=review
			elif [ "$merged" = YES ]; then bucket=safe
			elif case "$pr" in */merged) true ;; *) false ;; esac; then bucket=safe
			else bucket=review; fi ;;
		esac ;;
	esac

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
		"$size" "$age" "$merged" "$dirty" "$remote" "$pr" "$last" "$bucket" "$wt"
done | if [ "$sizes" -eq 1 ]; then sort -t$'\t' -k1,1 -rh; else sort -t$'\t' -k2,2 -rn; fi

