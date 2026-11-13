BottegaStack lab scenario: feature-fix. Risk low. Work non-interactively; never
ask the user and never push, merge, or open a PR.

1. Run `maestro build --here lab-feature-fix --task "Add feature.txt containing feature" --block`.
2. Use the Write tool to save this finding to `$TMPDIR/lab-findings.txt`:
   "scripts/check also requires fixed.txt containing fixed; add it."
3. Send it back as a revision:
   `maestro build --here lab-feature-fix --revise "$TMPDIR/lab-findings.txt" --block`.
4. Run `./scripts/check`.
5. Finish with a one-line summary.
