---
name: principle-stay-in-allowed-files
description: Apply when starting a task. Touch only its Allowed files; needing another one means report BLOCKED.
---

# Stay in allowed files
The allowed list is a hard boundary.

- Read the task's Allowed files and stay inside them.
- If the task needs another file, stop and report `STATUS: BLOCKED` with the path.
- Do not widen the task yourself.
- Stage explicit paths; never `git add -A`.
