# Explore

How to learn the code before acting, and how to answer read-only questions. Explorers run as `subagent_type: "Explore"` on the explorer role (`subagents.md`) and never edit files.

## Briefing an explorer

One explorer per distinct angle (a subsystem, a flow, a question), 1 for a narrow question, 2 to 4 for a cross-cutting one, all in one message. Each brief stands alone:

> Question: <the question>. Your angle: <slice>; other explorers cover the rest, so go deep on yours. Don't edit files. Return: **Components** (name, `path:line`, one sentence each), **Flow** (step by step: function, file, what it calls next, the data passed), **Boundaries** (inputs and outputs of this area), **Surprises** (what looks one way and works another), **Open** (what you could not trace). Separate what you read from what you infer.

Merge the reports yourself. Read a file only to settle a disagreement or to judge code you will change.

## Why is it like this

Anchor first, inline: `git blame -L`, `git log --follow -p -- <file>`, PR numbers from merge subjects, and `gh pr view <n> --json title,body,comments,reviews` for the commits that matter. Give that anchor to one explorer per evidence source (git and PRs always; an issue tracker or docs only through an MCP server the user approved this session). Present what is known, what is inferred, and what is a guess, each labeled. When the question precedes a change, end with Preserve / Change / Avoid / Risk. The current shape is usually several old decisions stacked, not one.

## Read-only questions (no change)

- **How or why.** Answer as Overview, Key Concepts, How It Works, Where Things Live, Gotchas (drop the ones that don't apply), or as a recommendation with a tradeoffs table for a choice between alternatives. For "are we sure?", give your real judgment and push back on a wrong premise.
- **Symptom** (a leak, a CPU spin, a captured profile or trace). Capture or read the artifact without changing running code. Have a subagent parse a large artifact into sqlite, one row per sample or node (**Mechanize It**). Narrow to the hot path or the retainer chain, prove the mechanism with a paired before and after capture or added logging, and attribute it to a file and line. Without that proof, call it the strongest hypothesis. Once the cause is known, route the fix to `/implement`.

No final gate, no PR.

## Catch-up

"Catch me up", and the end of an unattended run. Read-only.

1. Gather your work, subagent reports, and the live state of every PR, CI run and agent this chat touched. Check each number at its source.
2. Open with one sentence naming what waits on the user, or that nothing does.
3. What happened, under 100 words: one plain bullet per thing the user asked for, with its outcome and whether it is done, running, failed, or unchecked.
4. The calls only the user can make (a product choice, an approval, an irreversible step, access you lack), about 30 words each: the call, your pick, what it changes, the evidence, the risk. Never invent one.

Plain words; no hashes or paths unless the user needs them to act.
