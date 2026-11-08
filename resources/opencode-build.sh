#!/usr/bin/env bash
# Run one PaganiStack builder task headless in OpenCode (DeepSeek via OpenCode Go).
# Claude (the master) drives; OpenCode only implements and reports back.
#
#   scripts/opencode-build <job> <task>                      first build
#   scripts/opencode-build <job> <task> --revise <findings>  resume with review findings
#
# Model and permissions come from the OpenCode `builder` agent (agents/opencode/
# builder.md, generated from agents/models.conf). Nothing is configured by env.
set -euo pipefail

usage() { echo "usage: scripts/opencode-build <job> <task> [--revise <findings-file>]" >&2; exit 2; }
[ "$#" -ge 2 ] || usage
job="$1"; task="$2"; shift 2
findings=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --revise) findings="${2:?findings file required}"; shift 2 ;;
    *) usage ;;
  esac
done

command -v opencode >/dev/null 2>&1 || { echo "opencode-build: opencode not installed" >&2; exit 3; }
repo="$(git rev-parse --show-toplevel)"
name="$(basename "$repo")"
jobdir="$repo/pagani/jobs/$job"
wt="$(cd "$repo/.." && pwd)/$name-pagani/$job/$task"
agent=builder
max_rev=2
report="$jobdir/build/$task.md"
wt_report="$wt/pagani/jobs/$job/build/$task.md"
state="$jobdir/build/$task.opencode"

[ -d "$jobdir" ] || { echo "opencode-build: no job folder $jobdir" >&2; exit 3; }
[ -f "$jobdir/SPEC.md" ] || { echo "opencode-build: $jobdir/SPEC.md missing" >&2; exit 3; }
[ -d "$wt" ] || { echo "opencode-build: no worktree $wt (run: pagani worktree create $job $task)" >&2; exit 3; }
mkdir -p "$jobdir/build"
branch="$(git -C "$wt" branch --show-current)"

if [ -n "$findings" ]; then
  [ -f "$state" ] || { echo "opencode-build: no session for $task; run a first build" >&2; exit 3; }
  [ -f "$findings" ] || { echo "opencode-build: findings file not found: $findings" >&2; exit 3; }
  sid="$(sed -n 's/^session=//p' "$state")"
  rev="$(sed -n 's/^revisions=//p' "$state")"; rev="${rev:-0}"
  if [ "$rev" -ge "$max_rev" ]; then
    echo "opencode-build: $max_rev revisions used; escalate to the human (workflow rule: max two fix rounds)" >&2
    exit 4
  fi
  rev=$((rev + 1))
  msg="Revision $rev for task $task. Fix every finding in $findings (read it first), nothing else. Same rules as before: stay inside Allowed files, do not edit or weaken tests, commit locally on $branch, never push or merge. Update the report $wt_report and keep its format."
  args=(--session "$sid")
else
  rev=0
  msg="Job folder: $jobdir
Task: $task
Worktree: $wt
Everything stays inside the worktree. Read the task from SPEC.md in the worktree root or $jobdir/SPEC.md.
Branch: $branch
Implement exactly this task from $jobdir/SPEC.md. Follow your builder instructions. Write the report to $wt_report (inside the worktree; it is gitignored, do not commit it). Commit locally on $branch. Never push or merge."
  args=()
fi

log="$jobdir/build/$task.opencode.log"
set +e
(cd "$wt" && opencode run --agent "$agent" --auto --format json \
  --title "pagani $job/$task" "${args[@]}" "$msg") > "$log" 2>&1
rc=$?
set -e
if [ -s "$wt_report" ]; then cp "$wt_report" "$report"; fi

sid="${sid:-$(grep -o '"sessionID":"[^"]*"' "$log" | head -1 | cut -d'"' -f4)}"
[ -n "$sid" ] && printf 'session=%s\nrevisions=%s\nagent=%s\n' "$sid" "$rev" "$agent" > "$state"

status="MISSING"
[ -s "$report" ] && status="$(grep -m1 -o 'STATUS: [A-Z_]*' "$report" || echo UNKNOWN)"
commits="$(git -C "$wt" log --oneline "pagani/$job..HEAD" 2>/dev/null | wc -l | tr -d ' ')"

echo "task: $task"
echo "session: ${sid:-none}"
echo "revisions: $rev/$max_rev"
echo "opencode exit: $rc"
echo "report: $report ($status)"
echo "commits on $branch: $commits"
echo "files changed:"; git -C "$wt" diff --name-only "pagani/$job...HEAD" 2>/dev/null | sed 's/^/  /'
[ "$rc" -eq 0 ] && [ "$status" != "MISSING" ] || exit 1
