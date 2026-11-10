# Make operations idempotent

A step you can run twice is a step you can trust.

- Check state before acting and skip work already done.
- Make create, install and update safe to repeat.
- Leave partial state recoverable on failure.
