---
name: weekly-review
description: Produce a weekly review of shipped work, open work, lessons, and next priorities. Use at the end of a week, sprint, or batch of jobs.
---

# Weekly Review

Turn a week of activity into a short review that changes what happens next.

## Gather

- Merged PRs and commits.
- Closed and open tickets or `BACKLOG.md` items.
- `pagani/jobs/*/job.md` and `human.md`.
- Incidents, reverts, and repeated review findings.
- Lessons already written in `AGENTS.md` or `mistakes.md`.

## Write `weekly-review.md`

```markdown
# Week of <date>

## Shipped
- <outcome> — <link>

## Learned
- <lesson> — <where it was written down>

## Blocked
- <item> — <what it needs>

## Next
1. <priority>
2. <priority>

## Metrics
- Jobs merged:
- Review rounds:
- Escaped defects:
- Human corrections:
```

Rules:

- Group by outcome, not activity.
- Do not list vanity metrics.
- Every lesson names where it was recorded.
- Every next item has an owner and a first step.

## Follow-up

Propose at most three environment changes: a lint rule, a test, an `AGENTS.md`
line, or a skill edit. Ask before editing.

## Report

```
SHIPPED: <count>
LESSONS: <count>
NEXT: <top item>
```
