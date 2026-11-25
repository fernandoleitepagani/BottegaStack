---
name: reframe
description: Clarify a rough idea when you know what you want but lack the exact technical vocabulary. Outputs interpretations, ranked expert terms, analogies, and a crisp prompt for /plan or /maestro.
disable-model-invocation: true
---

# Reframe

Use before `/plan` or `/maestro` when you know what you want to build or fix, but are struggling to communicate it precisely (e.g. *"the settings page saves some fields right away and others only on submit, and people lose edits"*).

Do not edit any files. Read any referenced files first so every term is grounded in the real codebase.

## Output structure

1. **Interpretations (2–3):** If the description can mean more than one thing, list 2–3 concrete interpretations and the signal that separates them. Name the most likely intent.
2. **Expert terminology (8–12 terms):** Rank domain-specific terms by how drastically they would change what gets built. For each term: one-line definition, how it applies to this repo, and how to use it in a prompt.
3. **Cross-disciplinary analogies (2–3):** Name adjacent fields that solved the same problem under a different name, and state explicitly **where each analogy breaks down**.
4. **Reframed prompt:** Synthesize the best framing into a clean, technically precise prompt the user can copy straight into `/plan` or `/maestro`.

Keep every section concrete and terse. Run the reply through `../unslop/SKILL.md`.
