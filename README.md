# PaganiStack

PaganiStack is a personal agentic development workflow, packaged as an
installable harness. It keeps a human in the loop from plan to merge:

```
setup + lane -> plan -> spec -> tickets -> build -> checks -> review -> fix -> approve -> human
```

Read `HOW-IT-WORKS.md` for the full explanation of the workflow, agents, rules,
skills, integrations, and installer.

It is designed for OpenCode and Claude Code. It does not use cloud sessions.

## Requirements

- OpenCode, Claude Code, or both.
- `gh` for PR helpers.
- `agent-browser` for browser verification: `npm install -g agent-browser`.
- Node 22+ for the design inspector.

## Install

```bash
git clone <this-repo> ~/Projects/PaganiStack
~/Projects/PaganiStack/install.sh --target both
```

Or choose one target:

```bash
./install.sh --target opencode
./install.sh --target claude
```

Useful flags:

```bash
./install.sh --target both --dry-run
./install.sh --target opencode --copy
./install.sh --target both --uninstall
./bin/pagani doctor
./bin/pagani lint
./bin/pagani init /path/to/project
./bin/pagani job new "Add rate limiting"
./bin/pagani classify --diff
./bin/pagani route <job>
./bin/pagani check <job>
./bin/pagani gate <job>
./bin/pagani usage start|end <job>
```

The installer backs up existing files, writes a manifest, flattens the category
skills into `<target>/skills/<name>`, and generates model variants from
`agents/models.conf`.

## Lanes

Not every request needs the full pipeline. Step 0 picks a lane:

| Lane | Use when | Pipeline |
|---|---|---|
| `trivial` | docs/copy/config only, ≤3 files | builder-lite → check → review-code-lite → human |
| `bugfix` | reproducible symptom | diagnosis → failing test → builder → check → review-code-lite → human |
| `small` | one feature, one area, ≲10 files | short interview + plan → one ticket → builder → check → review-code-lite → human |
| `standard` | normal product change | full flow |
| `high-risk` | auth, payments, data, deploy, dependencies, secrets | full flow + adversarial review + simplify + strong security + strong approver |

Use `/pagani --lane small <feature>` or `/pagani quick <feature>` to override.
After the first builder commit, `pagani classify --diff` escalates if the diff
grows or touches a risk path. Lanes never downgrade.

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

The master runs the workflow and stops at every checkpoint. You approve, rework,
or reject. The approver writes a decision, an explainer, and a quiz. You decide
whether to merge, commit, push, or open a PR.

## Skills

Skills use the nine Claude Code categories plus two extensions:

```
library-api-reference/
product-verification/
data-analysis/
business-automation/
scaffolding/
code-quality/
ci-cd/
runbooks/
infrastructure-ops/
workflow/       extension: interview, summary, planning, handoff, retro
design/         extension: UI/UX production
```

The review lenses live in `code-quality/` and `product-verification/`. The
design skills live in `design/`; see `skills/design/README.md` for sources and
licenses. The category definitions are in `CATEGORIES.md`.

## Agents

```
agents/opencode/   OpenCode agents
agents/claude/     Claude Code agents
```

The bodies are the same workflow. The frontmatter and tool names differ.

## Project templates

`resources/` contains `AGENTS.md`, `checks.sh`, `verify.sh`, `REVIEW.md`,
`PR-TEMPLATE.md`, `BACKLOG.md`, `GLOSSARY.md`, `CODING_STANDARDS.md`,
`TASKS.md`, and an ADR template. `pagani init` copies them into a project.

## Review convergence and evals

Review is capped and re-reviews only the new diff after the first round. Findings
are not repeated. `evals/` holds a small reviewer set (known bugs and clean PRs)
so prompt, skill, and model changes can be measured instead of guessed.

## What is not included

- Cloud sessions.
- Paid skills or paid assets.
- A dashboard, a database, or a state machine.
- A full sandbox, network allowlist, or per-job spending cap. Use worktrees,
  permission denies, read-only tokens, and no secrets first.
- Backups of `pagani/jobs/`. It is gitignored and local to the machine. There is
  no snapshot, sync, or export.
- Prompt-injection defenses. Browser pages, PR bodies and comments,
  `BACKLOG.md`, and screenshots reach agents as data; nothing separates
  instructions from that data yet.

## License

MIT for the PaganiStack code. Vendored skills keep their own licenses; see
`VENDOR.md` and the license file in each skill folder.
