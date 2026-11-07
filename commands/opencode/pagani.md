---
description: Start or continue a PaganiStack job.
agent: master
argument-hint: "<feature> | status | resume | triage | wayfind | improve | wizard | pr <n> | --lane <lane> <feature> | quick <feature>"
---

Use the PaganiStack workflow.

The user's request is:

$ARGUMENTS

If the request starts with `--lane <lane>`, use that lane. If it starts with
`quick`, pick `trivial` or `small`. Otherwise, load `lanes` at Step 0 and ask the
user to confirm the proposed lane.

If the request is empty, find the newest `pagani/jobs/*/job.md`, read it, and
show the current stage, the next step, and the open questions. Do not start a
new job.

If the request is `status`, do the same for the newest job.

If the request is `resume`, read the newest `job.md` and continue from its
current stage without redoing completed steps.

If the request is `triage`, load `backlog-triage` and work the local
`BACKLOG.md`. Do not start a build job.

If the request is `wayfind`, load `wayfinding` and chart the map under
`pagani/jobs/<id>/map/`. Do not start a build job.

If the request is `improve`, load `improve-architecture` and run its
architecture review. Do not start a build job.

If the request is `pr <number>`, load `review-pr`, run `gh pr view`,
`gh pr diff`, and `gh pr checks`, then write `review-pr.md`. Do not merge.

If the request is `wizard`, load `wizard` and scope the human-only procedure.
Do not start a build job.

Otherwise, start a new job at **Step 0 — Explore and set up**.
