# bottega: decisions

The decisions that shape the stack and why. History lives in git, not here. When a decision changes, edit its line instead of appending a new round.

Base: a port of pstack (Lauren Tan, MIT), reshaped on 2026-11-24 around Matt Pocock's plan, spec, tickets and implement flow (mattpocock/skills, MIT).

## Scope

- **Claude Code first; other harnesses experimental.** Core skills in `skills/` stay harness-agnostic; thin adapters live under `harnesses/claude/` (supported) and `harnesses/antigravity/`, `harnesses/codex/`, `harnesses/opencode/` (experimental, #46). No work is added only for the experimental ones. Their installers link each skill under its real name, as pstack does, so `../<name>/SKILL.md` links resolve; they stop rather than overwrite a skill of the same name.
- **No hooks, no compiled binary.** Rules are prose the model follows; `skills/maestro/scripts/bottega` is a thin Bash wrapper around `gate-check.sh`, `log.sh`, and `worktree-audit.sh` (plus `ship`, `followup` and `garden`; the agent names the checks, nothing is auto-detected) that collapses verification turns and keeps raw logs out of context without adding dependencies.
- **Per-repo state only.** `.bottega/` holds run state, plans and tickets, and stays untracked. Cross-repo memory is left to Claude Code.
- **Linux and macOS only.** bash 3.2, BSD and GNU tools, no `jq`. Any Python 3 (CI uses the runner's default) only for the developer lint and evals. Native Windows is not supported; WSL counts as Linux.
- **No UI driving.** Where a change needs a visual check, the agent says what to look at and the user checks it.

## Shape: grill, tickets, implement

- **Why.** Most of what the old routing, playbooks and fan-out skills described, current models already do unprompted. What they don't do unprompted: settle decisions with the user before building, size work to one session's context, keep the orchestrator's context small by delegating, and prove results mechanically. The stack keeps only those.
- **`/plan`** grills the user one decision at a time (the frontier of settled prerequisites, numbered questions with a recommended answer that "yes" accepts, facts looked up rather than asked, prototypes for ungrillable questions) and writes a spec of decisions the user made. Plan mode stays off during grilling.
- **Named `plan` (use `/bottega:plan` if Claude Code's built-in `/plan` clashes).** Built-in plan mode stays off during grilling.
- **Map mode** replaces the `wayfinder` skill: for efforts too big for one grilling session, a local map of decision questions, one resolved per session, research answered by explorers. Folded into `/plan` because it is grilling plus bookkeeping, and a separate skill duplicated the grilling rules.
- **`/tickets`** cuts vertical tracer-bullet slices, each sized for one fresh orchestrator session: **300k tokens, ±10%** (hard limit 330k), counting only the orchestrator's own context, estimated from file sizes. Each ticket names what the orchestrator does, a table of subagents (role, tier, task, write scope, which run together), blocked-by edges, a wave, and an abstract model tier (`heavy`, `medium`, `standard`, `fast`, translated per harness in `references/models.md`). Tickets that write the same file are serialized.
- **`/implement`** runs one ticket per fresh session (or one small direct task): explore, shape before logic, pin behavior by kind (bug, refactor, feature), delegate, verify, review (parallel Spec + Standards axes), final gate, then mark the ticket done and list what it unblocked. It replaces the bug-fix, feature, refactoring and investigate playbooks.
- **`/maestro`** is a one-page front door: a routing table plus the shared rules (confidence, risk, autonomy, subagents, context, replies).
- **Skills (17):** maestro, reframe, recall, triage, plan, sharpen, tickets, implement, ship, autopilot, correct, garden, unslop, frontend-design, create- and maintain-verification-skill, wizard. Every one sets `disable-model-invocation: true`.
- **References under `maestro/references/`**, read only when a step needs them: `delegate.md`, `final-gate.md`, `subagents.md`, `models.md`, `principles.md`, `explore.md` (was `understand` and Investigate), `review.md` (was `crossfire` and `parallel`), `prototype.md`, `handoff.md`, `worktree-cleanup.md`.
- **Principles:** 17, on one page, each a short section. Delegates read a section before applying it.

## Models

- `maestro/references/subagents.md` maps roles to 4 abstract tiers (`heavy`, `medium`, `standard`, `fast`); `maestro/references/models.md` translates those tiers per harness (Claude Code, Antigravity CLI, Codex, OpenCode).
- Overrides live in an optional `~/.bottega/models.md` (or `~/.claude/rules/bottega-models.md` on Claude Code), written by the user.
- Effort ceiling: never `xhigh` or `max`. Adversarial crossfire review uses `heavy` at high risk.
- Risk only goes up during a run. Never switch `/model` mid-session; the user sets the orchestrator model at the start of each ticket's session.

## Workflow rules

- **Light route:** a docs or config change with no runtime effect skips `/implement`: edit, check, reply. Runtime config (CI, build, deploy, flags, dependencies) goes through `/implement`.
- **Review:** every `/implement` run gets parallel fresh reviewers (Spec + Standards) against the ticket. At high risk it is adversarial, in budgeted rounds (3 by default, up to 5 for security or data, stop early on nits), keeping only findings a rerun proves. The ledger row stays `crossfire` so `gate-check.sh` needs no change.
- **Fix rounds:** capped at 2, each by a fresh implementer; a third failure is ESCALATE.
- **Proof ledger:** the final gate logs one row per acceptance condition to `.bottega/proofs.tsv` (PASS, FAIL, INCONCLUSIVE, WAIVED; a waiver needs the user's words). The run opens with `gate-check.sh --start`; the check reads only rows after that `run` row, needs a proof for every declared condition, counts each condition's latest proof, refuses changed files no `--expect` covers, and allows APPROVE only on exit 0. At high risk it also needs a `crossfire` row with PASS. Added after evals showed agents skipping the ledger as "overkill" on small changes.
- **Final gate:** APPROVE or ESCALATE, then one closing line: open PR, commit only, rework, or reject. Nothing is pushed before APPROVE. PR opening, watching, and landing live in `/ship` (`skills/ship/SKILL.md`).
- **Context:** an orchestrator session stops at 300k tokens, ±10%: past about 270k it runs the handoff pause.
- **Handoff (pause):** saves a binary patch plus copies of new untracked files under `.bottega/`, never a wip commit.
- **Commits:** delegates commit freely on their own worktree branch. Nothing commits in the user's checkout unless the user asked.
- **Unattended permissions** are written out: the run may push and `--force-with-lease` its own branches, use any test method the proof needs, and in `queue land` merge past the gate. A ticket plan runs as a queue. Everything on the always-pause list still pauses.
- **One home per rule.** The always-pause list lives in maestro **Autonomy**, commits in `delegate.md`, the fan-out ask and model ceiling in `subagents.md`, the gate in `final-gate.md`.
- **Writing:** `unslop` only.
- **No security scan.** Secret detection is the forge's job (GitHub push protection and secret scanning).

## Measurement

- `evals/` is the fixed baseline: small tasks run with and without bottega, deterministic grading, sonnet low, Claude Code only. Correctness and behavior are scored apart. `evals/gate.py` compares a run with `evals/baseline.jsonl` after a change to the stack. A task is added when a skill regresses, not to cover every skill: prose skills have no pass/fail a fixed task can score. Not shipped with the plugin. The manual post-install checks live in `evals/README.md`.

## Dropped

The 8 UI review skills (`interface-review`, `better-interface`, `better-accessibility`, `better-colors`, `better-layout`, `better-typography`, `better-ui`, `better-writing`; current models handle these domains without a skill, and `frontend-design` stays for visual direction), `understand`, `crossfire` and `parallel` (folded into `explore.md` and `review.md`), the 8 playbooks (folded into `/implement` and the references), the throughput checkpoint, the explainer, runners and judge roles, `pr`, `architect`, `figure-it-out`, `wayfinder` (folded into `/plan` map mode), `setup-maestro`, the status line, progress files, `doctor.py`, `check-plan.mjs`, `security-scan.sh`, the Antigravity eval mode (it couldn't score code tasks), a release process (tags, CHANGELOG; history lives in git and `plugin.json` is bumped by hand), and earlier cuts recorded in git.

- **Human steps become scripts.** When a run needs the user's hands (dashboards, credentials, CI secrets, a cutover), `/wizard` writes an interactive bash script from a fixed library (adapted from mattpocock/skills, MIT) instead of a list of steps. The agent never runs it; it proves it statically. Unattended runs log the unit as blocked and move on.

## Later

- A post-run retro beyond `correct`.
- A migration and rollback reference (expand then contract, rollback first, dry run on a copy, rerunnable backfills), when a project with a production database needs it.
