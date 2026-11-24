---
name: principle-delete-first
description: "Apply when sizing a diff, sequencing an addition, refactor, or rewrite, or when tempted to add abstractions, layers, or signal threading. Remove before you build, and ship the smallest change that solves the problem."
disable-model-invocation: true
---

# Delete First

Every change starts by asking what can go. Remove complexity, then build on the simpler base. Leave the design a little simpler and more capable than you found it, behind the same or a smaller surface.

- **Sequence removal before construction.** Dead code, redundant validators, and stub references go first.
- **Minimize the diff.** The smallest change that solves the problem wins. Fewer lines beat "elegant" boilerplate.
- **One source of truth per decision.** Don't repeat a choice in several places. Decide once and pass the result as a plain value.
- **Build for observed usage.** No speculative validators, parsers, guards, or options beyond what the spec demands.
- **Cut before you polish.** Reach the minimum before you invest in quality.
- **No stubs.** A reference with no novel content gets deleted, not kept as a pointer. This holds for prompts and docs too.

The sign you skipped this: the diff adds a layer and removes nothing.
