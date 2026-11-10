---
name: principles
description: Apply when a task, review or skill cites a `principle <slug>`. Index of the 15 named rules; the full text of each is in this skill's `references/<slug>.md`.
user-invocable: false
---

# BottegaStack principles
Each rule's full text is `references/<slug>.md` beside this file; read it when a task cites the rule. Cite it as `principle <slug>`; reuse the slug so citations stay stable.
- `attack-the-premise`: question whether the request itself is right before building.
- `boundary-discipline`: validate at system edges, trust internal code; keep module seams clean.
- `encode-lessons-in-structure`: a repeated mistake becomes a hook, lint, test or script, not more prose.
- `exhaust-the-design-space`: list and compare real options before picking one.
- `experience-first`: judge UI and CLI changes by what the user sees and does first.
- `explain-the-number`: every metric or claim names its source and how it was measured.
- `fix-root-causes`: reproduce, find the cause, fix it; no symptom patches.
- `guard-the-context-window`: read narrowly, delegate wide searches, keep outputs short.
- `laziness-protocol`: do the smallest thing that fully meets the goal; reuse and subtract before adding.
- `make-operations-idempotent`: rerunning a script or step must be safe.
- `minimize-reader-load`: write so the reader needs the least effort.
- `never-block-on-the-human`: act on reversible work and report; ask only for irreversible or external actions.
- `prove-it-works`: define done as an observable result; nothing is done without real evidence; label claims measured, inferred or guessed.
- `sequence-verifiable-units`: break work into steps that each can be checked alone.
- `test-behavior-not-implementation`: tests assert external behavior; never edit or weaken existing tests to pass.
