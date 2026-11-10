---
name: architect
description: Sketch types, signatures, and module structure before code, twice, then hand the chosen shape to the builders as the contract. Run only when the user asks for it (architect this, design this).
disable-model-invocation: true
---

# Architect

Adapted from pstack's `architect` (Lauren Tan, MIT). Design the shape before any code, so a wrong first shape does not get built. Run it at Step 1, before the SPEC; the sketch goes into the SPEC's `## Implementation decisions`, so the normal SPEC approval is the checkpoint. Track the phases in the todo list.

## 1. Ground

Build a real model of every system the new code touches: load `how` over the relevant subsystems and produce its architectural explanation; naming a file is not grounding. If the design changes ownership or layering, load `why` on the existing shape so its rationale becomes a constraint, not a guess. Skip only for genuinely greenfield work. Read `GLOSSARY.md` and use its terms.

## 2. Write the usage first

Write the caller's view before any type: the quickstart a consumer would read and two or three realistic call sites (what they import, call, and get back). The sketch is derived from this; when the two disagree, change the sketch.

## 3. Sketch it twice

Spawn two read-only subagents (`general-purpose`, told not to edit files), one on the `planner` model and one on the `reviewer` model from `~/.claude/rules/bottega-models.md`. Give each the grounding, the usage, and this brief: sketch types, function signatures, and module boundaries with `not implemented` bodies and pseudocode; take a structurally different direction from the other (whole-shape alternatives, not point fixes); name what you considered and rejected.

Screen each sketch against `references/design-red-flags.md`. Assume the next contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that compiles; prefer the shape where a change that looks right from one file is right for the whole repo. Compare on interface depth: prefer the design that hides more behind a smaller public surface.

Synthesize one design: pick a base, port what is worth keeping from the other, and record what was rejected and why. If the stakes are high, offer the user `arena` to compare built candidates instead.

## 4. Hand it over

Put into the SPEC: the usage, the type and signature sketch (a module map plus type definitions for larger work), the synthesis decision, the tradeoffs accepted ("we accept X in exchange for Y"), and at least one alternative that lost and why. Each task then builds against the sketch; the sketch is the contract. A deviation is a signal to surface, not friction to absorb: if a function needs a parameter the sketch did not foresee, ask whether the sketch was wrong, a requirement was missed, or the builder is overreaching. The master does not write the sketch into the repo; the first task's builder commits it as a scaffold.

## 5. Scrap when it is wrong

If implementation keeps producing friction the sketch cannot absorb, throw the sketch out. The signal is a pattern, not one case: the same workaround repeated across unrelated code, many special-case branches, types needing `any` or casts to compile, a lock reflex where the sketch said state was not shared, callers needing the abstraction's internal rules, or two independent deviations of the same shape. A few edge cases do not condemn a design. When scrapping: re-run `how` on what exists, redesign as if the new constraints had been day-one, remove before adding, and return to step 3.

## Reply

The usage, the chosen shape, the synthesis decision, tradeoffs, the rejected alternative, and open questions, ready to paste into the SPEC.

## Gotchas

- Grounding by naming files. Produce the explanation.
- One candidate shape. Design it twice.
- Writing types before the caller's usage.
- Absorbing sketch deviations silently.
- Bolting fixes onto a design the pattern says is wrong.
