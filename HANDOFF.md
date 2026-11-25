# Handoff: bottega

Updated 2026-11-24. Current state and open work only. Decisions and their reasons are in `DECISIONS.md`; measurement and the manual post-install checks are in `evals/README.md`; history is in git.

## What it is

`~/Projects/BottegaStack` is the Claude Code plugin `bottega`. One workflow: `/plan` grills the user into a spec, `/tickets` splits it into tickets that each fit one 300k-token orchestrator session (with the orchestrator/subagent split, waves, and an opus- or sonnet-level orchestrator), `/implement` builds one ticket per fresh session and ends at a mechanical proof gate. `/maestro` is the front door. It started as a port of pstack (Lauren Tan, MIT) and adapts Matt Pocock's skills (MIT).

## Layout

- `.claude-plugin/`: `plugin.json` (loads `skills/` and `harnesses/claude/agents/maestro-agent.md`) and `marketplace.json` (`bottega@bottega`, source `./`).
- `harnesses/`: `claude/` (`agents/maestro-agent.md`), `antigravity/`, `codex/`, `opencode/` (each with `install.sh` + `subagents.md`).
- 12 skills: maestro, reframe, grill, sharpen, tickets, implement, ship, correct, unslop, frontend-design, create- and maintain-verification-skill.
- `skills/maestro/`: `SKILL.md` (routing and shared rules), `SKILLS-INDEX.md`, `references/` (delegate, final-gate, models, subagents, principles, explore, review, prototype, unattended, handoff, worktree-cleanup), `scripts/` (`bottega`, `gate-check.sh`, `worktree-audit.sh`, `log.sh`). 17 principles in `references/principles.md`.
- `scripts/`: `lint-skills.py`, `test-scripts.sh` (dev only). `evals/`: `run.py`, `gate.py`, `baseline.jsonl`, 12 tasks (dev only). CI: `.github/workflows/ci.yml`.
- Runtime needs only bash and git (plus `gh` for PRs).

## Done on 2026-11-24

- Reshaped around grill, tickets, implement (see `DECISIONS.md`). New skills `plan` (with map mode, replacing `wayfinder`), `tickets`, `implement`.
- Cut the 8 UI review skills; kept `frontend-design`.
- Folded `understand` into `references/explore.md`, `crossfire` and `parallel` into `references/review.md`, the bug-fix, feature, refactoring and investigate playbooks into `/implement`, and moved prototype, unattended, handoff and worktree cleanup to `references/`. Principles: 4 files into one page. Roles: 7 into 4.
- Fixed the four `gate-check.sh` bugs (committed renames and deletions outside `--expect`, options after the ledger path, a missing snapshot, `--expect` globs starting with `+ - = @`), each with a regression test that fails on the old script. Renamed `plan` to `plan` (Claude Code's built-in `/plan` turns on plan mode). Version 3.0.0.
- `lint-skills.py` now also checks skill and principle counts in README, HANDOFF and every guide page, and fails on names of cut skills.
- README, guide (now 9 chapters), DECISIONS rewritten for the new shape.

## Open

1. **Bump the version on every release:** `plugin.json` is 3.2.0; a reinstall without a bump reuses the cached copy unless `~/.claude/plugins/cache/bottega` is deleted.

## Hard rules from the user

- Change files only inside `~/Projects/BottegaStack` unless the user approves a specific outside change.
- In this repo, commit and push straight to `main` when asked; never commit unasked.
- Multi-harness via `harnesses/`; no hooks in the plugin, no compiled CLI binary (thin Bash `bottega` wrapper only).
- Linux and macOS; bash 3.2, BSD and GNU tools, no `jq`.
- Never `xhigh` or `max` effort in bottega's role table; `high` only on haiku.
- Touch `~/.claude/settings.json` only with the user's yes and a backup.
- Keep Lauren Tan's MIT notice and the Pocock credit; keep the Anthropic license with `frontend-design`.

## Verify

```bash
python3 scripts/lint-skills.py && bash scripts/test-scripts.sh && python3 evals/run.py --selftest
claude plugin validate --strict .
```
