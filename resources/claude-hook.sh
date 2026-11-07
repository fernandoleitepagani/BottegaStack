#!/usr/bin/env bash
# Claude Code hook helper: format, skill-usage logging, and PreCompact handoff.
# Every subcommand is best-effort and exits 0 so it never breaks a tool call.
set -euo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"

usage() {
  cat >&2 <<'EOF'
usage: claude-hook.sh <command>

commands:
  format                  format the file in .tool_input.file_path
  skill-log               log the skill name from stdin JSON
  precompact              snapshot the newest job into handoff.md
  skill-log-name <name>   log a skill name without stdin
EOF
}

# Extract a dotted field from JSON on stdin. Uses python3 when available and
# falls back to a sed scan of the last path component.
json_field() {
  local path="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
path = sys.argv[1].split(".")
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for key in path:
    if isinstance(data, dict):
        data = data.get(key)
    else:
        data = None
        break
if data is None:
    sys.exit(0)
print(data if isinstance(data, str) else str(data))
' "$path" || true
  else
    local key="${path##*.}"
    sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1 || true
  fi
}

iso_date() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown"
}

record_skill() {
  local skill="$1"
  local dir="$project_dir/pagani"
  mkdir -p "$dir" 2>/dev/null || true
  printf '%s\t%s\t%s\n' "$(iso_date)" "$(basename "$project_dir")" "$skill" \
    >>"$dir/skill-usage.tsv" 2>/dev/null || true
}

cmd_format() {
  local input file formatter
  input="$(cat || true)"
  file="$(printf '%s' "$input" | json_field tool_input.file_path || true)"
  [ -n "$file" ] || return 0
  formatter="$project_dir/scripts/format"
  if [ -x "$formatter" ]; then
    if ! "$formatter" "$file"; then
      echo "pagani: formatter failed for $file; edit kept" >&2
    fi
  fi
  return 0
}

cmd_skill_log() {
  local input skill key
  input="$(cat || true)"
  skill=""
  for key in tool_input.skill tool_input.name tool_input.command tool_name; do
    skill="$(printf '%s' "$input" | json_field "$key" || true)"
    [ -n "$skill" ] && break
  done
  [ -n "$skill" ] || skill="unknown"
  record_skill "$skill"
  return 0
}

cmd_skill_log_name() {
  local skill="${1:-unknown}"
  [ -n "$skill" ] || skill="unknown"
  record_skill "$skill"
  return 0
}

job_field() {
  local file="$1" key="$2"
  sed -n "s/^${key}:[[:space:]]*//p" "$file" 2>/dev/null | head -n1 || true
}

newest_job() {
  local f newest=""
  for f in "$project_dir"/pagani/jobs/*/job.md; do
    [ -e "$f" ] || continue
    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then
      newest="$f"
    fi
  done
  [ -n "$newest" ] && printf '%s\n' "$newest"
}

write_snapshot() {
  local handoff="$1" job="${2:-}"
  local stage="unknown" lane="unknown" branch="unknown"
  if [ -n "$job" ]; then
    stage="$(job_field "$job" Stage)"
    lane="$(job_field "$job" Lane)"
    branch="$(job_field "$job" Branch)"
  fi
  [ -n "$stage" ] || stage="unknown"
  [ -n "$lane" ] || lane="unknown"
  [ -n "$branch" ] || branch="unknown"
  mkdir -p "$(dirname "$handoff")" 2>/dev/null || true
  {
    printf '\n## PreCompact snapshot %s\n\n' "$(iso_date)"
    printf -- '- Stage: %s\n' "$stage"
    printf -- '- Lane: %s\n' "$lane"
    printf -- '- Branch: %s\n' "$branch"
    printf -- '- Resume with: /pagani resume\n'
  } >>"$handoff" 2>/dev/null || true
}

cmd_precompact() {
  local job handoff
  job="$(newest_job || true)"
  if [ -n "$job" ]; then
    handoff="$(dirname "$job")/handoff.md"
  else
    handoff="$project_dir/pagani/handoff.md"
  fi
  write_snapshot "$handoff" "${job:-}"
  return 0
}

sub="${1:-}"
case "$sub" in
  format)
    cmd_format
    ;;
  skill-log)
    cmd_skill_log
    ;;
  precompact)
    cmd_precompact
    ;;
  skill-log-name)
    shift || true
    cmd_skill_log_name "${1:-}"
    ;;
  *)
    usage
    exit 1
    ;;
esac

exit 0
