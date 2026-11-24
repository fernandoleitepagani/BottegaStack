# Bottega v2: decisions

The decisions that shape the stack and why. History lives in git, not here. When a decision changes, edit its line instead of appending a new round.

Base: a port of pstack (Lauren Tan, MIT). When in doubt, the port wins. All changes happen inside `BottegaStack/` (developed as `Bottega-v2/` until it replaced BottegaStack on 2026-11-24).

## Scope

- **Claude Code only, for now.** No third-party models or harnesses yet. A port to Codex CLI and Gemini/Antigravity CLI is planned in issue #46; new prose stays harness-neutral where it costs nothing.
- **No hooks, no CLI.** Rules are prose the model follows; `scripts/lint-skills.py` and CI keep the prose in sync. A CLI saves under 2% of a run's tokens, and isn't worth a cross-platform binary.
- **Per-repo state only.** `.bottega/` holds run state and stays untracked. Cross-repo memory is left to Claude Code's own user memory.
- **Linux and macOS only.** One version of every script, written for both (bash 3.2, BSD and GNU tools), with no `jq` dependency. Python 3.9+ only for the developer lint and evals. CI runs the checks and `scripts/test-scripts.sh` on Ubuntu and macOS. Native Windows is not supported; WSL counts as Linux.
- **No UI driving.** Where a change needs a visual check, the agent says what to look at and the user checks it.

## Naming

- Plugin `bottega`, entry skill `/maestro`. `setup-pstack` → `setup-maestro`, `poteto-mode` → `maestro`, `poteto-agent` → `maestro-agent`, `.pstack/` → `.bottega/`.
- The plugin agent is namespaced: `bottega:maestro-agent`.
- Merged skills get original names and count as original bottega works: `principle-delete-first`, `principle-shape-before-logic`, `principle-mechanize-it`, `crossfire`, the `understand` skill (how, why, recall, ketchup), the `pr` skill (opening a PR, babysit, shipping, file-followups, reviewer triage), and the `investigate` (investigation, forensics), `performance` (perf issue, hillclimb), `skill-work` (authoring, eval), `unattended` (autopilot, autonomous run, orchestrate), and `handoff` (pause safely, session pickup) playbooks. The repo keeps pstack's MIT notice for the text they derive from.

## Skill loading

- Every skill except `setup-maestro` sets `disable-model-invocation: true`, so descriptions cost nothing per session.
- `/maestro` reads `SKILLS-INDEX.md`, picks candidates, asks with `AskUserQuestion`, and only then reads the chosen `SKILL.md`.
- Delegates read `maestro/references/delegate.md` (about 1.5k tokens), never the full maestro `SKILL.md` or a playbook.
- Maestro's `SKILL.md` keeps routing and the rules every run needs. `delegate.md` and `references/final-gate.md` load at the start of every playbook run (a lazy "read before your first edit" version got skipped in evals); `references/subagents.md` before the first spawn. The light route reads none of them.

## Models

- The role table in `maestro/references/subagents.md` is the only source of truth. `/setup-maestro` reads it and writes the user's overrides to `~/.claude/rules/bottega-models.md`. No skill hardcodes a model; each names a role.
- Effort is never `high` except on haiku. The `large` budget raises opus and sonnet to `medium`; the rule file then sets the ceiling.
- Risk only goes up during a run, never down.
- A second opinion is the same prompt on a different Claude tier.

## Workflow rules

- **Light route:** a docs or config change with no runtime effect skips the playbook: edit, check, reply. Runtime-affecting config (CI, build, deploy, flags, dependencies) uses a playbook.
- **Architect:** never automatic. On a cross-boundary change, maestro suggests it and runs it only on a yes. Arena is optional in Feature.
- **Crossfire:** solo mode runs automatically at high risk; panel mode on request; PR mode replaces `review-pr`. Review runs in budgeted rounds (3 by default, up to 5 for security or data, stop early on nits), with one findings list, an idea borrowed from tstack's `sol-loop`.
- **Proof ledger:** the final gate logs one row per acceptance condition to `.bottega/proofs.tsv` (PASS, FAIL, INCONCLUSIVE, WAIVED; a waiver needs the user's words). Every run except the light route and read-only playbooks, whatever the size of the change. The run opens with `gate-check.sh --start` and its declared acceptance conditions. The check reads only the rows after that `run` row (none means exit 2), needs a proof row for every declared condition, counts only each condition's latest proof row (a fixed FAIL approves; the old row stays as history), refuses a waiver whose evidence doesn't start with `user:` and the user's words, in a git repo refuses any file the run changed that no `--expect` covers (files already dirty at `--start` and left alone don't count), and allows APPROVE only on exit 0; at high risk it also needs crossfire's own row, and any crossfire verdict but PASS escalates. Added after the evals showed agents skipping the ledger and crossfire as "overkill" on small changes.
- **Final gate:** APPROVE or ESCALATE, then one closing line: open PR, commit only, rework, or reject. Reject deletes nothing. Nothing is pushed before APPROVE.
- **Todo list:** pstack's rule as is: copy the playbook's steps in verbatim, keep skipped ones as `skip: <reason>`, use `TodoWrite` (`TaskCreate` in newer Claude Code) or keep the list in the reply. It is the user's live view of the run, not enforcement, so nothing scores it; the ledger and gate enforce.
- **Fix rounds:** capped at 2, through crossfire's fix step.
- **Handoff (pause):** saves a binary patch plus copies of new untracked files under `.bottega/`, never a wip commit.
- **Commits:** delegates commit freely on their own worktree branch. Nothing commits in the user's checkout unless the user asked, including the orchestrator working inline.
- **No security scan** (cut 2026-11-24). Secret detection is the forge's job (GitHub push protection and secret scanning). pstack has none either. High-risk changes still get crossfire.
- **Confidence rule (95%)** lives only in maestro's Non-negotiables.
- **One home per rule.** The always-pause list lives in maestro **Autonomy**, commits in `delegate.md`, the fan-out ask and model ceiling in `subagents.md`, the gate in `final-gate.md`. Playbooks point to them instead of restating them.
- **Unattended permissions** are written out (an idea borrowed from tstack's `full-send`): the run may push and `--force-with-lease` its own branches, use any test method the proof needs, and in `queue land` merge past the gate. Everything on the always-pause list still pauses.
- **Writing:** `unslop` only. `technical-writing` was dropped (2026-11-24); PR title and body rules live in the `pr` skill.

## Status line, progress files, runtimes

- `/setup-maestro` touches `~/.claude/settings.json` only to retire an old bottega status line, on the user's yes and after a backup.
- No status line and no progress files (cut 2026-11-24). They cost about 8 tool calls per run and Python on every install, for a hint that a slow agent is alive. The Unattended playbook records agent ids, PRs and `stuck_after` in the decision trail.
- Scripts need only bash and git at runtime. The gate's changed-files snapshot is bash (`run-start.tsv`), and the multi-phase plan is checked in prose, not by `check-plan.mjs`. Python stays dev-only (lint, evals).

## Measurement

- `evals/` is the fixed baseline: small tasks run with and without bottega, deterministic grading, sonnet low. Correctness and behavior (maestro's rules) are scored apart. `evals/gate.py` compares a run with `evals/baseline.jsonl` before a release. Not shipped with the plugin. The Skill work playbook's blind test stays the tool for a one-off judged experiment. The manual post-install checks live in `evals/README.md`.

## Dropped

Quiz, formal verification skills, `statechart`, `reflect` (replaced by `pr` followups mode), `maestro-help`, `teach`, `wizard`, `runbook`, `library-reference`, `data-analysis`, `technical-writing`, `review-pr` (folded into crossfire), `improve-architecture` (folded into architect, with `codebase-design` and `domain-modeling` as its references), the status line, `doctor.py`, `check-plan.mjs`, `security-scan.sh`, `plans/` (in git history), `lab/`, generic sysadmin skills, `agentation`, `animation`, live UI checks, typescript-best-practices, automate-me, bro, in-your-own-words, sharpen, and BottegaStack's web-design-guidelines, infra-ops, scaffold, untrusted-content, simplify (clashes with the built-in), and review-code.

## Future work (evaluated 2026-11-24, not yet adopted)

1. **Build, prove, review loop** (from tstack). Adopt as bottega's inner loop and keep the mechanical gate at the end. Crossfire's round budget already makes it a loop; the open step is running it on every code change (one cheap round on sonnet at normal risk, full rounds at high risk). Cost: one reviewer per run. Gain: fewer corrections after delivery.
2. **`review-loop` and `parallel` skills.** Done 2026-11-24: no separate `review-loop` (crossfire is the loop, with `diagnosis` folded in as its fix step), and `parallel` replaces `swarm` and `arena`.
3. **One-page maestro.** Not in full: maestro's split (routing, lazy playbooks, references at fixed points) is pstack's design and already loads little per run; one page would load more or lose the playbooks' depth. Adopt the parts: shrink `SKILL.md`'s triggers to one-line pointers, and optionally make `blast-radius` a crossfire reference (the user chose to keep it as a skill).
4. **Model choice as a workflow step, replacing `/setup-maestro`.** After the objective and plan are settled, the orchestrator suggests a model per role from a list the user supplies (for example a strong orchestrator model with a fast subagent model from the same provider). Non-Claude entries depend on the port in issue #46; until then the list holds Claude models. Open: the user's list, and where it lives (a rule file or `CLAUDE.md`).

## Skill review (2026-11-24)

- **Keep:** understand, pr, crossfire, parallel, architect, figure-it-out, wayfinder, correct, blast-radius, show-me-your-work, create- and maintain-verification-skill, unslop, the 9 UI skills as they are, 20 principles.
- **Merged (applied):** `diagnosis` into crossfire (each round writes the fix brief for a fresh delegate); `swarm` and `arena` into a new `parallel` skill (coverage, race, bakeoff modes); `tdd` into the bug-fix playbook.
- **Replaced with a rule (applied):** `no-comments` and the `comment-sicko` agent became the comments rule in `delegate.md` (no comments by default, four allowed cases, a grep self-check on the diff before review), read by every agent and run by pr open mode.
- **Dropped:** `benchmark-checklist`, `principle-explain-the-number`, and the `performance` and `skill-work` playbooks (not needed for this workflow). Slowness reports go through Bug fix; skill edits are ordinary Feature runs plus `evals/`.
- **`setup-maestro`:** stays until future-work item 4 replaces it.
- Also dropped: the `multi-phase-plan` playbook (plans now go through figure-it-out) and `principle-experience-first`.
- Result: 43 skills (19 principles), 8 playbooks, 1 agent.

## Second simplification pass (2026-11-24)

- **Principles** live in four group files under `maestro/references/principles/` (core, architecture, verification, delegation), not as 19 skills. Text unchanged; overlapping pairs carry a **Scope** line that says which one applies (outcome-oriented execution vs sequence verifiable units, exhaust the design space vs prototype and parallel, redesign vs migrate callers, guard the context window vs token rules, never block on the human vs Autonomy, mechanize it vs `correct`).
- **Maestro `SKILL.md`** cut from about 2,500 to about 1,600 words: one-line triggers that point to the owning file; Autonomy points to Never Block on the Human and keeps only the always-pause list; token rules point to Guard the Context Window.
- **`show-me-your-work`** folded into the Unattended playbook's **Decision trail** section; `log.sh` moved to `maestro/scripts/`.
- **`blast-radius`** dropped; crossfire's brief checks breakage outside the diff.
- **Role table** cut from 17 roles to 7: orchestrator, writer, reviewer, explorer, explainer, runners, judge. Crossfire adversaries use the reviewer's High column.
- **Worktree audit** fixed: paths with spaces, untracked and `.bottega/` state keep a worktree out of `safe`, an unreadable status holds it, behind is no longer reported as `ahead0`, and a failed `gh` call warns.
- **`pr` babysit** acts on what is already there first, and waits only when something is pending, with one event watcher (Monitor on `gh pr checks --watch`); `/loop` is the fallback.
- **From tstack:** crossfire pre-flight (fix known blockers and brief known issues before round 1, reusing existing check output); a `pr` refresh mode that decides REFRESH, REWORK, or CLOSE before rebasing an old PR; Handoff resume and `pr` keep prior contributors' commits and credit.
- Result: 22 skills, 19 principles in 4 files, 8 playbooks, 1 agent. 21 once model choice replaces `setup-maestro`.

## Later

- Port `writing-for-agents` from BottegaStack.
- A spec step before build (to-spec, to-ticket).
- A post-run retro beyond `correct`.
- A migration and rollback playbook (expand then contract, rollback first, dry run on a copy, rerunnable backfills). Deferred until a project with a production database needs it; trigger only on migrations that rewrite existing rows.
