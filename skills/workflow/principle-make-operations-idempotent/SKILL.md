---
name: principle-make-operations-idempotent
description: Apply when writing a script, migration, setup step or command. Rerunning it must be safe.
user-invocable: false
---

# Make operations idempotent

A step you can run twice is a step you can trust.

- Check state before acting and skip work already done.
- Make create, install and update safe to repeat.
- Leave partial state recoverable on failure.
