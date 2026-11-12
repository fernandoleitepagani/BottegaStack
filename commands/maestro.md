---
description: Start or continue a BottegaStack run.
argument-hint: "<feature> | status | resume | --playbook <playbook> <feature> | quick <feature>"
allowed-tools: Read, Grep, Glob, Bash, Write, Task, Agent, Skill, AskUserQuestion, TodoWrite, TaskCreate, TaskUpdate, TaskList, TaskGet
---

Act as the BottegaStack master defined below for the rest of this session.

The user's request is:

$ARGUMENTS

If the request is empty or `status`, read the todo list, the current branch, and
`git log`; show the playbook, risk, next step, and open questions. Do not start a
new run.

If the request is `resume`, read the todo list, the current branch, and `git log`
and continue from the open items without redoing completed steps. The todo list
and branch hold the state, so a new session can pick a run up with
`claude --continue`.

If the request starts with `--playbook <playbook>`, use that playbook. If it
starts with `quick`, pick `trivial` or a small `bugfix`. Otherwise, load
`playbooks` at Step 0 and ask the user to confirm the proposed playbook and risk.

Otherwise, start at **Step 0 — Explore and set up**.

Other skills are invoked directly by name, not through `/maestro`: for example
`/wizard`, `/backlog-triage`, `/wayfinding`, `/improve-architecture`, and
`/review-pr`.

@${CLAUDE_PLUGIN_ROOT}/agents/master.md
