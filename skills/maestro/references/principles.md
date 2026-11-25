# Principles

Seventeen rules, one section each. Name every principle that changed a decision, and the choice it changed.

## Delete First

Start every change by asking what can go. Remove dead code, one-caller wrappers and speculative options before you build. The smallest diff that solves the problem wins. One source of truth per decision. The sign you skipped it: the diff adds a layer and removes nothing.

## Shape Before Logic

Pick the data shape before writing logic: a state machine over scattered booleans, a table or registry over branching, a typed model over repeated shape assumptions, a module that owns one body of knowledge rather than one step of a pipeline. Scaffold first (CI, test setup, shared types). The sign you skipped it: one more `if` branch, or a second boolean that must stay in sync with the first.

## Redesign from First Principles

Fold a new requirement in as if it had been there from the start, not bolted on. Read every affected file, ask what you would build from scratch, propagate it through types, docs and examples, then deliver it in steps.

## Attack the Premise

When two fixes that share one premise fail the same check, write the premise down and test it before a third fix. Look at how the failures are spread, not only how big they are. Remove the condition rather than compensating for it.

## Minimize Reader Load

Code is maintainable when a reader can answer "where does X come from?" and "what can change X?" in under 30 seconds. Cut layers that only pass calls through, and shrink state scope: returns over mutation, locals over fields, derived values over synced copies.

## Mechanize It

A rule you have written twice becomes a lint, check, or script. Do the first unit by hand, then build the smallest tool that repeats it and diff it against your hand version. A deterministic script beats a fan-out of agents. Citing this principle with no new script or check in the diff means you didn't apply it. Repeated mistakes across sessions go to the **correct** skill.

## Boundary Discipline

Validate, parse and handle errors at system boundaries (CLI args, config, network, external APIs). Inside, trust the types and don't re-validate. Business logic lives in pure functions; the shell stays thin. Expose domain concepts, not the boundary's wire types.

## Type System Discipline

Make the compiler reject impossible states. Brand primitives that mean different things (`UserId`, `OrderId`). External data is untyped until a parse function turns it into the model. Derive types from the schema that owns the shape instead of hand-writing a parallel one.

## Make Operations Idempotent

Every state-changing step must converge to the same end state if it runs twice or after a crash at any point. Read the current state, compare it to the goal, apply only the difference. Anything a run leaves behind (a lock, a temp file, a claimed job) must be recognizably stale to the next run.

## Migrate Callers Then Delete Legacy APIs

Replacing an internal API: move every caller and delete the old one in the same wave. No shims, aliases, or dual paths. Update tests to the new contract and delete tests that only protected the old internals.

## Separate Before Serializing Shared State

Before two actors share mutable state, ask whether they need the same object. Usually they don't: give each its own file, key, branch or worktree and merge at read time. Only for a real invariant, serialize structurally (a lock, sequential phases, a single writer). Conventions are not concurrency control.

## Prove It Works

Check the real thing, never a proxy, a self-report, or "it compiles". Read the actual value. Prefer a script that reruns the check over a one-time look, and keep its output where a reviewer can rerun it. When a check fails, suspect the observation method before the system.

## Fix Root Causes

Fix the first place the system did something wrong, not the place it surfaced. Reproduce first, instrument instead of guessing, and ask whether the triggering state is legitimate. Guards, retries and swallowed errors usually hide the bug. Fix every instance of the pattern, not just this one.

## Sequence Work into Verifiable Units

Order work as small units that each end green before the next starts. Deliver commits and PRs in the order that proves the work: the failing test, then the fix; the subtraction, then the reshape.

## Test Behavior, Not Implementation

A test is a claim about what users of the code can observe. Keep a test that fails when the behavior breaks and survives a change to the internals. Derive the expected value from the requirement, never from a run of the code. Mock only at system boundaries.

## Guard the Context Window

Send bulk output to files and wide reads to subagents; keep their summaries, not raw payloads. Read each file once. Budget the context a fan-out or loop will cost before starting it. `/implement` holds each session to 300k tokens, ±10%.

## Never Block on the Human

For reversible work, decide, proceed, and report; the human corrects afterwards. Product direction still comes from the human, and irreversible actions (maestro **Autonomy**) still pause.
