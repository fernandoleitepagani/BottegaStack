---
name: principle-subtract-before-you-add
description: Apply before adding code, text or options. Remove or simplify first; a refactor changes structure, not behaviour.
---

# Subtract before you add
Less is the default; add only what survives subtraction.

- Delete dead code, duplicate rules and unused options first.
- Reuse or extend what exists before writing new.
- For a refactor, put tests before and after and keep behaviour the same.
- Use expand-contract when a change cannot land in one step.
