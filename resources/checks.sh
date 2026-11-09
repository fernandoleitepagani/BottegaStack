#!/usr/bin/env bash
# Deterministic checks for this project.
# Exit 0 only when the branch is fit to review.
# Keep it fast, deterministic, and non-interactive.
set -euo pipefail

echo "scripts/check is not configured yet: put this project's real commands here." >&2
echo "Example:" >&2
echo "  npm ci --prefer-offline" >&2
echo "  npm run lint" >&2
echo "  npm run typecheck" >&2
echo "  npm test -- --run" >&2
echo "  npm run build" >&2
exit 1
