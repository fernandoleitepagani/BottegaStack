---
name: sharpen
description: Strip vague adjectives and ambiguity from a prompt or spec, turning every requirement into a concrete, testable claim or explicit non-goal before writing code.
disable-model-invocation: true
---

# Sharpen

Use standalone on a rough prompt, or at the end of `/plan` right before writing `spec.md`. Do not expand scope—deepen precision without adding features.

## Steps

1. **Scan for soft language:** Flag every subjective or untestable phrase (*"fast"*, *"clean"*, *"robust"*, *"handle errors gracefully"*, *"user-friendly"*, *"scalable"*).
2. **Convert to observable claims:** Rewrite each flagged item into a concrete, verifiable condition (a threshold, an exit code, a state transition, an error format, or a test assertion) that `gate-check.sh --condition` can check directly.
3. **Name explicit non-goals:** List 2–4 things that are *out of scope* so `/tickets` and `/implement` don't invent them.
4. **Pin test seams:** Name the exact boundary where behavior will be tested (CLI, HTTP endpoint, pure function, UI state) and what may be mocked (system boundaries only).

Output the sharpened requirements cleanly so the user can approve them in one reply.
