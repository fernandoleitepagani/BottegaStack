# Final gate

Read at the start of every `/implement` run (and every unattended unit), and do these steps before its final report. The light route skips this file. Read-only work (explore, prototype) skips the ledger and the check script, and still states its evidence in the reply.

`<maestro dir>` is the absolute directory of the maestro `SKILL.md`, and `<skills dir>` is its parent.

## 0. Open the run before your first edit or spawn

```bash
<maestro dir>/scripts/bottega start "<goal>" --risk <normal|high> \
  --condition "<acceptance condition>" --condition "<next condition>"
```

(`bottega start` wraps `gate-check.sh --start`.) This writes the `run` row with its risk, one `condition` row each, and a snapshot of the tree. An edit made before it is part of the snapshot, so the changed-files check can't see it. A condition found later goes in with `--condition` on the final call. Every declared condition needs a `--proof` row with the same text, word for word.

## 1. Run checks, log proofs, and check the gate in one call

```bash
<maestro dir>/scripts/bottega verify --check "<test/lint cmd>" [--check "<next cmd>"] --risk <normal|high> \
  --expect "<file or glob the change is meant to touch>" --expect "<dir>/" \
  --proof "<acceptance condition>" "<command run, file:line, or commit>" <PASS|FAIL|INCONCLUSIVE|WAIVED> \
  --proof "<next condition>" "<evidence>" <RESULT>
```

(`bottega verify` sends raw check output to `.bottega/last-verify.log`, prints a compact pass/fail summary, and calls `gate-check.sh` in the same turn.) Run it from the checkout that holds the change.

- **Expect.** One `--expect` per file or directory the change is meant to touch. Every file the run changed (edits, new files, deletions, commits since `--start`) must match one. Revert a stray file, or delete what a check left behind (such as `__pycache__/`), rather than declaring it. Files already dirty before the run and left alone don't count. A glob's `*` also matches `/`, so `--expect "*.md"` covers `docs/x.md`; use a directory (`docs/`) when that's what you mean.
- **Proof.** One `--proof` per declared condition, with its exact text. Only a condition's latest proof counts, so after a fix round log the new result for the same condition. A WAIVED row's evidence starts with `user:` and quotes the user's words, for example `"user: \"skip the docs check\""`. Never waive on your own.
- **Exit 0** allows APPROVE. **Exit 1** means ESCALATE: a latest proof is FAIL or INCONCLUSIVE, or crossfire's latest verdict is not PASS. **Exit 2** means a step is missing: do it, then rerun without repeating the proofs already logged. Never end a run on exit 2. A missing crossfire row means run the adversarial review.

At high risk (from `--start` or this call), run the adversarial review (`review.md`) on the finished diff first. It logs the `crossfire` row. To log a row by hand, use `<maestro dir>/scripts/log.sh .bottega/proofs.tsv proof "<condition>" "<how>" "<evidence>" <RESULT>`.

## 2. Write the decision

Write it as the first block of the report:

- **Decision.** APPROVE or ESCALATE, and one sentence why.
- **Evidence.** Each acceptance condition with the command run and its output, or the verdict that covers it.
- **Open risks.** What is unproven and who would notice.
- **Needs from you.** Only for ESCALATE: the exact decision, with the options.

ESCALATE when the check exits 1, the fix-round cap was hit, or a high-risk finding is unresolved. ESCALATE stops before marking a PR ready or merging. An Unattended run may push draft branches earlier.

## 3. Close out

Unless the user already said what to do, end with one line: `Next: open a PR, commit only, rework <what>, or reject. Reply with one.` An unattended run skips it and follows its own merge rules. When `.bottega/followups.md` has unchecked lines, list them in one line and offer to file them as issues (`gh issue create`, after one confirmation).

## 4. Opening a PR

All PR creation, watching, and landing live in `../../ship/SKILL.md` (`/ship stop` for a Draft PR, `/ship full` for a Ready PR + CI/review watching + merge). On `open a PR`, invoke `/ship`.
