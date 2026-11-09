#!/usr/bin/env bash
# Append one line per hook firing. PROTOTYPE_HOOK_LOG is inherited from the
# session environment; fall back to a temp file so a run never fails.
set -euo pipefail
log="${PROTOTYPE_HOOK_LOG:-${TMPDIR:-/tmp}/pagani-prototype-hooks.log}"
printf '%s %s\n' "${1:-unknown}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$log"
