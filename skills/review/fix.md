# Fix step

Verified findings and failed checks become a fix brief for a **fresh** implementer; never resume the one that failed.

1. A loop that drives the real failure and goes red: a failing test first, else a script.
2. The cause in one sentence before any code changes. With several candidates, test the cheapest falsifiable one first.
3. The regression test at the right seam, written before the fix.
4. The fixer changes only the lines a finding names, plus its test. Never fix a test by weakening, skipping or deleting it.
5. Rerun the loop, then the failed checks, then a reviewer on the findings it touched.

**Caps.** At most **2 fix rounds**; a third failure goes to the final gate as ESCALATE. Two rounds that don't reduce the failures also ESCALATE. At high risk, after each fix round, rerun the same high-risk check on the new diff only, with a fresh worker, and log a new `crossfire` row; a blocker still open after the cap logs `FAIL`.
