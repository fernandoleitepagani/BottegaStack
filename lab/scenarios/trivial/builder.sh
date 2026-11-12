#!/usr/bin/env bash
# Stub builder side effect for the trivial scenario: add the line and commit.
set -eu

printf 'bye\n' >> greeting.txt
git add greeting.txt
git commit -q -m "lab: add bye"
