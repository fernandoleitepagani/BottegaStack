### Forensics

**You own the diagnosis, not the fix.** Pick the input first, then follow its track. The deliverable is a cited diagnosis.

- **Live:** a running process shows the symptom (leak, idle-CPU spin, glitch). Instrument it, don't theorize from source.
- **Artifact:** a capture already exists (cpuprofile, trace `.json.gz`, heap snapshot, spindump). It is a fixed dataset. Read it, don't re-run it.

1. **Get the signal.** Live: capture it on the matching surface via the project's `verify-<app>` skill. A CPU profile for a spin, a heap snapshot for a leak, a trace for a glitch. Artifact: identify the format and load it with a generic tool (DevTools or a trace parser, a text editor for a spindump, heap tooling for a snapshot). Either way, parse large artifacts in a subagent (principle-guard-the-context-window) and keep only the reduced finding in the main thread.
2. **Make it queryable.** Dump the trace or heap into sqlite, one row per sample, frame, or node (principle-mechanize-it). Reach the queryable shape before you read.
3. **Narrow to the cause.** Frames holding the most time, walked down to the hot path. For a leak, the retainer chain from the leaked object to a GC root. For a spindump, the thread stuck on-CPU or blocked and its wait reason. Live only: a loop firing without input.
4. **Prove the mechanism.** Live: inject instrumentation or hotfix the running code without reloading, to confirm cheaply. Artifact: diff a paired before/after capture. Without one, label the finding the strongest hypothesis the artifact supports, not a confirmed cause.
5. **Attribute to source.** File, symbol, and the line that allocates or schedules. A frame with no source mapping is not yet a diagnosis. Resolve the symbols, or say plainly the artifact lacks them.
6. Throughput checkpoint stays one line: `throughput checkpoint: n/a, read-only forensics`. Hand back to Bug fix or Perf issue once the cause is known. No fix unless asked.

**Reply:** the input and its format, the reduced finding, how the mechanism was proved (or that it is a hypothesis), the source location, and artifact paths.
