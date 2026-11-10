# Perf
Use when a metric must improve against a stated target. Track the steps below in the todo list.
1. **State the metric and target.** Name the metric (latency, wall time, throughput, memory, bytes) and the workload; give the target as a number, for example `p95 < 200ms`. No number means no target.
2. **Measure a baseline with a repeatable command.** Write the exact command in the notes; run it at least three times and keep every number. Report the median and the spread, and change nothing else while measuring.
3. **Profile before guessing.** Run the profiler, `time`, CPU or heap samples, or a trace on the baseline; name the calls or lines that dominate and keep the profile output.
4. **Change one thing at a time.** Make the smallest change the profile points at; leave the workload and the measurement command untouched.
5. **Re-measure with the same command.** Compare the new median and spread with the baseline. A change inside the spread is not an improvement.
6. **Vet the number.** Before you keep or report it, answer these with evidence from a run: (1) what limits it, and why isn't it double; (2) did every side run tuned the way production runs; (3) does the result break a physical limit (bandwidth, cores, the share of time the changed piece took); (4) did anything error or return wrong output; (5) does it reproduce over at least 5 alternating A/B runs, with median and range; (6) does it matter on the end-to-end path a user waits on; (7) did the work run inside the timed region. If you cannot name the limiter, a side ran untuned, or you could not check 4 and 7, the verdict is `inconclusive`. Check the load with `uptime` and `nproc` first. Adapted from pstack's `benchmark-checklist`.
7. **Keep only wins beyond noise.** Revert a change that does not beat the spread or that regresses another metric; commit each kept change with its before and after numbers.
8. **Guard the gain.** Add or update the benchmark or test that would catch the regression, then run `./scripts/check`.
9. **Report.** Give the verdict (faster, slower, no measurable difference, or inconclusive), the before and after numbers measured with the same command, the run count, range, and limiter, the profile evidence, and whether the target is met.
## Reply
`Done: <change and target>`
`Evidence: <baseline and after numbers from the same command>`
`Claims: measured | inferred | guessed`
