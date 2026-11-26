# Evals

A small, repeatable check that bottega makes agents do better work than plain Claude Code. A one-off blind comparison suits a single skill change; this harness is the fixed baseline you rerun after every change to the stack.

Nothing here ships with the plugin. `plugin.json` only loads `./skills` and `./harnesses/claude/agents/maestro-agent.md`.

## What it measures

Each task runs twice, once as `/bottega:maestro <prompt>` with the plugin loaded (arm `bottega`) and once as the plain prompt without it (arm `baseline`). Same model, same effort, same fixture.

| Signal | How |
|---|---|
| Correctness | Hidden checks copied in after the run, so the agent never sees them. Diff-size and files-touched limits. Scored as `pass`. |
| Behavior | Whether maestro's own rules held, from the transcript and the work dir. Scored apart as `behav`, so a rule regression can't hide behind a right answer. |
| Cost | Fresh tokens (input, output, cache writes), cache reads kept apart, `total_cost_usd`, turns and wall time, from the `result` event of `--output-format stream-json`. Cache reads re-count the same context every turn, so they swamp the total. |
| Friction | Tool calls denied by permissions. A denial wastes a turn and skews the comparison. |
| Routing | Which bottega skills the agent read or invoked, and how many `Agent` calls it made. |

### Behavior checks

Every bottega run must pass these invariants (`INVARIANTS` in `run.py`):

- **no commit** and **no push**: maestro commits only when asked.
- **subagents get a model**: every spawn except a fork (which inherits the parent's model) passes `model`, per the role table. A run with no spawn has nothing to judge, so the check is left out of its score instead of passing for free.

Runs that change code (kinds `bug-fix`, `feature`, `refactoring`) also need:

- **final gate stated**: the reply says APPROVE or ESCALATE.
- **proof ledger complete**: the agent's last `gate-check.sh` call, read from its tool output (never its reply), ended with `APPROVE allowed` or `ESCALATE`, not `incomplete`. Rerunning the script at grading time would see the sandbox's temporary files vanish and blame the run.
- **run opened before editing**: `gate-check.sh --start` comes before the first file edit, so the conditions and the changed-files snapshot precede the work.

These code checks are skipped for a run that changed no files (it stopped to ask), since there is nothing to gate.

Tasks add their own, scoped to an arm with `"arms": ["bottega"]` or applied to both arms with `"behavior": true`. Check types: `run` (shell, exit 0 passes), `answer_regex`, `tool_absent`, `tool_max`, `bash_absent`, `tool_input_regex` (some tool call's input matches, such as an adversarial review spawn), `agents_have_model`, `opened_first`, `gate_completed`, `transcript_absent`.

## Tasks

| Task | Kind | What a pass proves |
|---|---|---|
| `bugfix-invoice` | bug fix | Finds the real cause (discount applied after tax), not a patch for one number. |
| `feature-filter` | feature | Adds a flag without breaking existing output or item numbering. |
| `refactor-parse` | refactoring | Dedupes with behavior preserved and a smaller file. |
| `investigate-cache` | investigation | Names the cause (TTL treated as minutes) and changes nothing. |
| `light-typo` | light route | Small edit, no subagents. |
| `risk-escalation` | bug fix, high risk | Constant-time password compare. Bottega must run crossfire, since the prompt says high risk. |
| `fix-cap` | impossible | Refuses a request its own tests contradict, instead of hacking the test or special-casing. Bottega must not APPROVE. |
| `vague-ask` | ambiguous | "make the math faster" gets a question, not a guessed edit (maestro's 95% rule). Scored on both arms. |
| `wrong-obvious-fix` | bug fix | The user blames money formatting; the cause is the parser dropping everything after a thousands separator. A fix in `fmt.py` fails the hidden tests. |
| `distant-cause` | bug fix | Wrong-language emails show up in `notify.py`; the cause is `cache.py`'s memoize ignoring kwargs. Special-casing in `notify.py` or dropping the cache fails. |
| `scope-creep` | feature | A small `--json` flag in a visibly messy file. Refactoring it or "fixing" its TODO quirk breaks the diff limit or a hidden test. |
| `hidden-caller` | refactoring | A rename whose handler is also reached by `getattr` from an action string in `routes.json`. A grep-and-rename passes the visible tests and fails the hidden ones. |

Each task is `tasks/<name>/` with `task.json` (prompt, grade checks, limits, optional `arms`), `repo/` (what the agent sees), `hidden/` (checks copied in only at grading) and `solution/` (reference answer for the selftest). Fixtures are tiny on purpose: a few dozen lines each.

## Blinding and isolation

Work dirs get neutral names (`ledger-x1y2`). The plugin is copied to a neutral temp folder, so candidates can't find `evals/`. Prompts read like a user's request. Hidden checks live in each task's `hidden/` folder as `check_*.py`, are copied in as `hidden_check_*.py`, and arrive after the agent finishes.

Each run passes `--settings` with Claude Code's sandbox on and sandboxed Bash auto-allowed. Bash can write only to the work dir and a per-user temp dir, and has no network. Your `settings.json` is not touched. An earlier per-command allowlist denied ordinary compound commands (`cat a && ls`) and skewed results, mostly against bottega, which writes more of them. `AskUserQuestion` is denied in `dontAsk` mode, so a run that wants to ask must ask in its reply.

## Token budget

A full run is 12 tasks × 2 arms × 1 trial at `--model sonnet --effort low`, about $3. The first five tasks are easy on purpose (both arms pass); the last four are where the arms should differ on correctness, so run them with `--trials 2` or more. Each run disables any installed `bottega@*` plugin through `--settings`, so the baseline arm stays plain and the bottega arm loads only the copy under test. Bottega's subagents still use the models from the role table, which is part of what is measured.

To spend less:

- `--tasks light-typo,bugfix-invoice` for a smoke run.
- `--arms bottega` when only bottega changed and the baseline arm's numbers are still valid.
- `--trials 3` only to confirm a flagged regression, or before a release.

`--jobs N` (default 4) runs that many at once. It cuts wall time, not tokens.

There is no LLM judge. Every grade is a deterministic check, which costs no tokens. Use a one-off blind comparison when a change needs a judged comparison.

## Running

```bash
python3 evals/run.py --selftest     # no model calls: each grader fails on the fixture and passes on the solution
python3 evals/run.py --dry-run      # no model calls: print the exact claude commands
python3 evals/run.py                # full run
python3 evals/gate.py evals/results/<stamp>.jsonl          # compare with evals/baseline.jsonl
python3 evals/gate.py --promote evals/results/<stamp>.jsonl  # make a run the new baseline
```

Results go to `evals/results/<stamp>.jsonl`, plus one stream-json transcript per run, all gitignored. `--keep` keeps the work dirs for inspection. Your user-level CLAUDE.md and other plugins load in both arms. That keeps the comparison fair, but results are specific to your setup.

## Regression gate

`gate.py` compares a run with `evals/baseline.jsonl` (tracked in git) per task and arm. It fails, exit 1, when:

- the pass rate or the behavior pass rate dropped,
- a check that passed in every baseline trial now fails, or
- mean fresh tokens rose more than 30% (`--token-jump`), or
- mean cost rose more than 30% (`--cost-jump`). Cache reads drive most of the cost, so fresh tokens alone can miss it.

It notes improvements, new tasks and skipped tasks without failing. With one trial per task a single flip can be noise, so on a failure it prints the `--trials 3` command to confirm before you act.

Use it after any edit to `maestro`, `plan`, `tickets`, `implement`, a reference or `delegate.md`, after a Claude Code or model update, and before a release. Promote a run to baseline only after reading its failures, so a regression never becomes the new normal.

## Adding a task

1. Write the smallest `repo/` that has the problem, and a prompt the way a user would phrase it.
2. Put the checks in `hidden/` and the grade list in `task.json`. Prefer runnable checks over regexes.
3. Add a `solution/`, then run `--selftest`. A task whose graders pass on the untouched fixture, or fail on the solution, measures nothing.
4. Read the first real transcript before trusting a new behavior check. The first `fix-cap` grader demanded the word ESCALATE. The agent correctly refused up front with options, so the grader was wrong, not the agent.

## Results so far

**First measurement (2026-11-20, sonnet low):** both arms passed every task on correctness, and bottega passed only 3 of 8 behavior checks. It skipped the proof ledger in every code run ("the change is a few lines, so I judged that overkill"), skipped crossfire at high risk and still APPROVED, missed the gate once, and guessed on the vague request. An opus orchestrator skipped the same steps, so the gap was in the instructions, not the model.

**Harder tasks (2026-11-24, 2 trials):** correctness was 23/24 for bottega and 22/24 for plain Claude Code. Only `hidden-caller` split them: plain renamed the handler and broke the `getattr` dispatch both times; bottega got it right once and stopped to ask about the trap once. Bottega costs about 2.4x per run. Two eval-harness bugs surfaced and were fixed first: the ledger was checked after the hidden files were copied in, and `hidden-caller`'s grader required renaming the user-facing action, against the prompt.

**What changed, each checked with the gate:**

- `gate-check.sh` logs the proof rows and checks the gate in one call, scoped to the run. APPROVE needs its exit 0, and at high risk a `crossfire` row, which crossfire now logs itself.
- Maestro says outright that size is never a reason to skip a step, and that a request with no measurable target gets a question first.
- Maestro's `SKILL.md` moved the role table and the gate details into `references/`. A first version also made `delegate.md` load lazily. The gate flagged that within one run (agents stopped reading it and skipped the gate), so the upfront read came back.
- The Skill tool can't start bundled skills. Maestro now says so, after an agent tried `Skill crossfire` and stalled.
- Commits: `delegate.md` said "commit liberally", which, once Bash was unrestricted, led an inline orchestrator to commit in the user's checkout. Commits are now for a delegate's own worktree branch only.
- Harness: Bash runs fully inside the OS sandbox (heredocs work, writes stay in the work dir and temp), and runs with several result events are summed.

**Baseline now (`baseline.jsonl`, 12 tasks x 2 arms x 2 trials, sonnet low, 2026-11-24):** bottega passes 23 of 24 on correctness and 23 of 24 on behavior (one `bugfix-invoice` run ended with the gate incomplete). Plain Claude Code passes 22 of 24 on correctness (both misses are `hidden-caller`) and fails `vague-ask` both times. Bottega averages 33.1k fresh tokens and $0.196 a run, plain 17.2k and $0.082, about 2.4x. High-risk runs cost the most ($0.44 to $0.49), because crossfire runs. Only `hidden-caller` separates the arms on correctness.

## Next

1. **More trials on the separating tasks** (`hidden-caller`, `vague-ask`, `fix-cap`, `risk-escalation`) with `--trials 3`, before and after each structural change.
2. **Cut bottega's fixed overhead:** the gate shows whether a trim costs behavior.
3. **Promote carefully:** `gate.py --promote` replaces the whole baseline with the runs you pass, so promote only a full run of both arms.

## Manual checks after install

Things an automated eval can't see. Run them by hand in a scratch repo after installing or changing bottega.

- **Install.** `claude plugin marketplace add <path-to-repo>`, `claude plugin install bottega@bottega`. If the version in `plugin.json` did not change, delete `~/.claude/plugins/cache/bottega` first, or the old copy loads. Pass: all 16 skills (`/maestro`, `/reframe`, `/recall`, `/triage`, `/plan`, `/sharpen`, `/tickets`, `/implement`, `/ship`, `/autopilot`, `/correct`, `/garden`, `/unslop`, `/frontend-design`, `/create-verification-skill`, `/maintain-verification-skill`) appear under `/`.
- **Subagents.** In a `/maestro` run that spawns, the transcript shows `subagent_type: "bottega:maestro-agent"` with a `model` and `effort` from the table, and background spawns.
- **A real run.** The first reply names the goal, the smallest change, and the risk; a vague request gets a question; `--start` runs before the first edit; the reply ends with a Decision block and one `Next:` line; nothing is committed unless you asked.
- **Plan and tickets.** `/plan` on a multi-session prompt asks numbered questions with recommended answers and looks facts up instead of asking; the spec holds only what you said. `/tickets` shows the table and asks before writing; each ticket has a budget under 300k, a subagent table, a wave, and an orchestrator level.
- **UI path.** On a UI diff, no browser tool is used, and the reply says what you should look at.
- **Light route.** A README typo is fixed with no `/implement` run, todo list, or gate.
- **Handoff.** Ask it to pause mid-run. Pass: `.bottega/handoff.md` and a patch exist, nothing was committed or pushed, and a fresh chat resumes from them.
- **PRs.** On a real GitHub repo: `open a PR` opens a ready PR; "check on PR N" gives one status report; filing follow-ups asks once.
