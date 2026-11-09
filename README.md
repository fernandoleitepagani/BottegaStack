# PaganiStack

PaganiStack is a personal agentic development workflow for Claude Code. It turns a request into a verified change and keeps a human in the loop.

The job folder is the state: `pagani/jobs/<id>/`. `job.md` holds only stage,
round, lane, branch, and base. There is no database, no cloud service, and no
state machine.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/fernandoleitepagani/PaganiStack/main/get.sh | bash
```

Needs only `bash`, `curl`, and `tar` (Linux, macOS, Windows via WSL or Git Bash).
No clone and no repo is kept: it installs a self-contained copy into `~/.claude`.
Preview with `... | bash -s -- --dry-run`. Details, flags, and uninstall:
[docs/SETUP.md](docs/SETUP.md). Contributors can install from a clone instead.

The installer links `pagani` into `~/.local/bin` (override with `PAGANI_BIN_DIR`);
agents call it by name, so that directory must be on `PATH`.

In a project there is nothing to set up: open Claude Code there and run
`/pagani <request>`. The first request creates the project files (all excluded from
git) and asks for your lint, test, and build commands. `pagani upgrade` refreshes an
older project.

## Quick start

```
/pagani Add an estimated reading time to blog posts
```

The master picks a lane, creates the job, asks a few questions, writes a
`SPEC.md`, and stops for approval. You drive the rest with `approve`,
`rework <note>`, `reject`, or a question. `/pagani status` and `/pagani resume`
continue a job.

Other skills are invoked directly by name, for example `/wizard`,
`/backlog-triage`, `/wayfinding`, `/improve-architecture`, and `/review-pr`.

## The pipeline

```
setup + lane -> SPEC -> build -> checks -> review -> fix -> approval -> human decision -> close
```

`SPEC.md` carries the requirements and a tracer-bullet task graph. Checks run
before review. One `review-code` reviewer covers code, UI, UX, and security. The
master posts a short summary after every step, writes the final `summary.md`
once at close, writes `decision.md`, and presents the explainer (and the quiz on
`standard`/`high-risk` jobs). You make the call.

## Docs

- [docs/WORKFLOW.md](docs/WORKFLOW.md) — the 9 steps, lanes, agents, job folder, automation.
- [docs/SKILLS.md](docs/SKILLS.md) — all 34 skills, invocation model, vendored sources.
- [docs/SETUP.md](docs/SETUP.md) — install, uninstall, `doctor`, `init`, `upgrade`, troubleshooting.
- [docs/RATIONALE.md](docs/RATIONALE.md) — the rationale: why the workflow is shaped this way, what was removed, and the trade-offs.

## License

MIT for the PaganiStack code. Vendored skills keep their own licenses; see
[docs/SKILLS.md](docs/SKILLS.md) and the license file in each skill folder.
