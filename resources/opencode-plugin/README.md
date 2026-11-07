# PaganiStack OpenCode plugins

`pagani-skill-log.ts` is an OpenCode V2 plugin that records which skills an
agent loads. It installs only for the OpenCode target:

```bash
./install.sh --target opencode
```

The installer copies the plugin to `<opencode-config>/plugins/pagani-skill-log.ts`.

## What it logs

The plugin listens for `execute.after` tool events and ignores everything except
the `skill` tool. For each skill call it appends one tab-separated row:

```text
<ISO date>	<project basename>	<skill name>
```

Rows go to the project-local `pagani/skill-usage.tsv`, relative to the session
directory. The plugin creates `pagani/` on first use. `pagani/skill-usage.tsv`
is gitignored, so usage data stays local and never enters the repository.

Filesystem failures are swallowed: logging is best effort and never breaks the
tool call that triggered it.
