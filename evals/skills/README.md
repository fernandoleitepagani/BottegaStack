# Skill evals

Use this folder to test skill triggering and skill output.

## Trigger tests

For each skill, write three prompts:

1. One that should trigger it.
2. One that should not trigger it.
3. One ambiguous prompt.

Record the expected skill and the actual skill.

## Output tests

For each skill with a fixed output contract, write one small input and the
expected file shape. Run it after every skill edit.

## Rule

A skill change must improve the trigger or output score without breaking the
other cases. If the gain is within noise, do not keep it.
