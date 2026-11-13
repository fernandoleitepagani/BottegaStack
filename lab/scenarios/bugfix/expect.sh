#!/usr/bin/env bash
# The bugfix scenario passed when answer.sh prints 4 and the check passes.
set -eu
. "$BOTTEGA_LAB_ROOT/lab/assert.sh"

assert_eq "answer is 4" 4 "$(bash answer.sh)"
assert "check passes" bash scripts/check
