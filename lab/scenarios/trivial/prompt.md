BottegaStack lab scenario: trivial. Work non-interactively; never ask the user
anything and never push, merge, or open a PR.

Use the light path (no run and no SPEC):

1. Run `maestro build --here lab-trivial --task "Append a line 'bye' to greeting.txt" --block`.
2. Run `bash scripts/check`.
3. Finish with a one-line summary.
