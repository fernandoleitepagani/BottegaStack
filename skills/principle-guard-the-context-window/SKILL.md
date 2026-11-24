---
name: principle-guard-the-context-window
description: "Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Route bulk to subagents; keep summaries in the main thread, not raw payloads."
disable-model-invocation: true
---

# Guard the Context Window

**Why:** Context overflow degrades reasoning quality, creates compression artifacts, and halts progress.

**Pattern:**
- **Route bulk to files and subagents.** Send large outputs to a file and read the tail. Give wide reads to a subagent and keep its summary, not the raw payload.
- **Size phases and cap scope.** Limit files per phase and set turn budgets.
- **Avoid repeated reads.** Read a file once, note what you need, and move on.
- **Count what the mechanism costs.** A fan-out or loop spends context on every spawn and every report, so budget for that before you start.
