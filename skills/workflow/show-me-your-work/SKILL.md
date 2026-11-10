---
name: show-me-your-work
description: Keep a reviewable decision trail for long-running or unattended work (autopilot, multi-phase runs, anything a human reviews after stepping away): one row per decision with what, why, evidence, and result. Use when the user asks for a decision log or an audit of what an agent did.
---

# Show me your work

One decision log per run, one row per decision. Adapted from pstack's `show-me-your-work` (Lauren Tan, MIT).

## The log

A TSV in the state directory outside the repo: `$STATE/decisions/<run>.tsv`. It survives `maestro report --close` and is cleared with the temp dir. Columns:

- **ts:** UTC timestamp, written for you.
- **phase:** the phase or workstream.
- **decision:** what was chosen or done, one line.
- **why:** the reason in plain words.
- **evidence:** a pointer that proves it: commit SHA, `file:line`, a path to output. Never a paragraph.
- **result:** the outcome or predicate state: `tests green`, `reverted`, `INCONCLUSIVE`, `open`.

## Write a row

```bash
maestro log <run> "<phase>" "<decision>" "<why>" "<evidence>" "<result>"
maestro log <run>        # print the log as a table
```

The command strips tabs and newlines and quotes a cell that starts with `=`, `+`, `-`, or `@`, because evidence can come from untrusted text. Write each row the way you would tell a teammate what you did: plain words, concrete actions (load `unslop`). Log decision points and checkpoints, not every action: a fork chosen, a unit done with its check result, a pivot or revert with its trigger, a blocker, a gate. In a loop, one row per iteration. Append only: a wrong call gets a new row that supersedes it.

## Audit before you hand back

1. Walk the rows against what happened. Each row maps to a real action, and its evidence resolves and shows what the row claims. A fork or abandoned approach that shaped the work but is missing is a gap: add a row. Never edit or delete a row.
2. Spawn one reviewer subagent on a different model from the one that did the work (the `reviewer` line of the model rule, or the headless `second-opinion`). It reads the log and the run's transcript (`~/.claude/projects/<repo-slug>/<session>.jsonl`, this run only) and flags weak or missing evidence, checks skipped or claimed without proof, risky choices, and gaps a casual skim would miss.
3. End the reply with an **Attention** section: `reviewed by <model>`, then each flag pointing at specific rows. "No flags" is a valid result.

## Gotchas

- Logging every action. Keep it to decisions.
- Prose in the evidence cell. Use a pointer.
- Editing history. Supersede with a new row.
- Skipping the audit or the cross-model review.
