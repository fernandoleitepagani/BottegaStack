---
name: arena
description: Give one task to several headless builders in separate worktrees, have a judge score them blind against a hidden rubric, pick a base and graft the best parts of the others. Run only when the user asks for it (arena this).
disable-model-invocation: true
---

# Arena

Adapted from pstack's `arena` (Lauren Tan, MIT). Use it when one attempt at a non-trivial artifact would lock in the wrong shape and the user wants real alternatives to compare. It costs about N times one build, so run 2 or 3 candidates, not more. Track the phases in the todo list: Frame, Fan out, Judge, Pick, Graft, Verify.

## 1. Frame

Every candidate gets the same prompt, so the prompt is the contract.

1. State the artifact each candidate produces.
2. Write the rubric: 3 to 6 concrete, gradable criteria for success on this task. It is for the judge and for you; candidates see only the task.
3. Run `maestro start "<title>"` on the user's branch. Save a SPEC with one task per candidate, each task identical (`### Task 1`, `### Task 2`, ...) with the same `Allowed files`, `Test first`, and `Done when`, and ask each builder to end its report with the alternatives it considered and rejected. `maestro spec <slug>` extracts them.

## 2. Fan out

For each task: `maestro worktree create <slug> <n>`, then `maestro build <slug> <n> --block` as background Bash tasks, at most 3 at once, on the headless builder model. Each candidate has its own worktree and branch; none shares a working directory. A candidate that produces nothing drops out; continue with the rest and say so. If the user asks for a different-family candidate, add one `general-purpose` subagent with `isolation: "worktree"` on a Claude model.

## 3. Judge

After all candidates finish, spawn one read-only subagent on the `reviewer` model from `~/.claude/rules/bottega-models.md` (default `sonnet`). It gets the rubric and each candidate as `candidate-1`, `candidate-2`, ... with its diff (`git diff <base>...<branch>`), never branch names that reveal the model. It scores each criterion per candidate and recommends a base with its reasoning. Do not spawn it while a candidate is still writing.

## 4. Pick a base

Read every candidate end to end before choosing, and score each criterion yourself. Compare with the judge: agreement confirms the pick; disagreement means one of you is biased or the rubric was ambiguous, so read both rationales. Prefer the base a future maintainer can extend most easily without breaking invariants; when two are tied, prefer the cleaner boundary or smaller interface.

## 5. Graft

Walk each losing candidate once more for what is worth porting, usually one or two things each. The master does not write code: hand each approved graft to a builder working in the base worktree, so the result stays coherent under one mental model. If the candidates converge on one shape, note the agreement and ship it with no graft. If they diverge wildly, the prompt was under-specified: reframe and re-run instead of averaging.

## 6. Verify

Run `maestro check <slug>` and the normal review path on the chosen branch; the winner is not approved by the arena alone. Merge only the chosen branch into the run branch. `maestro worktree prune` keeps unmerged candidate branches; list them and ask before deleting any.

## Reply

The task, the rubric, each candidate's tokens and steps, the judge's scores, the base chosen and why, what was grafted from each, what was rejected, and the branches left to delete.

## Gotchas

- Telling candidates the rubric or that others exist.
- Letting the judge see model or branch names.
- More than 3 candidates, or candidates that share a worktree.
- Picking by overall feel instead of criterion by criterion.
- Treating the arena's winner as approved without the checks and review.
