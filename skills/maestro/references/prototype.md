# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify which question is being answered, using the user's prompt, the surrounding code, or by asking if the user is around:

- **"Does this logic / state model feel right?"** → [prototype-logic.md](prototype-logic.md). Build a single shareable HTML file (free-play buttons plus tabbed guided walkthroughs) that pushes the state machine through cases that are hard to reason about on paper, and that a non-developer can drive.
- **"What should this look like?"** → [prototype-ui.md](prototype-ui.md). Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar.

The two branches produce very different artifacts, so getting this wrong wastes the whole prototype. If the question is genuinely ambiguous and the user isn't reachable, default to whichever branch better matches the surrounding code (a backend module → logic; a page or component → UI) and state the assumption at the top of the prototype.

## Rules that apply to both

1. **Throwaway from day one, and clearly marked as such.** Locate the prototype code close to where it will actually be used (next to the module or page it's prototyping for) so context is obvious, but name it so a casual reader can see it's a prototype, not production. For throwaway UI routes, obey whatever routing convention the project already uses; don't invent a new top-level structure.
2. **Trivial to run.** A UI prototype starts from one command in the project's task runner: `pnpm <name>`, `python <path>`, `bun <path>`, etc. A logic demo is a single HTML file the user double-clicks. Either way, no thinking required to start it.
3. **No persistence by default.** State lives in memory. Persistence is the thing the prototype is _checking_, not something it should depend on. If the question explicitly involves a database, hit a scratch DB or a local file with a clear "PROTOTYPE, wipe me" name.
4. **Skip the polish.** No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. The point is to learn something fast.
5. **Surface the state.** After every action (logic) or on every variant switch (UI), print or render the full relevant state so the user can see what changed.
6. **Capture it when done.** Fold any validated decision into the real code, then capture the prototype itself as a **primary source**: commit it to a throwaway branch, out of main, and leave a context pointer to that branch on the implementation issue. Capture the answer too (the verdict and the question it settled) in the issue or a commit. The main branch keeps only the validated decision.

## In bottega

Adapted from mattpocock/skills `prototype` (MIT, see NOTICE). These rules take precedence where they differ:

- **Routing.** `/plan` sends a question it can't settle by grilling here, and so does `/maestro` for "a design fork that only seeing it can settle". The answer goes back to `/plan` as a decision, or to `/implement` for the real build. The prototype itself never ships.
- **No gate.** Nothing from a prototype reaches the main branch, so it skips the final gate. The real build goes through `/implement` and its gate.
- **The user looks, the agent doesn't.** Agents don't drive or screenshot a UI. Hand over the URL and `?variant=` keys or the HTML file, say what to look at, and let the user report back.
- **Capture.** Commit the throwaway branch (rule 6) only when the user says yes, since `delegate.md` forbids commits in the user's checkout otherwise. Without a yes, leave the prototype in place, report its path, and record the verdict in `.bottega/` next to the spec.

**Reply:** the question, the branch (logic or UI), the variants or scenarios built, how to run it, what to look at, your recommendation, and where the prototype lives. Say plainly that it is throwaway.
