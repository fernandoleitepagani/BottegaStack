# Build the change and clean the diff

The build playbooks share one discipline. Say what you observed, and let the playbook demand the evidence. This page shows what to put in the prompt for each common build task, then the cleanup habit that keeps diffs reviewable.

## Prompt each build playbook with what you know

A bug prompt states the symptom and asks for a reproduction first:

```text
/maestro this command emits two records after a retry. repro first, then fix and verify.
```

A feature prompt states the behavior and what must not change:

```text
/maestro add a --json flag. text output stays byte-identical. verify both forms.
```

A refactoring prompt pins behavior before structure moves:

```text
/maestro move parsing into one module, zero behavior change. record the current output first and prove it's unchanged after.
```

A perf prompt states the measurement, not an impression:

```text
/maestro startup takes 1.8s on this fixture. trace it, fix the measured cause, show me before and after.
```

Each of these routes to its playbook ([Bug fix](../../skills/maestro/playbooks/bug-fix.md), [Feature](../../skills/maestro/playbooks/feature.md), [Refactoring](../../skills/maestro/playbooks/refactoring.md)), and the playbook supplies the steps you didn't type: reproduce before fixing, name the data shape before implementing, pin behavior before restructuring.

Sometimes you want the cause before any fix. For a live symptom, such as a leak, an idle CPU spin, or a glitch, the [Investigate playbook](../../skills/maestro/playbooks/investigate.md) instruments the running process. For a profile you already captured, the same playbook reads the artifact and maps the hot frame to source. Either way it returns a diagnosis, not a fix:

```text
/maestro here's a cpuprofile from the slow startup. tell me where the time goes and which source lines own it. no fix yet.
```

## Write the failing test first

When a bug has a cheap local test path, the whole prompt can be two words:

```text
/maestro fix this. failing test first.
```

In context, that's enough. The [Bug fix playbook](../../skills/maestro/playbooks/bug-fix.md) writes the smallest test that fails for the intended reason, then the fix, then reruns the test. If a test would need broad harness setup or brittle mocks, the skill says so and uses the closest executable check instead. Don't force a test where a real command is stronger evidence.


## When a check fails

You don't need to prompt for this. When a check fails or a review returns findings, `/maestro` runs [`crossfire`](../../skills/crossfire/SKILL.md)'s fix step, which turns the failure into a precise fix brief. A fresh delegate then applies the fix. There are at most two fix rounds per task. A third failure goes to the final gate as ESCALATE, with the evidence, so you decide.

On a high-risk task, `/maestro` also runs [`crossfire`](../../skills/crossfire/SKILL.md) on the finished diff before the final gate. Risk is `normal` or `high`, it is stated in the first message, and it only goes up during a run.

## Clean before you commit

Every agent follows the comments rule in the [delegate brief](../../skills/maestro/references/delegate.md) and runs its self-check before review, and the [`pr` skill](../../skills/pr/SKILL.md) and applies [`/unslop`](../../skills/unslop/SKILL.md) to the PR description and commit bodies. For the rest of the code, ask for the cleanup in plain words: remove narrating comments, unsupported guards, dead compatibility paths, and unrelated edits.

For prose, `/unslop` takes a target and any extra rules you have:

```text
/unslop the readme changes, no emdashes
```

You'll develop your own shorthand. The skill reads intent fine from terse prompts like `unslop that, tighten it`.

## Comments: none by default

Agents write no comments unless one of four cases applies: a license header, a constraint the code can't show (an external quirk, a spec or issue link, a named upstream workaround), a formatter or linter directive, or a doc comment on a public API. Before review, each agent greps its own diff for added comments and removes the rest. If code seems to need a comment saying what it does, the agent renames or reshapes it instead.

The division of labor: plain-words cleanup removes slop from the code, `/unslop` cleans it out of prose, and the comments rule keeps comments out.

**Pitfall:** cleanup is not optional polish. A diff with narrating comments and defensive dead weight reads as unfinished to reviewers, and the extra code is where the next bug hides. If the diff feels padded, say `remove the padding` before you commit, not after review calls it out.

Next: [Verify and ship](./06-verify-and-ship.md).
