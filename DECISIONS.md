# Bottega v2: decisions

The decisions that shape the stack and why. History lives in the backup tarballs, not here. When a decision changes, edit its line instead of appending a new round.

Base: a port of pstack (Lauren Tan, MIT). When in doubt, the port wins. All changes happen inside `Bottega-v2/`, which later replaces `BottegaStack/` as a drop-in.

## Scope

- **Claude Code only.** No third-party models or harnesses for now. A headless wrapper (`opencode run`, Gemini CLI) is the deferred path if this reopens.
- **No hooks, no CLI.** Rules are prose the model follows; `scripts/lint-skills.py` and CI keep the prose in sync. A CLI saves under 2% of a run's tokens, and isn't worth a cross-platform binary.
- **Per-repo state only.** `.bottega/` holds run state and stays untracked. Cross-repo memory is left to Claude Code's own user memory.
- **Linux and macOS only.** One version of every script, written for both (bash 3.2, BSD and GNU tools, Python 3.9+), with no `jq` dependency. CI runs the same checks and `scripts/test-scripts.sh` on Ubuntu and macOS, plus a Python 3.9 job. Native Windows is not supported; WSL counts as Linux.
- **No UI driving.** Where a change needs a visual check, the agent says what to look at and the user checks it.

## Naming

- Plugin `bottega`, entry skill `/maestro`. `setup-pstack` → `setup-maestro`, `poteto-mode` → `maestro`, `poteto-agent` → `maestro-agent`, `poteto-help` → `maestro-help`, `.pstack/` → `.bottega/`.
- Plugin agents are namespaced: `bottega:maestro-agent`, `bottega:comment-sicko`.
- Merged skills get original names: `principle-delete-first`, `principle-shape-before-logic`, `principle-mechanize-it`, `crossfire`, and the `autopilot` and `forensics` playbooks. Derived text keeps its MIT notice and README credit.

## Skill loading

- Every skill except `setup-maestro` sets `disable-model-invocation: true`, so descriptions cost nothing per session.
- `/maestro` reads `SKILLS-INDEX.md`, picks candidates, asks with `AskUserQuestion`, and only then reads the chosen `SKILL.md`.
- Delegates read `maestro/references/delegate.md` (about 1.5k tokens), never the full maestro `SKILL.md` or a playbook.
- Maestro's `SKILL.md` keeps routing and the rules every run needs. `delegate.md` and `references/final-gate.md` load at the start of every playbook run (a lazy "read before your first edit" version got skipped in evals); `references/subagents.md` before the first spawn. The light route reads none of them.

## Models

- The role table in maestro `SKILL.md` is the source of truth. `/setup-maestro` writes the user's overrides to `~/.claude/rules/bottega-models.md`, and lint checks the two role lists match.
- Effort is never `high` except on haiku. The `large` budget is opus and sonnet medium in both columns.
- Risk only goes up during a run, never down.
- A second opinion is the same prompt on a different Claude tier.

## Workflow rules

- **Light route:** a docs or config change with no runtime effect skips the playbook: edit, check, reply. Runtime-affecting config (CI, build, deploy, flags, dependencies) uses a playbook.
- **Architect:** never automatic. On a cross-boundary change, maestro suggests it and runs it only on a yes. Arena is optional in Feature.
- **Crossfire:** solo mode runs automatically at high risk; panel mode on request.
- **Proof ledger:** the final gate logs one row per acceptance condition to `.bottega/proofs.tsv` (PASS, FAIL, INCONCLUSIVE, WAIVED; a waiver needs the user's words). Every run except the light route and read-only playbooks, whatever the size of the change. The run opens with `gate-check.sh --start` and its declared acceptance conditions. The check reads only the rows after that `run` row (none means exit 2), needs a proof row for every declared condition, counts only each condition's latest proof row (a fixed FAIL approves; the old row stays as history), refuses a waiver whose evidence doesn't start with `user:` and the user's words, in a git repo refuses any file the run changed that no `--expect` covers (files already dirty at `--start` and left alone don't count), and allows APPROVE only on exit 0; at high risk it also needs crossfire's own row, and any crossfire verdict but PASS escalates. Added after the evals showed agents skipping the ledger and crossfire as "overkill" on small changes.
- **Final gate:** APPROVE or ESCALATE, then ask once: open PR, commit only, rework, or reject. Reject deletes nothing. Nothing is pushed before APPROVE.
- **Todo list:** pstack's rule as is: copy the playbook's steps in verbatim, keep skipped ones as `skip: <reason>`, use `TodoWrite` (`TaskCreate` in newer Claude Code) or keep the list in the reply. It is the user's live view of the run, not enforcement, so nothing scores it; the ledger and gate enforce.
- **Fix rounds:** capped at 2, through `diagnosis`.
- **Pause safely:** saves a patch under `.bottega/`, never a wip commit.
- **Commits:** delegates commit freely on their own worktree branch. Nothing commits in the user's checkout unless the user asked, including the orchestrator working inline.
- **Security scan:** `security-scan.sh` runs before every PR outside the light route. A secret in the diff blocks at any risk. A sensitive path or high risk adds `/security-review` when `origin/HEAD` exists, else a reviewer delegate.
- **Confidence rule (95%)** lives only in maestro's Non-negotiables.

## Status line and progress files

- `/setup-maestro` may replace `statusLine` in `~/.claude/settings.json` after backing it up. Nothing else touches that file.
- One progress file per spawn, `.bottega/agents/<name>.json`, written with `scripts/progress.py`, is the only agent-state record. Orchestrate and autopilot add the agent id, PR number and `stuck_after` to it.
- The status line shows `step/total`, and marks a running agent `quiet` when its file is unchanged past `stuck_after` (default 5 minutes). It drops done files after 10 minutes and running files untouched for a day.

## Measurement

- `evals/` is the fixed baseline: small tasks run with and without bottega, deterministic grading, sonnet low. Correctness and behavior (maestro's rules) are scored apart. `evals/gate.py` compares a run with `evals/baseline.jsonl` before a release. Not shipped with the plugin. `playbooks/eval.md` stays the tool for a one-off judged experiment.

## Dropped

Quiz, formal verification skills, `statechart`, `reflect` (replaced by `file-followups`), `lab/`, generic sysadmin skills, `agentation`, `animation`, live UI checks, typescript-best-practices, automate-me, bro, in-your-own-words, sharpen, and BottegaStack's web-design-guidelines, infra-ops, scaffold, untrusted-content, simplify (clashes with the built-in), and review-code.

## Later

- Port `writing-for-agents` from BottegaStack.
- A spec step before build (to-spec, to-ticket).
- A post-run retro beyond `correct`.
- Harder eval tasks (see `evals/README.md`).
- A migration and rollback playbook (expand then contract, rollback first, dry run on a copy, rerunnable backfills). Deferred until a project with a production database needs it; trigger only on migrations that rewrite existing rows.
