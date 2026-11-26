# Blast radius

Find what a change breaks somewhere else, before it ships. Use for "blast radius of X", "what could this break", or reviewing a small diff you don't trust yet.

Companion to `how` and `why`. `how` tells you what the code does. `why` tells you why it's shaped that way. Blast radius tells you what it breaks somewhere else.

Listing the callers is not the job. The agent can grep those in a second. The job is the breakage grep won't show you.

## Don't trust your own writeup

A blast-radius writeup that sounds right is worthless. It reads as convincing whether or not it's true. So don't hand back the writeup. Find the one or two facts the whole thing depends on and prove them by running code.

### How sure are you

For each fact the change's safety depends on, get it as far down this list as is cheap, and say where it stopped.

1. You said so. Worthless on its own.
2. You pointed at the line. A real `file:line`, or the library's own source.
3. You showed the bad case can't happen. You walked the failure step by step and it doesn't reach.
4. You ran it. A script or test that calls the real code and fails loud if you're wrong.
5. You reproduced it in the running app.

Step 4 is usually one small script that imports the same library the app ships and calls the exact function you're worried about.

## Steps

1. Read the change. The diff, the symbols it adds, changes, and deletes, and what it now does differently, including the part the diff doesn't spell out. Pull the PR and its commits.
2. Find the one fact it's safe because of. Most changes that look risky are safe because of a single fact, like "this call only drops already-dead cache entries and does nothing else". Find that fact. If it holds, most risky cases are cleared at once. Spend your time here, not on a long list of maybes.
3. Look where grep stops. Read the source of the library you call, and check its pinned version and any local patch. Work out when things run: microtasks, unmount and teardown, Solid versus React. Follow what a symbol search misses: the JSON an API returns, a DB column, a wire format, another language reading the same bytes, a feature flag, code three hops downstream.
4. Be honest about each risk. Give it a real chance of happening and a real cost if it does. Keep the risks you confirmed. List the ones you checked and cleared separately. Cite a real `file:line`, a search that finds nothing is still an answer, and never make up a caller or an API.
5. Prove the one fact. Write a script or test that runs the real code, run it, and paste what happened.
6. For a big or wide change, run a coverage swarm (`swarm.md`) with one verifier per area of risk, and merge their risks into one list.

## What to hand back

- **What it does.** What changed, including the part that isn't obvious.
- **The one fact it's safe because of.** State it, say which step you got it to, and show the proof. If you couldn't prove it, write unproven.
- **Risks.** Each names how it breaks, the `file:line`, how likely and how bad, and how to check. Paste the proof for the ones that matter.
- **Cleared.** What you checked and why it's fine.
- **Before you merge.** The cheapest test or repro that catches the real bug, including the script you wrote.

Write it through `unslop`, cite real code, and strip anything private before it goes anywhere public.

**Reply:** the writeup above, with the one safety fact either proven or marked unproven.

## In bottega

Adapted from pstack's `blast-radius` (MIT, see NOTICE). These rules take precedence where they differ:

- **When it runs.** Only where a change can break code it doesn't touch:
  1. Before shaping: always in `playbooks/refactoring.md` (step 2), and in `playbooks/feature.md` or `playbooks/bug-fix.md` when the change touches a shared interface, public API, data format, schema or config other code reads. Run it on the planned change; it hands back the dependents to migrate and the safety fact the pin must prove.
  2. The high-risk review of a diff of 100 lines or fewer across 2 files or fewer (`review.md`). It replaces the single adversarial reviewer there.
  3. When the user asks "what could this break", "blast radius of X", or to crossfire a small diff they don't trust.

  Normal-risk features and bug fixes confined to their own code skip it.
- **Who runs it.** One fresh delegate on the verifier role (`subagents.md`; `heavy` at high risk, `standard` otherwise), in its own worktree when its proof script needs files. Proof scripts stay in scratch or the worktree, never in the diff.
- **`how` and `why`** are bottega's `playbooks/investigation.md`. The Solid and React note in step 3 stands for whatever framework the repo uses.
- **Verdict for the gate** (high-risk review only): log a `crossfire` row with `log.sh` per `review.md` **Ledger**. PASS when the safety fact reached step 4 or 5 and no confirmed risk is open; FAIL otherwise. Confirmed risks go to `review.md` **Verify findings** and **Fix step**; after a fix round, run it again on the new diff and log a new row.
