---
name: principle-test-behavior-not-implementation
description: Apply when writing or changing tests. Assert external behaviour, write the failing test first, and never weaken existing tests.
---

# Test behavior, not implementation
Tests describe what the system does, not how it does it.

- Write the failing test at the named seam first, then make it pass.
- Assert public behaviour; do not mock internals or private methods.
- Keep tests readable as a specification and stable across refactors.
- Never edit, delete, skip or weaken an existing test to pass; report BLOCKED or get approval.
