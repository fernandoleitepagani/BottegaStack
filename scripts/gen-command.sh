#!/usr/bin/env bash
# Generate commands/pagani.md: the command source's frontmatter, then the
# master agent's body, then the command source's body. The Claude Code plugin
# ships the generated command; hooks live in hooks/hooks.json, not here.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/commands/claude/pagani.md"
MASTER="$ROOT/agents/master.md"
OUT="$ROOT/commands/pagani.md"

[ -f "$SRC" ] || { echo "gen-command: missing $SRC" >&2; exit 1; }
[ -f "$MASTER" ] || { echo "gen-command: missing $MASTER" >&2; exit 1; }

generate() {
  # Opening --- plus the command frontmatter, then the closing ---.
  awk 'NR==1{print; next} $0=="---"{exit} {print}' "$SRC"
  echo '---'
  # Master body after its frontmatter, then the command body.
  awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$MASTER"
  awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$SRC"
}

mode="${1:-write}"
case "$mode" in
  write)
    tmp="$(mktemp)"
    generate > "$tmp"
    if [ -f "$OUT" ] && cmp -s "$tmp" "$OUT"; then
      rm -f "$tmp"
      echo "unchanged: commands/pagani.md"
    else
      mv "$tmp" "$OUT"
      echo "wrote: commands/pagani.md"
    fi
    ;;
  --check)
    tmp="$(mktemp)"
    generate > "$tmp"
    if [ -f "$OUT" ] && cmp -s "$tmp" "$OUT"; then
      rm -f "$tmp"
    else
      rm -f "$tmp"
      echo "stale: commands/pagani.md (run: scripts/gen-command.sh)" >&2
      exit 1
    fi
    ;;
  *)
    echo "usage: scripts/gen-command.sh [--check]" >&2
    exit 2
    ;;
esac
