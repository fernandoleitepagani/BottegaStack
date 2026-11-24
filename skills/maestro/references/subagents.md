# Subagents: models and effort

Read before your first spawn in a run. The rules in the maestro `SKILL.md` **Subagents** section still apply.

**Models per role.** `~/.claude/rules/bottega-models.md` (written by `/setup-maestro`) holds one line per role, `role: <normal model effort> | <high model effort>`. A role with no line uses the default below. Pass both `model` and `effort` on every spawn. A playbook names the role as `(role: <name>)`. Look it up here or in the rule file.

| Role | Normal | High |
|---|---|---|
| orchestrator | opus low | opus medium |
| feature | sonnet low | sonnet medium |
| refactoring | sonnet low | sonnet medium |
| bug-fix | sonnet low | sonnet medium |
| perf-issue | sonnet low | sonnet medium |
| hillclimb | sonnet low | sonnet medium |
| reviewer | sonnet low | sonnet medium |
| diagnosis | sonnet low | sonnet medium |
| crossfire | none (solo at high risk; panel on request) | sonnet medium |
| comment-sicko | sonnet low | sonnet medium |
| architecture explorer | haiku high | haiku high |
| how explorer | haiku high | haiku high |
| how explainer | opus low | opus medium |
| why investigators | haiku high | haiku high |
| why synthesizer | opus low | opus medium |
| swarm workers | haiku high | haiku high |
| verification workers | haiku high | haiku high |
| arena runners | sonnet low, haiku high | sonnet medium ×2, haiku high ×2 |
| architect runners | sonnet low, haiku high | sonnet medium ×2, haiku high ×2 |
| arena cross-judge | none | sonnet low |

**Effort ceiling.** Never `xhigh` or `max`. Never `high` except on haiku. You may lower effort one step for routine work. You may not raise it above the table. If a spawn rejects a model, use the role's default and say so.

**Fresh subagents by default.** Give new work to a fresh subagent with consolidated scope, meaning the original brief, every later directive, and the prior agent's report and branch. This holds for a fix round, a follow-up, a retry, and the next queue item. Resume or message an existing subagent only when the new work strictly needs state that lives in that agent and is costly to move: its local checkout, its uncommitted changes, or a process it still runs, such as a dev server or a babysit watcher. A stop or hold order to a running agent is not reuse. A role such as a PR owner outlives its agent. Once that agent returns, a fresh agent takes the role's next round. Chained resumes silently drop directives, so fire a fresh subagent with consolidated scope rather than trusting a "done" summary. No "standing by" reply that only waits on a nested agent.

**Fan-out ask.** Before spawning more than 3 agents in one fan-out, ask the user, unless a full-autonomy grant covers it.
