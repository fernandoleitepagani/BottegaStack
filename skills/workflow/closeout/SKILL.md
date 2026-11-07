---
name: closeout
description: Handle the PaganiStack human decision and final git actions. Use after the approver writes decision.md, when the human chooses merge, commit, push, PR, rework, or reject.
---

# PaganiStack Closeout

The approver recommends. The human decides. You execute only what the human
explicitly asks for.

## Present

Show:

- the approver's decision and why,
- the acceptance-criteria mapping,
- the explainer,
- the quiz and its answers,
- the exact git command you would run for each option.

Ask with the native `question` tool:

- **Approve and merge** — merge `pagani/<job-id>` into the base.
- **Approve and commit** — commit remaining changes with a message.
- **Approve and push** — push `pagani/<job-id>`.
- **Approve and open PR** — push and create a PR.
- **Rework** — the human gives feedback; start a fresh round.
- **Reject** — stop, keep the branch and artifacts.

## Git rules

- Show the exact command before running a push, merge, or PR.
- Ask for confirmation. Never infer consent from "looks good".
- Never force-push, reset --hard, clean, or rewrite history.
- Never push to the base branch.
- Never deploy.
- If the base branch is dirty or checked out elsewhere, stop and ask.

## Commands

Merge:

```bash
git switch <base>
git merge --no-ff pagani/<job-id> -m "Merge pagani/<job-id>"
```

Commit:

```bash
git add <explicit paths>
git commit -m "<message>"
```

Push:

```bash
git push -u origin pagani/<job-id>
```

PR:

```bash
gh pr create --base <base> --head pagani/<job-id> --title "<title>" --body "<body>"
```

Use the project's actual remote and base. If `gh` is not available, say so and
give the human the command.

## PR body

Use the smallest view that makes the change clear:

```markdown
## Summary

<diagram, diff sketch, call tree, or short file tree>

## Evidence

- **Before:** <screenshot/output/failing test>
  **After:** <screenshot/output/passing test>

## Merge Danger

**Door:** one-way or two-way

**Blast Radius:** <one word or short phrase>
```

Keep the prose short. Use the project's domain language. Show evidence, not a
claim.

## Rework

1. Write the human's feedback verbatim to `pagani/jobs/<id>/human.md`.
2. Spawn a fresh builder with the feedback, the affected ticket, and the branch.
3. Re-run the deterministic checks.
4. Re-run the reviewers whose area the feedback touches.
5. Reset the fix budget and return to the review step.

## Reject

1. Write the reason to `human.md`.
2. Keep the branch, worktrees, and job folder.
3. Do not delete anything unless the human explicitly asks.

## Close

1. Update `job.md`.
2. Record the decision in `human.md`.
3. If the job produced a reusable lesson, propose one line for `AGENTS.md` or
   `mistakes.md`. Ask before editing.
4. Tell the human what merged, what remains, and where the artifacts are.

## Gotchas

- Running push, merge, or PR without showing the exact command first.
- Inferring consent from "looks good".
- Force-pushing, resetting --hard, or cleaning.
- Forgetting to record the decision in `human.md`.
- Deleting the branch or worktree before the human confirms.
