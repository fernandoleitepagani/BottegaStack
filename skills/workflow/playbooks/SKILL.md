---
name: playbooks
description: Choose a PaganiStack playbook (trivial, bugfix, feature, refactor, pr-babysit) and a risk modifier (low, standard, high) at Step 0. Use the light path for small work and escalate risk when the diff grows or touches a risk path. Use before planning, again after the first builder commit, and whenever a job's scope changes.
---

# PaganiStack Playbooks

Not every request needs the full nine-step pipeline. Pick a playbook and a risk
modifier, write both to `job.md`, and run only the steps they need. Playbooks
never downgrade; risk only escalates.

## Playbooks

| Playbook | Use when | What runs |
|---|---|---|
| `trivial` | docs, copy, comments, config-only; a few files; no risk path; no behaviour change | the light path |
| `bugfix` | a reproducible symptom exists | failing test first; the light path when the change is small |
| `feature` | normal product work | interview, SPEC with a task graph, worktrees, full build/check/review |
| `refactor` | behaviour must not change | expand-contract; tests before and after; full build/check/review |
| `pr-babysit` | a PR is open and needs CI or review follow-up | watch checks and comments read-only, fix through the light path, push only with approval — see [pr-babysit.md](pr-babysit.md) |

## Risk paths

Risk is a modifier on top of the playbook:

| Risk | Use when |
|---|---|
| `low` | internal, reversible, no risk path |
| `standard` | normal product change; the default |
| `high` | auth, payments, data/schema/migrations, deploy/CI config, installers, dependency changes, secrets handling, or any path listed under `## Risk paths` in `REVIEW.md` |

A missing `REVIEW.md`, or a missing `## Risk paths` section, means there are no
risk paths. `high` adds `adversarial-review`, `simplify`, `review-code`
(`model: opus`), and the second-opinion reviewer: `pagani build --review <job>
<task> [--block]` writes findings to `pagani/jobs/<job>/build/<task>.review2.md`.

## The light path

`trivial` and small `bugfix` jobs take the light path: no job folder, SPEC, or
worktree. The master creates branch `pagani/quick-<slug>` first, then runs
`pagani build --here <slug> --task "<text>" [--block]`, which runs the headless
builder in the current checkout on the current branch. State and report live in
`pagani/quick/<slug>/` (`run`, `rc`, `progress`, `prompt`, `report.md`,
`builder.log`).

## Waiting on external events

When you are waiting on something outside the session — CI, a long build, a
review — do not idle or sleep-poll. Invoke the `loop` skill with a sensible
interval for the event (for example 120s for CI, 300s for a long build) and
re-check the same condition each time. State the interval and a maximum number
of checks (for example 20) before the first check. Stop as soon as the condition
is met or the cap is reached, and report the last state either way.

## Step 0 classification

1. Read the request, `AGENTS.md`, `GLOSSARY.md` if it exists, and the
   `## Risk paths` section of `REVIEW.md`.
2. Propose a playbook and risk with one line of reasoning.
3. Ask the user one question with the proposed values pre-selected.
4. Write to `job.md`:

```markdown
Playbook: feature
Risk: standard
```

5. If the user passes `--playbook <playbook>`, use it. `quick` means `trivial`
   or a small `bugfix`.

## Escalation

After the first builder commit, compare the diff against the playbook and risk:

```bash
git diff --stat <base>...HEAD
git diff --name-only <base>...HEAD
```

Read the risk globs from the project `REVIEW.md` under `## Risk paths` (defaults
in `resources/REVIEW.md`). If the diff touches a risk glob, exceeds ~300 changed
lines, or grows beyond the playbook's scope, **escalate the risk**, write the new
risk to `job.md`, and tell the user in one line. Never downgrade.

## Model tiers

There are no tier variants of an agent. The master picks the tier per call with
the Agent tool's `model` parameter; the agent's own frontmatter is the default.

- `explorer`: cheap for every playbook.
- `planner`: default for `feature` and `refactor`.
- `builder`: default; the Claude fallback is `haiku` for `trivial`.
- `review-code`: `haiku` for `trivial` and `bugfix`, default for `feature` and
  `refactor`, `opus` for `high` risk.

When `pagani build --check` passes, every playbook's builder is the headless
Claude Code `builder` run through `pagani build` on the model in `builder.env`;
the tiers above apply only to the Claude fallback.

One reviewer covers code, UI, UX, and security for every playbook. The master
writes `decision.md` at Step 6.

The base agents are `master`, `explorer`, `planner`, `builder`, and
`review-code`.

## Gotchas

- **Classifying by file count alone.** A one-file change to `auth/` is `high`
  risk, not `trivial`.
- **Forgetting to escalate.** A `trivial` job that grows into a migration is
  `high` risk; re-run the diff check after the first builder commit.
- **Spawning a separate UI, UX, or security reviewer.** The one `review-code`
  reviewer covers all four areas.
- **Skipping checks on a trivial job.** The project check still runs.
- **Using a strong model for search.** `explorer` is lite for a reason.
- **Waiting for a separate approval agent.** The master writes `decision.md`.
