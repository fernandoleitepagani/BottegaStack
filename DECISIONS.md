# bottega: decisions

The decisions that shape the stack and why. History lives in git, not here. When a decision changes, edit its line instead of appending a new round.

Base: a port of pstack (Lauren Tan, MIT), reshaped on 2026-11-24 around Matt Pocock's plan, spec, tickets and implement flow (mattpocock/skills, MIT). All changes happen inside `BottegaStack/`.

## Scope

- **Multi-harness via `harnesses/`.** Core skills in `skills/` stay harness-agnostic; thin adapters live under `harnesses/claude/`, `harnesses/antigravity/`, `harnesses/codex/`, and `harnesses/opencode/`.
- **No hooks, no compiled binary.** Rules are prose the model follows; `skills/maestro/scripts/bottega` is a thin Bash wrapper around `gate-check.sh` and `log.sh` that collapses verification turns and keeps raw logs out of context without adding dependencies.
- **Per-repo state only.** `.bottega/` holds run state, plans and tickets, and stays untracked. Cross-repo memory is left to Claude Code.
- **Linux and macOS only.** bash 3.2, BSD and GNU tools, no `jq`. Python 3.9+ only for the developer lint and evals. Native Windows is not supported; WSL counts as Linux.
- **No UI driving.** Where a change needs a visual check, the agent says what to look at and the user checks it.

## Shape: grill, tickets, implement

- **Why.** Most of what the old routing, playbooks and fan-out skills described, current models already do unprompted. What they don't do unprompted: settle decisions with the user before building, size work to one session's context, keep the orchestrator's context small by delegating, and prove results mechanically. The stack keeps only those.
- **`/plan`** grills the user one decision at a time (the frontier of settled prerequisites, numbered questions with a recommended answer that "yes" accepts, facts looked up rather than asked, prototypes for ungrillable questions) and writes a spec of decisions the user made. Plan mode stays off during grilling.
- **Named `plan` (use `/bottega:plan` if Claude Code's built-in `/plan` clashes).** Built-in plan mode stays off during grilling.
- **Map mode** replaces the `wayfinder` skill: for efforts too big for one grilling session, a local map of decision questions, one resolved per session, research answered by explorers. Folded into `/plan` because it is grilling plus bookkeeping, and a separate skill duplicated the grilling rules.
- **`/tickets`** cuts vertical tracer-bullet slices, each sized for one fresh orchestrator session: **300k tokens, ±10%** (hard limit 330k), counting only the orchestrator's own context, estimated from file sizes. Each ticket names what the orchestrator does, a table of subagents (role, tier, task, write scope, which run together), blocked-by edges, a wave, and an abstract model tier (`heavy`, `medium`, `standard`, `fast`, translated per harness in `references/models.md`). Tickets that write the same file are serialized.
- **`/implement`** runs one ticket per fresh session (or one small direct task): explore, shape before logic, pin behavior by kind (bug, refactor, feature), delegate, verify, review (parallel Spec + Standards axes), final gate, then mark the ticket done and list what it unblocked. It replaces the bug-fix, feature, refactoring and investigate playbooks.
- **`/maestro`** is a one-page front door: a routing table plus the shared rules (confidence, risk, autonomy, subagents, context, replies).
- **Skills (16):** maestro, reframe, recall, triage, plan, sharpen, tickets, implement, ship, autopilot, correct, garden, unslop, frontend-design, create- and maintain-verification-skill. Every one sets `disable-model-invocation: true`.
- **References under `maestro/references/`**, read only when a step needs them: `delegate.md`, `final-gate.md`, `subagents.md`, `principles.md`, `explore.md` (was `understand` and Investigate), `review.md` (was `crossfire` and `parallel`), `prototype.md`, `handoff.md`, `worktree-cleanup.md`.
- **Principles:** 17, on one page, each a short section. Delegates read a section before applying it.

## Models

- The role table in `maestro/references/subagents.md` is the only source of truth. Four roles: orchestrator (the session, opus- or sonnet-level per ticket), explorer (`Explore`, haiku high), implementer and reviewer (`bottega:maestro-agent`, sonnet low; medium at high risk).
- Overrides live in an optional `~/.claude/rules/bottega-models.md`, written by the user.
- Effort is never `xhigh` or `max`, and never `high` except on haiku. Adversarial review uses the reviewer's High column at any risk.
- Risk only goes up during a run. Never switch `/model` mid-session; the user sets the orchestrator model at the start of each ticket's session.

## Workflow rules

- **Light route:** a docs or config change with no runtime effect skips `/implement`: edit, check, reply. Runtime config (CI, build, deploy, flags, dependencies) goes through `/implement`.
- **Review:** every `/implement` run gets one fresh reviewer against the ticket. At high risk it is adversarial, in budgeted rounds (3 by default, up to 5 for security or data, stop early on nits), keeping only findings a rerun proves. The ledger row stays `crossfire` so `gate-check.sh` needs no change.
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

- `evals/` is the fixed baseline: small tasks run with and without bottega, deterministic grading, sonnet low. Correctness and behavior are scored apart. `evals/gate.py` compares a run with `evals/baseline.jsonl` before a release. Not shipped with the plugin. The manual post-install checks live in `evals/README.md`.

## Dropped

The 8 UI review skills (`interface-review`, `better-interface`, `better-accessibility`, `better-colors`, `better-layout`, `better-typography`, `better-ui`, `better-writing`; current models handle these domains without a skill, and `frontend-design` stays for visual direction), `understand`, `crossfire` and `parallel` (folded into `explore.md` and `review.md`), the 8 playbooks (folded into `/implement` and the references), the throughput checkpoint, the explainer, runners and judge roles, `pr`, `architect`, `figure-it-out`, `wayfinder` (folded into `/plan` map mode), `setup-maestro`, the status line, progress files, `doctor.py`, `check-plan.mjs`, `security-scan.sh`, and earlier cuts recorded in git.

## Later

- Port `writing-for-agents` from BottegaStack.
- A post-run retro beyond `correct`.
- A migration and rollback reference (expand then contract, rollback first, dry run on a copy, rerunnable backfills), when a project with a production database needs it.
