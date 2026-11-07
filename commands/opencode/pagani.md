---
description: Start or continue a PaganiStack job.
agent: master
argument-hint: "<feature> | status | resume | --lane <lane> <feature> | quick <feature>"
---

Use the PaganiStack workflow.

The user's request is:

$ARGUMENTS

If the request starts with `--lane <lane>`, use that lane. If it starts with
`quick`, pick `trivial` or `small`. Otherwise, load `lanes` at Step 0 and ask the
user to confirm the proposed lane.

If the request is empty or `status`, find the newest `pagani/jobs/*/job.md`,
read it, and show the current stage, lane, next step, and open questions. Do not
start a new job.

If the request is `resume`, read the newest `job.md` and continue from its
current stage without redoing completed steps.

Otherwise, start a new job at **Step 0 — Explore and set up**.

Other skills are invoked directly by name, not through `/pagani`: for example
`/wizard`, `/backlog-triage`, `/wayfinding`, `/improve-architecture`, and
`/review-pr`.
