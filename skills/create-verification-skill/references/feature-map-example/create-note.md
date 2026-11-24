# Create a note

Create note lets a user save a titled note from the CLI and confirm the saved note from a second user-facing view.

## Sub-features

- `create-save` persists a title and body.
- `create-cli` creates the same note shape from the terminal.

## How to get to it (user POV)

- Run `notes create --title <title> --body <body>` in a terminal.

## Driving it with control-notes

Preconditions:

- Notes is healthy at `http://127.0.0.1:4173`.
- No note is titled `Release checklist`.
- `control-notes doctor` reports the expected URL and disposable data directory.

- **CLI entry.** Create a note. Run `control-notes cli -- notes create --title "CLI note" --body "Created from terminal" --format json`. Exit code `0` and stdout contain the new note ID and title.
- **Proof.** Read both notes back. Run `control-notes cli -- notes list --format json > artifacts/create-note/list.json`. The artifact shows `Release checklist` and `CLI note`.

## Gotchas

- UI check for a human: the `New note` button and the `n` key open `Note editor`, `Save note` shows `Note saved`, and `Cancel` drops the draft.
- Titles are trimmed on save. Assert the stored title, not the input value.
- A save status alone is insufficient proof. Read the note back from the list.
- Remove `Release checklist` and `CLI note` during fixture cleanup, but retain their proof artifacts.
