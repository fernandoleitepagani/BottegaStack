#!/usr/bin/env bash
# One-line install, no clone, no git:
#   curl -fsSL https://raw.githubusercontent.com/fernandoleitepagani/PaganiStack/main/get.sh | bash
#   curl -fsSL .../get.sh | bash -s -- --dry-run
# Env: PAGANI_REF (branch or tag, default main).
set -euo pipefail

missing=""
for c in curl tar; do command -v "$c" >/dev/null 2>&1 || missing="$missing $c"; done
if [ -n "$missing" ]; then echo "pagani get: missing required tool(s):$missing" >&2; exit 1; fi

# PAGANI_TARBALL_URL is a test override (may be a file:// URL).
url="${PAGANI_TARBALL_URL:-https://github.com/fernandoleitepagani/PaganiStack/archive/refs/heads/${PAGANI_REF:-main}.tar.gz}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "fetching: $url"
curl -fsSL "$url" | tar xz --strip-components=1 -C "$tmp"
# The recorded source lets `pagani upgrade --self` work with no --from.
PAGANI_SOURCE="$url" bash "$tmp/bin/pagani" install --yes "$@" </dev/null
