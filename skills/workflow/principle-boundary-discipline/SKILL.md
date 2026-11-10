---
name: principle-boundary-discipline
description: Apply when adding validation, parsing or a module seam. Validate at system edges, trust internal code, and keep boundaries clean.
user-invocable: false
---

# Boundary discipline
Check input where it enters; trust it once inside.

- Validate at the edge: user input, network, files and environment.
- Trust internal callers; do not re-check what the edge already checked.
- Keep each module's public surface small and its seams explicit.
- One writer per file; a subagent writes only the artifact it was given.
