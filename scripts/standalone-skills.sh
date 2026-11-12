#!/usr/bin/env bash
# Standalone skill scan (issue #27, decision 6). Prints the standalone skill
# names C-sorted; `--write` saves them to skills/standalone.txt.
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="$ROOT/skills/standalone.txt"
ALLOW="$ROOT/skills/standalone-allow.txt"
# Decision 6: any file in the skill folder matching this removes the skill.
PATTERN='maestro |spawn|agent tool|bottega:(builder|planner|review-code|explorer)'

usage() {
  cat <<'EOF'
Usage: ./scripts/standalone-skills.sh [--write|--help]

Print the standalone skill names, one per line and C-sorted.
  --write   write skills/standalone.txt and report the count
  --help    show this message
EOF
}

# The `Load` targets a skill folder names, one per line, sorted.
loads_of() {
  grep -rhoE '([Ll]oad|loads)( the)? `[a-z0-9][a-z0-9-]*`' "$1" 2>/dev/null \
    | grep -oE '`[a-z0-9][a-z0-9-]*`' | tr -d '`' | sort -u
}

# Allow entries are exempt from the direct pattern test only; their Loads still
# count in the fixed point below.
allowed=""
if [ -f "$ALLOW" ]; then
  while IFS= read -r name || [ -n "$name" ]; do
    [ -n "$name" ] || continue
    allowed="${allowed}${name}"$'\n'
  done < "$ALLOW"
fi

standalone=""
for f in "$ROOT"/skills/*/*/SKILL.md; do
  [ -f "$f" ] || continue
  dir="$(dirname "$f")"
  name="$(basename "$dir")"
  if ! printf '%s' "$allowed" | grep -qxF -- "$name"; then
    if grep -rqiE "$PATTERN" "$dir"; then
      continue
    fi
  fi
  standalone="${standalone}${name}"$'\n'
done

# Fixed point: a skill that Loads a skill outside the set is not standalone.
changed=1
while [ "$changed" -eq 1 ]; do
  changed=0
  next=""
  for f in "$ROOT"/skills/*/*/SKILL.md; do
    [ -f "$f" ] || continue
    dir="$(dirname "$f")"
    name="$(basename "$dir")"
    printf '%s' "$standalone" | grep -qxF -- "$name" || continue
    keep=1
    for dep in $(loads_of "$dir"); do
      if ! printf '%s' "$standalone" | grep -qxF -- "$dep"; then
        keep=0
        break
      fi
    done
    if [ "$keep" -eq 1 ]; then
      next="${next}${name}"$'\n'
    fi
  done
  if [ "$next" != "$standalone" ]; then
    standalone="$next"
    changed=1
  fi
done

names="$(printf '%s' "$standalone" | LC_ALL=C sort)"

case "${1:-}" in
  "")
    if [ -n "$names" ]; then
      printf '%s\n' "$names"
    fi
    ;;
  --write)
    if [ -n "$names" ]; then
      printf '%s\n' "$names" > "$LIST"
      count="$(printf '%s\n' "$names" | wc -l | tr -d ' ')"
    else
      : > "$LIST"
      count=0
    fi
    echo "wrote skills/standalone.txt ($count skills)"
    ;;
  --help|-h)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
