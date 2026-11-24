# Make it yours

maestro is one person's style. The playbooks, routing, and model roles underneath it work just as well with yours. This page covers capturing follow-ups, fixing the repo so agents stop repeating mistakes, authoring a focused skill, and testing a skill change before you trust it.

Start smaller than you think. You don't need many skills on day one, or even this whole plugin. Prompt plainly, watch where agents fail, and add a skill or a check when the same failure shows up twice.

## File follow-ups with `/pr followups`

Right after a task that left loose ends, run:

```text
/pr followups that took way too long. file what we learned so the next run doesn't repeat it.
```

[`/pr`](../../skills/pr/SKILL.md) (followups mode) lists the follow-ups from the session as proposed GitHub issues, asks you to confirm once, and files them with `gh`. Confirm only items that would change a future decision. One weird session is an anecdote, not a rule.

## Fix the environment with `/correct`

When you correct agents for the same mistake again and again, the fix belongs in the repo, not in your next prompt. Rank the options by how well they hold:

1. Make the mistake impossible with architecture or a better data structure.
2. Block it with types, or with a lint or CI check whose error names the fix.
3. Catch it with a test.
4. Write it down as a doc or agent rule. Nothing fails when an agent skips a rule, so this comes last.

Human review isn't on the list. A reviewer who must catch the same mistake on every PR is the problem this fixes. [`/correct`](../../skills/correct/SKILL.md) does the work:

```text
/correct agents keep calling the database client directly instead of going through the repository layer
```

It reads recent commits, reverts, review comments, and comments that explain workarounds, then groups the mistakes into classes. A class counts once it has happened twice. It fixes the most frequent classes one commit each, at the highest level that works, and proves each new check fails on a real past mistake. It also keeps a table in the agent instruction file that pairs each rule with what enforces it, so a rule that nothing enforces shows up as a repeat. The reply lists each class with its evidence, the level chosen, and why a higher level didn't work.

Run it with no argument and it finds the classes from history on its own. `/pr followups` records loose ends from one session. `/correct` changes the repo so a mistake class can't come back. Pair it with `/architect` when the fix is a new boundary. [Run many tasks in parallel](./07-overnight.md#run-many-tasks-in-parallel) has a prompt that does both across a whole repo.

## Author a focused skill

When you already know the workflow you want to capture:

```text
/maestro write a skill for verifying database migrations in this repo
```

Writing a skill is a normal Feature run: keep only prose that changes a decision, run `python3 scripts/lint-skills.py`, and ship it through the `pr` skill. Agent-facing prose has a higher bar than human prose, because an unhelpful sentence becomes an instruction some future agent follows.

One special case has its own generators. A skill that must run your app and prove behavior is a verification skill, so use [`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md) and [`/maintain-verification-skill`](../../skills/maintain-verification-skill/SKILL.md) instead. [Verify and ship](./06-verify-and-ship.md#create-a-project-verification-skill) covers it.

## Write prose that reads clean with `/unslop`

Skills aren't the only prose you ship. For docs, readmes, PR descriptions, and commit messages:

```text
/unslop review the readme changes
```

[`/unslop`](../../skills/unslop/SKILL.md) strips the patterns that make text read as machine-written and keeps the meaning. `/maestro` applies it to every reply and PR body.

## Test a skill change

A skill edit affects every future session. For bottega itself, run the evals in `evals/` before and after a structural change (see `evals/README.md`). Fix a misbehaving skill in its own PR, not tangled into feature work.

Next: [Recipes and pitfalls](./10-recipes-and-pitfalls.md).
