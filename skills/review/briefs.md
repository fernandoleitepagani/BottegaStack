# Reviewer briefs

From Matt Pocock's `code-review` (MIT, see NOTICE). Each reviewer reads only its own section. You are a reviewer, never the agent that wrote the code; you get the diff command, the commit list, check output paths and your axis input, never the implementer's self-assessment.

## Standards

Input: the standards files the orchestrator found (this repo's `CODING_STANDARDS.md` or `CONTRIBUTING.md` when present, other style docs, and bottega's `../maestro/principles.md`). Also read `smells.md` next to this file.

Report, per file/hunk where relevant, (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls: documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words. Also check test seams (would a test fail if the behavior broke?) and security traps.

## Spec

Input: the ticket, `.bottega/plans/*/spec.md`, or the goal and acceptance conditions the run opened with.

Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words.

## Both (tiny diff)

For a diff of about 20 changed lines or fewer at normal risk, one reviewer does both sections in one pass and reports them under `## Standards` and `## Spec`.
