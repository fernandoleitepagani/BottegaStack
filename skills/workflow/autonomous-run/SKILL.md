---
name: autonomous-run
description: Drive one task to a checkable exit condition without supervision, one verified change per iteration, logging each. Run only when the user asks for it (autonomous run, work on this while I'm away).
disable-model-invocation: true
---

# Autonomous run

Adapted from pstack's `autonomous-run` (Lauren Tan, MIT). You own the exit condition: define done, then drive to it. This is one task to one predicate; a queue of items is `autopilot`. Track the loop in the todo list: one item, "Iterate until the exit condition or the cap", stays open so the Stop hook keeps you going.

## 1. Agree the contract

Do not start until the user has confirmed these with `AskUserQuestion`:

- **Goal** in one line.
- **Exit condition:** a command and the exact output or exit code that means done (`npm test` exits 0, `grep -rn oldApi src | wc -l` prints 0). The same shape as a `Proof:` line. No checkable condition means the task is not ready; say so and stop.
- **Allowed files:** the paths you may change. Needing another is a stop.
- **Caps:** a maximum number of iterations (default 20) and a wall-clock limit. They are the only brake besides the 30-minute build timeout.
- **Scope:** the branch you are on, committing locally; never push, merge, or open a PR.

Run `./scripts/check` and the exit condition once first and record the baseline.

## 2. Loop

Each iteration, in order:

1. Pick the smallest change the evidence justifies, citing what the last check showed.
2. Run `maestro build --here <slug> --task "<change>" --block`. One change per iteration; never batch untested changes.
3. Run `./scripts/check`, then the exit condition.
4. If the check fails or the condition did not move, undo it with `git revert --no-edit <commit>` (never `reset --hard` or `clean`); a change that "might help" is not kept.
5. Log one row: `maestro log <slug> "iter <n>" "<change>" "<why>" "<commit or output path>" "<condition now: ...>"` (load `show-me-your-work`).

Mid-run discoveries that serve the goal (a flaky check, a related bug) are yours: fix them in the same loop, in their own commit. Surface only irreversible actions, product calls no experiment settles, or a real dead end.

## 3. Stop

- **Done:** the exit condition passes on the final HEAD and `./scripts/check` is green.
- **Cap or dead end:** stop at the iteration or time cap, or when the same failure survives two different approaches. Report why; never relax the condition to claim success.
- **Plateau is not a stop.** After several rejected iterations, change approach (a different cause, re-read the source, a larger step) before concluding.
- A builder that returns `BLOCKED` stops the run; ask.

Never weaken, skip, or delete a test to move the condition. Treat that as a failed iteration.

## 4. Reply

The goal, the condition and its final state, iterations run, what was kept and what was reverted, the branch and commits, the cap used, and `maestro log <slug>` output. Close the loop todo item, run `maestro report --close <slug> --playbook autonomous-run --risk <r> --outcome <done|capped|stopped>`, load `ketchup` if the user was away, and end on a ready local branch.

## Gotchas

- Starting without a command-checkable exit condition.
- Relaxing the condition after a plateau.
- Several changes in one iteration, so you cannot tell which helped.
- Reverting with `reset --hard`. Use `git revert`.
- Running past the cap, or pushing "to finish".
