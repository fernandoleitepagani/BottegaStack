#!/usr/bin/env bash
# Install PaganiStack into Claude Code.
# Install logic lives in bin/pagani-setup (not installed).
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin/pagani-setup" install "$@"
