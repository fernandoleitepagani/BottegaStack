#!/usr/bin/env bash
# BottegaStack repo lint. `maestro doctor` and ./scripts/validate.sh run it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
echo "BottegaStack lint"

for f in "$ROOT"/skills/*/*/SKILL.md; do
  [ -f "$f" ] || continue
  d="$(basename "$(dirname "$f")")"
  n="$(sed -n 's/^name: //p' "$f" | head -1)"
  if [ "$d" != "$n" ]; then
    echo "FAIL name mismatch: ${f#"$ROOT"/} (dir=$d name=$n)"
    fail=1
  fi
  if ! grep -q '^description:' "$f"; then
    echo "FAIL missing description: ${f#"$ROOT"/}"
    fail=1
  fi
done

# Templates for the on-demand project files. `maestro seed <Name>` copies these
# lazily; init does not create them, so the lint only checks the templates.
for f in AGENTS.md SPEC.md PLAN.md GLOSSARY.md BACKLOG.md mistakes.md REVIEW.md \
         checks.sh verify.sh verify.conf FEATURE-MAP.md claude-settings.json \
         builder.env.example git-hooks/pre-commit git-hooks/pre-push; do
  if [ ! -f "$ROOT/resources/$f" ]; then
    echo "FAIL missing resource: resources/$f"
    fail=1
  fi
done

if [ -f "$ROOT/resources/claude-settings.json" ]; then
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -m json.tool "$ROOT/resources/claude-settings.json" >/dev/null 2>&1; then
      echo "FAIL invalid JSON: resources/claude-settings.json"
      fail=1
    fi
  fi
fi

for f in AGENTS.md SPEC.md PLAN.md GLOSSARY.md mistakes.md REVIEW.md \
         BACKLOG.md FEATURE-MAP.md; do
  if grep -rq -- "$f" "$ROOT/agents" "$ROOT/skills" 2>/dev/null; then
    if [ ! -f "$ROOT/resources/$f" ]; then
      echo "FAIL referenced project file has no template: $f"
      fail=1
    fi
  fi
done

while IFS= read -r name; do
  [ -n "$name" ] || continue
  if ! find "$ROOT/skills" -mindepth 2 -maxdepth 2 -type d -name "$name" | grep -q .; then
    echo "FAIL unresolved skill reference: $name"
    fail=1
  fi
done < <(grep -rhoE '([Ll]oad|loads)( the)? `[a-z0-9][a-z0-9-]*`' "$ROOT/agents" "$ROOT/skills" 2>/dev/null | grep -oE '`[a-z0-9][a-z0-9-]*`' | tr -d '`' | sort -u)

while IFS= read -r slug; do
  [ -n "$slug" ] || continue
  if [ ! -f "$ROOT/skills/workflow/principles/references/$slug.md" ]; then
    echo "FAIL unresolved principle citation: $slug"
    fail=1
  fi
done < <(grep -rhoE 'principle `[a-z-]+`' "$ROOT/agents" "$ROOT/skills" "$ROOT/commands" 2>/dev/null | grep -oE '`[a-z-]+`' | tr -d '`' | sort -u)

if ! grep -q 'Step 0' "$ROOT/agents/master.md"; then
  echo "FAIL missing Step 0: agents/master.md"
  fail=1
fi

# Command files must not reference a step the master does not have.
for cmd_file in "$ROOT/commands/maestro.md"; do
  [ -f "$cmd_file" ] || continue
  while IFS= read -r step; do
    [ -n "$step" ] || continue
    if ! grep -qF "$step" "$ROOT/agents/master.md" 2>/dev/null; then
      echo "FAIL step reference: ${cmd_file#"$ROOT"/} mentions $step but agents/master.md does not"
      fail=1
    fi
  done < <(grep -oE 'Step [0-9]+' "$cmd_file" | sort -u)
done

# /maestro loads the master prompt at run time; it must point at it.
if ! grep -qF '@${CLAUDE_PLUGIN_ROOT}/agents/master.md' "$ROOT/commands/maestro.md"; then
  echo "FAIL commands/maestro.md does not load agents/master.md"
  fail=1
fi

if command -v python3 >/dev/null 2>&1; then
  for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
    if [ ! -f "$ROOT/$f" ]; then
      echo "FAIL missing plugin file: $f"
      fail=1
    elif ! python3 -m json.tool "$ROOT/$f" >/dev/null 2>&1; then
      echo "FAIL invalid JSON: $f"
      fail=1
    fi
  done
fi

# Plugin hooks run in a shell without the plugin's bin/ on PATH, so they must
# call maestro through CLAUDE_PLUGIN_ROOT. A bare command fails with
# "maestro: command not found".
if [ -f "$ROOT/hooks/hooks.json" ]; then
  while IFS= read -r line; do
    case "$line" in
      *'"command"'*) ;;
      *) continue ;;
    esac
    stripped="$(printf '%s\n' "$line" | sed -E 's#\$\{CLAUDE_PLUGIN_ROOT\}/bin/maestro##g')"
    if printf '%s\n' "$stripped" | grep -Eq '(^|[^[:alnum:]_./-])maestro([^[:alnum:]_-]|$)'; then
      echo "FAIL hooks/hooks.json runs bare maestro (hook shells have no plugin bin on PATH; use \"\${CLAUDE_PLUGIN_ROOT}/bin/maestro\"): $line"
      fail=1
    fi
  done < "$ROOT/hooks/hooks.json"
fi

for f in docs/WORKFLOW.md docs/SKILLS.md docs/SETUP.md; do
  if [ ! -f "$ROOT/$f" ]; then
    echo "FAIL missing doc: $f"
    fail=1
  fi
done

for md in "$ROOT"/*.md "$ROOT"/docs/*.md; do
  [ -f "$md" ] || continue
  dir="$(dirname "$md")"
  while IFS= read -r link; do
    case "$link" in
      http://*|https://*|mailto:*|'#'*) continue ;;
    esac
    target="${link%%#*}"
    [ -n "$target" ] || continue
    if [ ! -e "$dir/$target" ]; then
      echo "FAIL broken link: ${md#"$ROOT"/} -> $link"
      fail=1
    fi
  done < <(grep -oE '\]\([^)]+\)' "$md" | sed -E 's/^\]\(//; s/\)$//')
done

if [ "$fail" = "0" ]; then
  echo "lint: PASS"
else
  echo "lint: FAIL"
  exit 1
fi
