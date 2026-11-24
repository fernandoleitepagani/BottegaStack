# Core principles

Read the section for a principle before applying it. Name each principle you applied in your report.

## Delete First

Every change starts by asking what can go. Remove complexity, then build on the simpler base. Leave the design a little simpler and more capable than you found it, behind the same or a smaller surface.

- **Sequence removal before construction.** Dead code, redundant validators, and stub references go first.
- **Minimize the diff.** The smallest change that solves the problem wins. Fewer lines beat "elegant" boilerplate.
- **One source of truth per decision.** Don't repeat a choice in several places. Decide once and pass the result as a plain value.
- **Build for observed usage.** No speculative validators, parsers, guards, or options beyond what the spec demands.
- **Cut before you polish.** Reach the minimum before you invest in quality.
- **No stubs.** A reference with no novel content gets deleted, not kept as a pointer. This holds for prompts and docs too.

The sign you skipped this: the diff adds a layer and removes nothing.

## Shape Before Logic

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

**Shared state.** Before two actors share state, ask what happens if the other one writes it concurrently. If the answer is not "nothing", isolate it (see Separate Before Serializing Shared State).

**Scaffold first.** Work every later phase benefits from goes first: CI, linting, test infrastructure, shared types. Setup before features, tests before fixes. Each increment lands or deepens one coherent abstraction instead of special-casing callers.

The sign you skipped this: a feature grows an if/else chain by one more branch, or a second boolean must stay in sync with the first.

## Redesign from First Principles

**Scope.** Adding a requirement to a design. Removing an old internal API is Migrate Callers Then Delete Legacy APIs (architecture.md).

When integrating a change, don't bolt it onto the existing design. Redesign as if the requirement had been a foundational assumption from the start.

- Read all affected files and understand the current design
- Ask: "if we were writing this from scratch with this new requirement, what would we build?"
- Propagate the change through every reference: types, docs, examples, rationale sections
- Think about the whole redesign, then deliver it incrementally

This is the method for preserving option value when integrating changes into an existing design.

## Attack the Premise

When two or more fixes that share one premise have failed the same gate, suspect the premise, not the fixes.

**Why:** Each failed fix is evidence against the belief it assumed. A third fix on the same premise spends effort where the evidence already says the cause is not.

**Pattern:**
- **Write the premise down.** The premise is the one sentence that every failed fix assumed.
- **Test the premise before the next fix.** Find an observation that would come out differently if the premise were false, and make it. Look at how the failures are distributed, not only at how large they are. Make the check rerunnable per [Mechanize It](core.md).
- **Follow the evidence.** If it contradicts the premise, the cause is elsewhere. Look for what the failures have in common that the premise did not predict. If it confirms the premise, ask the next "why" per [Fix Root Causes](verification.md). The earlier fixes may have treated a consequence instead of the cause.
- **Remove the condition instead of compensating for it**, per the [Delete First](core.md). If the evidence shows that one part always lands on the losing side, change what puts it there. A mechanism that cleans up after it leaves the cause in place and adds work on every run.

**Stop:** Do not start the next fix before the premise is written down and tested.

This principle is distinct from [Redesign from First Principles](core.md), which rebuilds a design around a new requirement. It questions a fact the current design assumes.

## Minimize Reader Load

Maintainability is the work a reader must do to understand code. Track two axes: **layers to trace** (indirections between the question and the answer) and **state to hold** (hidden or mutable context the reader must keep in their head). LOC, cyclomatic complexity, and "clean architecture" are proxies. Reader load is the thing that matters. The two axes are independent. A flat file with 50 globals can be as hard to reason about as a 6-layer adapter stack. Guard both. This is the human analog of [Guard the Context Window](delegation.md). Working memory is finite for readers too.

- **Collapse layers** that cost more than they save: wrappers with one caller, adapters with no second implementation, speculative indirection that was never needed. Inline them.
- **Make adjacent layers change the abstraction.** A layer that repeats the same methods and arguments adds reader load without compression. Collapse pass-through layers.
- **Demand interface compression.** A broad interface that hides little complexity makes readers learn both the surface and the implementation. Prefer boundaries that hide meaningful decisions.
- **Shrink state scope:** prefer pure functions (returns over mutations), locals over fields, fields over module state, and module state over globals. Derive instead of sync.
- **Name the invariant at the boundary,** not in every consumer, so the reader learns it once.
- Before adding a layer or a piece of state, ask: does it reduce reader load elsewhere by at least as much?

**The test:** can a new reader answer "where does X come from?" and "what can change X?" in under 30 seconds? If not, cut layers or cut state.

## Outcome-Oriented Execution

**Scope.** A planned rewrite or migration that may break intermediate states on purpose. For ordinary multi-step work where every unit must stay green, use Sequence Work into Verifiable Units (verification.md).

Optimize for the intended, verifiable end state rather than preserving smooth intermediate states.

**Why:** Keeping every intermediate step fully stable often creates temporary compatibility code that becomes long-lived debt. Converge on the target architecture and prove correctness at explicit verification boundaries.

**Core rule:**
- Prioritize end-state integrity over transitional stability
- Intermediate breakage is acceptable when it is planned, scoped, and reversible

**Guardrails:**
- Use this for planned rewrites and migrations with explicit phase boundaries
- Declare where temporary breakage is acceptable
- Keep high-signal checks for actively touched areas while migrating
- Require full static and runtime verification at plan completion

## Exhaust the Design Space

**Scope.** This decides *when* to compare designs. *How* is the Prototype playbook (throwaway sketches) or the **parallel** skill's bakeoff mode (competing candidates).

- Build 2-3 competing prototypes before committing to one
- Make each prototype cheap and throwaway, differing in the decision that matters
- Compare them side by side on the same task, not one after another from memory
- Pick on observed behavior, then discard the losers instead of keeping them as options
- It also applies to product design decisions where user experience depends on feel, not logic.

## Mechanize It

**Scope.** When a mistake repeats across sessions, the **correct** skill (`../../../correct/SKILL.md`) is the procedure for making it impossible.

Hand work and prose rules both depend on someone getting it right again next time. A tool does it the same way every time, reruns for free, and turns "trust me" into "run this". Default to the tool. Skip it only for trivial work, a couple of edits you can see at a glance.

**For the work in front of you:**

- Do the first unit by hand to learn the recipe, then build the tool. Prove it by rerunning it on that unit and diffing against your hand version. Make it safe to rerun.
- Codemod or script for edits, generator for repetitive files, a dump-to-sqlite query for analysis, a rerunnable check for verification.
- A deterministic tool beats fan-out. If one pass covers every unit, run it yourself instead of spawning delegates to hand-apply it.
- When you do fan out, write the recipe as a skill the delegates read: steps, verification contract, do-not-touch fences. Keep it outside their write scope.
- Build the smallest script that does the job, never a framework (Delete First). Commit it when the work outlives the session.

**For recurring lessons:**

- A rule you've written twice becomes a lint, metadata flag, runtime check, or script, so the mistake fails loudly. Example: "never hand-type worktree paths" becomes a script that reads `git worktree list`.
- Confirm the structure catches the failure before you delete the prose. Once it does, the structural fix is the only fix.
- If the lesson needs judgment and can't be encoded, make the instruction prominent and add an example of the failure.

Applying this principle produces a file. If you cited it and the diff has no script, codemod, generator, check, or delegate skill, you didn't apply it. For scripting the verification itself, see Prove It Works.
