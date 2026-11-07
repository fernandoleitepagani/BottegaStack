---
name: lanes
description: Classify a PaganiStack job into a lane at Step 0 and escalate it when the diff grows or touches a risk path. Use before planning and again after the first builder commit.
---

# PaganiStack Lanes

Not every request needs the full ten-step pipeline. Pick a lane, write it to
`job.md`, and skip the steps the lane does not need. Lanes only escalate.

## Lanes

| Lane | Use when | Steps that run | Human checkpoints |
|---|---|---|---|
| `trivial` | docs, copy, comments, config-only; ≤3 files; no risk path; no behaviour change | Step 0 → `builder-lite` → `pagani check` → `review-code-lite` → human | one summary at the end |
| `bugfix` | a reproducible symptom exists | Step 0 → `diagnosis` → failing test first → one `builder` → `pagani check` → `review-code-lite` (+ `review-security` if a risk path is touched) → human | one summary at the end |
| `small` | one feature, one area, ≲10 files, no risk path | Step 0 → short interview (≤3 questions) → `plan.md` with acceptance criteria (spec merged in) → one ticket → `builder` → `pagani check` → `review-code-lite` + routed lens → human. No separate spec, tickets index, or approver | after plan, after review |
| `standard` | normal product change | full flow; build/check summaries collapse into the review summary | after plan, spec, tickets, review |
| `high-risk` | auth, payments, data/schema/migrations, deploy/CI config, installers, dependency changes, secrets handling | full flow + `adversarial-review` + `simplify` + `review-security-strong` + `approver-strong`; quiz mandatory | every step; the human must read the diff before merge |

Commands `pr`, `design`, `wayfind`, `triage`, `improve`, `wizard` are separate
and are not lanes.

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

After the first builder commit, run:

```bash
pagani classify --diff
```

If the diff touches a risk glob, exceeds ~300 changed lines, or touches more
files than the lane allows, **escalate** the lane, write the new lane and reason
to `job.md`, and tell the user in one line. Never downgrade.

Risk paths live in the project `REVIEW.md` under `## Risk paths`. Defaults are
in `resources/REVIEW.md`.

## Model tiers

| Role | trivial | bugfix | small | standard | high-risk |
|---|---|---|---|---|---|
| explorer | lite | lite | lite | lite | lite |
| planner | — | — | `planner-std` | `planner-strong` | `planner-strong` |
| builder | `builder-lite` | `builder` | `builder` | `builder` | `builder-strong` |
| review-code | `review-code-lite` | `review-code-lite` | `review-code-lite` | `review-code` | `review-code-strong` |
| review-ui / review-ux | `review-ui` / `review-ux` | — | `review-ui` / `review-ux` | `review-ui` / `review-ux` | `review-ui` / `review-ux` |
| review-security | only on risk path (`review-security`) | `review-security` on risk path | `review-security` on risk path | `review-security` | `review-security-strong` |
| approver | — | — | — | `approver` | `approver-strong` |
| search / logs | `explorer` | `explorer` | `explorer` | `explorer` | `explorer` |

The base agents are `planner`, `builder`, `review-code`, `review-ui`,
`review-ux`, `review-security`, `approver`, `explorer`. The installer generates
the tier variants from `agents/models.conf`:

- `planner-std`, `planner-strong`
- `builder-lite`, `builder-strong`
- `review-code-lite`, `review-code-strong`
- `review-security-strong`
- `approver-strong`

## Gotchas

- **Classifying by file count alone.** A one-file change to `auth/` is
  high-risk, not trivial.
- **Forgetting to escalate.** A small job that grows into a migration is
  high-risk; re-run `pagani classify --diff` after the first builder commit.
- **Running the approver on a trivial job.** It is wasted tokens; the human
  checkpoint is enough.
- **Skipping checks on a trivial job.** `pagani check` still runs.
- **Using a strong model for search.** `explorer` is lite for a reason.
