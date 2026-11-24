### Investigate

**You own the answer, not a fix.** Read-only: the deliverable is a cited explanation, a recommendation, or a diagnosis, never a code change. No PR. Throughput checkpoint stays one line: `throughput checkpoint: n/a, read-only investigation`.

Pick the input first.

#### Question (how, why, are we sure, X or Y)

1. Route through the **understand** skill: how mode, plus why mode for motivation questions.
2. Answer in its shape (Overview, Key Concepts, How It Works, Where Things Live, Gotchas), or as a recommendation with a tradeoffs table for a choice between alternatives.
3. For "are we sure?", give your real judgment with reasons, and push back if the premise is wrong.

#### Symptom (leak, idle-CPU spin, glitch, a captured profile or trace)

- **Live:** a running process shows it. Capture the signal on the matching surface through the project's `verify-<app>` skill: a CPU profile for a spin, a heap snapshot for a leak, a trace for a glitch. Observe; do not change the running code.
- **Artifact:** a capture already exists (cpuprofile, trace, heap snapshot, spindump). It is a fixed dataset: read it, do not re-run it.

1. **Make it queryable.** Parse large artifacts in a subagent (**Guard the Context Window**) and dump them into sqlite, one row per sample, frame, or node (**Mechanize It**).
2. **Narrow.** The frames holding the most time down to the hot path; for a leak, the retainer chain to a GC root; for a spindump, the stuck thread and its wait reason.
3. **Prove the mechanism.** A paired before and after capture, or added logging read as the code runs. Without one, label the finding the strongest hypothesis the evidence supports.
4. **Attribute to source:** file, symbol, and the line that allocates or schedules. An unmapped frame is not yet a diagnosis.

Once the cause is known, hand back and route to Bug fix.

**Reply:** through the **unslop** skill. Question: the answer or recommendation. Symptom: the input and its format, the reduced finding, how the mechanism was proved (or that it is a hypothesis), the source location, and artifact paths.
