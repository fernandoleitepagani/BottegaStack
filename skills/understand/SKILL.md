---
name: understand
description: "Build understanding before acting. Four modes: how (how X works, where something should live), why (the motivation and history behind code), recall (rebuild recent working context across chats), and catch-up (what changed in this chat and what waits on the user). Use for /understand, 'how does X work', 'why is X like this', 'recall my work on X', 'catch me up'."
disable-model-invocation: true
---

# Understand

Understand first, so the change that follows is right the first time. Pick one mode from the request and run only that mode. If the scope is ambiguous, state your reading and proceed; the user can redirect.

| Mode | Answers | Spawns |
|---|---|---|
| **how** | What the code does now, runtime flow, where something should live | 0 or 2-4 explorers, then 1 explainer |
| **why** | What forces gave the code its shape | 1 investigator per evidence source, then 1 synthesizer |
| **recall** | Where the user's recent work stands across chats | haiku slices over transcripts, plus the why sweep |
| **catch-up** | What changed in this chat since the user's last message | none |

Models come from the role lines in `../maestro/references/subagents.md`: `explorer` (explorers, investigators, recall slices) and `explainer` (explainer and synthesizer). A rejected model falls back to the role default; say so. Every spawn is an `Agent` call that must not write: `subagent_type: "Explore"` for code and git, `general-purpose` only when an approved MCP server is needed. More than 3 parallel spawns follows the fan-out rule in that file.

## how

1. **Simple** (one module, one function, a narrow question): spawn one explainer with `references/explainer-prompt.md`, without the findings section. It explores and explains in one pass.
2. **Complex** (a subsystem across files or services, a cross-cutting feature): split the question into 2-4 distinct angles and spawn one explorer per angle in a single message, each with `references/explorer-prompt.md`. Then spawn one explainer with every explorer's findings. When in doubt, take the simple path.
3. Present the explainer's output with light edits only. Sections: Overview, Key Concepts, How It Works, Where Things Live, Gotchas. Drop any that do not apply.

## why

Be a careful, cautious, precise investigator. Separate what you know from what you infer, per `references/epistemics.md`.

1. **Target and question.** The target is code, a pattern, a feature, or a named decision. If it is vague, guess from context and say so.
2. **Code anchor.** Build it inline before any spawn: paths and line ranges, key symbols, `git blame -L`, `git log --follow -p -- <file>`, `git log --oneline -20 -- <file>`, PR numbers from merge subjects, and `gh pr view <n> --json title,body,comments,reviews,closingIssuesReferences` for substantive commits.
3. **Investigators.** One per evidence category, all in one message, each owning one source:
   - Source control (git, `gh`): always. Best at rationale captured in review.
   - Issue tracker, long-form docs, team chat, infrastructure observability, error tracking, product analytics: only for an MCP server the user approved this session (ask once per server). Each is best at, in order: the product forcing function, written design rationale, deliberation that never reached a doc, the runtime reality behind timeouts and retries, the errors behind defensive code, the data behind flags and thresholds.
   Each brief is `references/investigator-prompt.md` filled in, plus the matching `references/sources/<source>.md` (index in `references/source-playbook.md`), plus `references/sources/incident-postmortem.md` when the target looks defensive (null checks, retries, timeouts, rate limits, flags). MCP reads only.
   Skip a category only with a written reason that goes in Sources Consulted: no approved server ("gap, not a choice"), or provably irrelevant. A null result is a finding.
4. **Synthesize.** One synthesizer gets the findings (nulls and skips included), the anchor, the question, `references/epistemics.md`, and `references/synthesizer-prompt.md`.
5. **Present** without rewriting the confidence language. Keep Sources Consulted as one line per investigator. If the question precedes a change, end with Preserve / Change / Avoid / Risk.

Avoid recency bias: the current shape is usually an accretion of earlier decisions.

## recall

Rebuild the user's working context before they start or resume. Their history lives in two records: their chats, and the shared record (reports, fixes, reverts, errors) that the why mode searches.

1. **Route.** Resuming one specific prior chat is the handoff playbook, not this. If the user already gave a full state capsule, use it.
2. **Scope.** Pin the window (default the last 7 days), the topic, and the workspace (the active one; never another project's transcripts unasked). State it back.
3. **Mine chats.** Transcripts are `~/.claude/projects/<slug>/<session>.jsonl` (subagents under `<session>/subagents/`); `<slug>` is the workspace path with `/` and `.` replaced by `-`. Split the corpus into slices, one explorer each. Order by modification time (`ls -t`), grep the topic first, skip this chat and eval or test chats. Each returns per chat: topic, goal, decisions, open threads, struggles and corrections, artifacts, chat UUID. For one or two chats, search directly.
4. **Sweep the shared record** whenever a feature, file, area, or bug is named: run the why mode's investigators in parallel, asking "what is the current state, what was tried and didn't hold, what do users still report".
5. **Verify** surfaced PRs, branches, and tickets with `git` and `gh`.
6. **Brief:** a capsule of at most 5 bullets; one line per thread tagged `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`; at most 5 recurring problems; one next move. Cite chats by UUID and shared findings by source.

## catch-up

Catch the user up on what changed since their last message in this chat, then lay out every call waiting on them so they can decide from the reply alone. Notifications and subagent results are not their messages. Keep the turn read-only.

1. **Gather** your work, subagent reports, and the current state of each PR, CI run, or agent this chat touched. Check every number against its source. An action item is a call only the user can make (a product choice, an approval, an irreversible step, access you lack). Never invent one.
2. **Write.** Open with one sentence naming what waits on the user, or that nothing does. Then what happened, in under 100 words: one plain bullet per thing the user asked for, saying what came of it and whether it is done, running, failed, or unchecked ("Search was slow from a missing index", not "Search review: done"). Then the action items, about 30 words each: the call, your pick, what it changes for users, the evidence, and its risk, even when low. Items sharing a call get the call once and one bullet each, riskiest first. A call between options gives each option's gain and cost.
3. **Visuals** only when a picture explains better than sentences (how a system works, a PR stack, a before and after): a small Mermaid or text diagram, at most six boxes of at most eight words. Never a status list as a picture. Agents do not take screenshots; embed ones the user pasted.

Plain words, no jargon, no hashes or paths unless the user needs them to act.

**Reply:** the mode's output as described above, written through the **unslop** skill.
