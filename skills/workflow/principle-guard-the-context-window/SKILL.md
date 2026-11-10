---
name: principle-guard-the-context-window
description: Apply when a task needs reading, searching or large output. Read narrowly, delegate wide searches and keep outputs short.
user-invocable: false
---

# Guard the context window
Spend context on what the task needs and nothing else.

- Read the task, its constraints and the neighbouring code before editing.
- Search with `rg` and read only the matching lines.
- Delegate wide or noisy searches to a subagent and keep its summary.
- Print command output narrowly; never dump a whole log.
