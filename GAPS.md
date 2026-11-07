# PaganiStack: what is missing for a personal stack

**Verdict (0.5.0):** the minimum personal-stack layer is implemented. The
installer, project resources, verification, review convergence, evals,
observability, backups, and the compounding retro loop exist in the repo. The
remaining gaps are deliberate non-goals (full OS sandbox, control plane,
shell/`agent-browser` network egress) plus a few portability and runtime items.
The historical pre-0.2.0 gap analysis is kept below for reference.

## Implemented in 0.2.0–0.5.0

- Installer and `pagani` CLI for OpenCode and Claude Code.
- `resources/` project templates, including `PLAN.md`, `FEATURE-MAP.md`,
  `mistakes.md`, `claude-settings.json`, and `CLAUDE.md` (`@AGENTS.md`).
- README compatibility matrix for OpenCode, Claude Code, Node, `gh`, Python,
  gitleaks, systemd, agent-browser, and SQLite.
- Nine-plus-two skill taxonomy.
- P0 skills: library-reference, data-analysis, weekly-review, scaffold, ci-cd,
  runbook, infra-ops.
- P1 skills: adversarial-review, simplify, review-pr, pr, session-handoff,
  session-retro, skill-creator, agent-browser, vercel-react-best-practices.
- Lanes (`trivial`, `bugfix`, `small`, `standard`, `high-risk`) with escalation.
- `agents/models.conf` and generated model variants for both targets.
- `pagani lint`, `job new`, `classify`, `check`, `gate`, and `usage start|end`.
- Real `scripts/verify` start/stop/flow and `docs/FEATURE-MAP.md`.
- Review convergence, finding verification, risk tiers, and a PR review flow.
- Reviewer evals with diffs, `run.sh`, recall/noise, and train/test.
- `TASKS.md`, handoff, retro, worktrees, usage, status, and PR helpers.
- Gotchas sections on 23 PaganiStack-authored skills; vendored skills are
  untouched.
- Claude Code agent files, `.claude/settings.json`, and a generated `/pagani`
  command from the master body.
- Paid `design-mobile-apps` removed.
- `pagani classify` and `pagani route` read risk paths from `REVIEW.md`, with a
  fallback to `resources/REVIEW.md`.
- `unknown` classify outcome for an empty diff and `standard` lane for large
  non-risk diffs.
- `checks.log` per job and the `checks_first_pass` metric from the first check.
- Usage warnings when neither `opencode` nor `ccusage` is installed.
- `pagani lint` template checks for project files referenced by agents or skills.
- Idempotent installer for unchanged generated files.
- `verify.sh` start-timeout process-group cleanup and `PORT`/`READY_URL`
  ordering in `verify.conf`.
- Eval scoring that treats any non-`PASS` verdict on a clean case as a false
  positive and counts a bug only on `CHANGES` plus the case keyword, with
  train/test/all summaries.
- Optional format hook: Claude Code `PostToolUse` on `Edit|Write` runs
  `scripts/format <file>`; `pagani init` copies the stub.
- Optional gitleaks `pre-commit` and `pre-push` hooks:
  `pagani hooks install|uninstall|status`, installed by `pagani init` when
  `.git` exists, with backups of non-pagani hooks and a clean skip when
  gitleaks is absent.
- Optional PreCompact handoff hook: writes a snapshot to the newest job's
  `handoff.md`, or `pagani/handoff.md`.
- Optional retro scan: `pagani retro-scan [--write] [--exit-code]`; repeated
  findings prompt `session-retro` at Close.
- Optional skill-usage logging: the Claude Code `Skill` hook and the OpenCode
  plugin append to `pagani/skill-usage.tsv`; `pagani skill-log <name>` logs
  manually.
- Optional weekly timer:
  `pagani timer install|uninstall|status [path] [--at "Mon 09:00"]`; opt-in,
  spends tokens, and runs headless `pagani weekly`.
- `pagani frontier <job>`: prints the ready and blocked ticket set from
  `tickets/index.md`, with a `**Blocked by:**` fallback.
- Request-text `pagani classify`: risk, docs, bug, and feature word heuristics;
  lanes only escalate.
- Dirty-tree `pagani gate`: fails on modified, staged, or out-of-scope untracked
  files; `--allow-dirty` bypasses it.
- `pagani worktree prune` failure handling: reports `failed:` and continues;
  `--force` passes through to git.
- `pagani upgrade [path]`: merges hooks into an existing `.claude/settings.json`
  without dropping `permissions`, backs it up, and installs the other managed
  files.
- Opt-in network allowlist for Claude `WebFetch`:
  `pagani network init|check <url>` plus the `webfetch-guard` hook. Covers Claude
  `WebFetch` only; shell, `curl`, and `agent-browser` egress are not covered.
- Exact per-job cost from the local OpenCode `session` table, including worktree
  sessions, written to `usage.md` and `metrics.tsv`; `pagani usage report`.
- `pagani budget set|check <job>`: per-job USD budget check; exits 1 when over.
- `pagani dashboard`: local, read-only `pagani/dashboard.html`; inline CSS, no
  JS, no server, no login, no control plane.
- Local `pagani backup`/`pagani restore`: tar.gz under `pagani/backups/`, with
  overwrite refusal without `--force`; no sync or remote copy.
- Skill evals: `evals/skills/run.sh` trigger tests, opt-in and token-spending.
- GitHub Actions `pagani-check` workflow: lint and `scripts/check` on pull
  requests and pushes to `main`; GitHub runners, read-only `contents`, no
  secrets, no login, no LLM calls.
- `untrusted-content` skill and a headless weekly rule; thin-skill Gotchas.
- No cloud sessions.

Deliberate non-goals: a full OS sandbox and a control plane that starts or stops
agents. The network allowlist is opt-in and limited to Claude `WebFetch`; it does
not cover shell or `agent-browser` egress. `pagani budget check` is a check, not
a hard cap. `untrusted-content` is a convention, not a sandbox. Backups are
local only.

## PLAN.md minimum coverage

`PLAN.md` is the design baseline. The 0.5.0 tree covers its minimum:

| PLAN.md promise | Status | Evidence |
|---|---|---|
| 11 steps, including Step 0 setup and lane confirmation | Done | `agents/*/master.md`, `commands/*/pagani.md`, `HOW-IT-WORKS.md` §4 |
| Nine-plus-two skill taxonomy | Done | `skills/*`, `CATEGORIES.md`, `pagani lint` |
| Agent roles plus lite/std/strong variants | Done | `agents/*`, `agents/models.conf`, installer |
| Job folder is the state; no JSON state machine | Done | `pagani job new`, `pagani/jobs/<id>/job.md` |
| Plan, spec, tickets, build, checks, review, fix, approve, human, close | Done | masters, skills, `pagani check/gate/frontier` |
| Summary contract and review convergence | Done | `summary`, `REVIEW.md`, reviewer skills, `pagani route` |
| Verification: hands, eyes, map | Done | `scripts/verify`, `docs/FEATURE-MAP.md`, `verification` |
| Reviewer evals and skill evals | Done | `evals/reviewer`, `evals/skills` |
| Installer, uninstall, doctor, lint, upgrade | Done | `install.sh`, `bin/pagani`, `resources/` |
| Worktrees, ports, and parallel builders | Done | `pagani worktree create/prune`, `skills/workflow/lanes` |
| PR review and CI gate | Done | `pagani pr`, `review-pr`, GitHub Actions workflow |
| Cost, metrics, budget, dashboard | Done | `pagani usage`, exact cost, `metrics.tsv`, `budget`, `dashboard` |
| Backups | Done (local) | `pagani backup/restore`; no remote sync |
| Prompt-injection defense | Partial | `untrusted-content` convention; not a sandbox |
| Network allowlist | Partial | Claude `WebFetch` only; shell/`agent-browser` not covered |
| Full OS sandbox | Not done (deliberate) | see `PLAN.md` §10 |
| Control plane | Not done (deliberate) | dashboard is read-only |

---

## 1. What the Claude Code team does

From `claude.dev`, especially:

- [How the Claude Code team does code review](https://claude.dev/blog/solving-code-review-at-anthropic/)
- [Lessons from building Claude Code: How we use skills](https://claude.dev/blog/lessons-from-building-claude-code-how-we-use-skills/)
- [Building effective agent automations](https://claude.dev/blog/building-effective-agent-automations/)
- [Claude Code in the cloud](https://claude.dev/blog/claude-code-in-the-cloud/)
- [Getting started with Claude Code mods](https://claude.dev/blog/getting-started-with-claude-code-mods/)
- [Automating eval design and hillclimbing](https://claude.dev/blog/automating-eval-design-and-hillclimbing/)
- [Spending your effort](https://claude.dev/blog/spending-your-effort/)
- [What a task costs on Opus 5.5](https://claude.dev/blog/what-a-task-costs-on-opus-5-5/)
- [The new rules of context engineering](https://claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models/)

### Skills

The team groups internal skills into nine categories: library/API reference,
product verification, data fetching/analysis, business process automation,
scaffolding/templates, code quality/review, CI/CD/deployment, runbooks, and
infrastructure operations. A good skill fits one category; a skill that tries to
do everything confuses the agent.

Their highest-signal practices:

- **A skill is a folder, not just a markdown file.** It can include scripts,
  assets, references, examples, and data.
- **The Gotchas section is the most valuable part.** Add to it every time the
  agent hits a real failure.
- **Progressive disclosure.** `SKILL.md` is the hub; detailed references live in
  sibling files and are read only when needed.
- **Do not railroad.** State the goal and constraints, not every command.
- **Write descriptions for the model.** The description says *when to trigger
  this skill*, not what it is.
- **Setup and memory.** Store config in the skill folder; ask the user when it is
  missing. Append-only logs give a skill memory across runs.
- **Scripts over prose.** Give the agent a small library of tested helpers.
- **On-demand hooks.** `/careful` and `/freeze` are good examples: opinionated
  guardrails that run only when the skill is active.
- **Distribute through a marketplace or the repo.** Check skills into the repo
  for small teams; use a plugin marketplace at scale.
- **Measure skill usage.** Log when a skill triggers; find popular and
  undertriggering skills.

### Subagents

- Give each subagent a fresh context window and a narrow task.
- A subagent returns a summary; the main agent checks the evidence before
  accepting it.
- Route models: small models for search, log reading, and summarisation; the
  main model for code edits and judgment.
- Parallel subagents work when tasks are split along file boundaries. Each
  session needs its own worktree, ports, and branch.
- Agent teams are expensive: Anthropic puts a plan-mode team at roughly seven
  times the tokens of a standard session.
- Cloud sessions give each task its own VM and branch; one task, one session.

### Tips

- Give the agent a way to verify its own work. Boris calls this the 2-3x habit.
- Write every correction down: `CLAUDE.md`, a skill, a lint rule, or a test.
- Turn repeated work into a skill.
- Use worktrees for parallel sessions.
- Separate the writer from the reviewer.
- Keep context minimal; use progressive disclosure and references.
- Keep a `TASKS.md` checklist so a long run survives compaction.
- Name the finish line and the stop conditions in the first prompt.
- Read the "what I need from you" part of a long run first.
- Ask for evidence, not a claim.
- Remove "think hard" lines; newer models already think. Use effort instead.
- For design, name the styles you do *not* want.

### Token saving and context management

- A task is a loop; every turn resends the conversation. Fewer turns is the
  biggest saving.
- Cache reads are the cheapest input. Keep a steady session; changing the model,
  effort, MCP servers, or tool definitions can break the cache.
- Output is the most expensive token type. Effort mostly changes output.
- Use `/clear` between unrelated tasks. Use `/compact` at a natural break, with a
  note on what to keep. Use `/rewind` instead of correcting a wrong path.
- Keep `CLAUDE.md` short (Anthropic suggests under 200 lines) and spend it on
  gotchas, not obvious facts.
- MCP tool definitions are deferred; only names and server instructions load at
  the start.
- Put search/log subagents on a smaller model; keep code edits on the strong
  model.
- Raise effort before switching to a bigger model. If xhigh hits the same problem
  twice, switch, then switch back.
- Run `/usage` and measure your own tasks; do not trust generic cost figures.

### PR and code review

The Claude Code team uses six layers:

1. **Verify before the PR.** Tests, build, screenshots, a fresh-context subagent
   review, a bug-hunt skill, a simplify skill, a browser check.
2. **AI review on every PR.** It reads the diff against the repo and the stated
   intent. Findings are verified by several agents and voted on before posting.
3. **Security review that can block.**
4. **Automated checks that block.** Lint, typecheck, tests, build.
5. **Human approval scaled by risk.** Low: no human once automated review and
   security are green. Medium: one person. High: two people. A classifier sets
   the tier from the change, not the author.
6. **Merge queue, flags, gradual release, fast rollback.** Incidents and reverts
   become evals for the reviewer.

Review has to converge: cap rounds (they use three), re-review only the new diff,
flag the class of bug so every instance is fixed, and do not repeat findings.
Measure noise by watching how authors respond to comments. Turn incidents and
reverts into an eval set.

---

## 2. What pstack does

From [On pstack](https://barnabyrobson.org/on-pstack/):

- **Michelin kitchen:** prepare the environment so cooks can work without the
  chef at every station.
- **Trust ladder:** trust is earned by evidence. Verification is the first rung.
- **Inner and outer loops:** the inner loop builds and verifies; the outer loop
  brings fresh context from Slack, issues, email, and telemetry.
- **Gardener:** watch merged work for smells, group them, and change the
  environment (lint, types, tests, skills) so the same weed cannot grow back.
- **Hands, eyes, and a map:** a verification skill, a small CLI with named
  commands, and a feature map that tells the agent how to reach and drive every
  feature.
- **Measure a hundred times, cut once:** plan with code and evidence; prototypes,
  architecture candidates, then a multi-phase plan.

pstack also has a router, playbooks, principle skills, agent definitions, and
evals. The transferable core is verification plus the gardener, not the full
library.

---

## 3. What Boris and Anthropic say

From [Boris Cherny's workflow](https://digitalstrategy-ai.com/boris-cherny-claude-code-workflow):

- Verification is worth 2-3x. It is domain-specific: tests, build, browser,
  simulator, data CLI.
- Write corrections down; do not correct in chat.
- Turn repeats into skills.
- Worktrees are the biggest productivity unlock.
- Separate the writer and the reviewer.
- Context minimalism: minimal system prompt, minimal tools, a way to fetch what
  is needed.
- Plan mode is less necessary for newer models; the written plan is still useful
  as a human artifact.
- Quiz the human on the change before merging.
- Parallel sessions and an agent view are the scale path.

From [Building effective agents](https://www.anthropic.com/research/building-effective-agents):

- Start with the simplest solution. Add complexity only when it demonstrably
  improves outcomes.
- Use workflows for predictable paths and agents for open-ended work.
- Patterns: prompt chaining, routing, parallelization (sectioning and voting),
  orchestrator-workers, evaluator-optimizer.
- Maintain simplicity, transparency, and a well-designed agent-computer
  interface.
- Give agents ground truth from the environment at each step.
- Add human checkpoints, stopping conditions, and sandboxing.

---

## 4. Gap list — status at 0.5.0

This was the pre-0.2.0 gap list. The status below reflects the 0.5.0 tree; the
implemented items are also listed at the top of this file. Full OS sandboxing
and a control plane remain deliberate non-goals. The network allowlist is
opt-in and covers Claude `WebFetch` only, not shell or `agent-browser` egress.
The budget is a check, not a hard cap, and `untrusted-content` is a convention,
not a sandbox.

### P0 — installable and portable

| Item | Status | Notes |
|---|---|---|
| `install.sh` with `--dry-run`, `--copy`, `--uninstall`, backups, flat skill links, upstream check | Done | `install.sh`, `bin/pagani install/uninstall`, manifest, `pagani doctor` |
| `resources/` templates: `AGENTS.md`, `checks.sh`, `verify.sh`, `BACKLOG.md`, `GLOSSARY.md`, `docs/adr/` | Done | `resources/`; `pagani init` |
| A project `PLAN.md` template | Done | `resources/PLAN.md`; `pagani init` copies it when absent |
| `README.md`, `CHANGELOG.md`, `LICENSE`, git tags | Done | All files exist; `v0.5.0` tag |
| `pagani doctor`: versions, agents/skills, upstream skills, config | Done | `pagani doctor`; model availability is reported by OpenCode |
| `pagani init`: project scaffold and `.gitignore` | Done | `pagani init`; `scripts/check`, `scripts/verify`, `scripts/format`, hooks |
| Upstream skills pinned or checked at install | Partial | `VENDOR.md` records sources; `doctor` checks presence, not commit pins |
| Compatibility matrix: OpenCode, Node, Chrome, `gh`, Python | Done | README “Compatibility” table; `doctor` reports the local tools |
| Uninstall and update paths | Done | `pagani uninstall`, `pagani upgrade` |
| Plain-text install manifest | Done | `.pagani-manifest-<target>.txt` |

### P1 — verification, review, evals

| Item | Status | Notes |
|---|---|---|
| `agent-browser`/Playwright, `verify.sh`, feature map | Done | `scripts/verify`, `docs/FEATURE-MAP.md`; `agent-browser` optional |
| `checks.sh` template and a CI/PR gate | Done | `resources/checks.sh`, GitHub Actions `pagani-check` |
| `REVIEW.md` per repo | Done | `resources/REVIEW.md`; `pagani init` copies it |
| Review convergence: round cap, diff-only re-review, bug class, no repeats | Done | `REVIEW.md`, reviewer skills, `pagani route` |
| Multi-agent finding verification or voting | Partial | Finding verification is in the review skills; no voting layer |
| `evals/` for reviewers and skills | Done | `evals/reviewer`, `evals/skills` |
| Handoff/session pickup and `TASKS.md` | Done | `session-handoff`, `TASKS.md` |
| Retro/gardener loop | Done | `session-retro`, `pagani retro-scan` |
| `research` and `prototype` as first-class planning steps | Partial | Available in the runtime; not wired into the PaganiStack planner |
| `simplify`, bug-hunt, security-review skills | Done | `simplify`, `diagnosing-bugs`, `review-security` |
| `web-design-guidelines` in UI/UX review and visual regression | Partial | Wired into review; no visual-regression runner |

### P2 — scale, cost, safety

| Item | Status | Notes |
|---|---|---|
| Worktree helper, port allocation, cleanup | Done | `pagani worktree create/prune`; port written to the ticket |
| PR automation: `gh pr create`, CI status, merge queue, flags, rollback | Partial | `pagani pr`, `closeout`, GitHub Actions checks; no merge queue/flags/rollback automation |
| Token and cost tracking per job | Done | Exact OpenCode `session` cost, including worktrees; `usage report` |
| Metrics: first-pass gate rate, rounds, approvals, defects, time, cost | Done | `pagani/metrics.tsv`; `checks_first_pass`, rounds, fixes, reworks, cost |
| Agent view or control plane | Partial | Read-only `pagani dashboard`; no control plane |
| Sandbox, secret vault, network allowlist, spending cap | Partial | Claude `WebFetch` allowlist and `budget check`; no sandbox, vault, or hard cap |
| Prompt-injection defenses | Partial | `untrusted-content` convention; no sandbox |
| Audit log of tool calls and file writes | Not done | `pagani/skill-usage.tsv` logs skill use only |
| Review-capacity planning | Not done | Human process, not code |

### P3 — skill quality

| Item | Status | Notes |
|---|---|---|
| A Gotchas section in every skill | Partial | PaganiStack-authored skills used on most jobs have Gotchas; vendored skills are untouched |
| Progressive disclosure: references, assets, scripts | Partial | Used in several skills; not systematic |
| Trigger-rich descriptions | Done | `pagani lint` requires a description; descriptions are trigger-oriented |
| Skill usage logging and skill evals | Done | Claude/OpenCode hooks + `pagani/skill-usage.tsv`; `evals/skills` |
| Avoid railroading: goal and constraints, not every command | Done | Design principle in `AGENTS.md` and the skills |
| Apply `writing-for-agents` to every skill and `AGENTS.md` | Partial | Not systematically verified |
| Attribution and licenses for every upstream skill | Done | `VENDOR.md` and per-skill licenses |

---

## 5. Priority order

1. Installer, `resources/`, `README.md`, and `pagani doctor`.
2. Verification: `agent-browser`/Playwright, `verify.sh`, feature map, `checks.sh`.
3. Review convergence: `REVIEW.md`, round cap, diff-only re-review, no repeats.
4. Evals: reviewer incidents and clean PRs; skill trigger tests.
5. `handoff`, `TASKS.md`, and the gardener/retro loop.
6. Worktrees, PR automation, and cost metrics.
7. Sandbox, secrets, network allowlist, and spending caps.
8. Design integration: wire `web-design-guidelines` into UI/UX review and add
   visual regression.

At 0.5.0, items 1–6 are implemented; item 7 is partial (Claude `WebFetch`
allowlist and budget check, but no sandbox, secret vault, or hard cap); item 8
is implemented for UI/UX review, with visual regression still open.

The design skills are already in `skills/design/`. See
`skills/design/README.md` for sources and licenses.
