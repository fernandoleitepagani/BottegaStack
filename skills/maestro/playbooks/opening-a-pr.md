### Opening a PR

Invoked at the end of every other playbook.

**Worktree.** Work from a git worktree off main. Subagents inherit it. Multiple `Agent` calls on the same branch each get their own worktree, or `git fetch && git reset --hard origin/<branch>` between them. Dirty branch with unrelated work: patch out, fresh worktree, apply. Snarled worktree: reset from main, redo minimally.

**Commits.** Commit liberally. Rebase into small, ordered commits before opening PRs. Each commit is a future PR: landable, ordered to tell the story. Amend when the fix belongs in a just-made commit. New commit when separable. Commit bodies don't restate the subject.

**Security scan.** Before the Final gate, run `<maestro dir>/scripts/security-scan.sh [-b <base>]` (`<maestro dir>` is the absolute directory of the maestro `SKILL.md`). It never prints a secret value. A `secrets` hit blocks: remove the value from the diff and from history on this branch, and tell the user to rotate it, since a pushed secret counts as leaked. A `deps` finding needs a fix or a stated reason it does not reach this code, and each new dependency's license must be compatible with the project's. When `surface` lists a sensitive path, or risk is high, also run Claude Code's `/security-review` on the branch (Skill tool, `security-review`). It diffs against `origin/HEAD`, so run it only when `git rev-parse --verify --quiet origin/HEAD` succeeds; it fails to load without that ref. Otherwise brief one `maestro-agent` (role: reviewer) to review only those paths for auth, injection, and secret handling. Triage its findings per `references/reviewer-triage.md`. Log one proof row for the scan. Skip all of this on the light route.

**PRs.** Before review, `Read` `../../no-comments/SKILL.md` and follow it. Open the PR only after the maestro Final gate (`references/final-gate.md`) returns APPROVE. Write every PR title, description, and commit body with the **technical-writing** skill (`Read` `../../technical-writing/SKILL.md` and follow it; every layer except Diátaxis, and apply the STE vocabulary rules: one word per action, keep articles, a plain verb over `-ing` where one works), then `Read` `../../unslop/SKILL.md` and apply it.

**Titles.** Conventional Commits `type(scope): subject`, no trailing period. Type such as `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, or `perf`. Scope is the area, such as `bottega` or `maestro`. Subject is short, imperative, and names a real symbol when one carries the change, for example `fix(bottega): retarget opening-a-pr babysit trigger`.

**Descriptions.** The PR body is a one-minute briefing, not a lab notebook, for a reviewer who has the diff. It says why the change exists, what it leaves out, what it could break, and how you proved it works. Write short, simple sentences with few identifiers, no walls of text. The body becomes the squash commit body, so keep that commit under about 40 lines. Use `##` headings, not bold lead-ins, in this order, and drop a section with nothing to say:

- `## Why`: the problem and approach, 1-3 short sentences. No SHAs, rebase genealogy, or "based on main" preamble.
- `## What changed`: 1-3 short bullets. Name a real symbol or path only when it carries the change. Name both sides of a rename or retarget.
- `## Scope`: always. 1-3 short items on what it covers and what it deliberately leaves out (a follow-up, a known gap). No symbols, paths, or file-by-file essay.
- `## Tradeoffs`: only rejected alternatives a reviewer would otherwise ask about. Skip when there was no real choice.
- `## Blast Radius`: 1-2 sentences on who or what it touches and why that is safe or risky. If main is red, state the cost of leaving it red.
- `## Verification`: 1-3 bullets, each a real run path and its outcome. Perf: one primary number with its unit, `before → after`, and a link to the arena or swarm directory for the rest. No sample-size methodology, swarm recitals, or metric tables.

After the sections, link screenshots a human pasted back when they prove a claim. Full SHAs, swarm or arena lane recitals, lever-correction essays, file-by-file checklists, and "CLEAN" verdicts go in a linked artifact, not the body.

**Forge.** Use the GitHub CLI (`gh`) for every PR operation: create, edit, view, and merge.

**Size and stacks.** Prefer five narrow PRs to one large PR. A stack is a base-branch chain. The root PR targets trunk. Each child branch rebases onto its parent's exact tip and its PR targets the parent branch. As a parent merges, move its child onto trunk per `playbooks/shipping.md` step 4. Create a child with `gh pr create --base <parent-branch>` and retarget one with `gh pr edit <pr> --base <parent-branch>`. Branch from trunk only for independent work. Rebase on trunk before substantial stack work.

**Readiness.** Open every PR ready, never as a draft: omit `--draft` from `gh pr create`. The one exception is an Autopilot owner, which opens a draft early (`playbooks/autopilot.md` step 2) and marks it ready only after the final gate's APPROVE. If a PR still opens as a draft, run `gh pr ready <number>`. Run `gh pr view <number>` before you refer to PR status.

**Babysit.** Opening a PR does not start a babysit. Post the URL and keep building. Finish the phase or stack first. Run a separate babysit pass only when the user asks for one after the whole stack exists. A babysit for each new PR stalls the build and spends checks on commits later waves restart. Push back when feedback drifts from intent.

A subagent that opens a PR reads and follows the **no-comments** skill (`../../no-comments/SKILL.md`), and posts the URL. It returns to the parent without babysitting, unless it is an Autopilot owner. That owner's brief assigns the babysit loop and is the ask `playbooks/babysit.md` waits for. The owner starts the loop after its code-ready report, reports merge-ready, and is exempt from the rules here and in `playbooks/babysit.md` that hold babysitting until a whole stack is built.
