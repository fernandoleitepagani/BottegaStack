#!/usr/bin/env bash
# Install PaganiStack into OpenCode and/or Claude Code.
# All logic lives in bin/pagani so the same CLI can be used after install.
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin/pagani" install "$@"
