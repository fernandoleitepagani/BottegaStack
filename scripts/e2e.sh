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
{
  printf 'MODEL=%s\n' "${ANTHROPIC_MODEL:-}"
  printf 'OPUS=%s\n' "${ANTHROPIC_DEFAULT_OPUS_MODEL:-}"
  printf 'SONNET=%s\n' "${ANTHROPIC_DEFAULT_SONNET_MODEL:-}"
  printf 'HAIKU=%s\n' "${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}"
  printf 'SUBAGENT=%s\n' "${CLAUDE_CODE_SUBAGENT_MODEL:-}"
  echo '---'
} >> "$STUBENV"
if [ "${STUB_FAIL:-}" = "1" ]; then
  echo 'API Error: 400 Upstream request failed: Model is unavailable.' >&2
  echo '{"type":"result","result":"","usage":{"input_tokens":0,"output_tokens":0}}'
  exit 1
fi
[ -n "${STUB_SLEEP:-}" ] && sleep "$STUB_SLEEP"
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}'
printf '{"type":"result","result":"STATUS: %s\\nall good","usage":{"input_tokens":10,"output_tokens":5},"session_id":"s1"}\n' "${STUB_STATUS:-DONE}"
EOF
chmod +x "$TMP/bin/claude"
export PATH="$TMP/bin:$PATH" STUBLOG="$TMP/stub.log" STUBENV="$TMP/stub.env"

# The env the last stub invocation received (the stub logs five lines, then ---).
stub_env_has() { tail -n 6 "$STUBENV" | grep -qx "$1"; }
printf 'ANTHROPIC_BASE_URL=http://stub.invalid\nANTHROPIC_MODEL=stub\n' > "$HOME/.config/bottega/builder.env"
printf 'stub-key\n' > "$HOME/.config/bottega/builder.key"
chmod 600 "$HOME/.config/bottega/builder.env" "$HOME/.config/bottega/builder.key"
printf 'builder: headless, low\nsecond-opinion: headless, high\n' > "$CLAUDE_CONFIG_DIR/rules/bottega-models.md"

REPO="$TMP/repo"
mkdir -p "$REPO" && cd "$REPO" || exit 1
git init -q -b main && git commit -q --allow-empty -m init
"$M" init . >/dev/null 2>&1
printf '#!/usr/bin/env bash\necho ok\n' > scripts/check && chmod +x scripts/check

# Version (issue #24): --version, -V, and version print the plugin manifest's
# version before command dispatch and touch no run state. doctor repeats it.
plugin_version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$ROOT/.claude-plugin/plugin.json" | head -1)"
for form in --version -V version; do
  out="$("$M" "$form" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] && [ "$out" = "maestro $plugin_version" ] && printf '%s\n' "$out" | grep -q '^maestro 0\.'; then
    ok "version form $form"
  else
    fail "version form $form"
  fi
done
[ ! -e "$BOTTEGA_STATE_DIR" ] && ok "version touches no run state" || fail "version touches no run state"
out="$("$M" doctor 2>&1)"
printf '%s\n' "$out" | grep -qx "version: $plugin_version" && ok "doctor prints the version" || fail "doctor prints the version"

# /maestro loads the one master prompt.
f=$(grep -oE '@\$\{CLAUDE_PLUGIN_ROOT\}/[^ ]+' "$ROOT/commands/maestro.md" | sed 's#@${CLAUDE_PLUGIN_ROOT}/##')
[ -n "$f" ] && [ -f "$ROOT/$f" ] && ok "/maestro includes $f" || fail "/maestro includes the master"

# `start` validates before it writes (issue #16): a refused start leaves the
# repo byte-for-byte unchanged in a fresh repo, since auto-init would otherwise
# run before the branch and cleanliness rules.
fresh_snapshot() {
  ( cd "$1" && git status --short --ignored --untracked-files=all \
    && find . -path ./.git -prune -o -print | LC_ALL=C sort )
}
FRESH="$TMP/fresh-start"
mkdir -p "$FRESH" && ( cd "$FRESH" && git init -q -b main && git commit -q --allow-empty -m init )
before="$(fresh_snapshot "$FRESH")"
( cd "$FRESH" && "$M" start "On main" ) >/dev/null 2>&1; rc=$?
after="$(fresh_snapshot "$FRESH")"
if [ "$rc" -eq 1 ] && [ "$before" = "$after" ]; then
  ok "start refused on main writes nothing"
else
  fail "start refused on main writes nothing"
fi
DIRTY="$TMP/fresh-dirty"
mkdir -p "$DIRTY" && ( cd "$DIRTY" && git init -q -b main && git commit -q --allow-empty -m init )
printf 'work in progress\n' > "$DIRTY/dirty.txt"
before="$(fresh_snapshot "$DIRTY")"
( cd "$DIRTY" && "$M" start "Dirty tree" ) >/dev/null 2>&1; rc=$?
after="$(fresh_snapshot "$DIRTY")"
if [ "$rc" -eq 1 ] && [ "$before" = "$after" ]; then
  ok "start refused on a dirty tree writes nothing"
else
  fail "start refused on a dirty tree writes nothing"
fi

# Untracked files never enter a run (builds use a worktree from HEAD), so
# `start` ignores them; modified or staged tracked files still refuse (issue #22).
UNTRACKED="$TMP/fresh-untracked"
mkdir -p "$UNTRACKED" && ( cd "$UNTRACKED" && git init -q -b feat && git commit -q --allow-empty -m init )
mkdir -p "$UNTRACKED/__pycache__" && printf 'bytecode\n' > "$UNTRACKED/__pycache__/left.pyc"
out="$( cd "$UNTRACKED" && "$M" start "Untracked files" 2>&1 )"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'run: untracked-files'; then
  ok "start ignores untracked files"
else
  fail "start ignores untracked files"
fi
MODIFIED="$TMP/fresh-modified"
mkdir -p "$MODIFIED" && ( cd "$MODIFIED" && git init -q -b feat && git commit -q --allow-empty -m init )
printf 'base\n' > "$MODIFIED/tracked.txt"
( cd "$MODIFIED" && git add tracked.txt && git commit -q -m tracked )
printf 'changed\n' > "$MODIFIED/tracked.txt"
out="$( cd "$MODIFIED" && "$M" start "Modified tracked" 2>&1 )"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qx 'working tree is dirty; commit or stash first'; then
  ok "start refuses a modified tracked file"
else
  fail "start refuses a modified tracked file"
fi
( cd "$MODIFIED" && git add tracked.txt )
out="$( cd "$MODIFIED" && "$M" start "Staged tracked" 2>&1 )"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qx 'working tree is dirty; commit or stash first'; then
  ok "start refuses a staged tracked file"
else
  fail "start refuses a staged tracked file"
fi

# Runs and branches.
expect_not "start refused on main" "$M" start "On main"
git switch -q -c feat/e2e
expect "start on a branch" "$M" start "Run A"
printf '# Spec\n## Acceptance criteria\n- AC1: works. Proof: `true` -> exit 0\n- AC2: judgment. Proof: none (taste)\n### Task 1 - one\nbody\n### Task 2 - two\nbody\n' > "$TMP/spec.md"
[ "$("$M" spec run-a "$TMP/spec.md")" = "2" ] && ok "spec counts tasks" || fail "spec counts tasks"

# Checks and gates.
# An unknown run is named the way `check` names it, on stderr; a known run with
# no check result still reports the missing result (issue #17).
out="$("$M" gate no-such-gate 2>"$TMP/gate.err")"; rc=$?
if [ "$rc" -eq 1 ] && [ -z "$out" ] && grep -qx 'maestro gate: no such run: no-such-gate' "$TMP/gate.err"; then
  ok "gate unknown run names the run on stderr"
else
  fail "gate unknown run names the run on stderr"
fi
out="$("$M" gate run-a 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qx 'GATE: FAIL (no checks.result)'; then
  ok "gate known run without a result says no checks.result"
else
  fail "gate known run without a result says no checks.result"
fi
expect "check" "$M" check run-a
expect "gate" "$M" gate run-a
# `start` ignores untracked files, but `gate` keeps the strict check (issue #22).
printf 'leftover\n' > "$REPO/untracked-gate.txt"
out="$("$M" gate run-a 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qx 'GATE: FAIL (working tree dirty)'; then
  ok "gate still fails on an untracked file"
else
  fail "gate still fails on an untracked file"
fi
rm -f "$REPO/untracked-gate.txt"
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
out="$("$M" build --here qsum --task "summary" --block 2>&1)"
printf '%s\n' "$out" | grep -qx 'session: s1' && ok "light summary prints session" || fail "light summary prints session"
printf '%s\n' "$out" | grep -qx 'revisions: 0/2' && ok "light summary prints revisions" || fail "light summary prints revisions"
# Two concurrent callers for one light slug (issue #18): the first collects the
# result, the second must stop when the run marker disappears instead of waiting
# the full BOTTEGA_BUILD_WAIT. The wait limit is 20 s; both calls must return a
# few seconds after the build ends (the stub sleeps 4).
STUB_SLEEP=4 BOTTEGA_BUILD_WAIT=20 "$M" build --here race --task "race" >"$TMP/race-a.out" 2>&1 &
race_a=$!
i=0
while [ "$i" -lt 50 ] && ! find "$BOTTEGA_STATE_DIR" -path '*/quick/race/run' -type f | grep -q .; do
  sleep 0.1
  i=$((i + 1))
done
race_start="$(date +%s)"
STUB_SLEEP=4 BOTTEGA_BUILD_WAIT=20 "$M" build --here race --task "race" >"$TMP/race-b.out" 2>&1 &
race_b=$!
wait "$race_a"; race_ra=$?
wait "$race_b"; race_rb=$?
race_elapsed=$(( $(date +%s) - race_start ))
if [ "$race_ra" -eq 0 ] && [ "$race_rb" -eq 0 ] && [ "$race_elapsed" -lt 12 ]; then
  ok "concurrent light builds both return after the build"
else
  fail "concurrent light builds both return after the build"
fi
race_ok=0
for f in "$TMP/race-a.out" "$TMP/race-b.out"; do
  if grep -qx 'already collected by another caller' "$f" \
    && grep -qx 'task: race' "$f" \
    && grep -q '^report: .*report\.md' "$f"; then
    race_ok=1
  fi
done
[ "$race_ok" -eq 1 ] && ok "concurrent light build names the collected task" || fail "concurrent light build names the collected task"
# A collected light build is finished, never queued: a READY report and a failed
# (empty) report both count as 1/1 done, and READY shows the report status.
STUB_STATUS=READY "$M" build --here stat-ready --task "ready" --block >/dev/null 2>&1
out="$("$M" build --status stat-ready)"
printf '%s\n' "$out" | grep -q 'Builders 1/1 done' && ok "light status READY is done" || fail "light status READY is done"
printf '%s\n' "$out" | grep -q 'STATUS: READY' && ok "light status shows READY" || fail "light status shows READY"
STUB_FAIL=1 "$M" build --here stat-fail --task "fail" --block >/dev/null 2>&1
out="$("$M" build --status stat-fail)"
printf '%s\n' "$out" | grep -q 'Builders 1/1 done' && ok "light status failed is done" || fail "light status failed is done"
printf '%s\n' "$out" | grep -q '0 queued' && ok "light status failed is never queued" || fail "light status failed is never queued"
expect "build --review --here" "$M" build --review --here q1 --block
"$M" build --status run-a | grep -q "done" && ok "build --status" || fail "build --status"
grep -q -- "--agent bottega:builder" "$STUBLOG" && ok "runner uses bottega:builder" || fail "runner uses bottega:builder"
grep -q -- "--agent bottega:review-code" "$STUBLOG" && ok "runner uses bottega:review-code" || fail "runner uses bottega:review-code"
grep -q -- "--effort low" "$STUBLOG" && grep -q -- "--effort high" "$STUBLOG" && ok "effort routing" || fail "effort routing"
BOTTEGA_PLUGIN_DIR=/some/checkout "$M" build --here q2 --task x --block >/dev/null 2>&1
grep -q -- "--plugin-dir /some/checkout" "$STUBLOG" && ok "BOTTEGA_PLUGIN_DIR" || fail "BOTTEGA_PLUGIN_DIR"

# A light-path slug resolves where a run slug does (issue #8): status, check,
# gate, revisions, verify, and log all work against $STATE/quick/<slug>/.
"$M" build --status q1 | grep -q 'Builders 1/1 done' && ok "build --status light" || fail "build --status light"
"$M" build --status run-a | grep -q 'Builders 1/2 done' && ok "build --status run unchanged" || fail "build --status run unchanged"
expect "check light" "$M" check q1
find "$BOTTEGA_STATE_DIR" -path '*/quick/q1/checks.result' -type f | grep -q . && ok "check light records in the quick dir" || fail "check light records in the quick dir"
expect "gate light" "$M" gate q1
"$M" build --status q1 --every 1 | grep -q 'Builders 1/1 done' && ok "build --status light --every" || fail "build --status light --every"
git commit -q --allow-empty -m light-next
expect_not "gate light stale" "$M" gate q1
expect "check light again" "$M" check q1
expect "gate light after check" "$M" gate q1
expect "build --review --here after gate" "$M" build --review --here q1 --block
: > "$STUBLOG"
expect "build --here --revise" sh -c "echo 'fix it' | '$M' build --here q1 --revise - --block"
grep -q -- '--resume s1' "$STUBLOG" && ok "light revision resumes the session" || fail "light revision resumes the session"
expect "build --here --revise 2" sh -c "echo 'again' | '$M' build --here q1 --revise - --block"
sh -c "echo 'third' | '$M' build --here q1 --revise - --block" >/dev/null 2>&1
rc=$?
[ "$rc" -eq 4 ] && ok "light revision exits 4 on the third" || fail "light revision exits 4 on the third"
expect_not "build --status unknown slug" "$M" build --status no-such-light
expect_not "check unknown slug" "$M" check no-such-light
expect_not "gate unknown slug" "$M" gate no-such-light
# Regression guard only: cmd_gate rejects an unknown slug at the checks.result
# guard before verify_unmet runs, so this is not a red-first proof of any
# verify_unmet change.
expect_not "gate --proof unknown slug (regression guard)" "$M" gate no-such-light --proof
"$M" log q1 frame "light decision" why evidence done >/dev/null && ok "log light" || fail "log light"
"$M" log q1 | grep -q 'light decision' && ok "log light prints" || fail "log light prints"
expect "verify record light" "$M" verify record q1 AC1 INCONCLUSIVE --by reviewer
"$M" verify list q1 >/dev/null 2>&1 && ok "verify list light" || fail "verify list light"
expect "verify waive light" "$M" verify waive q1 AC1 "user approved"

# Model tiers: an empty tier var takes ANTHROPIC_MODEL; an explicit one wins.
"$M" build --here tiers --task "tier defaults" --block >/dev/null 2>&1
if stub_env_has "MODEL=stub" && stub_env_has "OPUS=stub" && stub_env_has "SONNET=stub" \
  && stub_env_has "HAIKU=stub" && stub_env_has "SUBAGENT=stub"; then
  ok "tier vars default to ANTHROPIC_MODEL"
else
  fail "tier vars default to ANTHROPIC_MODEL"
fi
cat > "$TMP/explicit.env" <<'EOF'
ANTHROPIC_BASE_URL=http://stub.invalid
ANTHROPIC_MODEL=stub
ANTHROPIC_DEFAULT_OPUS_MODEL=opus-x
ANTHROPIC_DEFAULT_SONNET_MODEL=sonnet-x
ANTHROPIC_DEFAULT_HAIKU_MODEL=haiku-x
CLAUDE_CODE_SUBAGENT_MODEL=sub-x
EOF
BOTTEGA_BUILDER_ENV="$TMP/explicit.env" "$M" build --here tiers2 --task "explicit tiers" --block >/dev/null 2>&1
if stub_env_has "OPUS=opus-x" && stub_env_has "SONNET=sonnet-x" \
  && stub_env_has "HAIKU=haiku-x" && stub_env_has "SUBAGENT=sub-x"; then
  ok "explicit tier vars win"
else
  fail "explicit tier vars win"
fi

# --check names an empty model and a space after `=` instead of a missing value.
printf 'ANTHROPIC_BASE_URL=http://stub.invalid\nANTHROPIC_MODEL=\n' > "$TMP/empty-model.env"
out="$(BOTTEGA_BUILDER_ENV="$TMP/empty-model.env" "$M" build --check 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'no ANTHROPIC_MODEL value'; then
  ok "build --check names an empty ANTHROPIC_MODEL"
else
  fail "build --check names an empty ANTHROPIC_MODEL"
fi
printf 'ANTHROPIC_BASE_URL= "http://stub.invalid"\nANTHROPIC_MODEL=stub\n' > "$TMP/space.env"
out="$(BOTTEGA_BUILDER_ENV="$TMP/space.env" "$M" build --check 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q "space after '='"; then
  ok "build --check reports a space after ="
else
  fail "build --check reports a space after ="
fi

# A 0-token failure prints the endpoint error on the console, not only in the log.
out="$(STUB_FAIL=1 "$M" build --here fail1 --task "api failure" --block 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'API Error: 400 Upstream request failed'; then
  ok "0-token build failure prints the error"
else
  fail "0-token build failure prints the error"
fi
"$M" build --here fail2 --task "seed" --block >/dev/null 2>&1
out="$(STUB_FAIL=1 "$M" build --review --here fail2 --block 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'API Error: 400 Upstream request failed'; then
  ok "0-token review failure prints the error"
else
  fail "0-token review failure prints the error"
fi
for s in tiers tiers2 fail1 fail2 stat-ready stat-fail race; do "$M" report --close "$s" >/dev/null 2>&1; done

# Hooks.
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TodoWrite","input":{"todos":[{"content":"Step 3","status":"pending","activeForm":"x"}]}}]}}' > "$TMP/t.jsonl"
hook_in="{\"transcript_path\":\"$TMP/t.jsonl\",\"stop_hook_active\":false}"
echo "$hook_in" | "$M" guard stop | grep -q '"block"' && ok "stop hook blocks with an open run" || fail "stop hook blocks with an open run"
echo '{"tool_input":{"subagent_type":"bottega:builder"}}' | "$M" guard builder | grep -q deny && ok "builder guard (namespaced)" || fail "builder guard (namespaced)"
echo '{"tool_input":{"subagent_type":"bottega:explorer"}}' | "$M" guard builder | grep -q deny && fail "guard ignores other agents" || ok "guard ignores other agents"

# A hold records an escalation, lets the Stop hook end the session, and shows in
# `build --status` (issue #23). An isolated state dir keeps the other open runs
# from counting as active.
HSTATE="$TMP/hold-state"
hold_out="$(BOTTEGA_STATE_DIR="$HSTATE" "$M" start "Hold run" 2>&1)"; rc=$?
hold_slug="$(printf '%s\n' "$hold_out" | sed -n 's/^run: //p')"
[ "$rc" -eq 0 ] && [ -n "$hold_slug" ] && ok "start hold run" || fail "start hold run"
out="$(BOTTEGA_STATE_DIR="$HSTATE" "$M" hold "$hold_slug" "human decision needed" 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx "run $hold_slug is on hold: human decision needed"; then
  ok "hold records the escalation"
else
  fail "hold records the escalation"
fi
out="$(echo "$hook_in" | BOTTEGA_STATE_DIR="$HSTATE" "$M" guard stop 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx "run $hold_slug is on hold: human decision needed"; then
  ok "stop hook ends the session on hold"
else
  fail "stop hook ends the session on hold"
fi
out="$(BOTTEGA_STATE_DIR="$HSTATE" "$M" build --status "$hold_slug" 2>&1)"
printf '%s\n' "$out" | grep -qx 'HOLD: human decision needed' && ok "build --status shows HOLD" || fail "build --status shows HOLD"
out="$(BOTTEGA_STATE_DIR="$HSTATE" "$M" hold --clear "$hold_slug" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "hold --clear" || fail "hold --clear"
echo "$hook_in" | BOTTEGA_STATE_DIR="$HSTATE" "$M" guard stop | grep -q '"block"' && ok "stop hook blocks after hold --clear" || fail "stop hook blocks after hold --clear"
out="$(BOTTEGA_STATE_DIR="$HSTATE" "$M" hold no-such-hold "reason" 2>"$TMP/hold.err")"; rc=$?
if [ "$rc" -eq 1 ] && [ -z "$out" ] && grep -qxF 'maestro hold: no such run: no-such-hold' "$TMP/hold.err"; then
  ok "hold unknown slug names the run on stderr"
else
  fail "hold unknown slug names the run on stderr"
fi
BOTTEGA_STATE_DIR="$HSTATE" "$M" hold "$hold_slug" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "hold without a reason is usage" || fail "hold without a reason is usage"

# A light-path slug holds in quick/<slug>.
BOTTEGA_STATE_DIR="$HSTATE" "$M" build --here hold-light --task "light" --block >/dev/null 2>&1
out="$(BOTTEGA_STATE_DIR="$HSTATE" "$M" hold hold-light "light reason" 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'run hold-light is on hold: light reason'; then
  ok "hold records a light-path run"
else
  fail "hold records a light-path run"
fi
find "$HSTATE" -path '*/quick/hold-light/hold' -type f | grep -q . && ok "hold lives in the quick dir" || fail "hold lives in the quick dir"
out="$(BOTTEGA_STATE_DIR="$HSTATE" "$M" build --status hold-light 2>&1)"
printf '%s\n' "$out" | grep -qx 'HOLD: light reason' && ok "light build --status shows HOLD" || fail "light build --status shows HOLD"
BOTTEGA_STATE_DIR="$HSTATE" "$M" hold --clear hold-light >/dev/null 2>&1

# A run id that could escape the state dir is rejected before anything resolves.
before="$(find "$HSTATE" | LC_ALL=C sort)"
out="$(BOTTEGA_STATE_DIR="$HSTATE" "$M" hold .. "x" 2>"$TMP/hold-dotdot.err")"; rc=$?
if [ "$rc" -eq 2 ] && [ -z "$out" ] && grep -qxF 'maestro hold: bad run id: ..' "$TMP/hold-dotdot.err"; then
  ok "hold rejects .."
else
  fail "hold rejects .."
fi
[ -e "$HSTATE/hold" ] && fail "hold .. writes outside the run dir" || ok "hold .. writes outside the run dir"
BOTTEGA_STATE_DIR="$HSTATE" "$M" hold ../x "r" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "hold rejects ../x" || fail "hold rejects ../x"
BOTTEGA_STATE_DIR="$HSTATE" "$M" hold --clear .. >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "hold --clear rejects .." || fail "hold --clear rejects .."
BOTTEGA_STATE_DIR="$HSTATE" "$M" resume .. >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "resume rejects .." || fail "resume rejects .."
after="$(find "$HSTATE" | LC_ALL=C sort)"
[ "$before" = "$after" ] && ok "bad slugs write nothing outside the run dir" || fail "bad slugs write nothing outside the run dir"

# Two open runs, only one on hold: the Stop hook still blocks.
HSTATE2="$TMP/hold-state-two"
BOTTEGA_STATE_DIR="$HSTATE2" "$M" start "Hold two a" >/dev/null 2>&1
BOTTEGA_STATE_DIR="$HSTATE2" "$M" start "Hold two b" >/dev/null 2>&1
BOTTEGA_STATE_DIR="$HSTATE2" "$M" hold hold-two-a "one of two" >/dev/null 2>&1
echo "$hook_in" | BOTTEGA_STATE_DIR="$HSTATE2" "$M" guard stop | grep -q '"block"' && ok "stop hook blocks while another run is open" || fail "stop hook blocks while another run is open"
BOTTEGA_STATE_DIR="$HSTATE2" "$M" hold hold-two-b "two of two" >/dev/null 2>&1
out="$(echo "$hook_in" | BOTTEGA_STATE_DIR="$HSTATE2" "$M" guard stop 2>&1)"
printf '%s\n' "$out" | grep -q 'is on hold:' && ok "stop hook ends when every run is on hold" || fail "stop hook ends when every run is on hold"

# A merged close removes a held run's state, so the hook goes silent.
HSTATE3="$TMP/hold-state-close"
BOTTEGA_STATE_DIR="$HSTATE3" "$M" start "Hold close" >/dev/null 2>&1
BOTTEGA_STATE_DIR="$HSTATE3" "$M" hold hold-close "closing" >/dev/null 2>&1
find "$HSTATE3" -name hold -type f | grep -q . && ok "hold file exists before close" || fail "hold file exists before close"
BOTTEGA_STATE_DIR="$HSTATE3" "$M" report --close hold-close --outcome merged >/dev/null 2>&1
find "$HSTATE3" -name hold -type f | grep -q . && fail "merged close removes the hold" || ok "merged close removes the hold"
out="$(echo "$hook_in" | BOTTEGA_STATE_DIR="$HSTATE3" "$M" guard stop 2>&1)"
[ -z "$out" ] && ok "stop hook silent after closing a held run" || fail "stop hook silent after closing a held run"

# A paused run is closed to the hook even when it also has a hold; resume clears
# both markers so the hook tracks the run again (issue #21, #23).
HSTATE4="$TMP/hold-state-resume"
BOTTEGA_STATE_DIR="$HSTATE4" "$M" start "Hold paused" >/dev/null 2>&1
BOTTEGA_STATE_DIR="$HSTATE4" "$M" report --close hold-paused --outcome paused >/dev/null 2>&1
BOTTEGA_STATE_DIR="$HSTATE4" "$M" hold hold-paused "paused and held" >/dev/null 2>&1
out="$(echo "$hook_in" | BOTTEGA_STATE_DIR="$HSTATE4" "$M" guard stop 2>&1)"
[ -z "$out" ] && ok "stop hook silent on a paused and held run" || fail "stop hook silent on a paused and held run"
out="$(BOTTEGA_STATE_DIR="$HSTATE4" "$M" resume hold-paused 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'resumed: hold-paused'; then
  ok "resume clears a paused run"
else
  fail "resume clears a paused run"
fi
paused_file="$(find "$HSTATE4" -name paused -type f | head -1)"
hold_file="$(find "$HSTATE4" -name hold -type f | head -1)"
[ -z "$paused_file" ] && [ -z "$hold_file" ] && ok "resume removes paused and hold" || fail "resume removes paused and hold"
echo "$hook_in" | BOTTEGA_STATE_DIR="$HSTATE4" "$M" guard stop | grep -q '"block"' && ok "stop hook blocks after resume" || fail "stop hook blocks after resume"
BOTTEGA_STATE_DIR="$HSTATE4" "$M" hold hold-paused "again" >/dev/null 2>&1
out="$(BOTTEGA_STATE_DIR="$HSTATE4" "$M" resume hold-paused 2>&1)"; rc=$?
hold_file="$(find "$HSTATE4" -path '*/hold-paused/hold' -type f | head -1)"
if [ "$rc" -eq 0 ] && [ -z "$hold_file" ] && printf '%s\n' "$out" | grep -q '^resumed: hold-paused'; then
  ok "resume not paused still clears the hold"
else
  fail "resume not paused still clears the hold"
fi
out="$(BOTTEGA_STATE_DIR="$HSTATE4" "$M" resume no-such-resume 2>"$TMP/resume.err")"; rc=$?
if [ "$rc" -eq 1 ] && [ -z "$out" ] && grep -qxF 'maestro resume: no such run: no-such-resume' "$TMP/resume.err"; then
  ok "resume unknown run names the run on stderr"
else
  fail "resume unknown run names the run on stderr"
fi

# The git hooks resolve maestro without the plugin bin/ on PATH (issue #3):
# PATH, then the install-time record, then the newest plugin cache copy.
HK="$TMP/hookbox"
mkdir -p "$HK/repo" "$HK/home" "$HK/minbin" "$HK/pathbin" "$HK/log" \
  "$HK/claude/plugins/cache/local/bottega/0.6.0/bin" \
  "$HK/claude/plugins/cache/local/bottega/0.10.0/bin" "$HK/emptyclaude"
for t in bash git grep sort tail; do
  ln -sf "$(command -v "$t")" "$HK/minbin/$t"
done
write_maestro_stub() {
  cat > "$2" <<EOF
#!/usr/bin/env bash
printf '%s\n' "$1" >> "\${HOOKLOG:-/dev/null}"
if [ "\${1:-}" = "_files" ]; then printf 'AGENTS.md\nPLAN.md\n'; fi
exit 0
EOF
  chmod +x "$2"
}
write_maestro_stub 0.6.0 "$HK/claude/plugins/cache/local/bottega/0.6.0/bin/maestro"
write_maestro_stub 0.10.0 "$HK/claude/plugins/cache/local/bottega/0.10.0/bin/maestro"
write_maestro_stub path "$HK/pathbin/maestro"
( cd "$HK/repo" && git init -q -b main && git commit -q --allow-empty -m init )
"$M" hooks install "$HK/repo" >/dev/null
hook="$HK/repo/.git/hooks/pre-commit"
grep -Eq '^MAESTRO_BIN=".+"' "$hook" && ok "hooks install records MAESTRO_BIN" || fail "hooks install records MAESTRO_BIN"
# Simulate a plugin update: the recorded path is gone.
tmp_hook="$hook.hookbox"
sed -e "s|^MAESTRO_BIN=.*|MAESTRO_BIN=\"$HK/gone/bin/maestro\"|" "$hook" > "$tmp_hook"
mv "$tmp_hook" "$hook"
chmod +x "$hook"
printf 'local\n' > "$HK/repo/AGENTS.md"
( cd "$HK/repo" && git add AGENTS.md )
run_hook() {
  ( cd "$HK/repo" && env -i HOME="$HK/home" CLAUDE_CONFIG_DIR="$1" PATH="$2" \
    HOOKLOG="$HK/log/version" "$hook" 2>"$HK/log/stderr" )
}
: > "$HK/log/version"
run_hook "$HK/claude" "$HK/minbin"; rc=$?
if [ "$rc" -ne 0 ] && grep -q 'refusing to commit AGENTS.md' "$HK/log/stderr"; then
  ok "pre-commit finds maestro in the plugin cache"
else
  fail "pre-commit finds maestro in the plugin cache"
fi
[ "$(cat "$HK/log/version")" = "0.10.0" ] && ok "pre-commit picks the newest cached version" || fail "pre-commit picks the newest cached version"
: > "$HK/log/version"
run_hook "$HK/emptyclaude" "$HK/minbin"; rc=$?
if [ "$rc" -eq 0 ] && grep -q 'maestro: not found; skipping Bottega file check' "$HK/log/stderr"; then
  ok "pre-commit warns when maestro is not found"
else
  fail "pre-commit warns when maestro is not found"
fi
: > "$HK/log/version"
run_hook "$HK/claude" "$HK/pathbin:$HK/minbin"; rc=$?
if [ "$rc" -ne 0 ] && [ "$(cat "$HK/log/version")" = "path" ]; then
  ok "pre-commit prefers maestro on PATH"
else
  fail "pre-commit prefers maestro on PATH"
fi

# Lint reads hooks.json as JSON, so a hook command that reaches maestro any
# other way is rejected too (issue #6).
LB="$TMP/lintbox"
mkdir -p "$LB/scripts" "$LB/hooks" "$TMP/hookvariants"
cp "$ROOT/scripts/lint.sh" "$LB/scripts/lint.sh"
if python3 - "$ROOT/hooks/hooks.json" "$TMP/hookvariants" <<'PY'
import json, os, sys
src, out = sys.argv[1], sys.argv[2]
data = json.load(open(src))
variants = {
    "bare": "maestro guard builder",
    "absolute": "/usr/local/bin/maestro guard builder",
    "unbraced": '"$CLAUDE_PLUGIN_ROOT/bin/maestro" guard builder',
    "compound": '"${CLAUDE_PLUGIN_ROOT}/bin/maestro" guard builder; maestro evil',
}
for name, command in variants.items():
    d = json.loads(json.dumps(data))
    d["hooks"]["PreToolUse"][0]["hooks"][0]["command"] = command
    with open(os.path.join(out, name + ".json"), "w") as f:
        json.dump(d, f, indent=2)
        f.write("\n")
# The value on its own line: the old line scan never saw "command" and
# "maestro" together.
with open(os.path.join(out, "bare.json")) as f:
    original = f.read()
text = original.replace('"command": "maestro guard builder"',
                        '"command":\n            "maestro guard builder"')
if text == original:
    sys.exit("multiline variant did not change the file")
with open(os.path.join(out, "multiline.json"), "w") as f:
    f.write(text)
PY
then
  ok "lint variants generated"
else
  fail "lint variants generated"
fi
lint_rejects_hooks() {
  ( cd "$LB" && bash scripts/lint.sh 2>&1 ) | grep -q '^FAIL hooks/hooks.json'
}
for v in bare absolute unbraced compound multiline; do
  cp "$TMP/hookvariants/$v.json" "$LB/hooks/hooks.json"
  if lint_rejects_hooks; then ok "lint rejects $v hook command"; else fail "lint rejects $v hook command"; fi
done
cp "$ROOT/hooks/hooks.json" "$LB/hooks/hooks.json"
if lint_rejects_hooks; then fail "lint accepts plugin-root hook commands"; else ok "lint accepts plugin-root hook commands"; fi

# Standalone skills (issue #27): decision 6. A direct pattern match or a Load of
# a non-standalone skill removes a skill; the allow file exempts a skill from
# the direct test only. `lint` keeps the checked-in list and allow file honest.
SCAN="$TMP/standalone-scan"
mkdir -p "$SCAN/scripts" "$SCAN/skills/cat"
cp "$ROOT/scripts/standalone-skills.sh" "$SCAN/scripts/standalone-skills.sh" 2>/dev/null
chmod +x "$SCAN/scripts/standalone-skills.sh" 2>/dev/null
mk_scan_skill() {
  mkdir -p "$SCAN/skills/cat/$1"
  printf -- '---\nname: %s\ndescription: fixture\n---\n%s\n' "$1" "$2" > "$SCAN/skills/cat/$1/SKILL.md"
}
mk_scan_skill a 'clean'
mk_scan_skill b 'run maestro start'
mk_scan_skill c 'Load `b`'
mk_scan_skill d 'Spawn a worker'
mk_scan_skill e 'clean references'
mkdir -p "$SCAN/skills/cat/e/references"
printf 'Use the Agent tool.\n' > "$SCAN/skills/cat/e/references/x.md"
mk_scan_skill f 'Load `a`'
mk_scan_skill g 'loads `c`'
mk_scan_skill h 'run maestro report'
printf 'h\n' > "$SCAN/skills/standalone-allow.txt"
scan_out="$("$SCAN/scripts/standalone-skills.sh" 2>&1)"; scan_rc=$?
if [ "$scan_rc" -eq 0 ] && [ "$scan_out" = "$(printf 'a\nf\nh')" ]; then
  ok "standalone scan applies the rule"
else
  fail "standalone scan applies the rule"
fi

# A full copy lets lint pass as it does in the repo; each mutation is checked in
# place. The checked-in list must match the scan before lint can pass.
SL="$TMP/standalone-lint"
mkdir -p "$SL"
cp -R "$ROOT/." "$SL/"
chmod +x "$SL/scripts/standalone-skills.sh" 2>/dev/null
if [ -f "$SL/skills/standalone.txt" ] \
  && "$SL/scripts/standalone-skills.sh" 2>/dev/null | diff - "$SL/skills/standalone.txt" >/dev/null 2>&1 \
  && ( cd "$SL" && bash scripts/lint.sh ) 2>&1 | grep -qx 'lint: PASS'; then
  ok "lint passes with a fresh standalone.txt"
else
  fail "lint passes with a fresh standalone.txt"
fi
printf 'bogus\n' > "$SL/skills/standalone.txt"
lint_out="$( cd "$SL" && bash scripts/lint.sh 2>&1 )"; lint_rc=$?
if [ "$lint_rc" -ne 0 ] \
  && printf '%s\n' "$lint_out" | grep -qx 'FAIL skills/standalone.txt is out of date; run ./scripts/standalone-skills.sh --write'; then
  ok "lint fails on a stale standalone.txt"
else
  fail "lint fails on a stale standalone.txt"
fi
regen_out="$("$SL/scripts/standalone-skills.sh" --write 2>&1)"; regen_rc=$?
lint_out="$( cd "$SL" && bash scripts/lint.sh 2>&1 )"; lint_rc=$?
if [ "$regen_rc" -eq 0 ] \
  && printf '%s\n' "$regen_out" | grep -qE '^wrote skills/standalone\.txt \([0-9]+ skills\)$' \
  && [ "$lint_rc" -eq 0 ] \
  && printf '%s\n' "$lint_out" | grep -qx 'lint: PASS'; then
  ok "regen fixes a stale standalone.txt"
else
  fail "regen fixes a stale standalone.txt"
fi
allow_backup="$TMP/standalone-allow.backup"
cp "$SL/skills/standalone-allow.txt" "$allow_backup"
printf 'no-such-skill\n' >> "$SL/skills/standalone-allow.txt"
lint_out="$( cd "$SL" && bash scripts/lint.sh 2>&1 )"; lint_rc=$?
if [ "$lint_rc" -ne 0 ] \
  && printf '%s\n' "$lint_out" | grep -qx 'FAIL skills/standalone-allow.txt: no such skill: no-such-skill'; then
  ok "lint fails on a nonexistent allow entry"
else
  fail "lint fails on a nonexistent allow entry"
fi
cp "$allow_backup" "$SL/skills/standalone-allow.txt"
mkdir -p "$SL/skills/cat/plainfixture"
printf -- '---\nname: plainfixture\ndescription: fixture\n---\nclean\n' > "$SL/skills/cat/plainfixture/SKILL.md"
"$SL/scripts/standalone-skills.sh" --write >/dev/null 2>&1
printf 'plainfixture\n' >> "$SL/skills/standalone-allow.txt"
lint_out="$( cd "$SL" && bash scripts/lint.sh 2>&1 )"; lint_rc=$?
if [ "$lint_rc" -ne 0 ] \
  && printf '%s\n' "$lint_out" | grep -qx 'FAIL skills/standalone-allow.txt: stale entry, the pattern does not flag: plainfixture'; then
  ok "lint fails on a stale allow entry"
else
  fail "lint fails on a stale allow entry"
fi
cp "$allow_backup" "$SL/skills/standalone-allow.txt"
printf 'ketchup\n' >> "$SL/skills/standalone-allow.txt"
lint_out="$( cd "$SL" && bash scripts/lint.sh 2>&1 )"; lint_rc=$?
if [ "$lint_rc" -ne 0 ] \
  && printf '%s\n' "$lint_out" | grep -qx 'FAIL skills/standalone-allow.txt: duplicate entry: ketchup'; then
  ok "lint fails on a duplicate allow entry"
else
  fail "lint fails on a duplicate allow entry"
fi
cp "$allow_backup" "$SL/skills/standalone-allow.txt"

# `maestro skills` (issue #27, task 2): list the checked-in standalone set and
# copy named skills into the config dir with a marker. No --all or dependency
# expansion yet. Every call uses a scratch CLAUDE_CONFIG_DIR.
SKILLS="$TMP/skills-dest"
mkdir -p "$SKILLS"
skill_cmd() { CLAUDE_CONFIG_DIR="$SKILLS" "$M" skills "$@"; }
# same_tree A B: same relative file set and contents, ignoring the marker.
same_tree() {
  local a="$TMP/same-tree-a" b="$TMP/same-tree-b"
  ( cd "$1" && find . -type f ! -name .bottega-managed -exec cksum {} + | LC_ALL=C sort ) > "$a"
  ( cd "$2" && find . -type f ! -name .bottega-managed -exec cksum {} + | LC_ALL=C sort ) > "$b"
  cmp -s "$a" "$b"
}

out="$(skill_cmd list 2>&1)"; rc=$?
names_out="$(printf '%s\n' "$out" | awk '{print $1}')"
expected_names="$(cat "$ROOT/skills/standalone.txt")"
if [ "$rc" -eq 0 ] && [ "$names_out" = "$expected_names" ] \
  && [ "$(printf '%s\n' "$out" | grep -c 'not installed$')" -eq "$(printf '%s\n' "$expected_names" | grep -c .)" ]; then
  ok "skills list shows every standalone skill"
else
  fail "skills list shows every standalone skill"
fi
[ -z "$(ls -A "$SKILLS")" ] && ok "skills list writes nothing" || fail "skills list writes nothing"

out="$(skill_cmd install 2>&1)"; rc=$?
last="$(printf '%s\n' "$out" | tail -1)"
if [ "$rc" -eq 0 ] \
  && [ "$last" = 'Nothing installed. Run: maestro skills install <name>... | --all' ] \
  && [ "$(printf '%s\n' "$out" | sed '$d' | awk '{print $1}')" = "$expected_names" ] \
  && [ -z "$(ls -A "$SKILLS")" ]; then
  ok "skills install with no args installs nothing"
else
  fail "skills install with no args installs nothing"
fi

out="$(skill_cmd install teach 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] \
  && printf '%s\n' "$out" | grep -qxF "installed teach -> $SKILLS/skills/teach" \
  && same_tree "$ROOT/skills/workflow/teach" "$SKILLS/skills/teach" \
  && [ "$(cat "$SKILLS/skills/teach/.bottega-managed" 2>/dev/null)" = "bottega $plugin_version" ]; then
  ok "skills install copies the folder and marker"
else
  fail "skills install copies the folder and marker"
fi
out="$(skill_cmd list 2>&1)"
if printf '%s\n' "$out" | awk -v v="$plugin_version" '$1 == "teach" && $2 == "installed" && $3 == v { found = 1 } END { exit !found }'; then
  ok "skills list shows a managed install"
else
  fail "skills list shows a managed install"
fi

rm -rf "$SKILLS/skills/teach"
mkdir -p "$SKILLS/skills/teach"
printf 'mine\n' > "$SKILLS/skills/teach/SKILL.md"
skill_cmd install teach >/dev/null 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 1 ] \
  && grep -qxF "maestro skills: $SKILLS/skills/teach exists and is not managed by BottegaStack; move it away first" "$TMP/skills.err" \
  && [ "$(cat "$SKILLS/skills/teach/SKILL.md")" = "mine" ]; then
  ok "skills install refuses an unmanaged dir"
else
  fail "skills install refuses an unmanaged dir"
fi
out="$(skill_cmd list 2>&1)"
printf '%s\n' "$out" | grep -q '^teach *unmanaged copy$' && ok "skills list shows an unmanaged copy" || fail "skills list shows an unmanaged copy"

rm -rf "$SKILLS/skills"
mkdir -p "$SKILLS/skills/how"
printf 'mine\n' > "$SKILLS/skills/how/SKILL.md"
skill_cmd install teach how >/dev/null 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 1 ] \
  && grep -qxF "maestro skills: $SKILLS/skills/how exists and is not managed by BottegaStack; move it away first" "$TMP/skills.err" \
  && [ ! -e "$SKILLS/skills/teach" ]; then
  ok "skills install is all-or-nothing"
else
  fail "skills install is all-or-nothing"
fi

rm -rf "$SKILLS/skills"
skill_cmd install teach >/dev/null 2>&1
printf 'local edit\n' >> "$SKILLS/skills/teach/SKILL.md"
printf 'extra\n' > "$SKILLS/skills/teach/extra.txt"
skill_cmd install teach >"$TMP/skills.out" 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 0 ] \
  && grep -qxF "refreshed teach -> $SKILLS/skills/teach" "$TMP/skills.out" \
  && same_tree "$ROOT/skills/workflow/teach" "$SKILLS/skills/teach" \
  && [ ! -e "$SKILLS/skills/teach/extra.txt" ] \
  && [ "$(cat "$SKILLS/skills/teach/.bottega-managed" 2>/dev/null)" = "bottega $plugin_version" ]; then
  ok "skills install refreshes a managed copy"
else
  fail "skills install refreshes a managed copy"
fi

# A bad name fails before anything is written, even beside a valid name.
skill_reject() {
  local name="$1" msg="$2" rc
  rm -rf "$SKILLS/skills"
  skill_cmd install "$name" >/dev/null 2>"$TMP/skills.err"; rc=$?
  if [ "$rc" -eq 1 ] && grep -qxF "maestro skills: $msg" "$TMP/skills.err" \
    && [ -z "$(ls -A "$SKILLS")" ]; then
    ok "skills install rejects $name"
  else
    fail "skills install rejects $name"
  fi
}
skill_reject no-such-skill "unknown skill: no-such-skill"
skill_reject playbooks "playbooks uses the BottegaStack stack and is not standalone"
skill_reject ../x "invalid skill name: ../x"
skill_reject Teach "invalid skill name: Teach"
rm -rf "$SKILLS/skills"
skill_cmd install teach ../x >/dev/null 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 1 ] && grep -qxF 'maestro skills: invalid skill name: ../x' "$TMP/skills.err" \
  && [ -z "$(ls -A "$SKILLS")" ]; then
  ok "skills install rejects a bad name mixed with a valid one"
else
  fail "skills install rejects a bad name mixed with a valid one"
fi
skill_cmd install -x >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "skills install option is a usage error" || fail "skills install option is a usage error"

# Each argument is one name: an empty or newline-bearing argument is invalid,
# never split or skipped, and repeated names install once.
rm -rf "$SKILLS/skills"
skill_cmd install "" >/dev/null 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 1 ] && grep -qxF 'maestro skills: invalid skill name: ' "$TMP/skills.err" \
  && [ -z "$(ls -A "$SKILLS")" ]; then
  ok "skills install rejects an empty name"
else
  fail "skills install rejects an empty name"
fi
rm -rf "$SKILLS/skills"
skill_cmd install "$(printf 'teach\ninterview')" >/dev/null 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 1 ] && [ -z "$(ls -A "$SKILLS")" ]; then
  ok "skills install rejects a newline-bearing name"
else
  fail "skills install rejects a newline-bearing name"
fi
rm -rf "$SKILLS/skills"
skill_cmd install teach teach >"$TMP/skills.out" 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 0 ] \
  && [ "$(grep -cxF "installed teach -> $SKILLS/skills/teach" "$TMP/skills.out")" -eq 1 ] \
  && ! grep -q '^refreshed ' "$TMP/skills.out"; then
  ok "skills install de-duplicates repeated names"
else
  fail "skills install de-duplicates repeated names"
fi

# `maestro skills install` dependency closure and --all (issue #27, task 3): a
# fixture plugin root whose skills Load one another, alpha -> beta -> gamma, and
# a skill delta that its standalone list leaves out.
SKPLUG="$TMP/skplug"
SKD="$TMP/skplug-dest"
mkdir -p "$SKPLUG/bin" "$SKPLUG/.claude-plugin" "$SKPLUG/skills/cat" "$SKD"
cp "$M" "$SKPLUG/bin/maestro" && chmod +x "$SKPLUG/bin/maestro"
printf '{\n  "name": "fixture",\n  "version": "9.9.9"\n}\n' > "$SKPLUG/.claude-plugin/plugin.json"
fixture_skill() {
  mkdir -p "$SKPLUG/skills/cat/$1"
  printf -- '---\nname: %s\ndescription: fixture\n---\n%s\n' "$1" "$2" > "$SKPLUG/skills/cat/$1/SKILL.md"
}
fixture_skill alpha 'Load `beta` before you start.'
fixture_skill beta 'Load the `gamma` skill.'
fixture_skill gamma 'A leaf with no Loads.'
fixture_skill delta 'Not on the fixture standalone list.'
printf 'alpha\nbeta\ngamma\n' > "$SKPLUG/skills/standalone.txt"
skplug() { CLAUDE_CONFIG_DIR="$SKD" "$SKPLUG/bin/maestro" skills "$@"; }

out="$(skplug install alpha 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] \
  && printf '%s\n' "$out" | grep -qxF "installed alpha -> $SKD/skills/alpha" \
  && [ -f "$SKD/skills/beta/.bottega-managed" ] \
  && [ -f "$SKD/skills/gamma/.bottega-managed" ] \
  && [ "$(cat "$SKD/skills/gamma/.bottega-managed" 2>/dev/null)" = "bottega 9.9.9" ] \
  && [ ! -e "$SKD/skills/delta" ]; then
  ok "skills install pulls in loaded skills"
else
  fail "skills install pulls in loaded skills"
fi
if printf '%s\n' "$out" | grep -qxF 'also installing beta (loaded by alpha)' \
  && printf '%s\n' "$out" | grep -qxF 'also installing gamma (loaded by beta)'; then
  ok "skills install names the dependency"
else
  fail "skills install names the dependency"
fi

rm -rf "$SKD/skills"
mkdir -p "$SKD/skills/gamma"
printf 'mine\n' > "$SKD/skills/gamma/SKILL.md"
skplug install alpha >/dev/null 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 1 ] \
  && grep -qxF "maestro skills: $SKD/skills/gamma exists and is not managed by BottegaStack; move it away first" "$TMP/skills.err" \
  && [ ! -e "$SKD/skills/alpha" ] && [ ! -e "$SKD/skills/beta" ] \
  && [ "$(cat "$SKD/skills/gamma/SKILL.md")" = "mine" ]; then
  ok "skills install refuses when a dependency is an unmanaged dir"
else
  fail "skills install refuses when a dependency is an unmanaged dir"
fi

rm -rf "$SKD/skills"
out="$(skplug install --all 2>&1)"; rc=$?
expected_all="$(cat "$SKPLUG/skills/standalone.txt")"
installed_all="$( cd "$SKD/skills" 2>/dev/null && ls -A | LC_ALL=C sort )"
if [ "$rc" -eq 0 ] && [ "$installed_all" = "$expected_all" ] \
  && [ ! -e "$SKD/skills/delta" ] \
  && [ "$(cat "$SKD/skills/alpha/.bottega-managed" 2>/dev/null)" = "bottega 9.9.9" ]; then
  ok "skills install --all installs exactly standalone.txt"
else
  fail "skills install --all installs exactly standalone.txt"
fi

rm -rf "$SKD/skills"
skplug install --all alpha >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 2 ] && [ ! -e "$SKD/skills" ]; then
  ok "skills install --all with a name is a usage error"
else
  fail "skills install --all with a name is a usage error"
fi

# `maestro skills uninstall` (issue #27, task 4): remove managed copies only,
# by name or --all. A user's own dir of the same name is never touched, and a
# batch aborts before removing anything when one target is unmanaged.
rm -rf "$SKILLS/skills"
skill_cmd install how why >/dev/null 2>&1
mkdir -p "$SKILLS/skills/mine"
printf 'mine\n' > "$SKILLS/skills/mine/SKILL.md"
out="$(skill_cmd uninstall how 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] \
  && printf '%s\n' "$out" | grep -qxF 'removed how' \
  && [ ! -e "$SKILLS/skills/how" ] && [ -d "$SKILLS/skills/why" ] \
  && [ "$(cat "$SKILLS/skills/mine/SKILL.md" 2>/dev/null)" = "mine" ]; then
  ok "skills uninstall removes only marked copies"
else
  fail "skills uninstall removes only marked copies"
fi

# An unmarked dir of a valid standalone name is refused, and a batch removes
# nothing, even though `how` is a managed copy.
rm -rf "$SKILLS/skills"
skill_cmd install how why >/dev/null 2>&1
mkdir -p "$SKILLS/skills/teach"
printf 'mine\n' > "$SKILLS/skills/teach/SKILL.md"
skill_cmd uninstall teach how >/dev/null 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 1 ] \
  && grep -qxF "maestro skills: $SKILLS/skills/teach is not managed by BottegaStack; refusing to remove" "$TMP/skills.err" \
  && [ -d "$SKILLS/skills/how" ] && [ -d "$SKILLS/skills/why" ] \
  && [ "$(cat "$SKILLS/skills/teach/SKILL.md")" = "mine" ]; then
  ok "skills uninstall refuses an unmanaged dir"
else
  fail "skills uninstall refuses an unmanaged dir"
fi

# --all removes every managed copy and leaves the user's own dirs alone.
out="$(skill_cmd uninstall --all 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] \
  && printf '%s\n' "$out" | grep -qxF 'removed how' \
  && printf '%s\n' "$out" | grep -qxF 'removed why' \
  && [ ! -e "$SKILLS/skills/how" ] && [ ! -e "$SKILLS/skills/why" ] \
  && [ "$(cat "$SKILLS/skills/teach/SKILL.md" 2>/dev/null)" = "mine" ]; then
  ok "skills uninstall --all keeps own skills"
else
  fail "skills uninstall --all keeps own skills"
fi

# An absent standalone skill is a no-op that says so.
rm -rf "$SKILLS/skills"
mkdir -p "$SKILLS/skills"
out="$(skill_cmd uninstall teach 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qxF 'teach is not installed' \
  && [ -z "$(ls -A "$SKILLS/skills")" ]; then
  ok "skills uninstall of an absent skill is a no-op"
else
  fail "skills uninstall of an absent skill is a no-op"
fi

# A bad name fails before anything is removed, even beside a managed name.
uninstall_reject() {
  local name="$1" msg="$2" rc
  rm -rf "$SKILLS/skills"
  skill_cmd install how >/dev/null 2>&1
  skill_cmd uninstall how "$name" >/dev/null 2>"$TMP/skills.err"; rc=$?
  [ "$rc" -eq 1 ] \
    && grep -qF "maestro skills: $msg" "$TMP/skills.err" \
    && [ -f "$SKILLS/skills/how/.bottega-managed" ]
}
uninstall_bad=1
uninstall_reject no-such-skill 'unknown skill: no-such-skill' || uninstall_bad=0
uninstall_reject playbooks 'playbooks uses the BottegaStack stack and is not standalone' || uninstall_bad=0
uninstall_reject ../x 'invalid skill name: ../x' || uninstall_bad=0
uninstall_reject Teach 'invalid skill name: Teach' || uninstall_bad=0
uninstall_reject '' 'invalid skill name: ' || uninstall_bad=0
uninstall_reject "$(printf 'how\nteach')" 'invalid skill name: how' || uninstall_bad=0
if [ "$uninstall_bad" -eq 1 ]; then
  ok "skills uninstall rejects an invalid name"
else
  fail "skills uninstall rejects an invalid name"
fi
skill_cmd uninstall -x >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "skills uninstall option is a usage error" || fail "skills uninstall option is a usage error"

# Every skills command writes only under <config>/skills/ (issue #27, task 4):
# snapshot the config dir outside skills/ and the plugin's skills tree.
CONF13="$TMP/skills-conf"
rm -rf "$CONF13"
mkdir -p "$CONF13/skills" "$CONF13/agents" "$CONF13/plugins"
printf '{}\n' > "$CONF13/settings.json"
printf 'mine\n' > "$CONF13/agents/mine.md"
printf 'plugin\n' > "$CONF13/plugins/p.txt"
cfg13() { CLAUDE_CONFIG_DIR="$CONF13" "$M" skills "$@"; }
( cd "$CONF13" && find . -path ./skills -prune -o -print | LC_ALL=C sort ) > "$TMP/skills-only.before"
( cd "$ROOT" && find skills -type f -exec cksum {} + | LC_ALL=C sort ) > "$TMP/skills-root.before"
cfg13 list >/dev/null 2>&1
cfg13 install teach >/dev/null 2>&1
cfg13 install --all >/dev/null 2>&1
cfg13 uninstall teach >/dev/null 2>&1
cfg13 uninstall --all >/dev/null 2>&1
( cd "$CONF13" && find . -path ./skills -prune -o -print | LC_ALL=C sort ) > "$TMP/skills-only.after"
( cd "$ROOT" && find skills -type f -exec cksum {} + | LC_ALL=C sort ) > "$TMP/skills-root.after"
if cmp -s "$TMP/skills-only.before" "$TMP/skills-only.after" \
  && cmp -s "$TMP/skills-root.before" "$TMP/skills-root.after"; then
  ok "skills writes only under the skills dir"
else
  fail "skills writes only under the skills dir"
fi

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
hold
hold run-x
resume
resume run-x
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
skills
skills list
skills install
skills install teach
skills install --all
skills uninstall
skills uninstall --all
tools
tools install
tools hint
guard
guard stop
guard builder
keyget
--version
-V
version
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

# A plugin update can leave an older `maestro` first on PATH (issue #20):
# doctor and the SessionStart hint warn and name every copy, first one wins.
MP="$TMP/maestro-path"
mkdir -p "$MP/old/bin" "$MP/old/.claude-plugin" "$MP/new/bin" "$MP/new/.claude-plugin" \
  "$MP/one/bin" "$MP/one/.claude-plugin" "$MP/tools"
printf '{"version":"0.0.1"}\n' > "$MP/old/.claude-plugin/plugin.json"
printf '{"version":"0.0.2"}\n' > "$MP/new/.claude-plugin/plugin.json"
printf '{"version":"0.0.1"}\n' > "$MP/one/.claude-plugin/plugin.json"
for d in old new one; do
  printf '#!/bin/sh\nexit 0\n' > "$MP/$d/bin/maestro"
  chmod +x "$MP/$d/bin/maestro"
done
printf '#!/bin/sh\n' > "$MP/tools/rtk"
cp "$MP/tools/rtk" "$MP/tools/gitleaks"
chmod +x "$MP/tools/rtk" "$MP/tools/gitleaks"
# Keep the PATH entries the other commands need, but drop any other maestro
# copy so the tests see exactly the copies they create. MPNO also drops rtk
# providers, so the hint still has a missing tool to report.
MPSAFE=""; MPNO=""
old_ifs="$IFS"; IFS=:
for d in $PATH; do
  [ -n "$d" ] || continue
  [ -x "$d/maestro" ] && continue
  MPSAFE="${MPSAFE:+$MPSAFE:}$d"
  if [ ! -x "$d/rtk" ]; then MPNO="${MPNO:+$MPNO:}$d"; fi
done
IFS="$old_ifs"
MPTWO="$MP/old/bin:$MP/new/bin:$MPNO"
out="$(PATH="$MPTWO" "$M" doctor 2>&1)"
printf '%s\n' "$out" | grep -q 'warning: 2 maestro copies on PATH' && ok "doctor warns about two copies" || fail "doctor warns about two copies"
printf '%s\n' "$out" | grep -q 'old/bin (0.0.1) \[wins\], .*new/bin (0.0.2)' && ok "doctor names both copies and the winner" || fail "doctor names both copies and the winner"
out="$(PATH="$MPTWO" "$M" tools hint 2>&1)"
printf '%s\n' "$out" | grep -q '^{"systemMessage":' && ok "copy warning is a systemMessage" || fail "copy warning is a systemMessage"
printf '%s\n' "$out" | grep -q 'old/bin (0.0.1) \[wins\], .*new/bin (0.0.2)' && ok "tool hint names both copies and the winner" || fail "tool hint names both copies and the winner"
printf '%s\n' "$out" | grep -q 'maestro tools install' && ok "tool hint keeps the missing-tools message" || fail "tool hint keeps the missing-tools message"
out="$(PATH="$MP/one/bin:$MPNO" "$M" doctor 2>&1)"
printf '%s\n' "$out" | grep -q 'maestro copies' && fail "doctor silent with one copy" || ok "doctor silent with one copy"
[ -z "$(PATH="$MP/one/bin:$MP/tools:$MPSAFE" "$M" tools hint 2>&1)" ] && ok "tool hint silent with one copy" || fail "tool hint silent with one copy"
# A symlinked `maestro` and its target file are one copy, and the version comes
# from the target's plugin, not the symlink's directory.
mkdir -p "$MP/link/bin" "$MP/via/bin"
ln -s "$MP/old/bin/maestro" "$MP/link/bin/maestro"
ln -s "$MP/new/bin/maestro" "$MP/via/bin/maestro"
out="$(PATH="$MP/link/bin:$MP/old/bin:$MP/tools:$MPSAFE" "$M" doctor 2>&1)"
printf '%s\n' "$out" | grep -q 'maestro copies' && fail "symlinked copy and target count once" || ok "symlinked copy and target count once"
[ -z "$(PATH="$MP/link/bin:$MP/old/bin:$MP/tools:$MPSAFE" "$M" tools hint 2>&1)" ] && ok "symlinked copy hint silent" || fail "symlinked copy hint silent"
out="$(PATH="$MP/via/bin:$MP/old/bin:$MP/tools:$MPSAFE" "$M" doctor 2>&1)"
printf '%s\n' "$out" | grep -q 'via/bin (0.0.2) \[wins\], .*old/bin (0.0.1)' && ok "symlinked copy reads the target version" || fail "symlinked copy reads the target version"
# Empty PATH entries are skipped and never counted as a copy.
out="$(PATH="::$MP/one/bin:$MP/tools:$MPSAFE" "$M" doctor 2>&1)"
printf '%s\n' "$out" | grep -q 'maestro copies' && fail "empty PATH entry is skipped" || ok "empty PATH entry is skipped"
out="$(PATH="::$MP/old/bin::$MP/new/bin:$MP/tools:$MPSAFE" "$M" doctor 2>&1)"
printf '%s\n' "$out" | grep -q 'warning: 2 maestro copies on PATH' && ok "empty PATH entry does not count" || fail "empty PATH entry does not count"
[ -z "$(PATH="$MPTWO" BOTTEGA_NO_TOOL_HINT=1 "$M" tools hint 2>&1)" ] && ok "BOTTEGA_NO_TOOL_HINT silences the copy hint" || fail "BOTTEGA_NO_TOOL_HINT silences the copy hint"
out="$(PATH="$MPTWO" "$M" doctor --help 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^Usage:' && ! printf '%s\n' "$out" | grep -q 'maestro copies'; then
  ok "doctor --help stays usage only with two copies"
else
  fail "doctor --help stays usage only with two copies"
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
expect "close light summary run" "$M" report --close qsum
"$M" report --trust | grep -q "run-a" && ok "trust log" || fail "trust log"
echo "$hook_in" | "$M" guard stop | grep -q '"block"' && fail "stop hook silent after close" || ok "stop hook silent after close"

# A paused close keeps the run state for a resume (issue #21): the state dir,
# spec, paused marker, and trust line survive, and guard stop treats the run as
# closed; a later close with a final outcome removes the directory.
paused_out="$("$M" start "Paused run")"; rc=$?
paused_slug="$(printf '%s\n' "$paused_out" | sed -n 's/^run: //p')"
paused_dir="$(printf '%s\n' "$paused_out" | sed -n 's/^state: //p')"
if [ "$rc" -eq 0 ] && [ -n "$paused_slug" ] && [ -d "$paused_dir" ]; then
  ok "start paused run"
else
  fail "start paused run"
fi
printf '# Spec\n## Acceptance criteria\n- AC1: works. Proof: none\n### Task 1 - one\nbody\n' > "$TMP/paused-spec.md"
"$M" spec "$paused_slug" "$TMP/paused-spec.md" >/dev/null
expect "close paused keeps state" "$M" report --close "$paused_slug" --playbook feature --risk standard --outcome paused
if [ -d "$paused_dir" ] && [ -f "$paused_dir/spec.md" ] && [ -f "$paused_dir/paused" ]; then
  ok "paused close keeps the state dir and spec"
else
  fail "paused close keeps the state dir and spec"
fi
paused_base="$(dirname "$paused_dir")"
awk -F'\t' -v r="$paused_slug" '$2 == r && $7 == "paused" { found = 1 } END { exit !found }' "$paused_base/trust.log" \
  && ok "paused close logs to trust.log" || fail "paused close logs to trust.log"
echo "$hook_in" | "$M" guard stop | grep -q '"block"' && fail "stop hook silent on a paused run" || ok "stop hook silent on a paused run"
"$M" build --status "$paused_slug" >/dev/null 2>&1 && ok "build --status resolves a paused run" || fail "build --status resolves a paused run"
"$M" verify list "$paused_slug" >/dev/null 2>&1 && ok "verify list resolves a paused run" || fail "verify list resolves a paused run"
"$M" spec "$paused_slug" "$TMP/paused-spec.md" >/dev/null 2>&1 && ok "spec resolves a paused run" || fail "spec resolves a paused run"
expect "close paused run for real" "$M" report --close "$paused_slug" --playbook feature --risk standard --outcome merged
[ ! -d "$paused_dir" ] && ok "merged close removes the paused state" || fail "merged close removes the paused state"

# An unknown review slug fails before the model runs (issue #15).
: > "$STUBLOG"
out="$("$M" build --review --here no-such-review 2>&1 >/dev/null)"; rc=$?
if [ "$rc" -eq 1 ] && [ "$out" = "maestro build --review: no such run: no-such-review" ] && [ ! -s "$STUBLOG" ]; then
  ok "review --here unknown slug fails before the model"
else
  fail "review --here unknown slug fails before the model"
fi
out="$("$M" build --review no-such-review 1 2>&1 >/dev/null)"; rc=$?
if [ "$rc" -eq 1 ] && [ "$out" = "maestro build --review: no such run: no-such-review" ] && [ ! -s "$STUBLOG" ]; then
  ok "review unknown run fails before the model"
else
  fail "review unknown run fails before the model"
fi

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
