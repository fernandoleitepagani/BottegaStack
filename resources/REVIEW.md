# Review contract

What failure looks like in this repo. Keep it short.

## Failure modes

- <for docs: it lies>
- <for config: it misroutes>
- <for UI: it breaks at phone width>
- <for data: it silently drops or duplicates>

## Paths to skip

- generated/
- vendor/
- lockfiles

## Evidence

Every finding needs a file and line, a command or screenshot, and why it
matters. A finding without evidence is a note.

## Nits

Cap non-blocking style notes at three per review.

## Summary

Start with a count: `3 blocking, 2 notes`. Say plainly when there is nothing to
fix.

## Convergence

- Max 3 rounds.
- After round 1, review only the new diff.
- Flag the class of bug, not one line.
- Do not repeat a finding already posted.

## Risk paths

A change that touches one of these paths is high-risk and must escalate.

- `**/auth/**`
- `**/api/**`
- `**/migrations/**`
- `**/*.sql`
- `package.json`
- `**/package-lock.json`
- `**/pnpm-lock.yaml`
- `**/yarn.lock`
- `.github/workflows/**`
- `Dockerfile*`
- `install*`
- `**/secrets/**`
- `**/*.pem`
- `**/*.key`

