---
name: how
description: Explain how a piece of code, module, or flow works. Use when asked "how does X work", when onboarding onto unfamiliar code, or before changing it; answer from file:line evidence, read-only, short answer first.
---

# How it works

Explain the code, change nothing. Read-only.

## Steps

1. Restate the question in one sentence and name the entry point you will trace.
2. Find the entry point (`rg`, `git grep`) and read only the files on the path.
3. Follow the call path caller -> callee across files; note where state is
   created, read, and mutated.
4. Answer first: a 2-4 sentence summary, then the walk-through in order.
5. Cite each claim as `path:line`; quote the smallest relevant snippet.

## Output

- Short answer first, then the flow in numbered order.
- Each step names `file:line` and what it does.
- State edge cases, error paths, and anything you could not verify.
- No fixes or opinions unless the user asks; if a fix is clearly needed, offer it
  separately.

## Gotchas

- Reading the whole repo. Search for the entry point, then read only the path
  (see principle `guard-the-context-window`).
- Explaining from memory or names. Every step needs `file:line` evidence.
- Burying the answer under the trace. Short answer first.
- Editing while explaining. This skill is read-only; propose changes separately.
