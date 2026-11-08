---
name: lanes
description: Classify a PaganiStack job into a lane at Step 0 and escalate it when the diff grows or touches a risk path. Use before planning and again after the first builder commit.
---

# PaganiStack Lanes

Not every request needs the full nine-step pipeline. Pick a lane, write it to
`job.md`, and skip the steps the lane does not need. Lanes only escalate.

## Lanes

| Lane | Use when | Steps that run | Human checkpoints |
|---|---|---|---|
| `trivial` | docs, copy, comments, config-only; ≤3 files; no risk path; no behaviour change | Step 0 → `builder` (haiku) → `pagani job check` → `review-code` (haiku) → human | one summary at the end, then the approval prompt |
| `bugfix` | a reproducible symptom exists | Step 0 → `diagnosis` → failing test first → one `builder` → `pagani job check` → `review-code` (haiku) → human | one summary at the end, then the approval prompt |
| `small` | one feature, one area, ≲10 files, no risk path | Step 0 → short interview (≤3 questions) → `SPEC.md` with acceptance criteria and one task → `builder` → `pagani job check` → `review-code` (haiku) → human. The master writes `decision.md` | after SPEC, after review |
| `standard` | normal product change | full flow; build/check summaries collapse into the review summary | after SPEC, after review |
| `high-risk` | auth, payments, data/schema/migrations, deploy/CI config, installers, dependency changes, secrets handling | full flow + `adversarial-review` + `simplify` + `review-code` (opus); quiz mandatory | every step; the human must read the diff before merge |

The master runs on its own between checkpoints: it never waits for "proceed" or
"approve" between steps, and background builders report back without being asked.

Every lane ends with the approval prompt (Step 6 and Step 7) through the native
question UI. Lanes only change how much runs before it and whether there is a
quiz (`standard` and `high-risk` only).

Skills `wizard`, `wayfinding`, `backlog-triage`, `improve-architecture`, and
`review-pr` are separate and are not lanes.

## Step 0 classification

1. Read the request, `AGENTS.md`, `GLOSSARY.md`, and `REVIEW.md` risk paths.
2. Propose a lane with one line of reasoning.
3. Ask the user one question with the proposed lane pre-selected.
4. Write to `job.md`:

```markdown
Lane: small
Lane-reason: one feature, one area, no risk path
```

5. If the user passes `--lane <lane>` or `quick`, use it. `quick` means the
   master picks `trivial` or `small`.

## Escalation

After the first builder commit, compare the diff against the lane:

```bash
git diff --stat <base>...HEAD
git diff --name-only <base>...HEAD
```

Read the risk globs from the project `REVIEW.md` under `## Risk paths` (defaults
in `resources/REVIEW.md`). If the diff touches a risk glob, exceeds ~300 changed
lines, or touches more files than the lane allows, **escalate** the lane, write
the new lane and reason to `job.md`, and tell the user in one line. Never
downgrade.

## Model tiers

There are no tier variants of an agent. The master picks the tier per call with
the Agent tool's `model` parameter; the agent's own frontmatter is the default.

| Role | trivial | bugfix | small | standard | high-risk |
|---|---|---|---|---|---|
| explorer | haiku | haiku | haiku | haiku | haiku |
| planner | — | — | default | default | default |
| builder | `model: haiku` | default | default | default | default |
| review-code | `model: haiku` | `model: haiku` | `model: haiku` | default | `model: opus` |

When `pagani build --check` passes, every lane's builder is the headless Claude
Code `builder` run through `pagani build` on the model in `builder.env`; the tier
above applies only to the Claude fallback.

One reviewer covers code, UI, UX, and security for every lane. The master writes
`decision.md` at Step 6.

The base agents are `master`, `explorer`, `planner`, `builder`, and
`review-code`.

## Gotchas

- **Classifying by file count alone.** A one-file change to `auth/` is
  high-risk, not trivial.
- **Forgetting to escalate.** A small job that grows into a migration is
  high-risk; re-run the diff check after the first builder commit.
- **Spawning a separate UI, UX, or security reviewer.** The one `review-code`
  reviewer covers all four areas.
- **Skipping checks on a trivial job.** `pagani job check` still runs.
- **Using a strong model for search.** `explorer` is lite for a reason.
- **Waiting for a separate approval agent.** The master writes `decision.md`.
