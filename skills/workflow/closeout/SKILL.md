---
name: closeout
description: Handle the BottegaStack human decision and final git actions. Use after the master presents the approval decision, when the human chooses merge, commit, push, PR, rework, or reject.
---
# BottegaStack Closeout
The master recommends. The human decides. Execute only what the human explicitly asks for.
The default closeout is a pull request whose body is the run's written record.
## Merge-readiness gate
Before presenting merge or PR options, run the `ship` checklist against the branch or PR and show every item:
- CI checks all green via `gh pr checks <n>` when a PR exists (`./scripts/check` for a branch only).
- Security checks passed.
- An independent `review-code` of the latest commit (`git rev-parse HEAD`), by a reviewer who did not write it.
- Review threads resolved.
- Manual testing noted.
List each unmet item with its verbatim command output. Unmet items are shown to the user and **block the "Approve and merge" option**: do not offer or run the merge until each is fixed or the user explicitly waives it with `AskUserQuestion`. Record any waiver in the merge-commit message. A fully met checklist is not consent; still ask.
## Present
Draft the write-up first, then present it. Show the master's decision and why, the
acceptance-criteria mapping, the explainer, the quiz and its answers for `feature`,
`refactor`, and `high` risk, the drafted PR body, and the exact git command for each
option. Ask with `AskUserQuestion`:
- **Approve and open PR** (default) — push `<branch>` only and create the PR with the write-up.
- **Approve and merge** — merge `<branch>` into the base with the same write-up in the merge-commit message.
- **Approve and commit** — commit remaining changes with the write-up as the message.
- **Approve and push** — push `<branch>` only; task branches (`<branch>-<task>`) stay local.
- **Rework** — the human gives feedback; start a fresh round.
- **Reject** — stop, keep the branch, worktrees, and state directory.
Create the PR only after the human picks that option. Never infer consent from "looks good".
## Git rules
- Show the exact command before running a push, merge, or PR.
- Ask for confirmation. Never infer consent from "looks good".
- Never force-push, reset --hard, clean, or rewrite history.
- Never push to the base branch. Never deploy.
- If the base branch is dirty or checked out elsewhere, stop and ask.
## Commands
```bash
git switch <base>                              # merge
git merge --no-ff <branch> -m "<write-up>"  # same text as the PR body
git add <explicit paths>                       # commit
git commit -m "<write-up>"                     # the commit message carries the decision
git push -u origin <branch>               # push
gh pr create --base <base> --head <branch> --title "<title>" --body "<write-up>"  # PR
```
Use the project's actual remote and base. If `gh` is not available, say so and give the human the command.
## Idempotent resume
A resume may re-enter closeout after a partial run. Before creating a branch,
worktree, or PR, check whether it exists and reuse it; create only what is missing.
```bash
git branch --list '<branch>'
git worktree list
gh pr view <branch>
maestro build --status <slug>
```
## PR body
The body is the record; there is no decision or summary file.
```markdown
## Done
<what changed, in a few lines>

## Evidence
- `<command>` -> `<verbatim output>`
- Before: `<verbatim>`; After: `<verbatim>`

## Claims
- <claim> — measured | inferred | guessed

## Acceptance
1. <criterion from the SPEC> — met: <evidence>

## Risks
<what could still be wrong, or "None known">

## Decision
APPROVE. <one-line why>. Quiz: <questions and answers, or "not applicable">.
```
Keep the prose short, use the project's domain language, and show evidence, not a claim.
A local merge writes this same text in the merge-commit message. The commit option
writes it in the commit message. Never write the decision to a file.
## Rework
1. Keep the feedback verbatim in the conversation; do not write it to a file.
2. Spawn a fresh builder with the feedback, the affected task, and the branch. For a
   headless task, run `maestro build <slug> <task> --revise <file|->` with the feedback.
3. Re-run the deterministic checks, then the reviewers whose area it touches.
4. Reset the fix budget and return to Step 5.
## Reject
1. Record the reason in the conversation; create no PR.
2. Keep the branch, worktrees, and state directory; delete nothing unless asked.
## Close
1. Record the decision in the PR body or the merge-commit (or commit) message.
2. If the run produced a reusable lesson, propose one line for `AGENTS.md` or `mistakes.md`; ask before editing.
3. After the PR or merge is confirmed, run `maestro report --close <slug>` to remove the run's state directory.
4. Tell the human what merged or opened, what remains, and where the state directory is.
## Gotchas
- Creating the PR, merging, or pushing before the human picks the option.
- Inferring consent from "looks good".
- Writing the decision to a file instead of the PR body or commit message.
- A PR body with claims but no verbatim evidence.
- A merge commit message that does not carry the same write-up.
- A duplicate PR, branch, or worktree after a resume.
- Force-pushing, resetting --hard, or cleaning.
- Deleting the branch or state directory before confirmation.
