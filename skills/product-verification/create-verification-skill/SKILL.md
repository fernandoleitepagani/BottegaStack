---
name: create-verification-skill
description: Use when a project has no `.claude/skills/verify-*` skill, or when its start command, drive recipe, or proof flows are undocumented. Interview the repo, then write a project verification skill and a feature map after the user approves the draft.
---

# Create a verification skill

Turn a project's real start, drive, and proof path into a project skill that `verification` loads. The next agent reads it cold, mid-task, having never seen the project. The approach follows pstack's `create-verification-skill` (Cursor, Lauren Tan), adapted to BottegaStack.

## 1. Interview the repo, not the user

Answer from the code; ask only what you cannot observe.

- **Surface:** what does a caller touch: a CLI, a service or API, a library, a data job, scripts? Pick the primary one and note the rest.
- **Run:** how does it start locally? Prefer the repo's documented command (package scripts, Makefile, README, `scripts/verify.conf`). Note ports, env var names (never values), seed data, auth.
- **Drive:** how can an agent exercise it? Existing harnesses first (test suites, fixtures, curl-able endpoints, expect or tmux for a TUI), then a generic recipe: plain commands, HTTP, or a PTY.
- **Observe:** what evidence can it capture: command output, exit codes, response bodies, logs, file and database state.
- **Isolate:** can two instances run side by side (ports, data dirs)? If not, say so; refusing to double-drive a shared instance beats corrupting it.

If the checkout does not build or start, fix that or report it first. Never read or print secrets or personal env values.

## 2. Write the skill

Show the draft in chat and write only after the user approves it with `AskUserQuestion`. Create `.claude/skills/verify-<project>/SKILL.md` at the project root, never in the BottegaStack repo. Frontmatter: `name: verify-<project>` and a `description` naming the project, the surface, and when to use it. Sections, each from what the interview found:

- **Launch:** the exact command, and how to tell it is ready (a log line, a probe). It must reach a usable state from an empty data dir; "ready" means usable, not just that a process answers. Include teardown. A short-lived CLI has no server: build once, run each drive in isolation.
- **Doctor:** one read-only check for "is this instance worth driving?" (process up, right build, port owned by us).
- **Drive:** the recipe with real commands from this repo, not examples.
- **Evidence:** what to capture and where, in the format `maestro verify record` expects (command, output, exit code). Proof standards: real path, not test-only endpoints; check side effects; observe what a dry-run skips; mocks only at an existing production boundary.
- **Cleanup:** tear down only what you started; never kill by process name; evidence survives cleanup.
- **Helpers:** point at `scripts/verify` instead of duplicating it. Any script the skill ships is executable and its use is shown in the skill.

## 3. Seed the feature map

Create `.claude/skills/verify-<project>/features/README.md` (an index) and one file per feature you can identify, the top 3 to 5 to start, from commands, routes, jobs, or docs. Each file has four sections: `Sub-features`, `How to get to it`, `Driving it`, and `Gotchas` (what proves it works, and the traps). If seed data lacks a precondition, the journey reports a failure and the reason goes in `Gotchas`; never weaken a journey to make it pass.

## 4. Prove it before handing it over

Run the skill's own instructions once: launch, doctor, drive one mapped feature, capture evidence, clean up. Confirm the evidence still exists after cleanup. Run cleanup after every failed attempt so nothing is stranded. A skill never executed is a draft; say so, and list any step a stand-in environment did that the real target will not.

## 5. Keep it honest

Point the user at `maintain-verification-skill` for keeping the map current as the project changes.

## Gotchas

- Guessing ports or commands. Run each one.
- Writing before approval.
- Copying secrets or personal data into the skill.
- Writing into the BottegaStack repo instead of the project.
- Leaving a process running after discovery.
- A feature map that lists only the convenient entry point.

## Report

```
SKILL: .claude/skills/verify-<project>/SKILL.md
FEATURES: <files in features/>
EVIDENCE: <commands run and output>
GAPS: <what could not be checked, or "none">
```
