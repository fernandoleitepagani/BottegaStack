# Eval
Use when the user wants to compare two versions of the stack or a skill on the same task ("does the new builder text do better?"). Adapted from pstack's `eval` playbook. You own the experiment; the candidates never learn they are measured. Track the steps in the todo list.
## What it can test
Anything that runs headless on the builder model: the `builder` agent, the skills it loads, and the headless reviewer prompt. Master routing is not covered; the runner starts only `builder` and `second-opinion`.
## Steps
1. **Frame.** State the variant under test (B) and the baseline (A, the installed stack), and what counts as success. Write 3 to 6 concrete criteria for the judge only; they stay in chat and never reach a candidate.
2. **Set up clean candidates.** One temp git repo per candidate with a project-shaped name and a small starter project. No path, file, or prompt may contain `eval`, `test`, `judge`, `rubric`, `score`, `compare`, `benchmark`, `candidate`, or `arena`. Variant B loads from a checkout: `BOTTEGA_PLUGIN_DIR=<checkout>`. A runs without it.
3. **Write one organic request.** The same text for every candidate, what a user would type: the goal, not the meta. Do not ask which skills or files it used and do not mention other candidates.
4. **Run.** In each repo: `maestro build --here <slug> --task "<request>" --block`, as background Bash tasks, at most 3 at once. They run on the builder model from `~/.config/bottega/builder.env`. Keep each printed session id, tokens, and steps.
5. **Judge.** Spawn one subagent on the `reviewer` model from `~/.claude/rules/bottega-models.md` (default `sonnet`, effort `low`). Give it the criteria and each result as "Result 1", "Result 2", never the variant or model names. It scores each criterion and picks the better result.
6. **Check the chain from the transcripts.** For each session id, read `~/.claude/projects/<repo-slug>/<session>.jsonl` (the slug is the repo path with `/` and `.` changed to `-`) and list the skills it loaded and the files it opened. Grade chain-following from that and the shape of the result, never from the candidate's own report.
7. **Read every result yourself.** Compare with the judge. A disagreement means a biased judge or an ambiguous criterion; read both rationales before deciding.
8. **Decide.** Recommend promoting B, keeping A, or re-running with a sharper criterion. Never promote on a single run: repeat each candidate at least twice and note the spread.
## Gotchas
- **Leaking the meta.** A prompt or path that says it is a test changes the behaviour.
- **Judging by variant name.** The judge sees labels only.
- **Trusting self-report.** Read the transcript.
- **One run as proof.** Runs are noisy; repeat and report the spread.
- **Grading what the master does.** Only headless roles run here.
## Reply
`Variant: <A vs B>` · `Criteria: <the 3-6 items>` · `Results: <per candidate: tokens, steps, notes>` · `Judge: <verdict>` · `Decision: <promote | keep | re-run>` · `Claims: measured | inferred | guessed`
