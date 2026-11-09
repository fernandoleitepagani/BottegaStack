---
name: principle-encode-lessons-in-structure
description: Apply when the same mistake or correction happens twice. Turn the lesson into a hook, lint, test or script instead of more prose.
---

# Encode lessons in structure

A repeated lesson belongs in code that enforces it.

- Move the rule to the highest prevention: hook, then lint or test, then script, then prose.
- Add the check that would have caught the last occurrence.
- Delete the prose the new check now enforces.
