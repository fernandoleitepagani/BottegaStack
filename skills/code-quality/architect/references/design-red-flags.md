# Design red flags

Screen every candidate sketch; a red flag is a reason to revise or reject the shape.

- **Shallow module.** A large interface that hides little. Signs: callers coordinate several methods for one operation; public options expose internal stages; learning the interface does not save learning the implementation. A deep module concentrates capability behind one small interface; a deep call chain only scatters understanding.
- **Information leakage.** Several modules depend on the same internal decision (a representation, policy, or protocol detail), so changing it needs coordinated edits. Public re-exports of wire or transport types are leakage: parse external data into domain types behind the interface.
- **Temporal decomposition.** Modules split by execution order (load, validate, transform, save) instead of the knowledge they own, repeating one representation and its invariants across boundaries. Group by ownership of the decision.
- **Pass-through method.** Forwards the same arguments to another method with the same shape and hides nothing. Remove it, or move the responsibility to the module that can finish the operation.
- **Split ownership.** More than one module writes the same state or keeps its own copy. Give each piece of state one owner; others read it or ask the owner to change it.

Adapted from pstack's `architect` reference (Lauren Tan, MIT) and the deep-module vocabulary in `codebase-design`.
