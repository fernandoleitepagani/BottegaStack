BottegaStack lab scenario: feature-fix. Risk low. Work non-interactively; never
ask the user and never push, merge, or open a PR.

1. Run `maestro build --here lab-feature-fix --task "Add feature.txt containing feature" --block`.
2. Send this finding back as a revision:
   `printf '%s\n' "scripts/check also requires fixed.txt containing fixed; add it." | maestro build --here lab-feature-fix --revise - --block`.
3. Run `bash scripts/check`.
4. Finish with a one-line summary.
