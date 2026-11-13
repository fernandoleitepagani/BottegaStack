#!/usr/bin/env bash
# The pause-resume scenario passed when the paused close is in the trust log,
# the resume cleared the marker, and the final close removed the run state.
set -eu
. "$BOTTEGA_LAB_ROOT/lab/assert.sh"

log="$(find "$BOTTEGA_STATE_DIR" -name trust.log -type f | head -1)"
[ -n "$log" ] || fail "no trust log"
assert "paused close recorded" grep -q lab-pause-resume "$log"
awk -F'\t' '$2 == "lab-pause-resume" && $7 == "paused" { found = 1 } END { exit !found }' "$log" \
  || fail "no paused outcome for lab-pause-resume"
assert "paused marker cleared" test -z "$(find "$BOTTEGA_STATE_DIR" -name paused -type f | head -1)"
assert "run state closed" test -z "$(find "$BOTTEGA_STATE_DIR" -type d -name lab-pause-resume | head -1)"
