#!/usr/bin/env bash
# Install or uninstall Bottega skills for Codex (~/.codex/skills/).
# Usage:
#   ./harnesses/codex/install.sh              # symlink all skills into ~/.codex/skills/
#   ./harnesses/codex/install.sh --uninstall  # remove Bottega symlinks
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
DEST="${BOTTEGA_CODEX_SKILLS_DIR:-$HOME/.codex/skills}"

if [ "${1:-}" = "--uninstall" ]; then
	for d in "$ROOT/skills"/*; do
		[ -d "$d" ] || continue
		name="$(basename "$d")"
		target="$DEST/bottega-$name"
		if [ -L "$target" ]; then
			rm "$target"
			printf 'removed  %s\n' "$target"
		fi
	done
	exit 0
fi

mkdir -p "$DEST"
for d in "$ROOT/skills"/*; do
	[ -f "$d/SKILL.md" ] || continue
	name="$(basename "$d")"
	target="$DEST/bottega-$name"
	ln -sfn "$d" "$target"
	printf 'linked   %s -> %s\n' "$target" "$d"
done
printf '\nInstalled Bottega skills for Codex in %s\n' "$DEST"
