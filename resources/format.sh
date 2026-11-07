#!/usr/bin/env bash
# Replace with the project formatter. Called as: scripts/format <file>
set -euo pipefail
file="${1:-}"
[ -n "$file" ] || exit 0
# npx prettier --write "$file"
# black "$file"
exit 0
