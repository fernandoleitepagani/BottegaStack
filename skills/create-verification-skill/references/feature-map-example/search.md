# Search notes

Search lets a user find notes by title or body text, inspect a matching note, and distinguish no matches from an unavailable search.

## Sub-features

- `search-match` returns title and body matches without changing note data.
- `search-empty` returns an empty result for a query with no matches.
- `search-cli` returns the same matching notes from the terminal.

## How to get to it (user POV)

- Run `notes search <query>` in a terminal.

## Driving it with control-notes

Preconditions:

- Notes is healthy at `http://127.0.0.1:4173`.
- The disposable data directory contains `Quarterly plan` with body text `Draft budget`.
- `control-notes doctor` reports the expected URL and data directory.

- **CLI match.** Search from the terminal. Run `control-notes cli -- notes search "quarterly" --format json`. Exit code `0` and stdout contain one object whose title is `Quarterly plan`.
- **CLI miss.** Search for an absent value. Run `control-notes cli -- notes search "volcano" --format json`. Exit code `0` and stdout are `[]`.
- **Proof.** Save the CLI match output. Run `control-notes cli -- notes search "quarterly" --format json > artifacts/search/results.json`. The artifact names `Quarterly plan`.

## Gotchas

- Archived notes are excluded unless the user enables `Include archived`.
- The CLI defaults to human-readable output. Use `--format json` for stable assertions.
- UI check for a human: the toolbar `Search` button and the `/` key open the `Search notes` dialog, a result opens the editor, and `Clear search` restores `Recent notes`.
