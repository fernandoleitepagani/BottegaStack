#!/usr/bin/env bash
# Install or uninstall Bottega skills for Antigravity CLI (~/.agents/skills/).
# Usage:
#   ./harnesses/antigravity/install.sh              # symlink all skills into ~/.agents/skills/
#   ./harnesses/antigravity/install.sh --uninstall  # remove Bottega symlinks from ~/.agents/skills/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
DEST="${BOTTEGA_AGY_SKILLS_DIR:-$HOME/.agents/skills}"

usage() {
	sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'
	exit "${1:-0}"
}

# A link is ours when it points into this repo's skills/.
ours() {
	[ -L "$1" ] || return 1
	case "$(readlink "$1" || true)" in
	"$ROOT/skills/"*) return 0 ;;
	esac
	return 1
}

# Skills keep their real names so sibling links like ../implement/SKILL.md
# resolve both through the symlink and under lexical path normalization.
# Older installs used a bottega-<name> prefix; remove those links.
remove_legacy() {
	for target in "$DEST"/bottega-*; do
		if ours "$target"; then
			rm "$target"
			printf 'removed  %s (legacy prefix)\n' "$target"
		fi
	done
}

case "${1:-}" in
"") ;;
-h|--help) usage 0 ;;
--uninstall)
	for d in "$ROOT/skills"/*; do
		[ -f "$d/SKILL.md" ] || continue
		target="$DEST/$(basename "$d")"
		if ours "$target"; then
			rm "$target"
			printf 'removed  %s\n' "$target"
		fi
	done
	remove_legacy
	exit 0
	;;
*)
	echo "error: unknown option: $1" >&2
	usage 2
	;;
esac

mkdir -p "$DEST"
# Check every target before linking any, so a name clash leaves nothing half-installed.
for d in "$ROOT/skills"/*; do
	[ -f "$d/SKILL.md" ] || continue
	target="$DEST/$(basename "$d")"
	if { [ -e "$target" ] || [ -L "$target" ]; } && ! ours "$target"; then
		echo "error: $target already exists and is not a Bottega link; remove or rename it first" >&2
		exit 1
	fi
done
remove_legacy
for d in "$ROOT/skills"/*; do
	[ -f "$d/SKILL.md" ] || continue
	target="$DEST/$(basename "$d")"
	ln -sfn "$d" "$target"
	printf 'linked   %s -> %s\n' "$target" "$d"
done
printf '\nInstalled Bottega skills for Antigravity CLI in %s\n' "$DEST"
