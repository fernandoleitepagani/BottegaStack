# Handoff: Bottega v2

Updated 2026-11-24. `DECISIONS.md` is the source of truth for decisions (edited in place). `evals/README.md` has the measurement story. `USER-TEST.md` is the manual test plan. `.bottega/handoff.md` (2026-11-17) is stale; this file supersedes it.

## Goal and objective

`~/Projects/Bottega-v2` is a Claude Code plugin, `bottega`, entry skill `/maestro`. It ports pstack (Lauren Tan, MIT, a Cursor plugin at `~/Projects/plugins/pstack/`) to native Claude Code and adds selected BottegaStack skills.

- **Goal:** make one Claude Code agent work like a small, rigorous engineering team. It should write less code and better code, prove its claims before it says "done", and stay trustworthy when several agents run in parallel. pstack's thesis: "if you want to go fast, go deep first."
- **Objective:** ship it as the drop-in replacement for `~/Projects/BottegaStack`. Done 2026-11-24: Bottega-v2 was copied over the BottegaStack repo (only `.git` kept) and pushed to `main` (`9747b59`, then CI fixes up to `bf6fdca`). The old layout is in git history before `9747b59`. `~/Projects/Bottega-v2` stays as a working copy because the installed plugin reads from it; keep the two in sync or reinstall from BottegaStack.
- **Not a goal:** speed or token thrift for its own sake, third-party models, hooks, a CLI, Windows.

## Architecture

- **Plugin:** `.claude-plugin/plugin.json` loads `skills/` (64 skills) and two agents: `bottega:maestro-agent` (the delegate) and `bottega:comment-sicko`. Every skill except `setup-maestro` sets `disable-model-invocation: true`, so skills cost nothing until a run reads them. The Skill tool can't start them, so maestro `Read`s their `SKILL.md`.
- **Orchestrator (`skills/maestro/`).** Each part is loaded at a fixed point:
  - **`SKILL.md`** holds routing, the triggers, risk (normal or high, only goes up), autonomy, token rules, the reply style and the list of 20 playbooks.
  - **`references/delegate.md`** holds the 21 principles index, comments, scope, commits and verification. The orchestrator and every delegate read it.
  - **`references/final-gate.md`** holds the ledger and gate steps. The orchestrator reads it on every playbook run.
  - **`references/subagents.md`** holds the role table (model and effort per role), the fresh-subagent rule and progress files. The orchestrator reads it before its first spawn.
  - **`SKILLS-INDEX.md`** lists the skills no trigger names.
- **Routes:**
  - **Light route:** docs or config with no runtime effect, never code. It edits, checks and replies, with no gate.
  - **Playbook run:** everything else. The steps are copied into a todo list, then the run opens the ledger, does the work through delegates, and ends at the final gate.
  - **Read-only playbooks** (Investigation, Forensics, Prototype) skip the ledger.
- **Mechanical gate:** `scripts/gate-check.sh` with `run-files.py`, writing to `.bottega/proofs.tsv` through `show-me-your-work/scripts/log.sh`.
  - `--start "<goal>" --condition "<c>"...` opens the run before any edit and takes a snapshot of the tree.
  - The final call uses `--expect "<path or glob>"` for each file the change should touch, and `--proof "<cond>" "<evidence>" PASS|FAIL|INCONCLUSIVE|WAIVED` for each condition.
  - **Exit codes:** 0 allows APPROVE, 1 means ESCALATE, 2 means a step is missing.
  - **What exits 2:**
    - no `run` row
    - a declared condition with no proof
    - a WAIVED row whose evidence doesn't start with `user:` and the user's words
    - a changed file that no `--expect` covers (files that were already dirty at the start and left alone don't count)
    - at high risk, no `crossfire` row (any crossfire verdict other than PASS escalates)
  - Only each condition's latest proof counts.
  - The Decision line has to quote the `gate-check: ...` line the script printed.
  - After the verdict, the run asks once: PR, commit only, rework or reject.
- **Other scripts:**
  - `security-scan.sh`, run before every PR
  - `progress.py`, which writes one progress file per spawn in `.bottega/agents/`
  - `check-plan.mjs`, which checks a multi-phase plan
  - `worktree-audit.sh`
  - `setup-maestro/scripts/`: `set-statusline.py`, `statusline.py`, `doctor.py`

  Bottega's scripts write `.bottega/.gitignore` (`*`), so run state ignores itself without touching any global git config.
- **Setup:** `/setup-maestro` writes `~/.claude/rules/bottega-models.md` (the model and effort for each role) and installs the status line. The status line is a stable copy at `~/.claude/bottega/statusline.py`, with timestamped backups that are never overwritten. Step 9 (`/setup-maestro doctor`) checks the tools on your PATH, the rule file and the status line.
- **Quality tooling:**
  - **`scripts/lint-skills.py`** checks frontmatter, the index, the principle and role lists, the doc counts, and that every bundled path a skill or agent file points to exists.
  - **`scripts/test-scripts.sh`** has 52 smoke tests.
  - **`evals/`** holds `run.py`, `gate.py`, `baseline.jsonl` and 12 tasks.
  - **CI** is `.github/workflows/ci.yml`: an Ubuntu and macOS matrix, a Python 3.9 job, `claude plugin validate --strict`, shellcheck and a link check. First run 2026-11-24 on GitHub: green on all four jobs after three fixes (bash 3.2 parse errors in `security-scan.sh` from quotes inside `$( )`, ShellCheck errors in `wizard/template.sh`, and the Python 3.9 job pinned to `ubuntu-22.04`).

## Workflow

1. Install: `claude plugin marketplace add <repo>`, `claude plugin install bottega@bottega`, then `/setup-maestro` once.
2. Daily use: `/maestro <goal + how to tell it's done>`.
   - **First reply:** the goal, the smallest change that meets it, and the risk.
   - **Vague targets:** a question before any edit.
   - **The run:** playbook steps in the todo list, the ledger opened, delegates spawned in the background with an explicit model and effort, the orchestrator's own review of the diff, fix rounds through `diagnosis` (2 at most), crossfire at high risk, the gate, a Decision, and one closeout question.
   - **Commits:** nothing is committed in your checkout unless you ask.
3. Long or overnight work: autopilot, orchestrate, `/loop`, a show-me-your-work decision log, and `/ketchup` in the morning.

## Measured results (sonnet low, `evals/baseline.jsonl`, 12 tasks x 2 trials, 2026-11-24)

| | correct | behavior | cost/run | fresh tokens | turns |
|---|---|---|---|---|---|
| bottega | 23/24 | 23/24 | $0.196 | 33.1k | ~9 |
| plain Claude Code | 22/24 | fails vague-ask | $0.082 | 17.2k | ~5 |

Only `hidden-caller` split the arms on correctness: plain renamed the handler and broke the `getattr` dispatch both times, while bottega got it right once and stopped to ask about the trap once. The other three hard tasks (`wrong-obvious-fix`, `distant-cause`, `scope-creep`) didn't separate them. A post-dedupe run on 2026-11-24 kept behavior at 12/12, with noise-level cost changes.

## Compared with no stack and other stacks

**Plain Claude Code (measured here)**
- **Bottega's advantages:**
  - It asks when a target is vague.
  - It proves each acceptance condition through a script, not a claim.
  - It refuses impossible requests without hacking the tests.
  - It never commits in your checkout.
  - Stray edits block the gate.
  - High-risk changes always get an adversarial review.
  - It traces cross-module traps more often (`hidden-caller`).
- **Plain's advantages:**
  - About 2.4x cheaper.
  - About half the turns.
  - The same correctness on most bug fixes and features, so on small, clear tasks bottega mostly adds cost.

**Other popular stacks** (not measured here; based on their public descriptions and pstack's design)
- **pstack (the source):**
  - **Same core:** playbooks, principles, a todo list of the steps, and delegates.
  - **Bottega adds:** a mechanical ledger and gate, evals, a status line, a doctor, the security scan and Linux/macOS CI.
  - **Bottega drops:** Cursor-only tools and any harness adapter.
- **obra/superpowers:**
  - **What it is:** a skills library that triggers on its own (brainstorm, plan, TDD, subagent-driven development). It's lighter and more automatic.
  - **Its limit:** no mechanical gate, so the proof rests on the model's discipline.
  - **Bottega's position:** more explicit and auditable, but more ceremony.
- **GitHub Spec Kit:**
  - **What it is:** spec first (specify, plan, tasks, implement), with the documents kept in the repo. It's strong for greenfield features and heavy for small fixes.
  - **Bottega's position:** it routes by task type instead, and has no spec step yet (on the Later list).
- **BMAD Method:**
  - **What it is:** a multi-persona agile process (analyst, PM, architect, developer, QA) that produces many documents. It's thorough for large projects but heavy.
  - **Bottega's position:** one orchestrator plus role-specific models, with less paperwork.
- **claude-flow / SuperClaude:**
  - **What they are:** swarm or command-and-persona frameworks, often with hooks, MCP or memory layers. Powerful, but more moving parts and more lock-in.
  - **Bottega's position:** deliberately no hooks, no CLI and no MCP. It's prose plus a few portable scripts.
- **Bottega's net position:** it favors auditability and refusing to ship unproven work over speed. The weak spot is cost: about 2.4x plain Claude Code, with thin evidence so far that it produces better code on correctness. Its strength is behavior: asking first, proving work, controlling scope and never committing on its own.

## Done this session (2026-11-23 to 11-24)

- **Gate:**
  - Acceptance conditions declared at `--start`, with a proof required for each.
  - The `run` row required.
  - Waivers have to quote the user (`user:`).
  - Only each condition's latest proof counts.
  - The stray-file check (`--expect`, `run-files.py`).
  - The run has to open before the first edit.
  - The Decision quotes the `gate-check:` line.
  - Any code change, however small, is a playbook run.
  - Never end a run on exit 2.
  - The crossfire doc now matches the script.
- **Setup:**
  - A stable status line copy with quoted paths.
  - Backups are never overwritten.
  - `.bottega/` ignores itself, which replaced the step that ran `git config --global`.
  - `doctor.py`.
- **Evals:**
  - Four hard tasks.
  - A cost gate.
  - Installed `bottega@*` plugins are disabled in eval runs.
  - Graders fixed (`risk-escalation`, `vague-ask`, `hidden-caller`).
  - "Subagents get a model" skips runs with no spawn instead of passing for free.
  - Gate checks read the agent's real gate output and skip runs that changed nothing.
  - A new baseline.
- **Docs:**
  - Wrong counts fixed.
  - The draft-PR rule for autopilot.
  - The `worktree-audit` safety buckets.
  - Duplicated rules removed (about 310 tokens), and 4 inconsistencies fixed.
  - Lint now checks bundled references.
  - The todo list is back to pstack's rule: the orchestrator owns it, it's unscored, and it says `TodoWrite` (`TaskCreate` in newer Claude Code) or a list in the reply.
- **Installed on this machine (with the user's yes):**
  - `bottega@bottega`, read live from this directory.
  - The status line, with backup `~/.claude/settings.json.bottega-backup-20261124-001956`.
  - The rtk hook wrapper `~/.claude/hooks/rtk-main-only.py`. It skips rtk's rewrite for subagent calls, which auto mode would otherwise refuse. Backup: `~/.claude/settings.json.bak-rtk-2026-11-23`.
  - `~/.config/rtk/config.toml` with `suppress_hook_warning = true`.
  - rtk is the user's own tool, not part of bottega.
- **Headless install test:** it passed apart from a one-line fix skipping the gate, which is now fixed. The status line fields, `effort` and `background` on plugin agents, and the `bottega:maestro-agent` name are all confirmed against the docs and in real runs.

## Open (in order; the overwrite is last)

1. **The user's interactive checks** (`USER-TEST.md`):
   - run `/setup-maestro` with its questions (no rule file exists yet)
   - check the `/` menu and how the status line looks
   - the UI path (section 5)
   - `/file-followups` and `/review-pr` on a real GitHub repo
   - the effort comparison
   - whether interactive runs open the todo list
2. **Point the installed plugin at BottegaStack** (`claude plugin marketplace add ~/Projects/BottegaStack`, reinstall), then retire `~/Projects/Bottega-v2`.
3. **Optional, later:**
   - Run `hidden-caller` and `wrong-obvious-fix` with `--trials 3`. One trial is noise.
   - Cut ceremony turns. Turns drive most of bottega's cost.
   - `.bottega/runs.tsv`.
   - The Later list in `DECISIONS.md`: `writing-for-agents`, a spec step, a post-run retro and a migration playbook.

## Hard rules from the user

- Change files only inside `~/Projects/Bottega-v2` unless the user explicitly approves a specific outside change. That's how the rtk wrapper, the status line, the plugin install and the rtk config above were done.
- Claude Code only: no third-party models or harnesses, no hooks in the plugin, no CLI (memory `claude-code-exclusive`).
- Linux and macOS only, one version of every script: bash 3.2, BSD and GNU tools, Python 3.9+, no `jq`.
- Commit and push only when asked. `file-followups` needs one confirmation.
- Never read or print keys, tokens or credentials. Be concise; lead with the answer.
- Never use `xhigh` or `max` effort; `high` only on haiku.
- Touch `~/.claude/settings.json` only through `/setup-maestro` step 6, or with the user's explicit yes and a backup.
- Lauren Tan's credit and the MIT license stay. frontend-design is credited to anthropics/skills.

## Verify

```bash
python3 scripts/lint-skills.py && bash scripts/test-scripts.sh && python3 evals/run.py --selftest
claude plugin validate --strict .
python3 skills/setup-maestro/scripts/doctor.py
```

## Gotchas

- Eval runs use `--permission-mode dontAsk`, so `AskUserQuestion` is denied and agents ask in the reply. The sandbox places temporary dotfiles in the work dir, so graders read the gate from the transcript instead of rerunning it.
- A full eval run is 12 tasks x 2 arms x 1 trial, about $3. Use `--tasks` and `--arms bottega` to spend less. Promote a baseline only after reading its failures.
- A run can emit several `result` events (a background delegate returning); `run.py` sums them.
- The auto-mode classifier denied installing shellcheck through `uvx`; don't work around it.
