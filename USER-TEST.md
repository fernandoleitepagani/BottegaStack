# What to test after installing v2

Run the sections in order. Each check says **how** to test it and what a pass looks like. Use a throwaway repo for sections 4 to 6:

```bash
mkdir -p ~/scratch/bottega-test && cd ~/scratch/bottega-test && git init
# add a tiny app with one test, e.g. a sum() function with a deliberate bug
```

## 1. Install

- [ ] **Old plugin off.** How: `claude plugin list`, find the v1 entry (`bottega@<marketplace>`), then `claude plugin disable bottega@<marketplace>`. Pass: `claude plugin list` shows it disabled.
- [ ] **v2 installed.** How: `claude plugin marketplace add ~/Projects/Bottega-v2`, then `claude plugin install bottega@bottega`. Pass: `claude plugin list` shows `bottega@bottega` enabled.
- [ ] **Right skills show up.** How: start a new chat, type `/` and scroll, or type `/bottega:`. Pass: `/maestro` and `/setup-maestro` are listed. `maestro-models`, `backlog-triage`, `animation`, `simplify` (bottega's) and `review-code` are not.
- [ ] **Only setup-maestro loads on its own.** How: in a new chat, type `set up maestro` (no slash). Then in another new chat, type `explain how this repo works` (no slash). Pass: the first loads `setup-maestro`. The second does not load `how` or any other bottega skill (no "Skill" tool call in the transcript).

## 2. `/setup-maestro`

Back up first: `cp ~/.claude/settings.json ~/settings.bak.json; cp ~/.claude/rules/bottega-models.md ~/models.bak.md`.

- [ ] **Rule rewritten in v2 format.** How: run `/setup-maestro`, answer its questions, then `cat ~/.claude/rules/bottega-models.md`. Pass: the roles match the "Models per role" table in `skills/maestro/references/subagents.md` (orchestrator, code delegate, reviewer, explorer…). No `builder: headless`, no `master:`, no `xhigh` or `max` anywhere.
- [ ] **Verification offer.** How: run `/setup-maestro` in the scratch repo (no `.claude/skills/verify-*`). Pass: it offers `/create-verification-skill` once. In a repo that has a `verify-*` skill, it doesn't offer.

## 3. Models and effort reach the subagents

- [ ] **Agent name resolves.** How: in the first run, check the Agent tool call. Pass: `subagent_type: "bottega:maestro-agent"` spawns without an "agent not found" error. If it errors, try the bare `maestro-agent` and report which works.
- [ ] **Model is passed.** How: in the scratch repo, run `/maestro fix the bug in sum(), the test must pass`. While it runs, open the agents view (press the arrow/`ctrl+o` on the agent line, or check the transcript's Agent tool call). Pass: each `maestro-agent` Agent call has `model` and `effort` set, and they match your rule file for its role.
- [ ] **Model is actually used.** How: open the subagent's transcript (`~/.claude/projects/<scratch-dir>/…/subagents/*.jsonl`) and check its `"model"` field: `grep -o '"model":"[^"]*"' <file> | sort | uniq -c`. Pass: it matches the model you passed (for example a sonnet ID for the code delegate).
- [ ] **Effort is honored (unverified).** How: give the same small task twice, once passing effort low and once medium (normal vs "high risk"), and compare the subagent's thinking length or token count in its transcript. Pass: the medium run thinks visibly more. If both look the same, effort is ignored for plugin agents. Report it.
- [ ] **Risk changes the roles.** How: run the same task again with "high risk" in the prompt. Pass: the reviewer's Agent call uses sonnet medium, and a solo crossfire agent runs. At normal risk, no crossfire runs.
- [ ] **No xhigh/max.** How: after the runs, `grep -rhoE '"effort":"[a-z]+"' ~/.claude/projects/<scratch-dir>/ | sort | uniq -c`. Pass: no `xhigh` or `max`. `high` appears only on haiku calls.
- [ ] **Background agents (unverified).** How: during a run with explorers, check whether the main chat keeps going while they work (you see a "running in background" notice). Pass: it continues and gets notified when they finish. If it blocks, `background: true` is ignored. Report it.

## 4. One real `/maestro` run (scratch repo)

Prompt: `/maestro add a multiply() function with a test; done when the test suite passes`.

- [ ] **Playbook and risk.** How: read its first reply. Pass: it names a playbook (Feature) and a risk, and the todo list shows the playbook steps, with skipped ones marked `skip: <reason>`.
- [ ] **Asks before architect/arena.** How: give a change that crosses a module boundary and watch for the suggestion. Pass: it asks (question UI) before running `architect` or `arena`. Answer "no" once. Pass: neither runs. On a change inside one function it may skip architect without asking.
- [ ] **95% rule.** How: give a vague prompt: `/maestro make the math faster`. Pass: it asks one targeted question or reads the code first, and doesn't start editing on a guess.
- [ ] **State in .bottega/.** How: after the run, `git status --porcelain; ls .bottega`. Pass: run files are under `.bottega/`. The only other changes are the code and test.
- [ ] **Fix rounds capped at 2.** How: give a task the test can't pass (e.g. "make sum(2,2) return 5 while keeping the test that expects 4"). Pass: it stops after 2 fix rounds and ESCALATEs to you.
- [ ] **Final gate.** How: read the last reply of a normal run. Pass: it says APPROVE or ESCALATE, with the evidence (test output).
- [ ] **No commit/push.** How: `git log --oneline; git status`. Pass: no new commit unless you asked for one.
- [ ] **Handoff threshold.** How: hard to trigger on purpose. During a long run, check `/context`. Pass: around 60% (or 300k tokens) it writes a handoff and suggests a fresh chat.

## 5. UI path (a repo with a front end)

Use a small web app (any framework). Prompt: `/maestro change the submit button label and color; done when it builds`.

- [ ] **One reviewer, main chat stays clean.** How: in the main transcript, check the Skill/Read calls. Pass: the main chat never reads a `better-*` SKILL.md. One `maestro-agent` (role: reviewer) is spawned, and its transcript reads `interface-review`.
- [ ] **No browser.** How: grep the run's transcripts for browser tools: `grep -l "Claude_Browser\|claude-in-chrome\|playwright\|screenshot" ~/.claude/projects/<app-dir>/**/*.jsonl`. Pass: no matches (other than text mentions). The reply lists checks for you (what to open, do, expect), marked unverified.
- [ ] **How many better-* loaded.** How: `grep -o 'better-[a-z]*/SKILL.md' <reviewer transcript> | sort -u`. Note the count. 1–2 is scoped. 6 means `better-interface` step 4 loaded everything (expected possible cost).

## 6. Spot checks

- [ ] **diagnosis.** How: in the scratch repo, break the test, then `/maestro the test fails, fix it`. Pass: on the failing check, a `maestro-agent` with the reviewer model reads `diagnosis`, writes a fix brief, and a *different* delegate makes the fix. Any temporary logging stays out of the final diff.
- [ ] **Output paths.** How: run `/review-pr <n>` on a real PR you own. Pass: the file appears at `.bottega/review-pr-<n>.md`, and nothing new at the repo root.
- [ ] **file-followups.** How: in a GitHub repo you own (a test repo), after a run that recorded follow-ups, run `/file-followups`. Pass: it shows the list and asks once. Answer yes. Then `gh issue list --label <followup label>`: issues have the label, and no title contains the label text. Close the test issues afterwards.
- [ ] **Multi-phase plan.** How: `/maestro plan a 3-PR change that adds logging, then config, then docs; don't implement`. Pass: the reply reports the step 6 plan check with nothing left unfixed, 3 lanes at normal risk. No code is changed.
- [ ] **Old rule format.** How: temporarily restore v1 rules (`cp ~/models.bak.md ~/.claude/rules/bottega-models.md`), start a new chat, run a tiny `/maestro` task, and check the reviewer's model. Expect sonnet medium (the v1 line matches). Then rerun `/setup-maestro` to restore v2.

## 7. Then

- [ ] Write down every failure (section and check), fix it in Bottega-v2, and rerun that check before copying over BottegaStack.
- [ ] Restore if needed: `cp ~/settings.bak.json ~/.claude/settings.json`.

## 8. Added in revision pass 3

- [ ] **Closeout choice.** How: finish a `/maestro` run without saying what to do with it. Pass: after APPROVE/ESCALATE it ends with one line offering PR, commit only, rework, reject. Pick "reject". Pass: nothing is deleted and no commit is made (`git status` still shows the changes).
- [ ] **Light route.** How: `/maestro fix the typo in README.md`. Pass: no playbook, no todo list. It edits, names the check, and replies. Then `/maestro bump the CI node version`. Pass: it uses a playbook, because CI is runtime behavior.
- [ ] **Proof ledger.** How: after any normal `/maestro` run, `column -t -s$'\t' .bottega/proofs.tsv`. Pass: a `run` row, then one `condition` row per acceptance condition, then one `proof` row per condition with the same text, each with evidence and PASS/FAIL/INCONCLUSIVE, and the gate's Evidence matches it. Then start a run and say "skip proving X" mid-way. Pass: that row is WAIVED and its evidence starts with `user:` and your words. A condition whose latest row is FAIL or INCONCLUSIVE must make the gate ESCALATE; a FAIL followed by a PASS for the same condition approves. `expect` rows name the files the change touched, and a stray file (for example `touch stray.log` mid-run) makes `gate-check.sh` exit 2. The run's rows start after a `run` row, and the reply shows `gate-check.sh` exiting 0 before any APPROVE. At high risk the ledger also has a `crossfire` row.
