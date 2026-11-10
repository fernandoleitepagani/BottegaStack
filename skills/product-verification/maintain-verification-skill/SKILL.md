---
name: maintain-verification-skill
description: Periodic pass that keeps a project's `verify-*` skill and its feature map honest. Use when the project changed a lot, a proof failed for a reason the map did not warn about, or the user asks to audit the verification skill.
---

# Maintain a verification skill

Keep `.claude/skills/verify-<project>/` true to the code. Adapted from pstack's `maintain-verification-skill`.

## Steps

1. **Read the skill and its feature map.** Load `.claude/skills/verify-<project>/SKILL.md` and `features/README.md`. Stop with `GAPS` if none exists; suggest `create-verification-skill`.
2. **Read the source per feature.** Spawn one `explorer` per listed feature (up to 3 at once, read-only). Each reports from `file:line`: current entry points, new or removed sub-features, and anything the feature file claims that the code no longer does.
3. **Find unmapped features.** Compare the project's commands, routes, and jobs against the map. List each user-facing feature the map lacks.
4. **Drive it live.** Run the skill's Launch, Doctor, and Drive once, covering every mapped feature in a single session. Record the real result of each journey.
5. **Propose corrections.** For each difference, give the file, the line to change, and the evidence (the command and its output). A correction without proof is dropped. Never weaken a journey to make it pass.
6. **Apply with approval.** Show the proposed edits in chat and ask with `AskUserQuestion`. Apply only the approved ones, in one change, and re-run the affected journey.

## Gotchas

- Fixing the map to match a bug. If the code is wrong, report it; do not bless it.
- Editing without running. Every correction needs a command and its output.
- Leaving the app running after the live pass. Tear down what you started.
- Touching files outside `.claude/skills/verify-<project>/`.

## Report

```
CHECKED: <features driven>
CORRECTIONS: <file: change, with evidence>
UNMAPPED: <features the map lacks, or "none">
GAPS: <what could not be checked, or "none">
```
