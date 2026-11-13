BottegaStack lab scenario: bugfix. Risk low. Work non-interactively; assume the
SPEC is approved, never ask the user, and never push, merge, or open a PR.

The bug: `answer.sh` prints 3, but `scripts/check` expects 4.

1. Run `maestro build --here lab-bugfix --task "Change answer.sh to print 4 so scripts/check passes" --block`.
2. Run `./scripts/check`.
3. Finish with a one-line summary.
