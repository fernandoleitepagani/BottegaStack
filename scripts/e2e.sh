#!/usr/bin/env bash
# End-to-end test of bin/maestro in a throwaway repo. No model, no network, no
# agent: a stub `claude` prints a stream-json result and logs its arguments.
# Prints `ok <step>` or `FAIL <step>` and exits non-zero on any failure.
set -u  # no pipefail: `cmd | grep -q` closes the pipe early by design

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
M="$ROOT/bin/maestro"
TMP="$(mktemp -d)"
trap '[ -n "${KEEP:-}" ] || rm -rf "$TMP"' EXIT
fails=0

ok() { echo "ok $1"; }
fail() { echo "FAIL $1"; fails=$((fails + 1)); }
expect() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else fail "$name"; fi; }
expect_not() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then fail "$name"; else ok "$name"; fi; }

# Isolated environment (CI runners set XDG_CONFIG_HOME, so pin it too).
unset BOTTEGA_BUILDER_ENV BOTTEGA_BUILDER_KEY BOTTEGA_PLUGIN_DIR BOTTEGA_NO_TOOL_HINT BOTTEGA_HEADLESS
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config" CLAUDE_CONFIG_DIR="$TMP/home/.claude" BOTTEGA_STATE_DIR="$TMP/state"
export GIT_AUTHOR_NAME=e2e GIT_AUTHOR_EMAIL=e2e@example.invalid GIT_COMMITTER_NAME=e2e GIT_COMMITTER_EMAIL=e2e@example.invalid
mkdir -p "$TMP/bin" "$CLAUDE_CONFIG_DIR/rules" "$HOME/.config/bottega"
cat > "$TMP/bin/claude" <<'EOF'
#!/usr/bin/env bash
echo "ARGS: $*" >> "$STUBLOG"
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}'
echo '{"type":"result","result":"STATUS: DONE\nall good","usage":{"input_tokens":10,"output_tokens":5},"session_id":"s1"}'
EOF
chmod +x "$TMP/bin/claude"
export PATH="$TMP/bin:$PATH" STUBLOG="$TMP/stub.log"
printf 'ANTHROPIC_BASE_URL=http://stub.invalid\nANTHROPIC_MODEL=stub\n' > "$HOME/.config/bottega/builder.env"
printf 'stub-key\n' > "$HOME/.config/bottega/builder.key"
chmod 600 "$HOME/.config/bottega/builder.env" "$HOME/.config/bottega/builder.key"
printf 'builder: headless, low\nsecond-opinion: headless, high\n' > "$CLAUDE_CONFIG_DIR/rules/bottega-models.md"

REPO="$TMP/repo"
mkdir -p "$REPO" && cd "$REPO" || exit 1
git init -q -b main && git commit -q --allow-empty -m init
"$M" init . >/dev/null 2>&1
printf '#!/usr/bin/env bash\necho ok\n' > scripts/check && chmod +x scripts/check

# /maestro loads the one master prompt.
f=$(grep -oE '@\$\{CLAUDE_PLUGIN_ROOT\}/[^ ]+' "$ROOT/commands/maestro.md" | sed 's#@${CLAUDE_PLUGIN_ROOT}/##')
[ -n "$f" ] && [ -f "$ROOT/$f" ] && ok "/maestro includes $f" || fail "/maestro includes the master"

# Runs and branches.
expect_not "start refused on main" "$M" start "On main"
git switch -q -c feat/e2e
expect "start on a branch" "$M" start "Run A"
printf '# Spec\n## Acceptance criteria\n- AC1: works. Proof: `true` -> exit 0\n- AC2: judgment. Proof: none (taste)\n### Task 1 - one\nbody\n### Task 2 - two\nbody\n' > "$TMP/spec.md"
[ "$("$M" spec run-a "$TMP/spec.md")" = "2" ] && ok "spec counts tasks" || fail "spec counts tasks"

# Checks and gates.
expect "check" "$M" check run-a
expect "gate" "$M" gate run-a
expect_not "gate --proof without proof" "$M" gate run-a --proof
printf 'cmd: true\nexit 0\n' > "$TMP/ev.txt"
expect_not "verify refuses the builder" "$M" verify record run-a AC1 PASS --by builder --evidence "$TMP/ev.txt"
expect_not "verify PASS needs evidence" "$M" verify record run-a AC1 PASS --by reviewer
"$M" verify record run-a AC1 INCONCLUSIVE --by reviewer >/dev/null
expect_not "gate --proof INCONCLUSIVE" "$M" gate run-a --proof
"$M" verify record run-a AC1 PASS --by reviewer --evidence "$TMP/ev.txt" >/dev/null
expect "gate --proof PASS" "$M" gate run-a --proof
git commit -q --allow-empty -m next
"$M" check run-a >/dev/null
expect_not "gate --proof stale" "$M" gate run-a --proof
"$M" verify waive run-a AC1 "user approved" >/dev/null
expect "gate --proof waived" "$M" gate run-a --proof

# Builds through the stub.
: > "$STUBLOG"
expect "worktree create" "$M" worktree create run-a 1
expect "build" "$M" build run-a 1 --block
expect "build --revise" sh -c "echo 'fix it' | '$M' build run-a 1 --revise - --block"
expect "build --review" "$M" build --review run-a 1 --block
expect "build --here" "$M" build --here q1 --task "small fix" --block
expect "build --review --here" "$M" build --review --here q1 --block
"$M" build --status run-a | grep -q "done" && ok "build --status" || fail "build --status"
grep -q -- "--agent bottega:builder" "$STUBLOG" && ok "runner uses bottega:builder" || fail "runner uses bottega:builder"
grep -q -- "--agent bottega:review-code" "$STUBLOG" && ok "runner uses bottega:review-code" || fail "runner uses bottega:review-code"
grep -q -- "--effort low" "$STUBLOG" && grep -q -- "--effort high" "$STUBLOG" && ok "effort routing" || fail "effort routing"
BOTTEGA_PLUGIN_DIR=/some/checkout "$M" build --here q2 --task x --block >/dev/null 2>&1
grep -q -- "--plugin-dir /some/checkout" "$STUBLOG" && ok "BOTTEGA_PLUGIN_DIR" || fail "BOTTEGA_PLUGIN_DIR"

# Hooks.
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TodoWrite","input":{"todos":[{"content":"Step 3","status":"pending","activeForm":"x"}]}}]}}' > "$TMP/t.jsonl"
hook_in="{\"transcript_path\":\"$TMP/t.jsonl\",\"stop_hook_active\":false}"
echo "$hook_in" | "$M" guard stop | grep -q '"block"' && ok "stop hook blocks with an open run" || fail "stop hook blocks with an open run"
echo '{"tool_input":{"subagent_type":"bottega:builder"}}' | "$M" guard builder | grep -q deny && ok "builder guard (namespaced)" || fail "builder guard (namespaced)"
echo '{"tool_input":{"subagent_type":"bottega:explorer"}}' | "$M" guard builder | grep -q deny && fail "guard ignores other agents" || ok "guard ignores other agents"

# Tool hint (SessionStart): silent when tools exist or when silenced.
mkdir -p "$TMP/notools" && ln -sf "$(command -v git)" "$TMP/notools/git"
PATH="$TMP/notools:/usr/bin:/bin" "$M" tools hint | grep -q "maestro tools install" && ok "tool hint when missing" || fail "tool hint when missing"
[ -z "$(BOTTEGA_NO_TOOL_HINT=1 "$M" tools hint)" ] && ok "tool hint silenced" || fail "tool hint silenced"
printf '#!/bin/sh\n' > "$TMP/bin/rtk"; cp "$TMP/bin/rtk" "$TMP/bin/gitleaks"; chmod +x "$TMP/bin/rtk" "$TMP/bin/gitleaks"
[ -z "$("$M" tools hint)" ] && ok "tool hint silent when installed" || fail "tool hint silent when installed"
"$M" tools install | grep -q "already installed" && ok "tools install no-op" || fail "tools install no-op"
rm -f "$TMP/bin/rtk" "$TMP/bin/gitleaks"

# --help/-h: usage only. Every user-facing form runs from a fresh sandbox with
# its own HOME, state, temp, and repo, and stubs for the optional tools.
HB="$TMP/helpbox"
mkdir -p "$HB/home/.config/bottega" "$HB/state" "$HB/tmp" "$HB/repo" "$HB/bin"
printf '#!/bin/sh\n' > "$HB/bin/rtk"
cp "$HB/bin/rtk" "$HB/bin/gitleaks"
chmod +x "$HB/bin/rtk" "$HB/bin/gitleaks"
printf 'stub-key\n' > "$HB/home/.config/bottega/builder.key"
( cd "$HB/repo" && git init -q -b main && git commit -q --allow-empty -m init )
( cd "$HB" && find . | LC_ALL=C sort ) > "$TMP/help.before"
while IFS= read -r form; do
  [ -n "$form" ] || continue
  for flag in --help -h; do
    out="$( cd "$HB/repo" && env -i HOME="$HB/home" XDG_CONFIG_HOME="$HB/home/.config" \
      CLAUDE_CONFIG_DIR="$HB/home/.claude" BOTTEGA_STATE_DIR="$HB/state" TMPDIR="$HB/tmp" \
      PATH="$HB/bin:/usr/bin:/bin" "$M" $form "$flag" </dev/null 2>/dev/null )"
    rc=$?
    if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^Usage:'; then
      ok "$flag $form"
    else
      fail "$flag $form"
    fi
  done
done <<'EOF'
doctor
init
seed
upgrade
start
spec
check
gate
verify
verify record
log
log run-x
report
report --close run-x
report --trust
build
build --init
build --check
build --status
build --here q
build --review
worktree
worktree create
worktree prune
hooks
hooks install
hooks uninstall
tools
tools install
tools hint
guard
guard stop
guard builder
keyget
EOF
out="$( cd "$HB/repo" && env -i HOME="$HB/home" XDG_CONFIG_HOME="$HB/home/.config" \
  CLAUDE_CONFIG_DIR="$HB/home/.claude" BOTTEGA_STATE_DIR="$HB/state" TMPDIR="$HB/tmp" \
  PATH="$HB/bin:/usr/bin:/bin" "$M" keyget --help </dev/null 2>/dev/null )"
rc=$?
if [ "$rc" -eq 0 ] && ! printf '%s\n' "$out" | grep -q 'stub-key'; then
  ok "keyget --help hides the key"
else
  fail "keyget --help hides the key"
fi
( cd "$HB" && find . | LC_ALL=C sort ) > "$TMP/help.after"
if cmp -s "$TMP/help.before" "$TMP/help.after"; then
  ok "--help writes nothing"
else
  fail "--help writes nothing"
fi

# Logs, findings, close, trust.
expect "log" "$M" log run-a frame "a decision" "a reason" "commit x" done
"$M" log run-a | grep -q "a decision" && ok "log prints" || fail "log prints"
"$M" report --finding run-a "Missing null check" >/dev/null
"$M" report --finding run-b "missing null check" >/dev/null
expect_not "retro finds a repeat" "$M" report --retro --exit-code
expect "close run" "$M" report --close run-a --playbook feature --risk standard --outcome merged
expect "close light run" "$M" report --close q1
expect "close light run 2" "$M" report --close q2
"$M" report --trust | grep -q "run-a" && ok "trust log" || fail "trust log"
echo "$hook_in" | "$M" guard stop | grep -q '"block"' && fail "stop hook silent after close" || ok "stop hook silent after close"

# Worktrees: named branches survive prune; merged task branches go.
expect "worktree create --branch" "$M" worktree create prog u1 --branch feat/unit-1
expect "worktree prune" "$M" worktree prune run-a --force
"$M" worktree prune prog >/dev/null 2>&1
git show-ref --verify --quiet refs/heads/feat/unit-1 && ok "named branch kept" || fail "named branch kept"

echo
if [ "$fails" -gt 0 ]; then
  echo "e2e: $fails failed"
  exit 1
fi
echo "e2e: PASS"
