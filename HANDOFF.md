# Handoff: bottega

Updated 2026-11-24. Current state and open work only. Decisions and their reasons are in `DECISIONS.md`; measurement and the manual post-install checks are in `evals/README.md`; history is in git.

## What it is

`~/Projects/BottegaStack` is the Claude Code plugin `bottega`, entry skill `/maestro`. It ports pstack (Lauren Tan, MIT, a Cursor plugin) to Claude Code and keeps pstack's shape: an orchestrator, playbooks, 21 principles, delegates, and fan-out skills. It adds a mechanical proof gate. Goal: one agent that works like a small, rigorous team, writes less and better code, and proves its claims before it says done.

## Layout

- `.claude-plugin/`: `plugin.json` (version 2.0.0; loads `skills/` and `agents/`) and `marketplace.json` (`bottega@bottega`, source `./`).
- `agents/`: `maestro-agent` (the delegate).
- `skills/maestro/`: `SKILL.md` (triggers, risk, the one always-pause list, subagents, token rules, reply style, routing), `SKILLS-INDEX.md`, 8 playbooks, `references/` (`delegate.md`, `final-gate.md`, `subagents.md`), `scripts/` (`gate-check.sh`, `worktree-audit.sh`, `log.sh`).
- 22 skills: maestro, setup-maestro, understand, pr, architect, parallel, crossfire, figure-it-out, wayfinder, correct, create- and maintain-verification-skill, unslop, 9 UI skills. 19 principles in `maestro/references/principles/` (4 files).
- `scripts/`: `lint-skills.py`, `test-scripts.sh` (dev only). `evals/`: `run.py`, `gate.py`, `baseline.jsonl`, 12 tasks (dev only). CI: `.github/workflows/ci.yml`.
- Runtime needs only bash and git (plus `gh` for `/pr`).

## Done on 2026-11-24

- Cut the status line, progress files, doctor, `check-plan.mjs`, `run-files.py`, `security-scan.sh`, and the skills `maestro-help`, `teach`, `wizard`, `runbook`, `library-reference`, `data-analysis`, `technical-writing`, `review-pr`.
- Merged into new, original skills: `understand` (how, why, recall, ketchup) and `pr` (opening a PR, babysit, shipping, file-followups, reviewer triage). `improve-architecture` became architect's scan mode, with `codebase-design` and `domain-modeling` as its references.
- Playbooks 20 → 9, with new names: `investigate`, `unattended`, `handoff`. Merged `diagnosis` into crossfire, `swarm` and `arena` into `parallel`, `tdd` into bug-fix. Replaced `no-comments` and `comment-sicko` with the comments rule in `delegate.md`. Dropped `benchmark-checklist`, `principle-explain-the-number`, and the `performance` and `skill-work` playbooks.
- One home per rule, the crossfire round budget, and written-out unattended permissions (see `DECISIONS.md`).
- Docs: README, guide, DECISIONS, and the evals README updated. `USER-TEST.md` moved into `evals/README.md`; `plans/` removed (in git history).

## Open

1. **Gate bugs** found in the full analysis, not yet fixed: a committed rename or deletion outside `--expect` passes (needs `--no-renames`); options after the ledger path are dropped; a missing snapshot still allows exit 0; `--expect` globs starting with `+ - = @` never match.
3. **`gate.py --promote`** replaces the whole baseline with only the runs given.
4. **Eval after the restructure:** run the separating tasks with `--trials 3` and compare with the baseline before promoting.
5. **Version bump:** `plugin.json` is still 2.0.0, so a reinstall reuses the cached copy unless `~/.claude/plugins/cache/bottega` is deleted.
6. Codex and Gemini/Antigravity port: issue #46.

## Hard rules from the user

- Change files only inside `~/Projects/BottegaStack` unless the user approves a specific outside change.
- In this repo, commit and push straight to `main` when asked; never commit unasked.
- Claude Code only for now; no hooks in the plugin, no CLI.
- Linux and macOS; bash 3.2, BSD and GNU tools, no `jq`.
- Never `xhigh` or `max` effort in bottega's role table; `high` only on haiku.
- Touch `~/.claude/settings.json` only with the user's yes and a backup.
- Keep Lauren Tan's MIT notice; keep the Krehel, Pocock, and Anthropic licenses with their files.

## Verify

```bash
python3 scripts/lint-skills.py && bash scripts/test-scripts.sh && python3 evals/run.py --selftest
claude plugin validate --strict .
```
