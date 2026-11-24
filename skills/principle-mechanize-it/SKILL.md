---
name: principle-mechanize-it
description: "Apply to any non-trivial work (edits, migrations, analyses, checks) and whenever you catch yourself writing the same instruction or correction twice. Build the tool that does, proves, or enforces it (codemod, script, generator, lint, runtime check, or a skill delegates follow) instead of doing it by hand or adding more prose."
disable-model-invocation: true
---

# Mechanize It

Hand work and prose rules both depend on someone getting it right again next time. A tool does it the same way every time, reruns for free, and turns "trust me" into "run this". Default to the tool. Skip it only for trivial work, a couple of edits you can see at a glance.

**For the work in front of you:**

- Do the first unit by hand to learn the recipe, then build the tool. Prove it by rerunning it on that unit and diffing against your hand version. Make it safe to rerun.
- Codemod or script for edits, generator for repetitive files, a dump-to-sqlite query for analysis, a rerunnable check for verification.
- A deterministic tool beats fan-out. If one pass covers every unit, run it yourself instead of spawning delegates to hand-apply it.
- When you do fan out, write the recipe as a skill the delegates read: steps, verification contract, do-not-touch fences. Keep it outside their write scope.
- Build the smallest script that does the job, never a framework (principle-delete-first). Commit it when the work outlives the session.

**For recurring lessons:**

- A rule you've written twice becomes a lint, metadata flag, runtime check, or script, so the mistake fails loudly. Example: "never hand-type worktree paths" becomes a script that reads `git worktree list`.
- Confirm the structure catches the failure before you delete the prose. Once it does, the structural fix is the only fix.
- If the lesson needs judgment and can't be encoded, make the instruction prominent and add an example of the failure.

Applying this principle produces a file. If you cited it and the diff has no script, codemod, generator, check, or delegate skill, you didn't apply it. For scripting the verification itself, see principle-prove-it-works.
