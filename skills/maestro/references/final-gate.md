# Final gate

Read at the start of every playbook run, and do these steps before its final report. The light route skips this file. Read-only playbooks (Investigation, Forensics, Prototype) skip the ledger and the check script, and still state their evidence in the reply.

`<maestro dir>` is the absolute directory of the maestro `SKILL.md`, and `<skills dir>` is its parent.

## 0. Declare the acceptance conditions when the run opens

```bash
<maestro dir>/scripts/gate-check.sh --start "<goal>" \
  --condition "<acceptance condition>" --condition "<next condition>"
```

This writes the `run` row and one `condition` row each, and snapshots the tree. Run it before your first edit or spawn: an edit made before it is part of the snapshot, so the changed-files check can't see it. A condition found later goes in with `--condition` on the final call. Every declared condition needs a `--proof` row with the same text, word for word, or the check exits 2.

## 1 and 2. Log the proofs and check the gate, in one call

```bash
<maestro dir>/scripts/gate-check.sh --risk <normal|high> \
  --expect "<file or glob the change is meant to touch>" --expect "<dir>/" \
  --proof "<acceptance condition>" "<command run, file:line, or commit>" <PASS|FAIL|INCONCLUSIVE|WAIVED> \
  --proof "<next condition>" "<evidence>" <RESULT>
```

Run it from the checkout that holds the change. One `--expect` per file or directory the change is meant to touch: in a git repo the check lists every file the run changed (edits, new files, and commits since `--start`) and exits 2 on any that no `--expect` covers. Revert a stray file, or delete what a check left behind (such as `__pycache__/`), rather than declaring it; declare it only when the change needs it. Files already dirty before the run and left alone don't count. One `--proof` per declared condition, with its exact text. Only a condition's latest proof row counts, so after a fix round log the new result for the same condition; the old row stays as history. The script logs each row to `.bottega/proofs.tsv` and then checks this run's rows (those after the `run` row that `--start` wrote; with no `run` row it exits 2). A two-line change gets rows too. Size is never a reason to skip this call: it is one command, and the rows are what let the user trust the result without rereading the diff. A WAIVED row's evidence starts with `user:` and quotes the user's words, for example `"user: \"skip the docs check\""`; the script refuses one without it. Never waive on your own.

Exit 0 allows APPROVE. Exit 1 means ESCALATE: a row is FAIL or INCONCLUSIVE, or crossfire's latest verdict is anything but PASS. Exit 2 means a step is missing (no `run` row, no declared condition, a condition with no proof, a waiver without the user's words, a changed file outside `--expect`, or no crossfire row at high risk): do it now, then rerun without repeating the `--proof` rows already logged. Never end a run on exit 2: a missing crossfire row means run crossfire, not report "not approved yet". Never APPROVE without an exit 0.

At high risk, run the crossfire skill on the finished diff first. It logs its own `crossfire` row, and the check requires it. If you think crossfire is overkill for a change this small, run it anyway and say so in the reply. To log a row by hand, use `<skills dir>/show-me-your-work/scripts/log.sh .bottega/proofs.tsv proof "<condition>" "<how>" "<evidence>" <RESULT>`.

## 3. Write the decision

Write it as the first block of the report, before opening a PR, or before the final report when there is no PR:

- **Decision.** APPROVE or ESCALATE, one sentence why, and the last line `gate-check.sh` printed (`gate-check: ...`), quoted.
- **Evidence.** Each acceptance condition with the command run and its output, or the verdict that covers it. Take it from the ledger. A condition with no row counts as missing.
- **Open risks.** What is unproven and who would notice.
- **Needs from you.** Only for ESCALATE: the exact decision, with the options.

ESCALATE when any condition lacks evidence, the fix-round cap was hit, a high-risk finding is unresolved, a verdict is `inconclusive`, or `gate-check.sh` exits 1. ESCALATE stops before marking a PR ready or merging. Autopilot playbooks may push draft branches earlier. APPROVE continues to Opening a PR.

## 4. Ask what to do with the work

Ask the user once with `AskUserQuestion`: open a PR (continues to Opening a PR), commit only (local commit, no push), rework (name what to change, then back to the playbook), or reject (leave the worktree for the user to discard; delete nothing). When `AskUserQuestion` is unavailable, ask in the reply instead, listing the four options by name. Skip the question when the user already said what to do, or in an autopilot, autonomous-run, or babysit playbook, which follow their own merge rules.

When `.bottega/followups.md` has unchecked lines, end the reply with one line offering the **file-followups** skill.
