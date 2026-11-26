#!/usr/bin/env bash
# Install or uninstall Bottega skills for OpenCode (~/.config/opencode/skills/).
# Usage:
#   ./harnesses/opencode/install.sh              # symlink all skills into ~/.config/opencode/skills/
#   ./harnesses/opencode/install.sh --uninstall  # remove Bottega symlinks
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
DEST="${BOTTEGA_OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}"

usage() {
	sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'
	exit "${1:-0}"
}

case "${1:-}" in
"") ;;
-h|--help) usage 0 ;;
--uninstall)
	for target in "$DEST"/bottega-*; do
		[ -L "$target" ] || continue
		link="$(readlink "$target" || true)"
		case "$link" in
		"$ROOT/skills/"*)
			rm "$target"
			printf 'removed  %s\n' "$target"
			;;
		esac
	done
	exit 0
	;;
*)
	echo "error: unknown option: $1" >&2
	usage 2
	;;
esac

mkdir -p "$DEST"
for d in "$ROOT/skills"/*; do
	[ -f "$d/SKILL.md" ] || continue
	name="$(basename "$d")"
	target="$DEST/bottega-$name"
	if [ -d "$target" ] && [ ! -L "$target" ]; then
		echo "error: $target exists as a directory (not a symlink); remove or move it first" >&2
		exit 1
	fi
	ln -sfn "$d" "$target"
	printf 'linked   %s -> %s\n' "$target" "$d"
done
printf '\nInstalled Bottega skills for OpenCode in %s\n' "$DEST"
