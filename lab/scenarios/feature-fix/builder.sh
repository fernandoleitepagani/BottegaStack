#!/usr/bin/env bash
# Stub builder side effect for the feature-fix scenario. The first build adds
# the feature; the revision (the prompt names a Revision) adds the missing file.
set -eu

case "${BOTTEGA_LAB_PROMPT:-}" in
  *Revision*) printf 'fixed\n' > fixed.txt ;;
  *) printf 'feature\n' > feature.txt ;;
esac
git add -A
git commit -q -m "lab: builder change"
