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

# A Bash 3.2 [a-z] range can match uppercase under a UTF-8 collation, so the
# name validators must not depend on locale. Run them under en_US.UTF-8 when
# the host has it; without it the uppercase case still runs (issue #27 CI).
utf8_locale=""
if locale -a 2>/dev/null | grep -Eqi '^en_US\.utf-?8$'; then
  utf8_locale=en_US.UTF-8
fi
locale_run() {
  if [ -n "$utf8_locale" ]; then LC_ALL="$utf8_locale" "$@"; else "$@"; fi
}

# Isolated environment (CI runners set XDG_CONFIG_HOME, so pin it too).
unset BOTTEGA_BUILDER_ENV BOTTEGA_BUILDER_KEY BOTTEGA_PLUGIN_DIR BOTTEGA_NO_TOOL_HINT BOTTEGA_HEADLESS
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config" CLAUDE_CONFIG_DIR="$TMP/home/.claude" BOTTEGA_STATE_DIR="$TMP/state"
export GIT_AUTHOR_NAME=e2e GIT_AUTHOR_EMAIL=e2e@example.invalid GIT_COMMITTER_NAME=e2e GIT_COMMITTER_EMAIL=e2e@example.invalid
mkdir -p "$TMP/bin" "$CLAUDE_CONFIG_DIR/rules" "$HOME/.config/bottega"
# A complete status-line config: the existing silent-hint cases below must stay
# silent now that a missing status line adds its own SessionStart line (AC9).
printf '%s\n' '{"statusLine":{"type":"command","command":"maestro watch --line","refreshInterval":10}}' > "$CLAUDE_CONFIG_DIR/settings.json"
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
# STUB_COMMIT lists paths to change and commit in order; `build` runs
# verify-task at the end, so a fixture builder must leave real commits.
if [ -n "${STUB_COMMIT:-}" ]; then
  for stub_path in $STUB_COMMIT; do
    mkdir -p "$(dirname "$stub_path")"
    printf 'stub %s %s\n' "$stub_path" "$RANDOM$$" >> "$stub_path"
    git add -- "$stub_path" >/dev/null 2>&1
    git commit -q -m "stub: $stub_path" >/dev/null 2>&1
  done
fi
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}'
printf '{"type":"result","result":"STATUS: %s\\nall good","usage":{"input_tokens":10,"output_tokens":5},"session_id":"s1"}\n' "${STUB_STATUS:-DONE}"
EOF
chmod +x "$TMP/bin/claude"
export PATH="$TMP/bin:$PATH" STUBLOG="$TMP/stub.log" STUBENV="$TMP/stub.env"

# Stay independent of any `maestro` the host has on PATH: drop empty entries and
# entries holding an executable `maestro`, keeping everything else in order. The
# copy-warning cases below build their own fixture PATHs with two copies.
e2e_path=""
e2e_old_ifs="$IFS"; IFS=:
for e2e_dir in $PATH; do
  [ -n "$e2e_dir" ] || continue
  [ -f "$e2e_dir/maestro" ] && [ -x "$e2e_dir/maestro" ] && continue
  e2e_path="${e2e_path:+$e2e_path:}$e2e_dir"
done
IFS="$e2e_old_ifs"
export PATH="$e2e_path"

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

# Monitor and `build --status --every` were designed out (Task 3): the master
# and docs drive progress with `maestro watch` instead.
if grep -nE 'Monitor|--every' "$ROOT/agents/master.md" "$ROOT/commands/maestro.md" \
  "$ROOT/docs/WORKFLOW.md" "$ROOT/docs/SETUP.md" "$ROOT/skills/workflow/playbooks/SKILL.md" \
  "$ROOT/README.md" "$ROOT/AGENTS.md" >/dev/null 2>&1; then
  fail "docs: no Monitor or --every"
else
  ok "docs: no Monitor or --every"
fi
grep -q 'maestro watch' "$ROOT/agents/master.md" && ok "docs: master names maestro watch" || fail "docs: master names maestro watch"

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
printf '# Spec\n## Acceptance criteria\n- AC1: works. Proof: `true` -> exit 0\n- AC2: judgment. Proof: none (taste)\n### Task 1 - one\nbody\n**Allowed files:** `allowed.txt`\n### Task 2 - two\nbody\n**Allowed files:** `allowed.txt`\n' > "$TMP/spec.md"
[ "$("$M" spec run-a "$TMP/spec.md")" = "2" ] && ok "spec counts tasks" || fail "spec counts tasks"

# Atomic spec save and empty-spec guards (issue #39). A source that is its own
# destination, directly or through a symlink, and an empty source, a 0-byte file
# or empty stdin, must leave spec.md untouched; a successful save leaves no
# temp file behind.
spec_dir="$(dirname "$(find "$BOTTEGA_STATE_DIR" -path '*/run-a/spec.md' -type f | head -1)")"
spec_before="$(cat "$spec_dir/spec.md")"
spec_self_ok=1
out="$("$M" spec run-a "$spec_dir/spec.md" 2>&1)"; rc=$?
[ "$rc" -eq 1 ] && [ "$(cat "$spec_dir/spec.md")" = "$spec_before" ] \
  && printf '%s\n' "$out" | grep -qxF "maestro spec: refusing to read the spec from its own destination: $spec_dir/spec.md" \
  || spec_self_ok=0
ln -s "$spec_dir/spec.md" "$TMP/spec-self-link.md"
out="$("$M" spec run-a "$TMP/spec-self-link.md" 2>&1)"; rc=$?
[ "$rc" -eq 1 ] && [ "$(cat "$spec_dir/spec.md")" = "$spec_before" ] \
  && printf '%s\n' "$out" | grep -qxF "maestro spec: refusing to read the spec from its own destination: $TMP/spec-self-link.md" \
  || spec_self_ok=0
[ "$spec_self_ok" -eq 1 ] && ok "spec refuses its own spec.md" || fail "spec refuses its own spec.md"
spec_empty_ok=1
: > "$TMP/empty-source.md"
out="$("$M" spec run-a "$TMP/empty-source.md" 2>&1)"; rc=$?
[ "$rc" -eq 1 ] && [ "$(cat "$spec_dir/spec.md")" = "$spec_before" ] \
  && printf '%s\n' "$out" | grep -qxF "maestro spec: empty spec: $TMP/empty-source.md" \
  || spec_empty_ok=0
out="$("$M" spec run-a </dev/null 2>&1)"; rc=$?
[ "$rc" -eq 1 ] && [ "$(cat "$spec_dir/spec.md")" = "$spec_before" ] \
  && printf '%s\n' "$out" | grep -qxF 'maestro spec: empty spec: stdin' \
  || spec_empty_ok=0
[ "$spec_empty_ok" -eq 1 ] && ok "spec refuses an empty source" || fail "spec refuses an empty source"
printf '# Spec\n## Acceptance criteria\n- AC1: works. Proof: `true` -> exit 0\n- AC2: judgment. Proof: none (taste)\n### Task 1 - one\nbody\n**Allowed files:** `allowed.txt`\n### Task 2 - two\nbody\n**Allowed files:** `allowed.txt`\n' > "$TMP/spec-new.md"
out="$("$M" spec run-a "$TMP/spec-new.md" 2>&1)"; rc=$?
spec_leftovers="$(find "$spec_dir" -maxdepth 1 \( -name '.spec*' -o -name 'spec.md.*' -o -name '*.tmp' \) -print)"
if [ "$rc" -eq 0 ] && [ "$out" = "2" ] && cmp -s "$TMP/spec-new.md" "$spec_dir/spec.md" \
  && [ -z "$spec_leftovers" ]; then
  ok "spec saves without leftovers"
else
  fail "spec saves without leftovers"
fi
# AC parser (Task 2): `maestro spec` rejects a malformed AC line and leaves the
# previous spec.md and tasks/ byte-for-byte unchanged. One AC per line, `Proof:`
# on the same line, and unique ids; every bad line is reported with its number.
run_snapshot() {
  ( cd "$1" && cat spec.md; find tasks -type f -print 2>/dev/null | LC_ALL=C sort \
    | while IFS= read -r f; do printf '%s: ' "$f"; cat "$f"; done )
}
spec_before="$(run_snapshot "$spec_dir")"
printf '# Spec\n## Acceptance criteria\n- AC1 works. Proof: `true` -> exit 0\n### Task 1 - one\nbody\n' > "$TMP/spec-malformed.md"
out="$("$M" spec run-a "$TMP/spec-malformed.md" 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] \
  && printf '%s\n' "$out" | grep -qxF 'maestro spec: line 3: not an AC line (expected "- AC<n>: <text> Proof: ..."): - AC1 works. Proof: `true` -> exit 0' \
  && [ "$(run_snapshot "$spec_dir")" = "$spec_before" ]; then
  ok "spec rejects a malformed AC line"
else
  fail "spec rejects a malformed AC line"
fi
printf '# Spec\n## Acceptance criteria\n- AC1: works.\n### Task 1 - one\nbody\n' > "$TMP/spec-no-proof.md"
out="$("$M" spec run-a "$TMP/spec-no-proof.md" 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qxF 'maestro spec: line 3: no Proof:: - AC1: works.' \
  && [ "$(run_snapshot "$spec_dir")" = "$spec_before" ]; then
  ok "spec rejects a missing Proof"
else
  fail "spec rejects a missing Proof"
fi
printf '# Spec\n## Acceptance criteria\n- AC1: judgment. Proof: none\n### Task 1 - one\nbody\n' > "$TMP/spec-none-reason.md"
out="$("$M" spec run-a "$TMP/spec-none-reason.md" 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qxF 'maestro spec: line 3: Proof: none needs a reason: - AC1: judgment. Proof: none' \
  && [ "$(run_snapshot "$spec_dir")" = "$spec_before" ]; then
  ok "spec rejects Proof: none without a reason"
else
  fail "spec rejects Proof: none without a reason"
fi
printf '# Spec\n## Acceptance criteria\n- AC1: one. Proof: `true` -> exit 0\n- AC1: two. Proof: `true` -> exit 0\n### Task 1 - one\nbody\n' > "$TMP/spec-duplicate.md"
out="$("$M" spec run-a "$TMP/spec-duplicate.md" 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qxF 'maestro spec: line 4: duplicate AC1 (first on line 3): - AC1: two. Proof: `true` -> exit 0' \
  && [ "$(run_snapshot "$spec_dir")" = "$spec_before" ]; then
  ok "spec rejects a duplicate AC id"
else
  fail "spec rejects a duplicate AC id"
fi
# `build` and `gate` refuse a run whose spec.md is 0 bytes, before any model
# call or check lookup. An isolated state dir keeps the empty run out of the
# other cases.
ESPEC_STATE="$TMP/empty-spec-state"
esp_out="$( cd "$REPO" && BOTTEGA_STATE_DIR="$ESPEC_STATE" "$M" start "Empty spec" 2>&1)"
esp_slug="$(printf '%s\n' "$esp_out" | sed -n 's/^run: //p')"
esp_dir="$(printf '%s\n' "$esp_out" | sed -n 's/^state: //p')"
: > "$esp_dir/spec.md"
stub_before="$( [ -f "$STUBLOG" ] && wc -l < "$STUBLOG" | tr -d ' ' || echo 0)"
out="$( cd "$REPO" && BOTTEGA_STATE_DIR="$ESPEC_STATE" "$M" build "$esp_slug" 1 --block 2>&1)"; rc=$?
stub_after="$( [ -f "$STUBLOG" ] && wc -l < "$STUBLOG" | tr -d ' ' || echo 0)"
if [ "$rc" -eq 3 ] && printf '%s\n' "$out" | grep -q 'spec.md is empty, re-run maestro spec' \
  && [ "$stub_before" = "$stub_after" ]; then
  ok "build refuses an empty spec.md"
else
  fail "build refuses an empty spec.md"
fi
out="$( cd "$REPO" && BOTTEGA_STATE_DIR="$ESPEC_STATE" "$M" gate "$esp_slug" 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q 'spec.md is empty, re-run maestro spec'; then
  ok "gate refuses an empty spec.md"
else
  fail "gate refuses an empty spec.md"
fi

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
# `Proof: none` criteria are listed before the gate result, whether it passes
# or fails (Task 2); run-a has AC2 with `Proof: none (taste)`.
out="$("$M" gate run-a --proof 2>&1)"; rc=$?
none_line="$(printf '%s\n' "$out" | grep -n '^proof none: AC2: ' | head -1 | cut -d: -f1)"
gate_line="$(printf '%s\n' "$out" | grep -n '^GATE:' | head -1 | cut -d: -f1)"
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'proof none: AC2: (taste)' \
  && [ -n "$none_line" ] && [ -n "$gate_line" ] && [ "$none_line" -lt "$gate_line" ]; then
  ok "gate --proof lists Proof: none criteria"
else
  fail "gate --proof lists Proof: none criteria"
fi
# A full run whose saved SPEC has no AC lines fails `gate --proof`; a light path
# (no SPEC) keeps its old behaviour. An isolated state dir keeps this run clean.
ZEROAC_STATE="$TMP/zero-ac-state"
zout="$( BOTTEGA_STATE_DIR="$ZEROAC_STATE" "$M" start "Zero ACs" 2>&1 )"
zslug="$(printf '%s\n' "$zout" | sed -n 's/^run: //p')"
printf '# Spec\n## Acceptance criteria\nNo criteria here.\n### Task 1 - one\nbody\n' > "$TMP/zero-ac-spec.md"
BOTTEGA_STATE_DIR="$ZEROAC_STATE" "$M" spec "$zslug" "$TMP/zero-ac-spec.md" >/dev/null
BOTTEGA_STATE_DIR="$ZEROAC_STATE" "$M" check "$zslug" >/dev/null 2>&1
out="$( BOTTEGA_STATE_DIR="$ZEROAC_STATE" "$M" gate "$zslug" --proof 2>&1 )"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qx 'GATE: FAIL (proof: SPEC has no acceptance criteria)'; then
  ok "gate --proof fails with zero ACs"
else
  fail "gate --proof fails with zero ACs"
fi
# A quoted `Proof: none` in the AC prose is not the proof field (Task 5 fix): the
# last `Proof:` on the line decides. AC1 quotes it first and then names a real
# command, so it stays a required proof and is never listed as `proof none:`.
LASTPROOF_STATE="$TMP/last-proof-state"
lpout="$( BOTTEGA_STATE_DIR="$LASTPROOF_STATE" "$M" start "Quoted proof" 2>&1 )"
lpslug="$(printf '%s\n' "$lpout" | sed -n 's/^run: //p')"
printf '# Spec\n## Acceptance criteria\n- AC1: quotes `Proof: none` in prose. Proof: `true` -> exit 0\n### Task 1 - one\nbody\n' > "$TMP/last-proof-spec.md"
BOTTEGA_STATE_DIR="$LASTPROOF_STATE" "$M" spec "$lpslug" "$TMP/last-proof-spec.md" >/dev/null
BOTTEGA_STATE_DIR="$LASTPROOF_STATE" "$M" check "$lpslug" >/dev/null 2>&1
out="$( BOTTEGA_STATE_DIR="$LASTPROOF_STATE" "$M" gate "$lpslug" --proof 2>&1 )"; rc=$?
if [ "$rc" -eq 1 ] \
  && printf '%s\n' "$out" | grep -qx 'GATE: FAIL (proof: AC1 has no recorded proof)' \
  && ! printf '%s\n' "$out" | grep -q '^proof none: AC1:'; then
  ok "gate reads the last Proof: on an AC line"
else
  fail "gate reads the last Proof: on an AC line"
fi
git commit -q --allow-empty -m next
"$M" check run-a >/dev/null
expect_not "gate --proof stale" "$M" gate run-a --proof
"$M" verify waive run-a AC1 "user approved" >/dev/null
expect "gate --proof waived" "$M" gate run-a --proof

# Check records are keyed per HEAD (Task 2): two task worktrees at different
# commits in the shared state directory keep their own result, so a check in B
# no longer makes A's gate stale. A new commit in A still does.
expect "worktree create A" "$M" worktree create run-a p1
expect "worktree create B" "$M" worktree create run-a p2
WT_A="$TMP/repo-bottega/run-a/p1"
WT_B="$TMP/repo-bottega/run-a/p2"
sha_a="$(git -C "$WT_A" rev-parse HEAD)"
git -C "$WT_B" commit -q --allow-empty -m parallel
sha_b="$(git -C "$WT_B" rev-parse HEAD)"
expect "check worktree A" sh -c "cd '$WT_A' && '$M' check run-a"
expect "check worktree B" sh -c "cd '$WT_B' && '$M' check run-a"
checks_dir="$(dirname "$(find "$BOTTEGA_STATE_DIR" -path '*/run-a/checks.result' -type f | head -1)")"
out="$( cd "$WT_A" && "$M" gate run-a 2>&1 )"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = "GATE: PASS" ] \
  && [ -f "$checks_dir/checks/$sha_a.result" ] && [ -f "$checks_dir/checks/$sha_b.result" ]; then
  ok "check record per HEAD survives a parallel worktree"
else
  fail "check record per HEAD survives a parallel worktree"
fi
grep -qx "HEAD: $sha_b" "$checks_dir/checks.result" && ok "check refreshes checks.result to the latest record" || fail "check refreshes checks.result to the latest record"
git -C "$WT_A" commit -q --allow-empty -m after-check
out="$( cd "$WT_A" && "$M" gate run-a 2>&1 )"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qE '^GATE: FAIL \(checks stale: [0-9a-f]+ != [0-9a-f]+\)$'; then
  ok "gate stale after a new commit"
else
  fail "gate stale after a new commit"
fi
mkdir -p "$checks_dir/../no-record"
out="$("$M" gate no-record 2>&1)"; rc=$?
rmdir "$checks_dir/../no-record" 2>/dev/null || true
if [ "$rc" -eq 1 ] && [ "$out" = "GATE: FAIL (no checks.result)" ]; then
  ok "gate fails with no check record"
else
  fail "gate fails with no check record"
fi

# Builds through the stub.
: > "$STUBLOG"
expect "worktree create" "$M" worktree create run-a 1
expect "build" env STUB_COMMIT=allowed.txt "$M" build run-a 1 --block
expect "build --revise" sh -c "echo 'fix it' | STUB_COMMIT=allowed.txt '$M' build run-a 1 --revise - --block"
# `maestro build` runs the worktree check and verify-task at the end (Task 5): a
# DONE build with commits passes only when every task rule holds; a changed file
# outside `Allowed files` exits 1 and leaves the task BLOCKED.
"$M" start "Build verify" >/dev/null 2>&1
cat > "$TMP/build-verify-spec.md" <<'EOF'
# Spec
## Acceptance criteria
- AC1: works. Proof: `true` -> exit 0
### Task 1 - pass
**Allowed files:** `tests/pass_test.sh`, `src/pass.sh`
**Test first:** tests/pass_test.sh
body
### Task 2 - outside
**Allowed files:** `src/ok.sh`
**Test first:** none
body
### Task 3 - revision
**Allowed files:** `src/rev.sh`
**Test first:** none
body
### Task 4 - blocked report
**Allowed files:** `src/blocked.sh`
**Test first:** none
body
### Task 5 - no commits
**Allowed files:** `src/none.sh`
**Test first:** none
body
EOF
"$M" spec build-verify "$TMP/build-verify-spec.md" >/dev/null 2>&1
for bvt in 1 2 3 4 5; do "$M" worktree create build-verify "$bvt" --branch "bv-$bvt" >/dev/null 2>&1; done
out="$(STUB_COMMIT='tests/pass_test.sh src/pass.sh' "$M" build build-verify 1 --block 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'verify-task: PASS'; then
  ok "build --block passes verify-task"
else
  fail "build --block passes verify-task"
fi
out="$(STUB_COMMIT='src/other.sh' "$M" build build-verify 2 --block 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q '^FAIL allowed-files:' \
  && printf '%s\n' "$out" | grep -q '^verify-task: FAIL; task stays BLOCKED' \
  && printf '%s\n' "$out" | grep -q 'verify-task build-verify 2 --waive'; then
  ok "build --block fails on verify-task"
else
  fail "build --block fails on verify-task"
fi
STUB_COMMIT='src/rev.sh' "$M" build build-verify 3 --block >/dev/null 2>&1
out="$(printf 'fix it\n' | STUB_COMMIT='src/bad.sh' "$M" build build-verify 3 --revise - --block 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q '^FAIL allowed-files:' \
  && printf '%s\n' "$out" | grep -q '^verify-task: FAIL; task stays BLOCKED'; then
  ok "build --block fails on verify-task after a revision"
else
  fail "build --block fails on verify-task after a revision"
fi
# A non-DONE report runs the rules too, so a BLOCKED build exits 1 instead of
# passing just because the builder exited 0 with commits.
out="$(STUB_STATUS=BLOCKED STUB_COMMIT='src/blocked.sh' "$M" build build-verify 4 --block 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q '^FAIL report: STATUS: BLOCKED' \
  && printf '%s\n' "$out" | grep -q '^verify-task: FAIL; task stays BLOCKED'; then
  ok "build --block fails a BLOCKED report"
else
  fail "build --block fails a BLOCKED report"
fi
# A DONE report with no commits still runs the rules, so the commits rule fails.
out="$("$M" build build-verify 5 --block 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q '^FAIL commits: no commits on ' \
  && printf '%s\n' "$out" | grep -q '^verify-task: FAIL; task stays BLOCKED'; then
  ok "build --block fails a DONE report with no commits"
else
  fail "build --block fails a DONE report with no commits"
fi
"$M" report --close build-verify >/dev/null 2>&1
expect "build --review" "$M" build --review run-a 1 --block
# `build --review` checks before it reviews (Task 3): a new HEAD runs the check
# in the worktree, a fresh PASS record is reused without another checks.log line,
# and a failing check stops the reviewer before it writes anything.
WT_REVIEW="$TMP/repo-bottega/run-a/1"
BDIR_REVIEW="$(dirname "$(find "$BOTTEGA_STATE_DIR" -path '*/run-a/build/1.report.md' | head -1)")"
RUN_REVIEW="$(dirname "$BDIR_REVIEW")"
git -C "$WT_REVIEW" commit -q --allow-empty -m "review check head"
STUB_REVIEW="$TMP/stub-review.log"
: > "$STUB_REVIEW"
out="$(STUBLOG="$STUB_REVIEW" "$M" build --review run-a 1 --block 2>&1)"; rc=$?
review_head="$(git -C "$WT_REVIEW" rev-parse HEAD)"
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^check: PASS' \
  && grep -qx 'RESULT: PASS' "$RUN_REVIEW/checks/$review_head.result" \
  && grep -q -- '--agent bottega:review-code' "$STUB_REVIEW"; then
  ok "build --review runs the check first"
else
  fail "build --review runs the check first"
fi
checks_before="$(wc -l < "$RUN_REVIEW/checks.log" | tr -d ' ')"
: > "$STUB_REVIEW"
out="$(STUBLOG="$STUB_REVIEW" "$M" build --review run-a 1 --block 2>&1)"; rc=$?
checks_after="$(wc -l < "$RUN_REVIEW/checks.log" | tr -d ' ')"
review_sha7="$(git -C "$WT_REVIEW" rev-parse HEAD | cut -c1-7)"
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx "check: reused PASS record $review_sha7" \
  && [ "$checks_before" = "$checks_after" ]; then
  ok "build --review reuses a fresh check"
else
  fail "build --review reuses a fresh check"
fi
git -C "$WT_REVIEW" commit -q --allow-empty -m "failing check head"
printf '#!/usr/bin/env bash\nexit 1\n' > "$WT_REVIEW/scripts/check"
chmod +x "$WT_REVIEW/scripts/check"
rm -f "$BDIR_REVIEW/1.review2.md"
: > "$STUB_REVIEW"
out="$(STUBLOG="$STUB_REVIEW" "$M" build --review run-a 1 --block 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'check: FAIL' \
  && ! grep -q -- '--agent bottega:review-code' "$STUB_REVIEW" \
  && [ ! -e "$BDIR_REVIEW/1.review2.md" ]; then
  ok "build --review refuses a failing check"
else
  fail "build --review refuses a failing check"
fi
printf '#!/usr/bin/env bash\necho ok\n' > "$WT_REVIEW/scripts/check"
chmod +x "$WT_REVIEW/scripts/check"
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
# Either order is correct (issue #34): normally one caller collects the result
# and the other prints the normal summary, but on a slow runner both callers can
# see the finished result at the same moment and both print the normal summary.
# A caller that returns with no result at all is still a failure.
race_collected=0
race_normal=0
race_bad=0
for f in "$TMP/race-a.out" "$TMP/race-b.out"; do
  if [ ! -s "$f" ] || ! grep -qx 'task: race' "$f" || ! grep -q '^report: .*report\.md' "$f"; then
    race_bad=1
  elif grep -qx 'already collected by another caller' "$f"; then
    race_collected=$((race_collected + 1))
  else
    race_normal=$((race_normal + 1))
  fi
done
race_report_a="$(sed -n 's/^report: //p' "$TMP/race-a.out" | head -1)"
race_report_b="$(sed -n 's/^report: //p' "$TMP/race-b.out" | head -1)"
race_ok=0
if [ "$race_bad" -eq 0 ]; then
  # (a) exactly one collected and one normal summary.
  if [ "$race_collected" -eq 1 ] && [ "$race_normal" -eq 1 ]; then
    race_ok=1
  fi
  # (b) both normal summaries, same report, neither collected.
  if [ "$race_collected" -eq 0 ] && [ "$race_normal" -eq 2 ] \
    && [ -n "$race_report_a" ] && [ "$race_report_a" = "$race_report_b" ]; then
    race_ok=1
  fi
fi
[ "$race_ok" -eq 1 ] && ok "concurrent light build names the collected task" || fail "concurrent light build names the collected task"
# Both callers name a finished report that exists, and exactly one caller
# collects the rc: the other prints the already-collected reply. A loser that
# sees the run marker gone before the report is written prints no report line.
race_report_files=1
race_collect_count=0
for f in "$TMP/race-a.out" "$TMP/race-b.out"; do
  race_report="$(sed -n 's/^report: \([^ ]*\).*/\1/p' "$f" | head -1)"
  [ -n "$race_report" ] && [ -f "$race_report" ] || race_report_files=0
  grep -qx 'already collected by another caller' "$f" && race_collect_count=$((race_collect_count + 1))
done
if [ "$race_report_files" -eq 1 ] && [ "$race_collect_count" -eq 1 ]; then
  ok "concurrent light build report exists for both callers"
else
  fail "concurrent light build report exists for both callers"
fi
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
# The light path follows the same rule: a failing check in the current checkout
# stops the reviewer. Swap the repo's check, then restore it.
"$M" build --here rev-here --task "review input" --block >/dev/null 2>&1
printf '#!/usr/bin/env bash\nexit 1\n' > "$REPO/scripts/check"
chmod +x "$REPO/scripts/check"
STUB_HERE="$TMP/stub-review-here.log"
: > "$STUB_HERE"
out="$(STUBLOG="$STUB_HERE" "$M" build --review --here rev-here --block 2>&1)"; rc=$?
printf '#!/usr/bin/env bash\necho ok\n' > "$REPO/scripts/check"
chmod +x "$REPO/scripts/check"
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'check: FAIL' \
  && ! grep -q -- '--agent bottega:review-code' "$STUB_HERE"; then
  ok "build --review --here refuses a failing check"
else
  fail "build --review --here refuses a failing check"
fi
"$M" report --close rev-here >/dev/null 2>&1
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
out="$("$M" build --status q1 --every 5 2>&1)"; rc=$?
if [ "$rc" -eq 2 ] && printf '%s\n' "$out" | grep -q 'maestro watch'; then
  ok "status: --every removed"
else
  fail "status: --every removed"
fi
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

# Event log (Task 1): every headless flavour appends start/step/end to the run's
# events.tsv with six tab-separated fields, and creates no .progress file.
SDIR="$(dirname "$(find "$BOTTEGA_STATE_DIR" -path '*/run-a' -type d | head -1)")"
events_ok() { # <name> <events> <task> <role>
  local name="$1" ev="$2" task="$3" role="$4" starts steps ends bad
  if [ ! -f "$ev" ]; then fail "$name"; return; fi
  starts="$(awk -F'\t' -v t="$task" -v r="$role" '$5 == "start" && $3 == t && $4 == r { n++ } END { print n + 0 }' "$ev")"
  steps="$(awk -F'\t' -v t="$task" -v r="$role" '$5 == "step" && $3 == t && $4 == r { n++ } END { print n + 0 }' "$ev")"
  ends="$(awk -F'\t' -v t="$task" -v r="$role" '$5 == "end" && $3 == t && $4 == r { n++ } END { print n + 0 }' "$ev")"
  bad="$(awk -F'\t' -v t="$task" -v r="$role" '$3 == t && $4 == r && (NF != 6 || tolower($0) ~ /token/) { n++ } END { print n + 0 }' "$ev")"
  if [ "$starts" -ge 1 ] && [ "$steps" -ge 1 ] && [ "$ends" -eq 1 ] && [ "$bad" -eq 0 ]; then
    ok "$name"
  else
    fail "$name"
  fi
}
expect "events: worktree for run task" "$M" worktree create run-a 2
expect "events: build run task" env STUB_COMMIT=allowed.txt "$M" build run-a 2 --block
expect "events: build review" "$M" build --review run-a 2 --block
expect "events: build here" "$M" build --here ev-here --task "events" --block
expect "events: build review here" "$M" build --review --here ev-here --block
events_ok "events: run task start/step/end" "$SDIR/run-a/events.tsv" 2 builder
events_ok "events: run review start/step/end" "$SDIR/run-a/events.tsv" 2 reviewer
events_ok "events: here start/step/end" "$SDIR/quick/ev-here/events.tsv" - builder
events_ok "events: here review start/step/end" "$SDIR/quick/ev-here/events.tsv" - reviewer
if awk -F'\t' 'NF != 6 || tolower($0) ~ /token/ { bad++ } END { exit bad ? 1 : 0 }' "$SDIR/run-a/events.tsv"; then
  ok "events: six fields, no token fields"
else
  fail "events: six fields, no token fields"
fi
if find "$BOTTEGA_STATE_DIR" -name '*.progress' -print -quit | grep -q .; then
  fail "events: no .progress file"
else
  ok "events: no .progress file"
fi

# `build --status` counts step events, not lines in a .progress file.
EVDIR="$SDIR/quick/ev-status"
mkdir -p "$EVDIR"
printf 'rev=0\nsid=\n' > "$EVDIR/run"
printf '1000\tev-status\t-\tbuilder\tstart\trev=0\n1001\tev-status\t-\tbuilder\tstep\tRead: a.txt\n1002\tev-status\t-\tbuilder\tstep\tBash: ls\n' > "$EVDIR/events.tsv"
out="$("$M" build --status ev-status 2>&1)"
if printf '%s\n' "$out" | grep -q 'Builders 0/1 done · 1 running' \
  && printf '%s\n' "$out" | grep -q 'ev-status: 2 steps, last Bash: ls'; then
  ok "status: steps come from events"
else
  fail "status: steps come from events"
fi
out="$("$M" build --here ev-steps --task "count steps" --block 2>&1)"
printf '%s\n' "$out" | grep -qx 'steps: 1' && ok "status: steps line counts step events" || fail "status: steps line counts step events"

# steps.tsv history: only a rev-0 builder build ending STATUS: DONE appends,
# and the history outlives `report --close`.
history="$SDIR/steps.tsv"
hcount() { if [ -f "$history" ]; then wc -l < "$history" | tr -d ' '; else echo 0; fi; }
before="$(hcount)"
"$M" build --here hist-ok --task "history" --block >/dev/null 2>&1
after="$(hcount)"
if [ "$after" -eq $((before + 1)) ] \
  && awk -F'\t' -v n="$after" 'NR == n { ok = (NF == 5 && $2 == "builder" && $4 + 0 > 0 && $5 + 0 >= 0) } END { exit ok ? 0 : 1 }' "$history"; then
  ok "history: DONE build appends one line"
else
  fail "history: DONE build appends one line"
fi
before="$(hcount)"
STUB_FAIL=1 "$M" build --here hist-fail --task "history fail" --block >/dev/null 2>&1
[ "$(hcount)" -eq "$before" ] && ok "history: failed build appends nothing" || fail "history: failed build appends nothing"
"$M" build --here hist-rev --task "history base" --block >/dev/null 2>&1
before="$(hcount)"
echo 'fix it' | "$M" build --here hist-rev --revise - --block >/dev/null 2>&1
[ "$(hcount)" -eq "$before" ] && ok "history: revision appends nothing" || fail "history: revision appends nothing"
"$M" build --here hist-close --task "history close" --block >/dev/null 2>&1
before="$(hcount)"
"$M" report --close hist-close >/dev/null 2>&1
if [ ! -d "$SDIR/quick/hist-close" ] && [ "$(hcount)" -eq "$before" ]; then
  ok "history: survives report --close"
else
  fail "history: survives report --close"
fi
# Close the light runs this section opened so the hook tests below see a quiet
# state directory (guard stop only blocks while a run is open).
for s in ev-here ev-steps ev-status hist-ok hist-fail hist-rev; do "$M" report --close "$s" >/dev/null 2>&1; done

# `maestro watch --line` (Task 2): one status line from the newest open run.
# Fixtures use fixed event times (BOTTEGA_NOW) and mtimes so the numbers are
# exact. Its own repo and state dir keep the other open runs out of the pick.
LREPO="$TMP/line-repo"
LSTATE="$TMP/line-state"
mkdir -p "$LREPO"
( cd "$LREPO" && git init -q -b main && git commit -q --allow-empty -m init \
  && git checkout -q -b work && BOTTEGA_STATE_DIR="$LSTATE" "$M" start "Line seed" ) >/dev/null 2>&1
LROOT="$(dirname "$(find "$LSTATE" -type d -name line-seed 2>/dev/null | head -1)")"
line() { printf '{"workspace":{"current_dir":"%s"}}' "$1" | BOTTEGA_NOW="${2:-10000}" BOTTEGA_STATE_DIR="$LSTATE" "$M" watch --line; }
mk_line_run() { # <slug> <tasks>
  local slug="$1" n="$2" i=1
  mkdir -p "$LROOT/$slug/tasks" "$LROOT/$slug/build"
  while [ "$i" -le "$n" ]; do : > "$LROOT/$slug/tasks/$i.md"; i=$((i + 1)); done
}
mk_line_run line-4 4
printf 'STATUS: DONE\n' > "$LROOT/line-4/build/1.report.md"
printf 'sid=\n' > "$LROOT/line-4/build/2.run"
printf '9000\tline-4\t1\tbuilder\tstart\trev=0\n9100\tline-4\t1\tbuilder\tstep\tRead: a.txt\n9200\tline-4\t1\tbuilder\tend\trc=0 DONE\n9970\tline-4\t2\tbuilder\tstart\trev=0\n9980\tline-4\t2\tbuilder\tstep\tBash: ls\n9990\tline-4\t2\tbuilder\tstep\tRead: b.txt\n' > "$LROOT/line-4/events.tsv"
out="$(line "$LREPO")"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = '1/4 tasks' ]; then
  ok "line: tasks without samples"
else
  fail "line: tasks without samples"
fi
# Three builder samples for the path of the newest builder sample; other paths
# and the reviewer role do not count.
printf '100\tbuilder\t/some/repo\t10\t120\n200\tbuilder\t/some/repo\t10\t120\n250\tbuilder\t/elsewhere\t50\t600\n300\tbuilder\t/some/repo\t10\t120\n320\treviewer\t/some/repo\t99\t900\n' > "$LROOT/steps.tsv"
out="$(line "$LREPO")"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = '1/4 tasks · ~30% · ETA 6m' ]; then
  ok "line: percent and ETA"
else
  fail "line: percent and ETA"
fi
mk_line_run line-stall 2
printf 'sid=\n' > "$LROOT/line-stall/build/1.run"
printf '9500\tline-stall\t1\tbuilder\tstart\trev=0\n9600\tline-stall\t1\tbuilder\tstep\tBash: ls\n' > "$LROOT/line-stall/events.tsv"
touch -t 209001010000 "$LROOT/line-4/events.tsv"
touch -t 209901010000 "$LROOT/line-stall/events.tsv"
out="$(line "$LREPO")"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = '0/2 tasks · ~5% · ETA 2m · stalled' ]; then
  ok "line: stalled and newest run"
else
  fail "line: stalled and newest run"
fi
: > "$LROOT/line-stall/paused"
out="$(line "$LREPO")"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = '1/4 tasks · ~30% · ETA 6m' ]; then
  ok "line: paused run skipped"
else
  fail "line: paused run skipped"
fi
out="$(printf 'not json' | BOTTEGA_STATE_DIR="$LSTATE" "$M" watch --line 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] && ok "line: bad stdin prints nothing" || fail "line: bad stdin prints nothing"
mkdir -p "$TMP/not-a-repo"
out="$(line "$TMP/not-a-repo" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] && ok "line: outside git prints nothing" || fail "line: outside git prints nothing"
rm -rf "$LROOT/line-4" "$LROOT/line-stall"
out="$(line "$LREPO" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] && ok "line: no run prints nothing" || fail "line: no run prints nothing"

# `maestro watch <run>` (Task 3): a TTY frame, change-only lines in a pipe, and
# the exit rules. Fixed BOTTEGA_NOW and mtimes keep the numbers exact. Its own
# repo and state dir keep the other runs out of the fixture.
WREPO="$TMP/watch-repo"
WSTATE="$TMP/watch-state"
mkdir -p "$WREPO"
( cd "$WREPO" && git init -q -b main && git commit -q --allow-empty -m init \
  && git switch -q -c feat/watch && BOTTEGA_STATE_DIR="$WSTATE" "$M" start "Watch seed" ) >/dev/null 2>&1
# `build --review` runs the check first, so `worktree create` copies a passing
# scripts/check into the task worktree.
mkdir -p "$WREPO/scripts"
printf '#!/usr/bin/env bash\necho ok\n' > "$WREPO/scripts/check"
chmod +x "$WREPO/scripts/check"
WROOT="$(dirname "$(find "$WSTATE" -type d -name watch-seed 2>/dev/null | head -1)")"
mk_watch_run() { # <slug> <tasks>
  local slug="$1" n="$2" i=1
  mkdir -p "$WROOT/$slug/tasks" "$WROOT/$slug/build"
  while [ "$i" -le "$n" ]; do : > "$WROOT/$slug/tasks/$i.md"; i=$((i + 1)); done
}
mk_watch_run watch-4 4
printf 'STATUS: DONE\n' > "$WROOT/watch-4/build/1.report.md"
printf 'sid=\n' > "$WROOT/watch-4/build/2.run"
printf '9000\twatch-4\t1\tbuilder\tstart\trev=0\n9100\twatch-4\t1\tbuilder\tstep\tRead: a.txt\n9200\twatch-4\t1\tbuilder\tend\trc=0 DONE\n9970\twatch-4\t2\tbuilder\tstart\trev=0\n9980\twatch-4\t2\tbuilder\tstep\tBash: ls\n9990\twatch-4\t2\tbuilder\tstep\tRead: b.txt\n' > "$WROOT/watch-4/events.tsv"
printf '100\tbuilder\t/some/repo\t10\t120\n200\tbuilder\t/some/repo\t10\t120\n300\tbuilder\t/some/repo\t10\t120\n' > "$WROOT/steps.tsv"
out="$( cd "$WREPO" && BOTTEGA_NOW=10000 BOTTEGA_WATCH_TTY=1 BOTTEGA_WATCH_ONCE=1 \
  BOTTEGA_STATE_DIR="$WSTATE" "$M" watch watch-4 2>&1 )"; rc=$?
if [ "$rc" -eq 0 ] \
  && printf '%s\n' "$out" | grep -qx 'Watch watch-4: 1/4 tasks · ~30% · ETA 6m (estimate) · elapsed 16m' \
  && printf '%s\n' "$out" | grep -qx '  1  done  1 steps' \
  && printf '%s\n' "$out" | grep -qx '  2  running  2 steps, last Read: b.txt' \
  && [ "$(printf '%s\n' "$out" | grep -c '^  [0-9]')" -eq 4 ]; then
  ok "watch: frame"
else
  fail "watch: frame"
fi
out="$( cd "$WREPO" && BOTTEGA_NOW=10000 BOTTEGA_WATCH_TTY=0 BOTTEGA_WATCH_ONCE=1 \
  BOTTEGA_STATE_DIR="$WSTATE" "$M" watch watch-4 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && [ "$out" = 'progress: 1/4 tasks · ~30% · ETA 6m' ] && ok "watch: non-TTY progress line" || fail "watch: non-TTY progress line"
# A stable running run polls but prints its line only once.
( cd "$WREPO" && exec env BOTTEGA_NOW=10000 BOTTEGA_WATCH_TTY=0 BOTTEGA_WATCH_EVERY=1 \
  BOTTEGA_STATE_DIR="$WSTATE" "$M" watch watch-4 ) > "$TMP/watch-nontty.out" 2>&1 &
watch_pid=$!
sleep 3
kill "$watch_pid" 2>/dev/null
wait "$watch_pid" 2>/dev/null
[ "$(grep -c '^progress:' "$TMP/watch-nontty.out")" -eq 1 ] && ok "watch: non-TTY prints changes only" || fail "watch: non-TTY prints changes only"
mk_watch_run watch-done 1
printf 'STATUS: DONE\n' > "$WROOT/watch-done/build/1.report.md"
out="$( cd "$WREPO" && BOTTEGA_WATCH_TTY=0 BOTTEGA_STATE_DIR="$WSTATE" "$M" watch watch-done 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^progress: 1/1 tasks' && ok "watch: done exits 0" || fail "watch: done exits 0"
mk_watch_run watch-hold 2
( cd "$WREPO" && BOTTEGA_STATE_DIR="$WSTATE" "$M" hold watch-hold "human needed" ) >/dev/null 2>&1
out="$( cd "$WREPO" && BOTTEGA_WATCH_TTY=0 BOTTEGA_WATCH_ONCE=1 \
  BOTTEGA_STATE_DIR="$WSTATE" "$M" watch watch-hold 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && [ "$out" = 'HOLD: human needed' ] && ok "watch: hold exits 0" || fail "watch: hold exits 0"
out="$( cd "$WREPO" && BOTTEGA_STATE_DIR="$WSTATE" "$M" watch no-such-watch 2>&1 )"; rc=$?
[ "$rc" -eq 2 ] && ok "watch: unknown run exits 2" || fail "watch: unknown run exits 2"
rm -rf "$WROOT/watch-4" "$WROOT/watch-done" "$WROOT/watch-hold"

# Every headless build flavour prints `progress:` lines while it waits (Task 3).
# Its own state dir keeps the counts to one task; the final summary is unchanged.
( cd "$WREPO" && BOTTEGA_STATE_DIR="$WSTATE" "$M" start "Progress run" ) >/dev/null 2>&1
printf '# Spec\n## Acceptance criteria\n- AC1: works. Proof: `true` -> exit 0\n### Task 1 - one\nbody\n**Allowed files:** `allowed.txt`\n' > "$TMP/progress-spec.md"
( cd "$WREPO" && BOTTEGA_STATE_DIR="$WSTATE" "$M" spec progress-run "$TMP/progress-spec.md" ) >/dev/null 2>&1
( cd "$WREPO" && BOTTEGA_STATE_DIR="$WSTATE" "$M" worktree create progress-run 1 ) >/dev/null 2>&1
out="$( cd "$WREPO" && STUB_COMMIT=allowed.txt BOTTEGA_STATE_DIR="$WSTATE" "$M" build progress-run 1 --block 2>&1 )"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^progress: 1/1 tasks' \
  && printf '%s\n' "$out" | grep -qx 'task: 1' \
  && printf '%s\n' "$out" | grep -q '^steps: ' \
  && printf '%s\n' "$out" | grep -q '^report: '; then
  ok "build progress: run task"
else
  fail "build progress: run task"
fi
out="$( cd "$WREPO" && BOTTEGA_STATE_DIR="$WSTATE" "$M" build --review progress-run 1 --block 2>&1 )"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^progress: 1/1 tasks' \
  && printf '%s\n' "$out" | grep -qx 'review: progress-run 1' \
  && printf '%s\n' "$out" | grep -q '^steps: '; then
  ok "build progress: review"
else
  fail "build progress: review"
fi
out="$( cd "$WREPO" && BOTTEGA_STATE_DIR="$WSTATE" "$M" build --here prog-here --task "progress" --block 2>&1 )"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^progress: 1/1 tasks' \
  && printf '%s\n' "$out" | grep -qx 'task: prog-here' \
  && printf '%s\n' "$out" | grep -q '^steps: '; then
  ok "build progress: here"
else
  fail "build progress: here"
fi
out="$( cd "$WREPO" && BOTTEGA_STATE_DIR="$WSTATE" "$M" build --review --here prog-here --block 2>&1 )"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^progress: 1/1 tasks' \
  && printf '%s\n' "$out" | grep -q '^review: prog-here' \
  && printf '%s\n' "$out" | grep -q '^steps: '; then
  ok "build progress: review here"
else
  fail "build progress: review here"
fi

# `maestro verify-task` (Task 4): the five acceptance rules and the HEAD-bound
# waiver. Its own repo and state dir, no stub: the task worktrees are committed
# directly and the report and the check record are written where the command
# reads them. Each broken-rule task breaks exactly one rule.
VREPO="$TMP/verify-repo"
VSTATE="$TMP/verify-state"
mkdir -p "$VREPO/scripts" "$VREPO/.claude"
( cd "$VREPO" \
  && git init -q -b main && git commit -q --allow-empty -m init \
  && git switch -q -c feat/verify \
  && printf '#!/usr/bin/env bash\necho ok\n' > scripts/check && chmod +x scripts/check \
  && printf '# Agents\n' > AGENTS.md && printf '{}\n' > .claude/settings.json \
  && git add scripts/check AGENTS.md .claude/settings.json && git commit -q -m setup \
  && BOTTEGA_STATE_DIR="$VSTATE" "$M" start "Verify run" ) >/dev/null 2>&1
VRUN="verify-run"
VDIR="$(find "$VSTATE" -type d -name "$VRUN" | head -1)"
VWTS="$TMP/verify-repo-bottega/$VRUN"
cat > "$TMP/verify-spec.md" <<'EOF'
# Spec
## Acceptance criteria
- AC1: works. Proof: `true` -> exit 0
### Task 1 - clean
**Allowed files:** `src/app.sh`, `tests/app_test.sh`
**Test first:** tests/app_test.sh
body
### Task 2 - report broken
**Allowed files:** `src/app.sh`
**Test first:** none
body
### Task 3 - commits broken
**Allowed files:** `src/app.sh`
**Test first:** none
body
### Task 4 - test first broken
**Allowed files:** `src/app.sh`, `tests/app_test.sh`
**Test first:** tests/app_test.sh
body
### Task 5 - allowed files broken
**Allowed files:** `src/app.sh`
**Test first:** none
body
### Task 6 - check broken
**Allowed files:** `src/app.sh`
**Test first:** none
body
### Task 7 - several broken
**Allowed files:** `src/app.sh`
**Test first:** none
body
### Task 8 - test first none
**Allowed files:** `src/app.sh`
**Test first:** none
body
### Task 9 - test file named in Test first
**Allowed files:** `src/app.sh`, `scripts/t.sh`
**Test first:** scripts/t.sh
body
EOF
( cd "$VREPO" && BOTTEGA_STATE_DIR="$VSTATE" "$M" spec "$VRUN" "$TMP/verify-spec.md" ) >/dev/null 2>&1
for vt in 1 2 3 4 5 6 7 8 9; do
  ( cd "$VREPO" && BOTTEGA_STATE_DIR="$VSTATE" "$M" worktree create "$VRUN" "$vt" ) >/dev/null 2>&1
done
vcommit() { # <task> <message> <path>...
  local vt="$1" msg="$2" p
  shift 2
  for p in "$@"; do
    mkdir -p "$(dirname "$VWTS/$vt/$p")"
    printf 'v %s\n' "$vt" > "$VWTS/$vt/$p"
  done
  ( cd "$VWTS/$vt" && git add "$@" && git commit -q -m "$msg (task $vt)" )
}
vreport() { mkdir -p "$VDIR/build"; printf 'STATUS: %s\n' "$2" > "$VDIR/build/$1.report.md"; }
vcheck() { ( cd "$VWTS/$1" && BOTTEGA_STATE_DIR="$VSTATE" "$M" check "$VRUN" ) >/dev/null 2>&1; }
vverify() { ( cd "$VREPO" && BOTTEGA_STATE_DIR="$VSTATE" "$M" verify-task "$VRUN" "$@" 2>&1 ); }

vcommit 1 "test first" tests/app_test.sh
vcommit 1 "implementation" src/app.sh
vreport 1 DONE
vcheck 1
vcommit 2 "implementation" src/app.sh
vcheck 2
vreport 3 DONE
vcheck 3
vcommit 4 "implementation first" src/app.sh
vcommit 4 "test after" tests/app_test.sh
vreport 4 DONE
vcheck 4
vcommit 5 "outside allowed files" src/other.sh
vreport 5 DONE
vcheck 5
vcommit 6 "implementation" src/app.sh
vreport 6 DONE
vcommit 7 "outside allowed files" src/other.sh
vreport 7 BLOCKED
vcommit 8 "implementation" src/app.sh
vreport 8 DONE
vcheck 8
vcommit 9 "test first" scripts/t.sh
vcommit 9 "implementation" src/app.sh
vreport 9 DONE
vcheck 9

out="$(vverify 1)"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = 'verify-task: PASS' ]; then
  ok "verify-task passes a clean task"
else
  fail "verify-task passes a clean task"
fi
# One rule broken alone: exit 1 and exactly one FAIL line for that rule.
for vpair in report:2 commits:3 test-first:4 allowed-files:5 check:6; do
  vrule="${vpair%%:*}"
  vtask="${vpair##*:}"
  out="$(vverify "$vtask")"; rc=$?
  vone="$(printf '%s\n' "$out" | grep -c "^FAIL $vrule:")"
  vtotal="$(printf '%s\n' "$out" | grep -c '^FAIL ')"
  if [ "$rc" -eq 1 ] && [ "$vone" -eq 1 ] && [ "$vtotal" -eq 1 ]; then
    ok "verify-task fails: $vrule"
  else
    fail "verify-task fails: $vrule"
  fi
done
# Several broken rules: one FAIL line per broken rule and nothing else on stdout.
out="$(vverify 7)"; rc=$?
if [ "$rc" -eq 1 ] \
  && [ "$(printf '%s\n' "$out" | grep -c '^FAIL report:')" -eq 1 ] \
  && [ "$(printf '%s\n' "$out" | grep -c '^FAIL allowed-files:')" -eq 1 ] \
  && [ "$(printf '%s\n' "$out" | grep -c '^FAIL check:')" -eq 1 ] \
  && [ "$(printf '%s\n' "$out" | grep -c '^FAIL ')" -eq 3 ] \
  && [ "$(printf '%s\n' "$out" | grep -vc '^FAIL ')" -eq 0 ]; then
  ok "verify-task prints one line per failed rule"
else
  fail "verify-task prints one line per failed rule"
fi
# `Test first: none` skips the rule: an implementation-only first commit passes.
out="$(vverify 8)"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = 'verify-task: PASS' ]; then
  ok "verify-task test-first skipped for none"
else
  fail "verify-task test-first skipped for none"
fi
# A test path that `is_test_path` does not match still counts when the task's
# `Test first:` names it.
out="$(vverify 9)"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = 'verify-task: PASS' ]; then
  ok "verify-task test-first counts files named in Test first"
else
  fail "verify-task test-first counts files named in Test first"
fi
# The waiver is bound to the worktree HEAD: empty reason exits 2 and records
# nothing, a recorded waiver hides the failures, and a new commit drops it.
vwaiver="$VDIR/build/7.verify-waiver"
waiver_ok=1
out="$(vverify 7 --waive "")"; rc=$?
[ "$rc" -eq 2 ] && [ ! -e "$vwaiver" ] || waiver_ok=0
out="$(vverify 7 --waive "user approved")"; rc=$?
[ "$rc" -eq 0 ] && [ -f "$vwaiver" ] || waiver_ok=0
out="$(vverify 7)"; rc=$?
if [ "$rc" -ne 0 ] || ! printf '%s\n' "$out" | grep -qx 'verify-task: WAIVED (user approved)' \
  || ! printf '%s\n' "$out" | grep -q '^FAIL '; then
  waiver_ok=0
fi
( cd "$VWTS/7" && git commit -q --allow-empty -m "after waiver" )
out="$(vverify 7)"; rc=$?
if [ "$rc" -ne 1 ] || printf '%s\n' "$out" | grep -q 'verify-task: WAIVED'; then
  waiver_ok=0
fi
[ "$waiver_ok" -eq 1 ] && ok "verify-task waiver holds for its HEAD only" || fail "verify-task waiver holds for its HEAD only"
# Bad run and task ids exit 2 before anything is written.
vstate_before="$(cd "$VSTATE" && find . -print | LC_ALL=C sort)"
vverify '../x' 1 >/dev/null 2>&1; vrc_a=$?
vverify 'run-a' '../x' >/dev/null 2>&1; vrc_b=$?
vstate_after="$(cd "$VSTATE" && find . -print | LC_ALL=C sort)"
if [ "$vrc_a" -eq 2 ] && [ "$vrc_b" -eq 2 ] && [ "$vstate_before" = "$vstate_after" ]; then
  ok "verify-task rejects bad ids"
else
  fail "verify-task rejects bad ids"
fi

# Hooks.
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TodoWrite","input":{"todos":[{"content":"Step 3","status":"pending","activeForm":"x"}]}}]}}' > "$TMP/t.jsonl"
hook_in="{\"transcript_path\":\"$TMP/t.jsonl\",\"stop_hook_active\":false}"
echo "$hook_in" | "$M" guard stop | grep -q '"block"' && ok "stop hook blocks with an open run" || fail "stop hook blocks with an open run"
echo '{"tool_input":{"subagent_type":"bottega:builder"}}' | "$M" guard builder | grep -q deny && ok "builder guard (namespaced)" || fail "builder guard (namespaced)"
echo '{"tool_input":{"subagent_type":"bottega:builder","model":"opus","effort":"high"}}' | "$M" guard builder | grep -q 'headless builder is configured' && ok "builder guard: headless denial kept" || fail "builder guard: headless denial kept"
echo '{"tool_input":{"subagent_type":"bottega:explorer","model":"haiku","effort":"low"}}' | "$M" guard builder | grep -q deny && fail "guard ignores other agents" || ok "guard ignores other agents"
# Every bottega agent call must name both model and effort; anything else is a
# routing mistake the hook refuses. Non-bottega agents and unreadable input pass.
echo '{"tool_input":{"subagent_type":"bottega:planner","effort":"high"}}' | "$M" guard builder | grep -q deny && ok "agent guard: missing model denied" || fail "agent guard: missing model denied"
echo '{"tool_input":{"subagent_type":"bottega:planner","model":"opus"}}' | "$M" guard builder | grep -q deny && ok "agent guard: missing effort denied" || fail "agent guard: missing effort denied"
echo '{"tool_input":{"subagent_type":"bottega:planner","model":"","effort":"high"}}' | "$M" guard builder | grep -q deny && ok "agent guard: empty model denied" || fail "agent guard: empty model denied"
echo '{"tool_input":{"subagent_type":"bottega:planner","model":"opus","effort":"high"}}' | "$M" guard builder | grep -q deny && fail "agent guard: model and effort allowed" || ok "agent guard: model and effort allowed"
echo 'not json' | "$M" guard builder | grep -q deny && fail "agent guard: bad json fails open" || ok "agent guard: bad json fails open"
echo '{"tool_input":{"subagent_type":"general-purpose"}}' | "$M" guard builder | grep -q deny && fail "agent guard: ignores non-bottega agents" || ok "agent guard: ignores non-bottega agents"

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

# Uppercase run ids are invalid under any collation; a Bash 3.2 [a-z] range
# can match them, so hold, resume, and build --here are checked under a UTF-8
# locale too. A rejected slug writes no state (issue #27 CI).
LOCSTATE="$TMP/locale-hold-state"
out="$(BOTTEGA_STATE_DIR="$LOCSTATE" locale_run "$M" hold Foo r 2>"$TMP/locale-hold.err")"; rc=$?
if [ "$rc" -eq 2 ] && [ -z "$out" ] \
  && grep -qxF 'maestro hold: bad run id: Foo' "$TMP/locale-hold.err" \
  && [ ! -e "$LOCSTATE" ]; then
  ok "hold rejects an uppercase run id under a UTF-8 locale"
else
  fail "hold rejects an uppercase run id under a UTF-8 locale"
fi
LOCSTATE2="$TMP/locale-resume-state"
out="$(BOTTEGA_STATE_DIR="$LOCSTATE2" locale_run "$M" resume Foo 2>"$TMP/locale-resume.err")"; rc=$?
if [ "$rc" -eq 2 ] && [ -z "$out" ] \
  && grep -qxF 'maestro resume: bad run id: Foo' "$TMP/locale-resume.err" \
  && [ ! -e "$LOCSTATE2" ]; then
  ok "resume rejects an uppercase run id under a UTF-8 locale"
else
  fail "resume rejects an uppercase run id under a UTF-8 locale"
fi
LBSTATE="$TMP/locale-build-state"
out="$(BOTTEGA_STATE_DIR="$LBSTATE" locale_run "$M" build --here Foo --task x 2>"$TMP/locale-build.err")"; rc=$?
if [ "$rc" -eq 2 ] && [ -z "$out" ] \
  && grep -qxF 'maestro build --here: slug must be lowercase letters, digits, and hyphens: Foo' "$TMP/locale-build.err" \
  && [ ! -e "$LBSTATE" ]; then
  ok "build --here rejects an uppercase slug under a UTF-8 locale"
else
  fail "build --here rejects an uppercase slug under a UTF-8 locale"
fi

# Every run-taking command shares one run-id check (issue #37): a malformed or
# traversal-style id is refused with `bad run id`, exit 2, before the command
# resolves or writes anything.
RUNID_STATE="$TMP/run-id-state"
mkdir -p "$RUNID_STATE"
runid_snapshot() {
  {
    [ -d "$RUNID_STATE" ] && find "$RUNID_STATE" | LC_ALL=C sort
    [ -d "$TMP/repo-bottega" ] && find "$TMP/repo-bottega" | LC_ALL=C sort
  } 2>/dev/null
  return 0
}
runid_check() {
  local label="$1" id="$2" rc
  shift 2
  BOTTEGA_STATE_DIR="$RUNID_STATE" BOTTEGA_WATCH_ONCE=1 "$M" "$@" >/dev/null 2>"$TMP/run-id.err"
  rc=$?
  if [ "$rc" -eq 2 ] && grep -q 'bad run id' "$TMP/run-id.err"; then
    return 0
  fi
  echo "FAIL run id $label $id"
  runid_fails=$((runid_fails + 1))
}
runid_before="$(runid_snapshot)"
runid_fails=0
for runid in '..' 'a/b' '' '-x'; do
  runid_check spec "$runid" spec "$runid"
  runid_check check "$runid" check "$runid"
  runid_check gate "$runid" gate "$runid"
  runid_check "verify list" "$runid" verify list "$runid"
  runid_check log "$runid" log "$runid"
  runid_check hold "$runid" hold "$runid" reason
  runid_check resume "$runid" resume "$runid"
  runid_check build "$runid" build "$runid" 1
  runid_check "build --here" "$runid" build --here "$runid" --task x
  runid_check "build --review" "$runid" build --review "$runid" 1
  runid_check "build --status" "$runid" build --status "$runid"
  runid_check watch "$runid" watch "$runid"
  runid_check "worktree create" "$runid" worktree create "$runid" 1
  runid_check "worktree prune" "$runid" worktree prune "$runid"
  runid_check "report --close" "$runid" report --close "$runid"
  runid_check "report --finding" "$runid" report --finding "$runid" title
done
runid_after="$(runid_snapshot)"
[ "$runid_before" = "$runid_after" ] && ok "bad run ids write nothing" || fail "bad run ids write nothing"
[ "$runid_fails" -eq 0 ] && ok "run id rejected everywhere" || fail "run id rejected everywhere"

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

# Stop-hook evidence (AC10): with every todo complete, an open run must record a
# passing check and, when the SPEC has Proof criteria, a PASS/WAIVED row per
# criterion plus a reviewer/second-opinion row. Each reason names the command
# that records the evidence. An isolated state dir keeps other runs out.
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TodoWrite","input":{"todos":[{"content":"Step 1","status":"completed","activeForm":"x"}]}}]}}' > "$TMP/t-done.jsonl"
hook_done="{\"transcript_path\":\"$TMP/t-done.jsonl\",\"stop_hook_active\":false}"
ESTATE="$TMP/evidence-state"
ev_out="$(BOTTEGA_STATE_DIR="$ESTATE" "$M" start "Evidence run" 2>&1)"; rc=$?
ev_slug="$(printf '%s\n' "$ev_out" | sed -n 's/^run: //p')"
[ "$rc" -eq 0 ] && [ -n "$ev_slug" ] && ok "stop evidence: start fixture" || fail "stop evidence: start fixture"
out="$(echo "$hook_done" | BOTTEGA_STATE_DIR="$ESTATE" "$M" guard stop 2>&1)"
if printf '%s\n' "$out" | grep -q '"block"' && printf '%s\n' "$out" | grep -qF "maestro check $ev_slug"; then
  ok "stop evidence: no check blocks"
else
  fail "stop evidence: no check blocks"
fi
BOTTEGA_STATE_DIR="$ESTATE" "$M" check "$ev_slug" >/dev/null 2>&1
out="$(echo "$hook_done" | BOTTEGA_STATE_DIR="$ESTATE" "$M" guard stop 2>&1)"
[ -z "$out" ] && ok "stop evidence: silent with a passing check" || fail "stop evidence: silent with a passing check"
cat > "$TMP/evidence-spec.md" <<'EOF'
## Acceptance criteria
- AC1: the run works. Proof: `true` -> ok.
EOF
BOTTEGA_STATE_DIR="$ESTATE" "$M" spec "$ev_slug" "$TMP/evidence-spec.md" >/dev/null 2>&1
out="$(echo "$hook_done" | BOTTEGA_STATE_DIR="$ESTATE" "$M" guard stop 2>&1)"
if printf '%s\n' "$out" | grep -q '"block"' && printf '%s\n' "$out" | grep -qF "maestro verify record $ev_slug AC1"; then
  ok "stop evidence: no proof blocks"
else
  fail "stop evidence: no proof blocks"
fi
printf 'true\n' > "$TMP/evidence.txt"
BOTTEGA_STATE_DIR="$ESTATE" "$M" verify record "$ev_slug" AC1 PASS --by master --evidence "$TMP/evidence.txt" >/dev/null 2>&1
out="$(echo "$hook_done" | BOTTEGA_STATE_DIR="$ESTATE" "$M" guard stop 2>&1)"
if printf '%s\n' "$out" | grep -q '"block"' && printf '%s\n' "$out" | grep -q 'reviewer or second-opinion'; then
  ok "stop evidence: no review blocks"
else
  fail "stop evidence: no review blocks"
fi
BOTTEGA_STATE_DIR="$ESTATE" "$M" verify record "$ev_slug" AC1 PASS --by reviewer --evidence "$TMP/evidence.txt" >/dev/null 2>&1
out="$(echo "$hook_done" | BOTTEGA_STATE_DIR="$ESTATE" "$M" guard stop 2>&1)"
[ -z "$out" ] && ok "stop evidence: silent with evidence" || fail "stop evidence: silent with evidence"
out="$(echo "{\"transcript_path\":\"$TMP/t-done.jsonl\",\"stop_hook_active\":true}" | BOTTEGA_STATE_DIR="$ESTATE" "$M" guard stop 2>&1)"
[ -z "$out" ] && ok "stop evidence: stop_hook_active is silent" || fail "stop evidence: stop_hook_active is silent"

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

# session-handoff writes the handoff to ${BOTTEGA_HANDOFF_DIR:-/tmp}; the master
# prompt must name the same location or the next session looks elsewhere.
HB="$TMP/handofflint"
mkdir -p "$HB/scripts" "$HB/agents" "$HB/skills/workflow/session-handoff"
cp "$ROOT/scripts/lint.sh" "$HB/scripts/lint.sh"
cp "$ROOT/agents/master.md" "$HB/agents/master.md"
cp "$ROOT/skills/workflow/session-handoff/SKILL.md" "$HB/skills/workflow/session-handoff/SKILL.md"
sed 's/BOTTEGA_HANDOFF_DIR/HANDOFF_DIR_ENV/g' "$HB/agents/master.md" > "$HB/agents/master.md.tmp"
mv "$HB/agents/master.md.tmp" "$HB/agents/master.md"
lint_drift() {
  ( cd "$HB" && bash scripts/lint.sh 2>&1 ) | grep -q '^FAIL session-handoff and agents/master.md disagree on the handoff path'
}
if lint_drift; then ok "lint rejects handoff skill/master drift"; else fail "lint rejects handoff skill/master drift"; fi
cp "$ROOT/agents/master.md" "$HB/agents/master.md"
if lint_drift; then fail "lint accepts matching handoff paths"; else ok "lint accepts matching handoff paths"; fi

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

# An installed copy keeps the source directory's mode: the staging dir made by
# mktemp -d is 0700, so a fix must set it back before the move. Compare the
# first column of `ls -ld` so the check works the same on macOS and Linux.
rm -rf "$SKILLS/skills"
skill_cmd install teach >/dev/null 2>&1
src_mode="$(ls -ld "$ROOT/skills/workflow/teach" | awk '{print $1}')"
inst_mode="$(ls -ld "$SKILLS/skills/teach" | awk '{print $1}')"
if [ -n "$src_mode" ] && [ "$inst_mode" = "$src_mode" ]; then
  ok "skills install keeps the source dir mode"
else
  fail "skills install keeps the source dir mode"
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
# The same uppercase name under a locale-sensitive collation (issue #27 CI).
rm -rf "$SKILLS/skills"
locale_run skill_cmd install Teach >/dev/null 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 1 ] && grep -qxF 'maestro skills: invalid skill name: Teach' "$TMP/skills.err" \
  && [ -z "$(ls -A "$SKILLS")" ]; then
  ok "skills install rejects uppercase under a UTF-8 locale"
else
  fail "skills install rejects uppercase under a UTF-8 locale"
fi
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
# The same uppercase name under a locale-sensitive collation: it is refused
# before any managed copy is removed (issue #27 CI).
rm -rf "$SKILLS/skills"
skill_cmd install how >/dev/null 2>&1
locale_run skill_cmd uninstall Teach >/dev/null 2>"$TMP/skills.err"; rc=$?
if [ "$rc" -eq 1 ] && grep -qxF 'maestro skills: invalid skill name: Teach' "$TMP/skills.err" \
  && [ -f "$SKILLS/skills/how/.bottega-managed" ]; then
  ok "skills uninstall rejects uppercase under a UTF-8 locale"
else
  fail "skills uninstall rejects uppercase under a UTF-8 locale"
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

# No CLAUDE_CONFIG_DIR and no HOME means there is no Claude config dir: every
# skills subcommand must name that once and exit 1 before it creates anything.
# A mkdir shim records any write attempt, so the test never reaches /skills
# even when it runs as root.
NOMKDIR="$TMP/no-mkdir"
mkdir -p "$NOMKDIR"
cat > "$NOMKDIR/mkdir" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$MKDIRLOG"
exit 1
EOF
chmod +x "$NOMKDIR/mkdir"
SKNOCFG="$TMP/skills-nocfg"
skills_nocfg() {
  local sub="$1" err="$TMP/skills-nocfg.err" rc
  shift
  rm -rf "$SKNOCFG" "$TMP/skills-nocfg.mkdir"
  mkdir -p "$SKNOCFG"
  ( cd "$SKNOCFG" && env -u HOME -u CLAUDE_CONFIG_DIR \
    PATH="$NOMKDIR:$PATH" MKDIRLOG="$TMP/skills-nocfg.mkdir" \
    "$M" skills "$sub" "$@" ) >/dev/null 2>"$err"
  rc=$?
  if [ "$rc" -eq 1 ] \
    && [ "$(grep -cxF 'maestro skills: cannot find the Claude config dir; set CLAUDE_CONFIG_DIR or HOME' "$err")" -eq 1 ] \
    && [ ! -e "$TMP/skills-nocfg.mkdir" ] \
    && [ -z "$(ls -A "$SKNOCFG")" ]; then
    ok "skills $sub fails without a config dir"
  else
    fail "skills $sub fails without a config dir"
  fi
}
skills_nocfg list
skills_nocfg install teach
skills_nocfg uninstall teach

# Tool hint (SessionStart): silent when tools exist or when silenced.
mkdir -p "$TMP/notools" && ln -sf "$(command -v git)" "$TMP/notools/git"
PATH="$TMP/notools:/usr/bin:/bin" "$M" tools hint | grep -q "maestro tools install" && ok "tool hint when missing" || fail "tool hint when missing"
[ -z "$(BOTTEGA_NO_TOOL_HINT=1 "$M" tools hint)" ] && ok "tool hint silenced" || fail "tool hint silenced"
printf '#!/bin/sh\n' > "$TMP/bin/rtk"; cp "$TMP/bin/rtk" "$TMP/bin/gitleaks"; chmod +x "$TMP/bin/rtk" "$TMP/bin/gitleaks"
[ -z "$("$M" tools hint)" ] && ok "tool hint silent when installed" || fail "tool hint silent when installed"
# A host directory holding a `maestro` must not leak into the hint:
# prepend a fixture copy and the hint still says nothing, because the e2e PATH
# drops every other copy. Leftover host copies would make this two and warn.
HOSTMAESTRO="$TMP/host-maestro"
mkdir -p "$HOSTMAESTRO"
printf '#!/bin/sh\nexit 0\n' > "$HOSTMAESTRO/maestro"
chmod +x "$HOSTMAESTRO/maestro"
[ -z "$(PATH="$HOSTMAESTRO:$PATH" "$M" tools hint)" ] && ok "tool hint silent when installed with a host maestro copy" || fail "tool hint silent when installed with a host maestro copy"
"$M" tools install | grep -q "already installed" && ok "tools install no-op" || fail "tools install no-op"
rm -f "$TMP/bin/rtk" "$TMP/bin/gitleaks"

# Status line (AC9-AC11): one settings reader drives the SessionStart hint and
# `maestro statusline`. Each fixture is its own scratch CLAUDE_CONFIG_DIR.
SL="$TMP/statusline"
mkdir -p "$SL"
sl_fixture() {  # sl_fixture <name> [json]
  mkdir -p "$SL/$1"
  [ "$#" -gt 1 ] && printf '%s\n' "$2" > "$SL/$1/settings.json"
  return 0
}
sl_hint_count() {
  CLAUDE_CONFIG_DIR="$SL/$1" "$M" tools hint 2>/dev/null \
    | grep -oF 'Status line not set up. Run: maestro statusline install' | wc -l | tr -d ' '
}
sl_hint_case() {  # sl_hint_case <name> <hint|silent>
  local n
  n="$(sl_hint_count "$1")"
  if [ "$2" = hint ]; then
    [ "$n" = 1 ] && ok "statusline hint $1" || fail "statusline hint $1"
  else
    [ "$n" = 0 ] && ok "statusline hint $1" || fail "statusline hint $1"
  fi
}
sl_fixture missing
sl_fixture empty '{}'
sl_fixture nori '{"statusLine":{"type":"command","command":"maestro watch --line"}}'
sl_fixture complete '{"statusLine":{"type":"command","command":"maestro watch --line","refreshInterval":10}}'
sl_fixture custom '{"statusLine":{"type":"command","command":"/opt/custom/status","refreshInterval":10}}'
sl_fixture invalid '{"statusLine":'
sl_hint_case missing hint
sl_hint_case empty hint
sl_hint_case nori hint
sl_hint_case complete silent
sl_hint_case custom silent
sl_hint_case invalid silent
# Without a working python3 the reader fails and the hint stays silent.
mkdir -p "$TMP/badpy"
printf '#!/bin/sh\nexit 1\n' > "$TMP/badpy/python3"
chmod +x "$TMP/badpy/python3"
out="$(PATH="$TMP/badpy:$PATH" CLAUDE_CONFIG_DIR="$SL/missing" "$M" tools hint 2>/dev/null)"
printf '%s\n' "$out" | grep -qF 'Status line not set up' && fail "statusline hint without python3" || ok "statusline hint without python3"
[ -z "$(BOTTEGA_NO_TOOL_HINT=1 CLAUDE_CONFIG_DIR="$SL/missing" "$M" tools hint 2>/dev/null)" ] \
  && ok "statusline hint silenced" || fail "statusline hint silenced"

# `statusline install`: plan first, apply only on y/--yes, never clobber.
sl_fixture install-empty
out="$(printf 'n\n' | CLAUDE_CONFIG_DIR="$SL/install-empty" "$M" statusline install 2>/dev/null)"; rc=$?
if [ "$rc" -ne 0 ] && [ -z "$(ls -A "$SL/install-empty")" ] \
  && printf '%s' "$out" | grep -q '"refreshInterval": 10'; then
  ok "statusline install prompts and writes nothing on n"
else
  fail "statusline install prompts and writes nothing on n"
fi
out="$(CLAUDE_CONFIG_DIR="$SL/install-empty" "$M" statusline install </dev/null 2>/dev/null)"; rc=$?
if [ "$rc" -ne 0 ] && [ -z "$(ls -A "$SL/install-empty")" ]; then
  ok "statusline install writes nothing on EOF"
else
  fail "statusline install writes nothing on EOF"
fi

sl_fixture install-yes '{"theme":"dark"}'
out="$(CLAUDE_CONFIG_DIR="$SL/install-yes" "$M" statusline install --yes </dev/null 2>/dev/null)"; rc=$?
sl_script="$SL/install-yes/statusline.sh"
got=""
[ "$rc" -eq 0 ] && got="$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
s=d["statusLine"]
print(d.get("theme"), s.get("type"), s.get("command"), s.get("refreshInterval"))' "$SL/install-yes/settings.json" 2>/dev/null)"
if [ "$got" = "dark command $sl_script 10" ]; then
  ok "statusline install merges the managed command"
else
  fail "statusline install merges the managed command"
fi
if printf '%s' "$out" | python3 -c 'import json,sys
d=json.load(sys.stdin)
sys.exit(0 if d == {"statusLine": {"type": "command", "command": sys.argv[1], "refreshInterval": 10}} else 1)' "$sl_script" 2>/dev/null; then
  ok "statusline install prints the exact JSON"
else
  fail "statusline install prints the exact JSON"
fi
if [ -x "$sl_script" ] && grep -qx '# bottega-managed statusline' "$sl_script" \
  && grep -qF "$M" "$sl_script" && grep -qF 'watch --line' "$sl_script" \
  && [ "$(ls -ld "$sl_script" | cut -c1-10)" = "-rwx------" ]; then
  ok "statusline install writes the managed script mode 700"
else
  fail "statusline install writes the managed script mode 700"
fi
n="$(ls "$SL/install-yes"/settings.json.bak.* 2>/dev/null | wc -l | tr -d ' ')"
ls "$SL/install-yes"/settings.json.bak.* 2>/dev/null | grep -qE 'settings\.json\.bak\.[0-9]+$' || n=0
[ "$n" = 1 ] && ok "statusline install backs up the settings once" || fail "statusline install backs up the settings once"

sl_fixture install-custom '{"statusLine":{"type":"command","command":"/opt/keep/me"},"keep":true}'
CLAUDE_CONFIG_DIR="$SL/install-custom" "$M" statusline install --yes </dev/null >/dev/null 2>&1
got="$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
s=d["statusLine"]
print(s.get("command"), s.get("refreshInterval"), d.get("keep"))' "$SL/install-custom/settings.json" 2>/dev/null)"
[ "$got" = "/opt/keep/me 10 True" ] && ok "statusline install keeps a custom command" || fail "statusline install keeps a custom command"

sl_fixture install-invalid '{"statusLine":'
before="$(cat "$SL/install-invalid/settings.json")"
CLAUDE_CONFIG_DIR="$SL/install-invalid" "$M" statusline install --yes </dev/null >/dev/null 2>&1; rc=$?
if [ "$rc" -ne 0 ] && [ "$before" = "$(cat "$SL/install-invalid/settings.json")" ] \
  && [ ! -e "$SL/install-invalid/statusline.sh" ] \
  && [ -z "$(ls "$SL/install-invalid"/settings.json.bak.* 2>/dev/null)" ]; then
  ok "statusline install refuses invalid JSON"
else
  fail "statusline install refuses invalid JSON"
fi

sl_fixture install-unmanaged
printf '#!/bin/sh\necho mine\n' > "$SL/install-unmanaged/statusline.sh"
chmod 755 "$SL/install-unmanaged/statusline.sh"
CLAUDE_CONFIG_DIR="$SL/install-unmanaged" "$M" statusline install --yes </dev/null >/dev/null 2>&1; rc=$?
if [ "$rc" -ne 0 ] && grep -qx 'echo mine' "$SL/install-unmanaged/statusline.sh" \
  && [ ! -e "$SL/install-unmanaged/settings.json" ]; then
  ok "statusline install refuses an unmanaged script"
else
  fail "statusline install refuses an unmanaged script"
fi

sl_before="$(cksum "$SL/install-yes/settings.json") $(cksum "$sl_script")"
sl_baks="$(ls "$SL/install-yes"/settings.json.bak.* 2>/dev/null | wc -l | tr -d ' ')"
out="$(CLAUDE_CONFIG_DIR="$SL/install-yes" "$M" statusline install --yes </dev/null 2>/dev/null)"
if printf '%s\n' "$out" | grep -qx 'statusline: already installed' \
  && [ "$sl_before" = "$(cksum "$SL/install-yes/settings.json") $(cksum "$sl_script")" ] \
  && [ "$sl_baks" = "$(ls "$SL/install-yes"/settings.json.bak.* 2>/dev/null | wc -l | tr -d ' ')" ]; then
  ok "statusline install is idempotent"
else
  fail "statusline install is idempotent"
fi

sl_fixture install-mode '{"statusLine":{"type":"command","command":"/opt/x"}}'
chmod 640 "$SL/install-mode/settings.json"
CLAUDE_CONFIG_DIR="$SL/install-mode" "$M" statusline install --yes </dev/null >/dev/null 2>&1
sl_bak="$(ls "$SL/install-mode"/settings.json.bak.* 2>/dev/null | head -1)"
if [ "$(ls -l "$SL/install-mode/settings.json" | cut -c1-10)" = "-rw-r-----" ] \
  && [ -n "$sl_bak" ] && [ "$(ls -l "$sl_bak" | cut -c1-10)" = "-rw-r-----" ]; then
  ok "statusline install preserves the settings mode"
else
  fail "statusline install preserves the settings mode"
fi

# `statusline status`: read-only report of the same reader.
out="$(CLAUDE_CONFIG_DIR="$SL/missing" "$M" statusline status 2>/dev/null)"
if printf '%s\n' "$out" | grep -qx 'statusLine: unset' \
  && printf '%s\n' "$out" | grep -qx 'refreshInterval: unset' \
  && printf '%s\n' "$out" | grep -qx 'command: none'; then
  ok "statusline status reports unset"
else
  fail "statusline status reports unset"
fi
out="$(CLAUDE_CONFIG_DIR="$SL/install-yes" "$M" statusline status 2>/dev/null)"
if printf '%s\n' "$out" | grep -qx 'statusLine: set' \
  && printf '%s\n' "$out" | grep -qx 'refreshInterval: set (10)' \
  && printf '%s\n' "$out" | grep -qx 'command: maestro' \
  && printf '%s\n' "$out" | grep -qxF "maestro path: $M (ok)"; then
  ok "statusline status reports the managed command"
else
  fail "statusline status reports the managed command"
fi
out="$(CLAUDE_CONFIG_DIR="$SL/custom" "$M" statusline status 2>/dev/null)"
if printf '%s\n' "$out" | grep -qx 'command: custom' \
  && ! printf '%s\n' "$out" | grep -q '^maestro path:'; then
  ok "statusline status reports a custom command"
else
  fail "statusline status reports a custom command"
fi
out="$(CLAUDE_CONFIG_DIR="$SL/invalid" "$M" statusline status 2>/dev/null)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qx 'settings: unreadable'; then
  ok "statusline status reports unreadable settings"
else
  fail "statusline status reports unreadable settings"
fi
sl_fixture status-ro '{"statusLine":{"type":"command","command":"/opt/custom","refreshInterval":10}}'
( cd "$SL/status-ro" && find . | LC_ALL=C sort ) > "$TMP/status-ro.before"
touch "$TMP/status-ro.stamp"
CLAUDE_CONFIG_DIR="$SL/status-ro" "$M" statusline status >/dev/null 2>&1
( cd "$SL/status-ro" && find . | LC_ALL=C sort ) > "$TMP/status-ro.after"
if cmp -s "$TMP/status-ro.before" "$TMP/status-ro.after" \
  && [ ! "$SL/status-ro/settings.json" -nt "$TMP/status-ro.stamp" ]; then
  ok "statusline status is read-only"
else
  fail "statusline status is read-only"
fi

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
watch
watch --line
lab
lab trivial
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
statusline
statusline install
statusline status
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
printf '# Spec\n## Acceptance criteria\n- AC1: works. Proof: none (summary only)\n### Task 1 - one\nbody\n' > "$TMP/paused-spec.md"
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

# `maestro lab` is opt-in: it runs the real master on sonnet/low in a scratch
# HOME, config, state, and temp dir, with the builder stubbed. CI and the
# release gate never call a model, so these cases inject a fake master with
# BOTTEGA_LAB_CLAUDE; the wrapper and its isolation are under test, not a model.
LAB="$TMP/lab"
mkdir -p "$LAB"
LAB_LOG="$LAB/master.log"
export LAB_LOG
LAB_FAKE_MASTER="$LAB/fake-master"
cat > "$LAB_FAKE_MASTER" <<'EOF'
#!/usr/bin/env bash
# Fake master: record the wrapper facts, then run the scenario's builder side
# effect so the scenario's expect script passes without a model.
{
  for lab_arg in "$@"; do
    printf 'ARG=%s\n' "$lab_arg"
  done
  printf 'HOME=%s\n' "$HOME"
  printf 'XDG_CONFIG_HOME=%s\n' "$XDG_CONFIG_HOME"
  printf 'CLAUDE_CONFIG_DIR=%s\n' "$CLAUDE_CONFIG_DIR"
  printf 'BOTTEGA_STATE_DIR=%s\n' "$BOTTEGA_STATE_DIR"
  printf 'TMPDIR=%s\n' "$TMPDIR"
  printf 'CLAUDE=%s\n' "$(command -v claude)"
  printf 'BUILDER_ENV=%s\n' "$(tr '\n' ' ' < "${XDG_CONFIG_HOME:-$HOME/.config}/bottega/builder.env" 2>/dev/null)"
  if [ -s "${XDG_CONFIG_HOME:-$HOME/.config}/bottega/builder.key" ]; then
    printf 'KEY_EXISTS=yes\n'
  else
    printf 'KEY_EXISTS=no\n'
  fi
  printf 'OAUTH=%s\n' "${CLAUDE_CODE_OAUTH_TOKEN:+yes}"
} >> "$LAB_LOG"
[ -n "${BOTTEGA_LAB_BUILDER:-}" ] && [ -f "$BOTTEGA_LAB_BUILDER" ] && bash "$BOTTEGA_LAB_BUILDER"
exit 0
EOF
chmod +x "$LAB_FAKE_MASTER"

out="$(env -u CLAUDE_CODE_OAUTH_TOKEN -u ANTHROPIC_API_KEY "$M" lab trivial 2>&1)"; rc=$?
if [ "$rc" -eq 3 ] && printf '%s\n' "$out" | grep -q 'CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY'; then
  ok "lab: refuses without auth"
else
  fail "lab: refuses without auth"
fi

: > "$LAB_LOG"
out="$(BOTTEGA_LAB_CLAUDE="$LAB_FAKE_MASTER" CLAUDE_CODE_OAUTH_TOKEN=lab-token "$M" lab trivial --keep 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "lab: trivial scenario passes with a fake master" || fail "lab: trivial scenario passes with a fake master"
grep -q '^HOME=.*/maestro-lab\.' "$LAB_LOG" && ok "lab: scratch HOME" || fail "lab: scratch HOME"
if grep -q '^XDG_CONFIG_HOME=.*/maestro-lab\.' "$LAB_LOG" \
  && grep -q '^CLAUDE_CONFIG_DIR=.*/maestro-lab\.' "$LAB_LOG" \
  && grep -q '^BOTTEGA_STATE_DIR=.*/maestro-lab\.' "$LAB_LOG" \
  && grep -q '^TMPDIR=.*/maestro-lab\.' "$LAB_LOG"; then
  ok "lab: scratch config, state, and temp"
else
  fail "lab: scratch config, state, and temp"
fi
if grep -q '^BUILDER_ENV=.*ANTHROPIC_BASE_URL=http://stub.invalid' "$LAB_LOG" && grep -qx '^KEY_EXISTS=yes' "$LAB_LOG"; then
  ok "lab: fake builder env and key"
else
  fail "lab: fake builder env and key"
fi
grep -q '^CLAUDE=.*/maestro-lab\.[^/]*/bin/claude$' "$LAB_LOG" && ok "lab: stub claude first on PATH" || fail "lab: stub claude first on PATH"
if grep -qx 'ARG=--model' "$LAB_LOG" && grep -qx 'ARG=sonnet' "$LAB_LOG" \
  && grep -qx 'ARG=--effort' "$LAB_LOG" && grep -qx 'ARG=low' "$LAB_LOG"; then
  ok "lab: master on sonnet low"
else
  fail "lab: master on sonnet low"
fi
if grep -qx 'ARG=--allowedTools' "$LAB_LOG" \
  && grep -qxF 'ARG=Read,Grep,Glob,Write,Edit,Skill,Agent,Task,TodoWrite,Bash(maestro:*),Bash(git:*),Bash(./scripts/check:*)' "$LAB_LOG" \
  && grep -qx 'ARG=--disallowedTools' "$LAB_LOG" \
  && grep -qxF 'ARG=Bash(git push:*),Bash(gh:*),WebFetch,WebSearch,AskUserQuestion' "$LAB_LOG"; then
  ok "lab: master allow and deny lists"
else
  fail "lab: master allow and deny lists"
fi
if grep -qx 'ARG=--plugin-dir' "$LAB_LOG" && grep -qx 'ARG=--strict-mcp-config' "$LAB_LOG"; then
  ok "lab: master loads the plugin with no MCP"
else
  fail "lab: master loads the plugin with no MCP"
fi
grep -qx '^OAUTH=yes' "$LAB_LOG" && ok "lab: auth env passed through" || fail "lab: auth env passed through"

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
