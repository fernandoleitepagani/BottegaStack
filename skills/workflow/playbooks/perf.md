# Perf
Use when a metric must improve against a stated target. Track the steps below in the todo list.
1. **State the metric and target.** Name the metric (latency, wall time, throughput, memory, bytes) and the workload; give the target as a number, for example `p95 < 200ms`. No number means no target.
2. **Measure a baseline with a repeatable command.** Write the exact command in the notes; run it at least three times and keep every number. Report the median and the spread, and change nothing else while measuring.
3. **Profile before guessing.** Run the profiler, `time`, CPU or heap samples, or a trace on the baseline; name the calls or lines that dominate and keep the profile output.
4. **Change one thing at a time.** Make the smallest change the profile points at; leave the workload and the measurement command untouched.
5. **Re-measure with the same command.** Compare the new median and spread with the baseline. A change inside the spread is not an improvement.
6. **Keep only wins beyond noise.** Revert a change that does not beat the spread or that regresses another metric; commit each kept change with its before and after numbers.
7. **Guard the gain.** Add or update the benchmark or test that would catch the regression, then run `./scripts/check`.
8. **Report.** Give the before and after numbers measured with the same command, the profile evidence, and whether the target is met.
## Reply
`Done: <change and target>`
`Evidence: <baseline and after numbers from the same command>`
`Claims: measured | inferred | guessed`
