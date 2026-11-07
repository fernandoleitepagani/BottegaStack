#!/usr/bin/env bash
# App/browser verification driver.
# Usage: ./scripts/verify doctor|start|stop|snapshot|screenshot|flow <name>
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-$((5100 + ($(printf '%s' "$ROOT" | cksum | awk '{print $1}') % 400)))}"
CONF="$ROOT/scripts/verify.conf"
# shellcheck disable=SC1090
[ -f "$CONF" ] && . "$CONF"
PORT="${PORT:-$((5100 + ($(printf '%s' "$ROOT" | cksum | awk '{print $1}') % 400)))}"
BASE_URL="${READY_URL:-http://localhost:$PORT}"
export PORT BASE_URL
PIDFILE="${PIDFILE:-/tmp/pagani-verify-$PORT.pid}"
LOGFILE="${LOGFILE:-/tmp/pagani-verify-$PORT.log}"
SESSION="${SESSION:-pagani-verify-$PORT}"
TIMEOUT="${READY_TIMEOUT:-60}"

is_up() {
  curl -fsS -o /dev/null --max-time 2 "$BASE_URL" >/dev/null 2>&1
}

require_up() {
  if ! is_up; then
    echo "app is not up at $BASE_URL; run: scripts/verify start" >&2
    exit 1
  fi
}

case "${1:-doctor}" in
  doctor)
    echo "root: $ROOT"
    echo "config: $CONF $([ -f "$CONF" ] && echo '(found)' || echo '(missing)')"
    echo "port: $PORT"
    echo "url: $BASE_URL"
    echo "start cmd: ${START_CMD:-<not set>}"
    command -v curl >/dev/null 2>&1 && echo "curl: yes" || echo "curl: no"
    command -v agent-browser >/dev/null 2>&1 && echo "agent-browser: yes" || echo "agent-browser: no (npm install -g agent-browser)"
    ;;
  start)
    if [ -z "${START_CMD:-}" ]; then
      echo "START_CMD is not set in scripts/verify.conf" >&2
      exit 1
    fi
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      echo "already running (pid $(cat "$PIDFILE")) at $BASE_URL"
      exit 0
    fi
    echo "starting: $START_CMD"
    (cd "$ROOT" && bash -lc "$START_CMD") >"$LOGFILE" 2>&1 &
    echo $! >"$PIDFILE"
    for _ in $(seq 1 "$TIMEOUT"); do
      if is_up; then
        echo "up: $BASE_URL (pid $(cat "$PIDFILE"), log $LOGFILE)"
        exit 0
      fi
      sleep 1
    done
    echo "failed to start within ${TIMEOUT}s; log: $LOGFILE" >&2
    tail -40 "$LOGFILE" >&2 || true
    exit 1
    ;;
  stop)
    if [ -f "$PIDFILE" ]; then
      pid="$(cat "$PIDFILE")"
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      rm -f "$PIDFILE"
      echo "stopped (pid $pid)"
    else
      echo "no pid file at $PIDFILE"
    fi
    ;;
  snapshot)
    require_up
    agent-browser --session "$SESSION" open "$BASE_URL"
    agent-browser --session "$SESSION" snapshot
    ;;
  screenshot)
    require_up
    agent-browser --session "$SESSION" screenshot "${2:-/tmp/pagani-verify-$PORT.png}"
    ;;
  flow)
    name="${2:?flow name required}"
    require_up
    flow="$ROOT/docs/verify/flows/$name.sh"
    if [ ! -x "$flow" ]; then
      echo "flow not found or not executable: $flow" >&2
      exit 1
    fi
    if "$flow"; then
      echo "FLOW: PASS ($name)"
    else
      echo "FLOW: FAIL ($name)"
      exit 1
    fi
    ;;
  *)
    echo "unknown command: $1" >&2
    exit 1
    ;;
esac
