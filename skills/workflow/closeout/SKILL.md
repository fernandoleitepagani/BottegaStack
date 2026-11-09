---
name: closeout
description: Handle the PaganiStack human decision and final git actions. Use after the master writes decision.md, when the human chooses merge, commit, push, PR, rework, or reject.
---
# PaganiStack Closeout
The master recommends. The human decides. Execute only what the human explicitly asks for.
## Present
Show the master's decision and why, the acceptance-criteria mapping, the explainer,
the quiz and its answers for `feature`, `refactor`, and `high` risk, and the exact
git command for each option. Ask with `AskUserQuestion`:
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
- Never push to the base branch. Never deploy.
- If the base branch is dirty or checked out elsewhere, stop and ask.
## Commands
```bash
git switch <base>                              # merge
git merge --no-ff pagani/<job-id> -m "Merge pagani/<job-id>"
git add <explicit paths>                       # commit
git commit -m "<message>"
git push -u origin pagani/<job-id>             # push
gh pr create --base <base> --head pagani/<job-id> --title "<title>" --body "<body>"  # PR
```
Use the project's actual remote and base. If `gh` is not available, say so and give the human the command.
## Idempotent resume
A resume may re-enter closeout after a partial run. Before creating a branch, worktree,
or PR, check whether it exists and reuse it; create only what is missing.
```bash
git branch --list 'pagani/<job-id>'
git worktree list
gh pr view pagani/<job-id>
```
## PR body
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
Keep the prose short, use the project's domain language, and show evidence, not a claim.
## Rework
1. Append the feedback verbatim under `## Human decision` in `decision.md`.
2. Spawn a fresh builder with the feedback, the affected task, and the branch.
3. Re-run the deterministic checks, then the reviewers whose area it touches.
4. Reset the fix budget and return to the review step.
## Reject
1. Append the reason under `## Human decision` in `decision.md`.
2. Keep the branch, worktrees, and job folder; delete nothing unless asked.
## Close
1. Update `job.md` and append the decision under `## Human decision` in `decision.md`.
2. If the job produced a reusable lesson, propose one line for `AGENTS.md` or `mistakes.md`; ask before editing.
3. Tell the human what merged, what remains, and where the artifacts are.
## Gotchas
- Running push, merge, or PR without showing the exact command first.
- Inferring consent from "looks good".
- A duplicate PR, branch, or worktree after a resume.
- Force-pushing, resetting --hard, or cleaning.
- Forgetting the decision in `decision.md`, or deleting before confirmation.
