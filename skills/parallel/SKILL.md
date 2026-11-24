---
name: parallel
description: "Fan work out to parallel agents and bring back one result. Three modes: coverage (split the work into slices), race (identical briefs, a declared winner rule), and bakeoff (candidates at one artifact, pick a base, graft the best of the rest). Use for /parallel, 'swarm this', 'arena this', 'throw it in the arena', parallel coverage or verification, races, and design or code bakeoffs."
disable-model-invocation: true
---

# Parallel

Open a todo list with one entry per phase (Frame, Fan out, Collect, then Pick and Graft for a bakeoff, Report) before launching anything.

| Mode | Shape | Returns |
|---|---|---|
| **coverage** | One worker per slice of the work | One report covering every slice |
| **race** | N workers on the same brief, a winner rule declared first (`first pass`, `rank all`, `best-of`) | The winner, or the ranking |
| **bakeoff** | N candidates at the same artifact | One artifact: a base with grafts from the others |

## Frame

1. State the done predicate and what comes back.
2. **Models** by role in `../maestro/references/subagents.md`: `explorer` for coverage and race workers (a model race names each arm's model up front), `runners` for a bakeoff (the list length sets the count: 2 at normal risk, up to 4 at high risk), `judge` at high risk. A rejected model falls back to the role default; say so.
3. **Fan-out** above 3 agents follows the fan-out rule in that file.
4. **Separate outputs.** Each agent writes to its own place: `isolation: "worktree"` when it writes or needs its own checkout, otherwise its own path under `.bottega/<task-slug>/<n>/`. Worktree runs share CPU, ports, and disk, so cap fan-out (**Separate Before Serializing Shared State**).
5. **Verification or measurement briefs** name the exact SHAs and the method (sample count, what one sample is, order); the agent records both.
6. **Bakeoff only:** write a rubric of 3-6 gradeable criteria for this task. It is the picker's tool; candidates see only the task.

## Fan out

Spawn every agent in one message: `Agent` with `subagent_type: general-purpose`, `run_in_background: true`, and `model` and `effort` from step 2. A worker that must start on another branch is told "check out `<branch>` first".

Every brief stands alone: goal, scope, its slice or arm, how to verify, and what to report. Coverage and race reports use `PASS`, `ISSUES` (every defect it can prove, not only the first), or `BLOCKED`, with evidence. A bakeoff candidate returns the artifact and a short rationale naming the alternatives it rejected.

An agent that drops out: continue with N-1 and note it.

## Collect

Read the terminal results. Drop a result that lacks the SHAs and method its brief named and respawn it once; a second miss is a gap, and a gap is not a pass. Coverage needs a result for every slice. A race applies its declared rule. Never paste raw dumps.

## Pick and graft (bakeoff)

1. **Cross-judge** at high risk only: one `Agent` with `subagent_type: "Explore"` that must not edit, spawned after every candidate finishes. It scores each candidate per criterion by path label and recommends a base. At normal risk, say it was skipped.
2. **Pick a base.** Read every candidate end to end and score each criterion, not on feel. Compare with the judge; disagreement means bias or an ambiguous rubric, so read both rationales. Prefer the base a maintainer can extend most easily; on a tie, the cleaner boundary or smaller API (**Delete First**).
3. **Graft** one or two things per losing candidate, folded in by hand so the result keeps one mental model (**Redesign from First Principles**). Candidates that converge need no graft. Candidates that diverge wildly mean the frame was under-specified: reframe and rerun instead of averaging.
4. **Verify** the result like any other output (**Prove It Works**). A problem the bakeoff missed means the frame was wrong or a graft was missed.

## Report

One in-chat report. Coverage and race: a result table, one line per issue, gaps and dropouts, and the winner rule when used. Bakeoff: the base and why, the judge's verdict or that it was skipped, each graft and its source, what was rejected, convergence or dropouts, and the verification result.
