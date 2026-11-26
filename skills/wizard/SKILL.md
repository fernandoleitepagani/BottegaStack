---
name: wizard
description: Generate an interactive bash wizard that walks the user through steps only a human can do (a third-party dashboard, credentials, CI secrets, a one-off migration or cutover), captures the values, and writes them where they belong. Use for /wizard, and whenever a run reaches an always-pause step that needs the user's hands. Never for steps the agent can do itself.
disable-model-invocation: true
---

# Wizard

A wizard is a bash script that walks the user through a manual procedure one stage at a time. It opens each URL, says exactly what to click and copy, reads the values back (secret ones hidden), writes them to `.env` or GitHub, confirms before anything irreversible, and shows how many stages are left. It replaces a wall of prose instructions at the moment a run needs the user's hands.

[`template.sh`](./template.sh) holds the library: progress, confirmation gates, URL opening (Linux, macOS, WSL), hidden secret entry, idempotent `.env` upserts at mode 0600, `gh secret` and `gh variable` writes, and a closing summary. Never edit anything above its `STAGES` marker. Your job is to scope the procedure and write the stages.

## Where it fits

- **Always-pause steps** (`../maestro/SKILL.md`, **Autonomy**): when the pause needs the user to act, not just approve (create an API key, set a CI secret, run a cutover), write a wizard instead of listing steps in the reply.
- **`/autopilot`**: a unit that needs a human step gets a wizard, is marked blocked in `.bottega/decisions.tsv` with the wizard's path, and the run moves on to the next unit. It resumes that unit once the wizard's outputs exist (the `.env` keys are set, `gh secret list` shows the names).
- **`/implement`**: a wizard is a run artifact, not product code. It is never driven by the agent, and the final gate proves it statically (step 4).

## 1. Scope the procedure

Read the repo first; don't ask cold:

- Setup: `.env`, `.env.example`, `.env.*`, `README`, `docker-compose*`, framework config, and `.github/workflows/*`. Every `secrets.*` and `vars.*` reference is a value the wizard must produce.
- Migration or cutover: the current state, the target state, and the irreversible actions between them.

List the stages in order with the values each produces, and confirm the list with the user. Unattended, write the list into the wizard's header comment and report it instead of waiting.

Done when each stage is named in order, and for each captured value you know where the user gets it, where it is written (`.env`, a GitHub secret, both, or nowhere), and whether it is secret.

## 2. Map each stage

For each stage, write the exact path a stranger would follow: the URL, what to click, where the value shows, which variable it fills ("Dashboard → Developers → API keys → Reveal test key → copy"). When you don't know the current UI or command, check the vendor's docs or say so. Never invent a step.

## 3. Write the wizard

Copy `template.sh` to `.bottega/wizards/<slug>.sh` (untracked, one run) or, when the user wants a repeatable setup path, to `scripts/<slug>.sh`. Replace the example stage with one `stage` per step, in dependency order, and set `TOTAL_STAGES` to match. Use the library: `stage`, `say`, `step`, `note`, `warn`, `open_url`, `ask`, `ask_secret`, `write_env`, `set_secret`, `set_var`, `pause`, `confirm`, `finish`.

- Open the URL before asking for its value.
- `ask_secret` for anything secret; `write_env` every value that persists.
- `set_secret` only the names CI actually reads.
- `confirm` before every irreversible action.
- One focused task per stage: each stage clears the screen.
- Keep every stage inside `run_wizard` and the last line as is, so an edit mid-run can't break a running script.

## 4. Prove it and hand off

- `bash -n <script>`, `shellcheck <script>` when available, and `chmod +x <script>`.
- Don't run it yourself: it opens browsers and waits for input. Trace it instead: every value from step 1 is captured and lands where step 1 said, and every `set_secret` name matches a `secrets.*` reference in CI exactly. In a gated run, log these as the condition's proof.
- Reply with the one command to run (`./.bottega/wizards/<slug>.sh`) and what the run does once it finishes. A repeatable wizard is committed and linked from the README.
- Delete a one-run wizard once its outputs exist.

Run the reply through `../unslop/SKILL.md`.
