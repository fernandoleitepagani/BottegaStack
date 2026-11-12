#!/usr/bin/env bash
# The trivial scenario passed when the builder's line is committed and the
# project check passes.
set -eu
. "$BOTTEGA_LAB_ROOT/lab/assert.sh"

assert "greeting has bye" grep -qx bye greeting.txt
assert "check passes" bash scripts/check
