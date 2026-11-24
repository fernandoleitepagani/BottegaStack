---
name: crossfire
description: "Adversarial review of a finished diff or a design. Use for \"crossfire\", \"adversarial review\", \"challenge this\", \"stress test this\", \"find blind spots\", or \"tear this apart\", and automatically at high risk before the final gate. Only findings proven by a run survive. Report only."
disable-model-invocation: true
---

# Crossfire

Assume the change is wrong and prove how it fails. A finding survives only when a run proves it. You are not the style reviewer. Report findings, never fix.

## Mode

- **Solo.** One adversary. Maestro runs this automatically on high-risk runs, before the final gate.
- **Panel.** Up to 4 adversaries on different models, verified and merged. Use when the user asks for crossfire directly, for a contested design, or when solo found something structural.

Both modes read the `crossfire` line in `~/.claude/rules/bottega-models.md`. If the rule or line is missing, use `sonnet` at `medium`. A direct call runs regardless of the maestro risk tier.

## Frame

The scope is what the user names. Otherwise it is the branch diff from its merge base with the base branch, through the working tree. State the intent in your own words from the user's message, the commits, and the PR description. Ask when the intent is unclear. Give each adversary the intent, the diff command, the brief, and the check output as paths. Never give it the builder's self-assessment.

## Spawn

- Solo: `subagent_type: "Explore"` when no repro needs files, otherwise `general-purpose` with `isolation: "worktree"`.
- Panel: run Phase A steps 3 and 4 and Phase B of the **arena** skill (`../arena/SKILL.md`), with the `crossfire` line in place of `arena runners`. Each adversary is `general-purpose` with `isolation: "worktree"`. Copy the scope's uncommitted changes into each worktree. Cap fan-out, since worktrees share CPU, ports and disk. Skip arena Phases C, D, and E. Adversaries find different failures, so the verdict keeps every verified finding.

## Brief

> Break this change. Read the brief, the check output, and the full diff, with each changed file read in full, plus prior findings if this is a later round. Prove each finding with a run against the real code: a failing test, a repro script, or output that shows the wrong behavior. For a design or plan, run a prototype or probe the current tree. Keep repros in a scratch or worktree location. Report each finding with a title, `file:line`, the exact command, the output it printed, and the output the intent requires. Anything you did not run is a note, not a finding. Skip style, naming, and structure. Stop when what remains is nitpicks. No findings is a valid result.
>
> Try: empty, null, zero, one, many. Duplicate action, retry, double submit. Timeout and partial failure. Concurrent writes. Permission boundaries (another user, another tenant, signed out). Data loss, irreversible state, rollback. Injection into HTML, SQL, shell, paths, URLs. Migration across old, new, and mixed data. Breakage outside the diff per `../blast-radius/SKILL.md`.

## Verify

Rerun each finding's command yourself. Keep it when the output shows the failure and the failure breaks the intent. Drop the rest. Merge findings that share a root cause. Hand verified findings to the **diagnosis** skill (`../diagnosis/SKILL.md`) for a fix brief.

## Output

```markdown
VERDICT: PASS | CHANGES
Intent: <restatement>

## Findings
1. <title> | `file:line` | command | output | how it breaks the intent | found by
## Notes (unreproduced)
## Dropped (per adversary: count and why)
## Verified safe
```

End with `FINDINGS: <count>` and `WORST: <one line>`.

## Ledger

When `.bottega/` exists, log the verdict so maestro's gate check can see it ran (`<skills dir>` is the parent of this skill's directory, as an absolute path):

```bash
<skills dir>/show-me-your-work/scripts/log.sh .bottega/proofs.tsv crossfire "<scope>" "<mode, adversaries and models>" "FINDINGS: <n>; WORST: <line>" <PASS|FAIL>
```

PASS for `VERDICT: PASS`, FAIL for `VERDICT: CHANGES`. After a fix round, rerun crossfire on the new diff and log a new row. The gate reads the latest one.
