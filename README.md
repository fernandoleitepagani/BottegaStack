# PaganiStack

PaganiStack is a personal agentic development workflow for OpenCode and Claude
Code. It turns a request into a verified change and keeps a human in the loop.

```
setup + lane -> plan -> spec -> tickets -> build -> checks -> review -> fix -> approve -> human
```

It is not a cloud service and it does not use a database or a state machine.
The job folder is the state: `pagani/jobs/<id>/`.

## Requirements

- OpenCode, Claude Code, or both.
- `gh` for PR helpers.
- Optional: `python3` for exact cost and `pagani upgrade`.
- Optional: `gitleaks` for the secret pre-commit hook.
- Optional: `systemd` for the weekly timer.
- Optional: `agent-browser` for browser checks.
- Optional: `ccusage` for Claude usage snapshots.

## Install

```bash
git clone <this-repo> ~/Projects/PaganiStack
~/Projects/PaganiStack/install.sh --target both
~/Projects/PaganiStack/bin/pagani doctor
```

For a project:

```bash
cd ~/Projects/my-project
~/Projects/PaganiStack/bin/pagani init
```

For an existing project, run `pagani upgrade` to merge the current hooks and
managed files without dropping your settings.

## Quick start

```
/pagani Add an estimated reading time to blog posts
```

The master picks a lane, creates the job, asks a few questions, writes a plan,
and stops for approval. You drive the rest with `approve`, `rework <note>`,
`reject`, or a question.

## Lanes

| Lane | Use when | Pipeline |
|---|---|---|
| `trivial` | docs, copy, config only; ≤3 files; no risk path | builder-lite → check → review-code-lite → human |
| `bugfix` | a reproducible symptom | diagnosis → failing test → builder → check → review-code-lite → human |
| `small` | one feature, one area, ≲10 files | short interview → plan → one ticket → builder → check → review-code-lite → human |
| `standard` | normal product change | full flow |
| `high-risk` | auth, payments, data/schema, deploy/CI, dependencies, secrets | full flow + adversarial review + simplify + strong security + strong approver |

Use `/pagani --lane small <feature>` or `/pagani quick <feature>` to override.
`pagani classify` prints `unknown` when there is no changed file; run it again
after the first change. Lanes only escalate.

## Use

```
/pagani <feature>
/pagani --lane small <feature>
/pagani quick <feature>
/pagani status
/pagani resume
/pagani triage
/pagani wayfind
/pagani improve
/pagani design
/pagani wizard
/pagani pr <number>
```

## Skills

Skills use the nine Claude Code categories plus `workflow/` and `design/`:

```
library-api-reference/  product-verification/  data-analysis/
business-automation/    scaffolding/           code-quality/
ci-cd/                  runbooks/              infrastructure-ops/
workflow/               design/
```

The core workflow skills are `lanes`, `interview`, `planning`, `implementation`,
`verification`, `review-code`, `review-security`, `approval`, `summary`,
`closeout`, `session-handoff`, `session-retro`, `diagnosis`, and
`untrusted-content`. The rest are situational: design, data, CI/CD, runbooks,
infrastructure, scaffolding, library reference, and the weekly review.

See [HOW-IT-WORKS.md](HOW-IT-WORKS.md) for the full skill list and how skills
load.

## Docs

- [HOW-IT-WORKS.md](HOW-IT-WORKS.md) — workflow, skills, commands, checks, automation.
- [PLAN.md](PLAN.md) — why the workflow is shaped this way.
- [AGENTS.md](AGENTS.md) — rules for agents maintaining this repo.
- [CHANGELOG.md](CHANGELOG.md) — release notes.

## What is not included

- Cloud sessions.
- A database or a state machine. The dashboard is a static, local HTML file.
- Full OS sandboxing.
- A control plane that starts or stops agents.
- A network allowlist for shell, `curl`, or `agent-browser` egress. The opt-in
  allowlist covers Claude `WebFetch` only.
- Remote or synced backups. `pagani backup` writes a local tar.gz.
- Prompt-injection enforcement. The `untrusted-content` skill is a convention,
  not a sandbox.
- A hard spending cap. `pagani budget check` asks the master to stop; it does
  not block a process.
- Exact per-job cost for Claude Code. Exact cost reads the local OpenCode
  `session` table; Claude usage is a raw `ccusage` snapshot when installed.

## License

MIT for the PaganiStack code. Vendored skills keep their own licenses; see the
license file in each skill folder and the vendored-skills table in
[HOW-IT-WORKS.md](HOW-IT-WORKS.md).
