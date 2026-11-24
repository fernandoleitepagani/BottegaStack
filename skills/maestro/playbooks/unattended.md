### Unattended

**You own the outcome while nobody is watching. Define done as a check, decide who does each piece, and prove every result before it lands.** Your updates go unread until long after you stop, so stay active until done: a turn that ends while checks are pending stops the work.

**Mode.** Name it in the first reply and in every `/loop` tick prompt.

- `task`: one task driven to a checkable exit condition ("run until done", "/loop until X").
- `queue`: independent PRs, one owner each. Sub-mode `land` (the default) merges them; `stack` stops at verified and hands them over ("autopilot, don't merge", "build the stack, I'll land it").
- `program`: a standing project over days (many stacked PRs, many agents). Work one agent can finish in the session is `task`, not this.

#### Permissions

The user's request for an unattended run is the permission for the steps below, and only these:

- Push and rebase this run's own branches, and `git push --force-with-lease` pinned to the SHA you last pushed or took over. These are the run's branches, not shared ones. On any push you did not make, stop and report.
- Use any test method the proof needs (run the app or a dev server, a `verify-<app>` skill) without asking first. Rules about how to test still apply.
- In `queue land` only: merge a PR once its gate below passes.

Everything on the Always-pause list in `../SKILL.md` (**Autonomy**) still pauses: deploys, data deletion, customer messages, force-push to shared branches, approvals the forge enforces. The operator's named gates come first, and items outside the grant stop at merge-ready.

#### Every mode

1. **Exit condition first.** State done as a checkable predicate (tests green, repro fixed, all N PRs merged). Never relax it to declare victory. A plateau is not a stop: pivot. Surface a genuine dead end instead of spinning.
2. **Wake.** Use `/loop`. An event to watch (CI, a merge) gets a watcher and a long heartbeat as fallback. No event gets a fixed interval sized to when the result is worth re-checking.
3. **Smallest verified step.** Each iteration makes the smallest change the evidence justifies, verifies it against the predicate, keeps it if it advanced, reverts it if not (**Sequence Work into Verifiable Units**).
4. **Assume you die.** Keep the decision trail below in `.bottega/`, one row per iteration, plus each spawned agent's id, PR, and `stuck_after` runtime, so a replacement can pick up.
5. **Side findings.** Fix what blocks the predicate in its own PR. Log everything else to `.bottega/followups.md`; do not fix it now.
6. **Ask only** for an irreversible step, a product call no experiment settles, or a dead end that survived a replan. Rebases, retries, CI flakes, and review triage never reach the user. Under the grant, skip any step that asks about **architect** and report the skip.

#### queue and program

7. **One owner per PR.** Each owner is an `Agent` (role: writer) with `isolation: "worktree"`, the only writer of its branch. It builds, opens its PR per the **pr** skill (open mode; an owner may open a draft early so CI runs), proves the change on the real artifact, and babysits it (babysit mode). Kickoffs name the goal, the paths it may write, the actions it must not take, and the evidence that proves done. Cap fan-out: worktree runs share CPU, ports, and disk.
8. **Start with one unit.** Take the first PR through kickoff, owner, verification, and merge before fanning out, so a flawed kickoff costs one agent.
9. **Verify independently.** Nothing merges until agents that never wrote the code prove it. Run a full **parallel** (coverage) of verifiers once, at the code-ready head, with a live lane through `verify-<app>` (for UI, say what a human should check). A rebase or minor fix gets a single verifier at the new head; a wording-only change gets none. Block only on a problem you can show at the head; a problem the base already has goes to follow-ups.
10. **Merge gate (`queue land`).** The verdict covers the current head (`git patch-id` per the **pr** skill's land mode), CI is green at that head, and trunk's changes since were checked against the patch. A conflict or a changed caller means rebase and re-check. Hold and report past a third rebase.
11. **`queue stack` stops** when each PR is verified and green: hand the PRs over, and nobody pushes after the handoff without the operator's go.
12. **Supervise by side effects.** Read the diff, not the summary. Probe each agent on every tick; an agent with nothing new past its `stuck_after` is stuck, so replace it with a fresh one carrying its consolidated brief. Retry by cause (smaller scope after a context limit, the same brief after a dropped connection); after two retries, drop the unit and replan. Anything that loosens a gate needs a verifier's proof and your countersign; never bypass an approval the forge enforces.
13. **`program` only:** you never write code. Use sub-coordinators only when one area has many workers, at most three levels deep, about ten workers in flight each, each sending one rollup.
14. **On the operator's stop,** every owner gets a zero-writes hold, reports where it stands, and keeps its brief.

#### Decision trail

The trail makes an unattended run reviewable. Any run the user steps away from keeps one, and so do figure-it-out runs.

- **Format.** One TSV, `.bottega/decisions.tsv` (or `.bottega/<task-slug>.tsv` when several efforts run at once), columns `ts phase decision why evidence result`. Write rows with `<maestro dir>/scripts/log.sh <file> <phase> <decision> <why> <evidence> <result>`, which stamps `ts`, writes the header, strips tabs and newlines, and guards cells that start with `= + - @`. Evidence is a pointer (SHA, PR, `file:line`, artifact path), never prose. Write rows in plain words through the **unslop** skill.
- **What to log.** Decision points, not every action: a fork chosen, a unit finished with its verification result, a pivot or revert with its trigger, a blocker. One row per loop iteration.
- **Append-only.** A wrong call gets a new row that supersedes it; never edit or delete history. A run that comes back to a log another run wrote first adds a `start` row naming the rows it did not write.
- **Audit before handing back.** Read this run's transcript (`~/.claude/projects/<slug>/<session>.jsonl` in the active workspace only) against its rows: every row maps to something real, every pointer resolves, and every fork or pivot that shaped the work is logged. Fix by adding superseding rows.
- **Review at high risk only.** Spawn one `reviewer` that reads the trail and the transcript and flags weak evidence, skipped verification, and risky choices. End the reply with an **Attention** section: `reviewed by <model>` (or why the review was skipped) and each flag, pointing at rows.
- **Keep it local.** Commit the trail only when the user asks. `column -s$'\t' -t <file>` renders it in a terminal.

**Reply:** catch the user up per the **understand** skill's catch-up mode: the exit condition and whether it holds, each PR's state and verdict with its link (in `stack`, the verdict in place of the merge), what was discarded or dropped and why, countersigns, and the calls waiting on the user.
