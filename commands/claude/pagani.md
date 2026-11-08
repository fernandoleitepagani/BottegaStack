---
description: Start or continue a PaganiStack job.
argument-hint: "<feature> | status | resume | --lane <lane> <feature> | quick <feature>"
model: opus
allowed-tools: Read, Grep, Glob, Bash, Write, Task, Skill, AskUserQuestion, TodoWrite
hooks:
  PreToolUse:
    - matcher: "Agent|Task"
      hooks:
        - type: command
          command: "pagani guard builder"
---

The user's request is:

$ARGUMENTS

If the request is empty or `status`, read the newest `pagani/jobs/*/job.md` and
show the stage, lane, next step, and open questions. Do not start a new job.

If the request is `resume`, read the newest `job.md` and continue from its
current stage without redoing completed steps. Both runtimes share the job
folder, so a job can start in Claude Code and finish in OpenCode.

If the request starts with `--lane <lane>`, use that lane. If it starts with
`quick`, pick `trivial` or `small`. Otherwise, load `lanes` at Step 0 and ask the
user to confirm the proposed lane.

Otherwise, start a new job at **Step 0 — Explore and set up**.

Other skills are invoked directly by name, not through `/pagani`: for example
`/wizard`, `/backlog-triage`, `/wayfinding`, `/improve-architecture`, and
`/review-pr`.
