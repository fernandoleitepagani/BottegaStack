#!/usr/bin/env bash
# Claude Code hook helper: format, skill-usage logging, PreCompact handoff, and
# the opt-in WebFetch network allowlist guard.
# Every subcommand is best-effort and exits 0 so it never breaks a tool call.
set -euo pipefail

# Read the hook payload once. Hooks always pipe JSON on stdin; a TTY means a
# human is running the script by hand, so do not block waiting for EOF.
if [ -t 0 ]; then
  input=""
else
  input="$(cat || true)"
fi

# Extract a dotted field from a JSON string. Uses python3 when available and
# falls back to a sed scan of the last path component.
json_field() {
  local json="$1" path="$2"
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$json" | python3 -c '
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
    printf '%s' "$json" | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1 || true
  fi
}

# Resolve the project directory. The hook payload's `cwd` follows Claude into a
# worktree while CLAUDE_PROJECT_DIR stays at the original checkout, so `cwd`
# wins. Fall back to CLAUDE_PROJECT_DIR, then the shell's PWD.
json_cwd="$(json_field "$input" cwd || true)"
if [ -n "$json_cwd" ]; then
  project_dir="$json_cwd"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  project_dir="$CLAUDE_PROJECT_DIR"
else
  project_dir="$PWD"
fi

usage() {
  cat >&2 <<'EOF'
usage: claude-hook.sh <command>

commands:
  format                  format the file in .tool_input.file_path
  precompact              snapshot the newest job into handoff.md
  webfetch-guard          deny WebFetch hosts missing from the allowlist
EOF
}

iso_date() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown"
}


cmd_format() {
  local file formatter
  file="$(json_field "$input" tool_input.file_path || true)"
  [ -n "$file" ] || return 0
  formatter="$project_dir/scripts/format"
  if [ -x "$formatter" ]; then
    if ! "$formatter" "$file"; then
      echo "pagani: formatter failed for $file; edit kept" >&2
    fi
  fi
  return 0
}



# Print the host from a URL. python3 handles credentials, ports, and IPv6;
# sed is the fallback.
url_host() {
  local url="$1"
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$url" | python3 -c '
import sys
from urllib.parse import urlparse
try:
    print(urlparse(sys.stdin.read().strip()).hostname or "")
except Exception:
    print("")
' || true
  else
    printf '%s' "$url" | sed -E \
      -e 's|^[a-zA-Z][a-zA-Z0-9+.-]*://||' \
      -e 's|[/?#].*||' \
      -e 's|^[^@]*@||' \
      -e 's|:[0-9]+$||' || true
  fi
}

# Opt-in WebFetch guard. No allowlist means allow. Otherwise allow exact host
# matches and `*.suffix` wildcard matches; deny everything else with the hook
# JSON payload.
cmd_webfetch_guard() {
  local allowlist="$project_dir/pagani/network-allowlist.txt"
  [ -f "$allowlist" ] || return 0

  local url host
  url="$(json_field "$input" tool_input.url || true)"
  [ -n "$url" ] || return 0

  host="$(url_host "$url")"
  host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')"
  [ -n "$host" ] || return 0

  local line suffix matched=0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
    [ -n "$line" ] || continue
    if [ "$line" = "$host" ]; then
      matched=1
      break
    fi
    case "$line" in
      \*.*)
        suffix="${line#\*}"
        case "$host" in
          *"$suffix")
            matched=1
            break
            ;;
        esac
        ;;
    esac
  done <"$allowlist"

  if [ "$matched" -eq 1 ]; then
    return 0
  fi

  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"pagani: host %s not in pagani/network-allowlist.txt"}}\n' "$host"
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
  precompact)
    cmd_precompact
    ;;
  webfetch-guard)
    cmd_webfetch_guard
    ;;
  *)
    usage
    exit 1
    ;;
esac

exit 0
