---
name: infra-ops
description: Review dependencies, cost, access, and orphaned resources. Use for dependency additions, cost spikes, cleanup, and least-privilege checks.
---

# Infrastructure Ops

Change infrastructure only with evidence, a dry run, and a rollback.

## Dependency management

Before adding a package:

- What does it do that the project cannot do with what it has?
- Is it maintained? Check the last release and open issues.
- What is the license?
- What is the install size and transitive footprint?
- Pin the version and record why.

## Cost investigation

- Find the top drivers by service, tag, or resource.
- Compare against the previous period.
- Separate growth from a price or configuration change.
- Propose the smallest change with a measured saving.

## Orphan cleanup

- List candidates with the tool's own dry run.
- Post the list for a soak period.
- Require explicit confirmation before deleting.
- Record what was removed and why.

## Access

- Prefer read-only credentials.
- Scope tokens to the smallest resource.
- Never put secrets in the repo or logs.
- Record where the credential lives, not the value.

## Output

`infra.md` with findings, evidence, proposed change, risk, and rollback.

## Report

```
AREA: <dependencies|cost|cleanup|access>
FINDINGS: <count>
RISK: <low|medium|high>
APPROVAL: <needed|not needed>
```

## Gotchas

- Adding a dependency for something the stack already does, such as a JSON
  parser when `python3` is already required.
- Assuming `gh`, `agent-browser`, or `gitleaks` is installed. `maestro doctor`
  exists because it often is not.
- Deleting orphaned resources without the dry run and soak period.
- Writing a token into the repo, a state file, or a log instead of a secret store.
