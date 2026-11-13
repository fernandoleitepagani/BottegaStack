#!/usr/bin/env bash
# BottegaStack lab: run the real master on cheap settings against a scenario in
# a scratch environment. Opt-in only: scripts/check, scripts/validate.sh, and
# CI never call this. The builder is stubbed; only the master spends a model.
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_USAGE='usage: maestro lab [trivial|bugfix|feature-fix|pause-resume|all] [--keep]'

scenario=""
keep=0
for arg in "$@"; do
  case "$arg" in
    --keep) keep=1 ;;
    -*) echo "$LAB_USAGE" >&2; exit 2 ;;
    *)
      [ -z "$scenario" ] || { echo "$LAB_USAGE" >&2; exit 2; }
      scenario="$arg"
      ;;
  esac
done
[ -n "$scenario" ] || scenario=all
case "$scenario" in
  trivial|bugfix|feature-fix|pause-resume|all) ;;
  *) echo "maestro lab: unknown scenario: $scenario" >&2; exit 2 ;;
esac

# The master is a real model call. Require a credential without reading it: the
# value is never printed, copied into the scratch dir, or written to a file.
if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "maestro lab: set CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY (the master runs a real model)" >&2
  exit 3
fi

master="${BOTTEGA_LAB_CLAUDE:-claude}"
if ! command -v "$master" >/dev/null 2>&1; then
  echo "maestro lab: master not found: $master" >&2
  exit 3
fi

scratch="$(mktemp -d "${TMPDIR:-/tmp}/maestro-lab.XXXXXX")" || {
  echo "maestro lab: cannot create a scratch directory" >&2
  exit 1
}
cleanup() {
  if [ "$keep" = "1" ]; then
    printf 'scratch: %s\n' "$scratch"
  else
    rm -rf "$scratch"
  fi
}
trap cleanup EXIT INT TERM

# Isolate every path the master, the run state, and the builder touch. The fake
# builder endpoint and key make an unstubbed builder call fail fast (stub.invalid)
# instead of reaching a real model.
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export CLAUDE_CONFIG_DIR="$HOME/.claude"
export BOTTEGA_STATE_DIR="$scratch/state"
export TMPDIR="$scratch/tmp"
export BOTTEGA_LAB_ROOT="$ROOT"
unset BOTTEGA_BUILDER_ENV BOTTEGA_BUILDER_KEY BOTTEGA_PLUGIN_DIR BOTTEGA_HEADLESS
mkdir -p "$HOME/.config/bottega" "$CLAUDE_CONFIG_DIR" "$BOTTEGA_STATE_DIR" "$TMPDIR" \
  "$scratch/work" "$scratch/bin"
printf 'ANTHROPIC_BASE_URL=http://stub.invalid\nANTHROPIC_MODEL=lab-stub\n' > "$HOME/.config/bottega/builder.env"
printf 'lab-stub-key\n' > "$HOME/.config/bottega/builder.key"
chmod 600 "$HOME/.config/bottega/builder.env" "$HOME/.config/bottega/builder.key"
ln -s "$ROOT/lab/stub-claude" "$scratch/bin/claude"
export PATH="$scratch/bin:$ROOT/bin:$PATH"
export GIT_AUTHOR_NAME=lab GIT_AUTHOR_EMAIL=lab@example.invalid
export GIT_COMMITTER_NAME=lab GIT_COMMITTER_EMAIL=lab@example.invalid

# The master gets a real allow-list: the file tools, its subagents, and only
# maestro, git, and the project check. Everything runs under the scratch HOME
# and temp dir.
LAB_ALLOWED="Read,Grep,Glob,Write,Edit,Skill,Agent,Task,TodoWrite,Bash(maestro:*),Bash(git:*),Bash(./scripts/check:*)"
LAB_DISALLOWED="Bash(git push:*),Bash(gh:*),WebFetch,WebSearch,AskUserQuestion"

run_one() {
  local name="$1" dir="$scratch/work/$1" rc=0
  mkdir -p "$dir"
  if ! ( cd "$dir" && bash "$ROOT/lab/scenarios/$name/setup.sh" ); then
    echo "lab: $name: setup failed" >&2
    return 1
  fi
  export BOTTEGA_LAB_SCENARIO="$name"
  export BOTTEGA_LAB_BUILDER="$ROOT/lab/scenarios/$name/builder.sh"
  ( cd "$dir" && "$master" -p "$(cat "$ROOT/lab/scenarios/$name/prompt.md")" \
      --agent bottega:master \
      --model sonnet --effort low \
      --plugin-dir "$ROOT" --strict-mcp-config \
      --permission-mode acceptEdits \
      --allowedTools "$LAB_ALLOWED" \
      --disallowedTools "$LAB_DISALLOWED" ) || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "lab: $name: master exited $rc" >&2
    return 1
  fi
  if ! ( cd "$dir" && bash "$ROOT/lab/scenarios/$name/expect.sh" ); then
    echo "lab: $name: expect failed" >&2
    return 1
  fi
  echo "lab: $name ok"
}

failed=0
for name in trivial bugfix feature-fix pause-resume; do
  if [ "$scenario" != "all" ] && [ "$name" != "$scenario" ]; then
    continue
  fi
  run_one "$name" || failed=$((failed + 1))
done

if [ "$failed" -ne 0 ]; then
  echo "lab: $failed scenario(s) failed" >&2
  exit 1
fi
echo "lab: PASS"
