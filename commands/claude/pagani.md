---
description: Start or continue a PaganiStack job.
argument-hint: "<feature> | status | resume | triage | wayfind | improve | wizard | pr <n> | --lane <lane> <feature> | quick <feature>"
model: opus
allowed-tools: Read, Grep, Glob, Bash, Write, Task, Skill, AskUserQuestion, TodoWrite
---

The user's request is:

$ARGUMENTS

If the request is empty or `status`, read the newest `pagani/jobs/*/job.md` and
show the stage, lane, next step, and open questions.

If the request is `resume`, read the newest `job.md` and continue from its
current stage without redoing completed steps. Both runtimes share the job
folder, so a job can start in Claude Code and finish in OpenCode.

If the request is `triage`, load `backlog-triage` and work `BACKLOG.md`.

If the request is `wayfind`, load `wayfinding` and chart `pagani/jobs/<id>/map/`.

If the request is `improve`, load `improve-architecture` and run its review.

If the request is `wizard`, load `wizard` and scope the human-only procedure.

If the request is `pr <number>`, load `review-pr`, run `gh pr view`, `gh pr diff`,
and `gh pr checks`, then write `review-pr.md`. Do not merge.

If the request starts with `--lane <lane>`, use that lane. If it starts with
`quick`, pick `trivial` or `small`. Otherwise, load `lanes` at Step 0 and ask the
user to confirm the proposed lane.

Otherwise, start a new job at **Step 0 — Explore and set up**.
