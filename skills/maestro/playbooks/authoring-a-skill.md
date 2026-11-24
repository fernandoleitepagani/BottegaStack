### Authoring or modifying a skill

**You own the skill's voice.**

1. Write the SKILL.md yourself, following the rules below and the **technical-writing** skill (`../../technical-writing/SKILL.md`). Frontmatter: `name`, a `description` that says when to use it, and `disable-model-invocation: true` unless the model must start it.
2. Validate the skill: frontmatter has `name` and `description`, referenced files exist, cross-skill links resolve. A bundled skill added, renamed, or removed updates `skills/maestro/SKILLS-INDEX.md` (one line with its size).
3. Test cases if structural. Skip if subjective.
4. Run **Opening a PR**.

When in doubt, delete. Keep only prose that changes a decision. Tell it to do the thing and skip the reason. Explain only when the rule is confusing without one. Match tone to scope. Point at structural sources (types, READMEs, config) per the **mechanize-it** principle skill. Delegate to other skills by path. Don't restate. A workflow you keep hitting but isn't captured → propose a new skill.

**Reply:** summary of the skill, key design decisions, validation notes.
