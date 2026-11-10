---
name: correct
description: Find the mistakes agents keep repeating in a project and make each one impossible. Fix at the highest level that works (architecture, types, a lint whose error names the fix, a test) and write docs last. Use when the same review finding appears twice, the retro scan exits 1, or the user corrects the agent for a repeat.
---

# Correct

Adapted from pstack's `correct` (Lauren Tan, MIT). The same mistake keeps coming back. Change the project so the next agent cannot make it. Assume every contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that compiles.

## Find the classes

Read recent commits, reverts, review findings, `mistakes.md`, `AGENTS.md`, and comments that explain a workaround, plus `maestro report --retro` output. Group the mistakes into classes. A class counts once it has happened twice.

## Fix each class at the highest level that works

1. **Architecture.** Give each piece of state one owner and each task one supported way. Hide internals so the wrong import fails. Replace hand-synced lists with one source of truth. Delete old ways and dead code an agent would copy.
2. **Types and lint.** Make bad state unrepresentable. If bad code still compiles, add a lint or `scripts/check` rule whose error names the file, type, or function to use instead. If the pattern is already common, fail only when a change adds more.
3. **Test.** Fix or delete a test that still passes when the behavior breaks, or fails when only internals change.
4. **Docs or rules last,** only for judgment calls nothing can fail on. One line in `AGENTS.md` or `mistakes.md`.

## Fix and prove

The master proposes each class with its evidence and the level it picked, and asks with `AskUserQuestion` before changing project code or lint config. A builder implements the approved fixes through the light path, one commit per class. Each new check must fail on a real past mistake: show the failing run, then the passing one. Run the same check locally and in CI. An exception goes on the offending line with a reason, an expiry date, and a human's approval.

## Keep the rule table

Keep a table in the project's `AGENTS.md` pairing each rule with what enforces it (`lint: no-direct-fetch`, `test: ...`, `type: ...`). When the user corrects you, fix the mistake and add the rule. A rule that is already there with nothing enforcing it is a repeat: fix it at the highest level in the same change. Drop a rule once its mistake cannot happen.

## Reply

Each class with its evidence, the level chosen, and why a higher level did not work.

## Gotchas

- Writing a doc line because it is cheapest. Docs are the last resort.
- A check never shown failing on a real past mistake.
- A lint error that says "don't" without naming the fix.
- Editing lint config or project code without approval.
