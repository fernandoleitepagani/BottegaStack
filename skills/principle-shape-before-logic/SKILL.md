---
name: principle-shape-before-logic
description: "Apply before writing logic, when writing stateful code, or when code branches a lot or repeats a shape assumption across files. Choose the data structure that encodes the domain first, so the logic that follows is obvious and invalid states can't exist."
disable-model-invocation: true
---

# Shape Before Logic

Get the data shape right before you write logic. Define core types early, trace every access pattern, and pick the structure that matches the dominant paths. A structure that fits the domain deletes branches and makes invalid states unrepresentable. Choosing it now is cheap. Recovering it later reads as a refactor and gets deferred.

Reach for:

- A state machine instead of scattered booleans, phases, or lifecycle checks.
- A typed model instead of loose parameters or repeated shape assumptions.
- A map, registry, lookup table, or discriminated union instead of branching spread across files.
- A reducer or command/event model instead of ad hoc mutations.
- A module that owns one body of domain knowledge, not one step of a load, validate, transform, save sequence. Execution order is not ownership.
- A queue, cache, index, graph, tree, or normalized collection where the access pattern calls for it.
- When nothing fits, write down what the code must never allow and how the data is read, then pick the structure that encodes exactly that.

**DRY the structure, not every line.** Types and models converge. Three similar statements still beat a premature abstraction. Distrust an abstraction that adds indirection without removing branches, duplicated rules, invalid states, or lifecycle risk. Boring code is fine when the shape is already clear and local.

**Shared state.** Before two actors share state, ask what happens if the other one writes it concurrently. If the answer is not "nothing", isolate it (see principle-separate-before-serializing-shared-state).

**Scaffold first.** Work every later phase benefits from goes first: CI, linting, test infrastructure, shared types. Setup before features, tests before fixes. Each increment lands or deepens one coherent abstraction instead of special-casing callers.

The sign you skipped this: a feature grows an if/else chain by one more branch, or a second boolean must stay in sync with the first.
