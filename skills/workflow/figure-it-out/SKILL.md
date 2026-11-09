---
name: figure-it-out
description: Use when no playbook fits the request, when the task is unusual, open-ended, or cuts across playbooks. Build a one-off playbook, confirm it with the user, then run it with the usual evidence reply.
---

# Figure it out

For work that fits no playbook: write a one-off playbook first, confirm it, then run it.

## Steps

1. Restate the goal in one sentence and the observable done condition.
2. Read `AGENTS.md`, `GLOSSARY.md` if it exists, and `REVIEW.md`; note the check command and risk paths.
3. Propose a one-off playbook: 3-8 numbered imperative steps, each naming the skill, tool, or command it uses.
4. Show the proposal to the user and confirm it with `AskUserQuestion`. If the answer changes scope, revise and ask again.
5. Copy the confirmed steps verbatim into `TodoWrite`; keep a skipped step with a one-line skip reason.
6. Run the steps. For waits on external events, invoke the `loop` skill with an interval and a cap.
7. Reply with verbatim before/after evidence and label each claim measured, inferred, or guessed.

## Reply

```
Done: <what changed>
Evidence: <verbatim before/after output>
Claims: measured | inferred | guessed
```

## Gotchas

- Editing before the user confirms the plan.
- Vague steps ("investigate", "fix it"). Each step names a tool or command and a check.
- Skipping the evidence reply because the playbook was improvised.
- Asking `figure-it-out` to plan itself. If you cannot name a first step, ask the user a direct question.
