# Steer with principle names

The 18 principles live on one page, [`skills/maestro/principles.md`](../../skills/maestro/principles.md). Agents name each one that changed a decision. You can use the same names to steer mid-task:

```text
apply delete first. what can go before you add anything?
```

```text
prove it works. show me the real output, not the build log.
```

| When you see | Say |
|---|---|
| A diff that adds a layer and removes nothing | **Delete First** |
| Another `if` branch, or two booleans that must stay in sync | **Shape Before Logic** |
| A new requirement bolted onto the old design | **Redesign from First Principles** |
| A third fix on the same theory | **Attack the Premise** |
| Code you can't trace in 30 seconds | **Minimize Reader Load** |
| The same correction a second time | **Mechanize It** |
| Validation scattered through the core | **Boundary Discipline** |
| IDs of different kinds passed as plain strings | **Type System Discipline** |
| A step that breaks when it reruns | **Make Operations Idempotent** |
| A compatibility shim left behind | **Migrate Callers Then Delete Legacy APIs** |
| Two agents writing one file | **Separate Before Serializing Shared State** |
| "It compiles" offered as proof | **Prove It Works** |
| A guard around the symptom | **Fix Root Causes** |
| A big batch checked only at the end | **Sequence Work into Verifiable Units** |
| Tests that check internals, or that pass when the code is wrong | **Test Behavior, Not Implementation** |
| Raw logs pasted into the chat | **Guard the Context Window** |
| Asking permission for reversible work | **Never Block on the Human** |

Next: [Make it yours](./08-make-it-yours.md).
