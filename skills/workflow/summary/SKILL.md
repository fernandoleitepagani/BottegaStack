---
name: summary
description: Post a short BottegaStack summary in chat after every step and the final summary once. Use by the master at each checkpoint to explain what changed, how it works, why, evidence, risks, and the next decision.
---

# BottegaStack Summary

The human is in the loop. A summary is not a status line; it is the explanation
that lets the human decide without reading the whole diff.

## Base skill

Run `unslop` only on text that ships: the final summary (the PR body or the
merge-commit message), the approval explainer, and user-facing docs. Do not run
it on two-line status updates or the chat summary.

## After every step

Post the short version in chat. Do not write a file at each checkpoint.

- Keep the chat version under 12 lines.
- Post it and keep going. Stop for the human only at the playbook's checkpoints
  (SPEC approval, the final decision), on an escalation, or on ambiguity.
- After every subagent run, post a short summary of what it returned before
  moving on.

## Post the final summary once

Post the full summary once at close, as the closeout write-up: the PR body, or
the merge-commit message for a local merge.

- `trivial`, `bugfix`: post it at close.
- `feature`, `refactor`, `high` risk: post it at review.
- It is a single write-up, never one per round.

## The six sections

1. **What changed** — files, behaviour, artifacts.
2. **How it works** — the mechanism in plain language.
3. **Why this choice** — the trade-off and the alternative rejected.
4. **Evidence** — the command, output, screenshot, or file:line.
5. **Risks / open questions** — what could still be wrong.
6. **Next step** — what happens next, or the decision needed.

## Good vs bad

Bad:

> Implemented the feature and tests pass.

Good:

> **What changed:** added `readingTime.js`, wired it into the blog post and list
> views, and updated the prerender dependency list.
> **How it works:** the helper counts words, divides by 200, and rounds up; the
> views render it beside the date.
> **Why:** the existing post metadata already carries the Markdown, so no new
> data source or API call was needed.
> **Evidence:** `npm test` passed; `/blog/random-number-mcp` shows
> `June 26, 2025 · 3 min read` at 390px and 1440px.
> **Risks:** code blocks count toward the estimate.
> **Next:** approve to run the code review.

## Checkpoints

Use `AskUserQuestion` for the decision:

- Approve
- Rework (with a note)
- Reject
- Stop

The human can also ask a question; answer it and do not change state.

## Rules

- Never hide a failure or a risk to make the summary look clean.
- Never claim a check ran if it did not.
- Never summarise from the implementer's report alone; read the artifact and the
  diff.
- If the human's decision is ambiguous, ask.

## Gotchas

- A chat summary over 12 lines.
- A claim without a command, output, screenshot, or file:line.
- Hiding a risk or a failed check to make the summary look clean.
- Summarising from an agent report instead of the artifact and the diff.
- Advancing without an explicit `approve`.
- Posting the full summary at every checkpoint instead of once at close.
