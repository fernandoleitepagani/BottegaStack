#!/usr/bin/env bash
# The feature-fix scenario passed when both the feature and the revision's file
# are present and the check passes.
set -eu
. "$BOTTEGA_LAB_ROOT/lab/assert.sh"

assert_eq "feature file" feature "$(cat feature.txt)"
assert_eq "revision file" fixed "$(cat fixed.txt)"
assert "check passes" bash scripts/check
