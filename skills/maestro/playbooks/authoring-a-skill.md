### Authoring or changing a skill

**You own the skill's voice.** Adapted from pstack's `poteto-mode` authoring-a-skill playbook (MIT, see LICENSE). A skill edit changes every future session, so it runs as a gated change.

1. Open the run (`<maestro dir>/playbooks/final-gate.md`, step 0), with conditions for what the skill must now make an agent do.
2. Write or edit the `SKILL.md`. Keep only prose that changes a decision. Tell it to do the thing; explain only when the rule is confusing without a reason. Point at structural sources (types, READMEs, config) instead of restating them (**Mechanize It**). Delegate to other skills by path, never restate them.
3. Validate: frontmatter has `name` (matching the directory) and `description`; every referenced file exists; every relative link resolves; the repo's own skill lint passes if it has one.
4. Run it through `/unslop` (`../../unslop/SKILL.md`).
5. When the change is structural, try the skill on one real task and keep the output as the proof. Skip for wording changes.
6. Run the final gate (`<maestro dir>/playbooks/final-gate.md`), then `/ship` when asked.

When in doubt, delete. A workflow you keep repeating that no skill captures is a proposal for a new skill, not a longer one.

**Reply:** what the skill now does, the key design decisions, and the validation and trial results.
