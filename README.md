# PaganiStack

PaganiStack is a personal agentic development workflow for OpenCode and Claude
Code. It turns a request into a verified change and keeps a human in the loop.

The job folder is the state: `pagani/jobs/<id>/`. There is no database, no
cloud service, and no state machine.

## Install

```bash
git clone <this-repo> ~/Projects/PaganiStack
~/Projects/PaganiStack/install.sh --target both
~/Projects/PaganiStack/bin/pagani doctor
```

In a project:

```bash
cd ~/Projects/my-project
~/Projects/PaganiStack/bin/pagani init
```

`pagani init` creates `SPEC.md`, `ROADMAP.md`, `TASKS.md`, and `AGENTS.md`.
Run `pagani upgrade` for an existing project.

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
master writes `decision.md`, presents the explainer and quiz, and you make the
call.

## Docs

- [docs/WORKFLOW.md](docs/WORKFLOW.md) — the 9 steps, lanes, agents, job folder, automation.
- [docs/SKILLS.md](docs/SKILLS.md) — all 34 skills, invocation model, vendored sources.
- [docs/SETUP.md](docs/SETUP.md) — install, uninstall, `doctor`, `init`, `upgrade`, troubleshooting.
- [docs/DESIGN.md](docs/DESIGN.md) — why the workflow is shaped this way, what was removed, trade-offs.

## License

MIT for the PaganiStack code. Vendored skills keep their own licenses; see
[docs/SKILLS.md](docs/SKILLS.md) and the license file in each skill folder.
