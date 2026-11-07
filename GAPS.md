# PaganiStack: what is missing for a personal stack

**Verdict:** the workflow is strong. The missing layer is the part that makes it
a *personal stack*: an installer, project resources, verification, evals,
observability, and a compounding correction loop. Right now it is a good
workflow that lives in one checkout. A personal stack is a workflow you can
install, update, and trust on any machine.

## Implemented in 0.2.0–0.3.1

- Installer and `pagani` CLI for OpenCode and Claude Code.
- `resources/` project templates, including `FEATURE-MAP.md`, `mistakes.md`,
  `claude-settings.json`, and `CLAUDE.md` (`@AGENTS.md`).
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
- Gotchas sections on 12 PaganiStack-authored skills.
- Claude Code agent files, `.claude/settings.json`, and a generated `/pagani`
  command from the master body.
- Paid `design-mobile-apps` removed.
- `pagani classify` and `pagani route` read risk paths from `REVIEW.md`, with a
  fallback to `resources/REVIEW.md`.
- `unknown` lane for an empty diff and `standard` lane for large non-risk diffs.
- `checks.log` per job and the `checks_first_pass` metric from the first check.
- Usage warnings when neither `opencode` nor `ccusage` is installed.
- `pagani lint` template checks for project files referenced by agents or skills.
- Idempotent installer for unchanged generated files.
- `verify.sh` start-timeout process-group cleanup and `PORT`/`READY_URL`
  ordering in `verify.conf`.
- Eval scoring that treats any non-`PASS` verdict on a clean case as a false
  positive and counts a bug only on `CHANGES` plus the case keyword, with
  train/test/all summaries.
- No cloud sessions.

Still intentionally not implemented: full sandbox, network allowlist, per-job
spending cap, backups of `pagani/jobs/`, and prompt-injection defenses. Those are
partial/optional; see the table below.

Optional items, still not implemented: a format hook, a gitleaks pre-commit
hook, a PreCompact handoff hook, a retro-scan, skill-usage logging, and an
opt-in weekly timer.

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

## 4. Gap list for a personal stack

This is the pre-0.2.0 gap list, kept as a reference. The implemented items are
listed at the top of this file. The remaining partial/optional items are the
full sandbox, network allowlist, per-job spending caps, automatic cost
attribution, and a full eval harness.

### P0 — installable and portable

- [ ] `install.sh` with `--dry-run`, `--copy`, `--uninstall`, backups, flat skill
      links, and an upstream-skill check.
- [ ] `resources/` templates: `AGENTS.md`, `checks.sh`, `verify.sh`,
      `BACKLOG.md`, `GLOSSARY.md`, `docs/adr/`, `PLAN.md`.
- [ ] `README.md`, `CHANGELOG.md`, `LICENSE`, and git tags.
- [ ] `pagani doctor`: check the OpenCode version, installed agents/skills,
      missing upstream skills, model availability, and config conflicts.
- [ ] `pagani init`: scaffold a project with `AGENTS.md`, `studio/checks.sh`,
      `studio/verify.sh`, and `.gitignore`.
- [ ] Upstream skills: vendor them at pinned commits or check them at install.
- [ ] A compatibility matrix: OpenCode version, Node, Chrome, `gh`, Python.
- [ ] Uninstall and update paths.
- [ ] A plain-text install manifest so uninstall removes only what it installed.

### P1 — verification, review, evals

- [ ] Install `agent-browser` or Playwright, plus a `verify.sh` template and a
      feature map.
- [ ] A `checks.sh` template and a CI/PR gate.
- [ ] A `REVIEW.md` per repo: what failure looks like, paths to skip, evidence
      format, and a cap on nits.
- [ ] Review convergence: round cap, diff-only re-review, flag the bug class, no
      repeat findings.
- [ ] Multi-agent finding verification or voting before a finding is posted.
- [ ] `evals/` for skills and reviewers. Start with incidents, reverts, and known
      clean PRs.
- [ ] `handoff` or session-pickup skill, plus a `TASKS.md` convention.
- [ ] `retro` or gardener skill that turns repeated findings into rules, lint,
      tests, or skill edits.
- [ ] `research` and `prototype` as first-class planning steps.
- [ ] `simplify`, `bug-hunt`, and `security-review` skills.
- [ ] Wire `web-design-guidelines` into `review-ui` and `review-ux`, and add a
      visual-regression check.

### P2 — scale, cost, safety

- [ ] Worktree helper and a parallel-job manager with port allocation and cleanup.
- [ ] PR automation: `gh pr create`, CI status, merge queue, flags, rollback.
- [ ] Token and cost tracking per job, with a `/usage` equivalent.
- [ ] Metrics: first-pass gate rate, review rounds, human approvals, escaped
      defects, time per stage, cost per job.
- [ ] An agent view or control plane grouped by needs-input, working, completed.
- [ ] Sandbox, secret vault, network allowlist, and a per-job spending cap.
- [ ] Prompt-injection defenses for web pages, issues, Slack, and screenshots.
- [ ] An audit log of tool calls and file writes.
- [ ] Review-capacity planning: the human is the bottleneck.

### P3 — skill quality

- [ ] A Gotchas section in every skill.
- [ ] Progressive disclosure: split long skills into references, assets, and
      scripts.
- [ ] Trigger-rich descriptions written for the model.
- [ ] Skill usage logging and skill evals.
- [ ] Avoid railroading: goal and constraints, not every command.
- [ ] Apply `writing-for-agents` to every skill and `AGENTS.md`.
- [ ] Attribution and licenses for every upstream skill.

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

The design skills are already in `skills/design/`. See
`skills/design/README.md` for sources and licenses.
