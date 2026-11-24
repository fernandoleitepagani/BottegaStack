#!/usr/bin/env bash
# Smoke tests for bottega's bundled scripts. Run from anywhere; exits 1 on any failure.
# Works on Linux and macOS (bash 3.2, BSD or GNU tools, Python 3.9+). Uses temp dirs only.
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
maestro="$root/skills/maestro/scripts"
logsh="$root/skills/show-me-your-work/scripts/log.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
pass() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
expect() { # <name> <expected exit> <command...>
	local name="$1" want="$2"; shift 2
	"$@" >"$tmp/out" 2>&1
	local got=$?
	if [ "$got" -eq "$want" ]; then pass "$name"; else fail "$name (exit $got, want $want)"; sed 's/^/      /' "$tmp/out"; fi
}
git_q() { git -c user.email=t@example.com -c user.name=t "$@"; }

# log.sh: header once, one row per call, formula-looking cells prefixed.
cd "$tmp" && mkdir logt && cd logt
"$logsh" .bottega/l.tsv proof "cond" "=cmd()" "ev" PASS && "$logsh" .bottega/l.tsv proof "c2" "w" "e" FAIL
[ "$(grep -c . .bottega/l.tsv)" -eq 3 ] && grep -q "'=cmd()" .bottega/l.tsv \
	&& pass "log.sh writes header, rows, formula guard" || fail "log.sh writes header, rows, formula guard"

# gate-check.sh: missing steps, scoped to the run, declared conditions, waivers, high risk.
cd "$tmp" && mkdir gate && cd gate
expect "gate-check: no ledger is incomplete" 2 "$maestro/gate-check.sh"
"$logsh" .bottega/proofs.tsv proof "old run" x y PASS
expect "gate-check: no run row is incomplete" 2 "$maestro/gate-check.sh"
expect "gate-check: --start needs a condition" 2 "$maestro/gate-check.sh" --start "goal"
"$maestro/gate-check.sh" --start "goal" --condition "tests pass" --condition "edge" >/dev/null
expect "gate-check: earlier run's rows don't count" 2 "$maestro/gate-check.sh"
"$logsh" .bottega/proofs.tsv proof "tests pass" ran unittest PASS
expect "gate-check: a declared condition without proof is missing" 2 "$maestro/gate-check.sh"
"$logsh" .bottega/proofs.tsv proof "edge" ran repro PASS
expect "gate-check: normal risk with every condition PASS" 0 "$maestro/gate-check.sh"
expect "gate-check: high risk needs crossfire" 2 "$maestro/gate-check.sh" --risk high
"$logsh" .bottega/proofs.tsv crossfire diff solo "FINDINGS: 1" FAIL
expect "gate-check: crossfire FAIL escalates" 1 "$maestro/gate-check.sh" --risk high
"$logsh" .bottega/proofs.tsv crossfire diff solo "FINDINGS: 0" PASS
expect "gate-check: latest crossfire PASS approves" 0 "$maestro/gate-check.sh" --risk high
"$maestro/gate-check.sh" --start "next goal" --condition "tests pass" >/dev/null
"$logsh" .bottega/proofs.tsv proof "tests pass" ran unittest PASS
expect "gate-check: earlier run's crossfire PASS doesn't count" 2 "$maestro/gate-check.sh" --risk high
"$logsh" .bottega/proofs.tsv proof "tests pass" ran repro INCONCLUSIVE
expect "gate-check: INCONCLUSIVE escalates" 1 "$maestro/gate-check.sh"
expect "gate-check: bad risk is a usage error" 2 "$maestro/gate-check.sh" --risk medium
cd "$tmp" && mkdir gate2 && cd gate2
"$maestro/gate-check.sh" --start "goal" --condition "tests pass" --condition "a | pipe, and 'quotes'" >/dev/null
expect "gate-check --proof: logs and approves in one call" 0 "$maestro/gate-check.sh" \
	--proof "tests pass" "python3 -m unittest: OK" PASS --proof "a | pipe, and 'quotes'" "file.py:3" PASS
[ "$(awk -F'\t' '$2 == "proof"' .bottega/proofs.tsv | grep -c .)" -eq 2 ] && grep -q "a | pipe, and 'quotes'" .bottega/proofs.tsv \
	&& pass "gate-check --proof: rows kept intact" || fail "gate-check --proof: rows kept intact"
expect "gate-check --condition: a late condition needs its own proof" 2 "$maestro/gate-check.sh" --condition "docs updated"
expect "gate-check --proof: waiver without the user's words is a usage error" 2 "$maestro/gate-check.sh" --proof "docs updated" "skipped" WAIVED
expect "gate-check --proof: waiver quoting the user approves" 0 "$maestro/gate-check.sh" --proof "docs updated" "user: \"skip the docs\"" WAIVED
expect "gate-check --proof: FAIL row escalates" 1 "$maestro/gate-check.sh" --proof "edge case" "repro.py" FAIL --condition "edge case"
expect "gate-check --proof: bad RESULT is a usage error" 2 "$maestro/gate-check.sh" --proof "x" "y" MAYBE
# gate-check.sh: the latest proof per condition counts; history stays in the ledger.
cd "$tmp" && mkdir gate4 && cd gate4
"$maestro/gate-check.sh" --start "goal" --condition "tests pass" >/dev/null
"$maestro/gate-check.sh" --proof "tests pass" "first try: 1 failure" FAIL >/dev/null
expect "gate-check: a FAIL fixed and proven PASS approves" 0 "$maestro/gate-check.sh" --proof "tests pass" "rerun: OK" PASS
[ "$(awk -F'\t' '$2 == "proof"' .bottega/proofs.tsv | grep -c .)" -eq 2 ] \
	&& pass "gate-check: the fixed FAIL stays in the ledger" || fail "gate-check: the fixed FAIL stays in the ledger"

# gate-check.sh in a git repo: every file the run changed must match --expect.
cd "$tmp" && mkdir gate5 && cd gate5 && git init -q -b main
echo a > a.py && echo u > user.txt && git_q add -A && git_q commit -qm init
echo "user edit" >> user.txt
"$maestro/gate-check.sh" --start "goal" --condition "ok" >/dev/null
echo fix >> a.py
expect "gate-check: changed files with no --expect is missing" 2 "$maestro/gate-check.sh" --proof "ok" "ran" PASS
expect "gate-check: changes inside --expect approve; the user's earlier edit doesn't count" 0 "$maestro/gate-check.sh" --expect "a.py"
echo junk > stray.log
expect "gate-check: a stray new file blocks" 2 "$maestro/gate-check.sh"
"$maestro/gate-check.sh" 2>&1 | grep -q "  - stray.log" && pass "gate-check: names the stray file" || fail "gate-check: names the stray file"
rm stray.log && mkdir -p src && echo x > src/b.py && git_q add src && git_q commit -qm "delegate commit"
expect "gate-check: a commit since the start counts as changed" 2 "$maestro/gate-check.sh"
expect "gate-check: a directory --expect covers it" 0 "$maestro/gate-check.sh" --expect "src/"
[ -z "$(git status --porcelain -- .bottega)" ] && pass "gate-check: run state stays untracked" || fail "gate-check: run state stays untracked"

cd "$tmp" && mkdir gate3 && cd gate3
"$maestro/gate-check.sh" --start "goal" --condition "docs updated" >/dev/null
"$logsh" .bottega/proofs.tsv proof "docs updated" "by hand" "no reason" WAIVED
expect "gate-check: hand-logged waiver without the user's words is missing" 2 "$maestro/gate-check.sh"

# progress.py and statusline.py: step counter, quiet agent first, abandoned file dropped.
cd "$tmp" && mkdir status && cd status
python3 "$maestro/progress.py" fixer start sonnet low --total 5 >/dev/null
python3 "$maestro/progress.py" fixer phase "running tests" --step 3 >/dev/null
python3 "$maestro/progress.py" owner start sonnet low >/dev/null
python3 "$maestro/progress.py" dead start haiku high >/dev/null
python3 - <<'PY'
import os, time
now = time.time()
os.utime(".bottega/agents/owner.json", (now - 700, now - 700))
os.utime(".bottega/agents/dead.json", (now - 90000, now - 90000))
PY
line=$(printf '{"model":{"display_name":"Opus"},"workspace":{"project_dir":"%s"}}' "$PWD" \
	| python3 "$root/skills/setup-maestro/scripts/statusline.py")
case "$line" in *"owner"*"(quiet"*"fixer"*"3/5: running tests"*) pass "statusline: step counter and quiet first" ;;
	*) fail "statusline: step counter and quiet first"; echo "      $line" ;; esac
[ ! -e .bottega/agents/dead.json ] && grep -q '"agents_quiet": \["owner"\]' .bottega/status.json \
	&& pass "statusline: drops abandoned files, lists quiet agents" || fail "statusline: drops abandoned files, lists quiet agents"
expect "progress.py: rejects a path as a name" 1 python3 "$maestro/progress.py" ../x start a b

# set-statusline.py: touches only statusLine, keeps permissions, backs up the old line.
cd "$tmp" && mkdir -p home/.claude
printf '{"model":"opus","env":{"X":"1"},"statusLine":{"type":"command","command":"other.sh"}}' > home/.claude/settings.json
chmod 600 home/.claude/settings.json
HOME="$tmp/home" python3 "$root/skills/setup-maestro/scripts/set-statusline.py" >/dev/null
python3 - "$tmp/home/.claude" <<'PY' && pass "set-statusline: only statusLine changes" || fail "set-statusline: only statusLine changes"
import json, os, stat, sys
d = sys.argv[1]
s = json.load(open(os.path.join(d, "settings.json")))
b = json.load(open(os.path.join(d, "statusline.backup.json")))
mode = stat.S_IMODE(os.stat(os.path.join(d, "settings.json")).st_mode)
assert s["model"] == "opus" and s["env"] == {"X": "1"}, s
assert s["statusLine"]["command"].endswith("bottega/statusline.py"), s
assert os.path.isfile(os.path.join(d, "bottega", "statusline.py")), "copy missing"
assert b["command"] == "other.sh" and mode == 0o600, (b, oct(mode))
PY

HOME="$tmp/home" python3 "$root/skills/setup-maestro/scripts/set-statusline.py" >/dev/null
[ "$(ls "$tmp/home/.claude" | grep -c '^settings.json.bottega-backup-')" -eq 2 ] \
	&& pass "set-statusline: second run keeps the first backup" || fail "set-statusline: second run keeps the first backup"
sample='{"model":{"display_name":"x"},"workspace":{"current_dir":"/tmp","project_dir":"/tmp"}}'
mkdir -p "$tmp/h o/.claude" && echo '{}' > "$tmp/h o/.claude/settings.json"
HOME="$tmp/h o" python3 "$root/skills/setup-maestro/scripts/set-statusline.py" >/dev/null
cmd=$(HOME="$tmp/h o" python3 "$root/skills/setup-maestro/scripts/set-statusline.py" --print-command)
out=$(printf '%s' "$sample" | sh -c "$cmd"); code=$?
[ "$code" -eq 0 ] && [ -n "$out" ] && pass "set-statusline: command works with a space in HOME" || fail "set-statusline: command works with a space in HOME"
mkdir -p "$tmp/h2"
HOME="$tmp/h2" python3 "$root/skills/setup-maestro/scripts/set-statusline.py" --print-command >/dev/null
[ ! -e "$tmp/h2/.claude" ] && pass "set-statusline: --print-command writes nothing" || fail "set-statusline: --print-command writes nothing"
printf '%s' '{"model":{"display_name":"SECRETVAL"},"cwd":"/tmp"}' | BOTTEGA_STATUSLINE_DEBUG="$tmp/dbg" python3 "$root/skills/setup-maestro/scripts/statusline.py" >/dev/null
grep -q '"model.display_name"' "$tmp/dbg" && ! grep -q SECRETVAL "$tmp/dbg" \
	&& pass "statusline: debug env writes key paths, no values" || fail "statusline: debug env writes key paths, no values"

# .bottega/ ignores itself: log.sh and progress.py write .bottega/.gitignore, never overwrite it.
cd "$tmp" && mkdir gi1 && cd gi1
"$logsh" .bottega/x.tsv p d w e r
[ "$(cat .bottega/.gitignore 2>/dev/null)" = "*" ] && pass "log.sh creates .bottega/.gitignore" || fail "log.sh creates .bottega/.gitignore"
cd "$tmp" && mkdir gi2 && cd gi2 && mkdir .bottega && echo keep > .bottega/.gitignore
"$logsh" .bottega/x.tsv p d w e r
[ "$(cat .bottega/.gitignore)" = "keep" ] && pass "log.sh keeps existing .gitignore" || fail "log.sh keeps existing .gitignore"
cd "$tmp" && mkdir gi3 && cd gi3
"$logsh" other/x.tsv p d w e r
[ ! -e other/.gitignore ] && [ ! -e .bottega ] && pass "log.sh outside .bottega adds no .gitignore" || fail "log.sh outside .bottega adds no .gitignore"
cd "$tmp" && mkdir gi4 && cd gi4
python3 "$maestro/progress.py" a start sonnet low >/dev/null
[ "$(cat .bottega/.gitignore 2>/dev/null)" = "*" ] && pass "progress.py creates .bottega/.gitignore" || fail "progress.py creates .bottega/.gitignore"
cd "$tmp" && mkdir gi5 && cd gi5 && git init -q
"$logsh" .bottega/x.tsv p d w e r; python3 "$maestro/progress.py" a start sonnet low >/dev/null
[ -z "$(git status --porcelain)" ] && pass "git status clean for .bottega" || fail "git status clean for .bottega"

# doctor.py: empty HOME passes, a missing status line script and a bad role value fail.
doctor="$root/skills/setup-maestro/scripts/doctor.py"
mkdir -p "$tmp/h1" "$tmp/h2/.claude/rules" "$tmp/h3/.claude/rules"
expect "doctor: empty HOME is not a failure" 0 env HOME="$tmp/h1" python3 "$doctor"
printf '# budget: standard\norchestrator: opus low | opus medium\n' >"$tmp/h2/.claude/rules/bottega-models.md"
printf '{"statusLine":{"type":"command","command":"python3 %s/.claude/bottega/statusline.py"}}' "$tmp/h2" >"$tmp/h2/.claude/settings.json"
expect "doctor: missing status line script fails" 1 env HOME="$tmp/h2" python3 "$doctor"
printf '# budget: standard\nreviewer: sonnet high | sonnet medium\nghost: opus low | opus low\n' >"$tmp/h3/.claude/rules/bottega-models.md"
expect "doctor: sonnet high is a bad value" 1 env HOME="$tmp/h3" python3 "$doctor"
env HOME="$tmp/h3" python3 "$doctor" | grep -q "unknown role 'ghost'" && pass "doctor: unknown role warns" || fail "doctor: unknown role warns"
cd "$tmp"

# security-scan.sh: built-in patterns find committed and untracked secrets, never print them.
cd "$tmp" && mkdir scan && cd scan && git init -q -b main
echo "x = 1" > app.py && git_q add -A && git_q commit -qm init && git checkout -qb feat
printf 'KEY = "AKIA%s"\n' ABCDEFGHIJKLMNOP > conf.py && git_q add -A && git_q commit -qm c
printf 'a\tpassword = "hunter2hunter2xx"\n' > notes.txt
SECURITY_SCAN_NO_GITLEAKS=1 "$maestro/security-scan.sh" -b main >"$tmp/out" 2>&1
code=$?
if [ "$code" -eq 1 ] && grep -q "conf.py:1: aws-access-key" "$tmp/out" && grep -q "notes.txt:1: assigned-secret" "$tmp/out" \
	&& ! grep -q "ABCDEFGHIJKLMNOP\|hunter2" "$tmp/out" && [ -z "$(ls -A .bottega/security)" ]; then
	pass "security-scan: finds secrets, hides values, leaves no temp files"
else fail "security-scan: finds secrets, hides values, leaves no temp files (exit $code)"; sed 's/^/      /' "$tmp/out"; fi

# worktree-audit.sh: classifies a worktree with uncommitted work, with and without sizes.
cd "$tmp" && git init -q --bare -b main origin.git && git clone -q origin.git main 2>/dev/null && cd main
echo a > a && git_q add -A && git_q commit -qm i && git push -q origin main && git remote set-head origin main
git worktree add -q -b feat ../feat && echo wip >> ../feat/a
for flag in "" --no-sizes; do
	# shellcheck disable=SC2086
	if "$maestro/worktree-audit.sh" $flag 2>/dev/null | grep -q "hold-wip"; then pass "worktree-audit ${flag:-(sizes)}: wip worktree held"
	else fail "worktree-audit ${flag:-(sizes)}: wip worktree held"; fi
done

# check-plan.mjs: the playbook's own template passes once filled, and the checker catches the placeholder.
awk '/^````markdown/{f=1;next} /^````$/{f=0} f' "$root/skills/maestro/playbooks/multi-phase-plan.md" > "$tmp/plan.md"
expect "check-plan: unfilled template is flagged" 1 node "$maestro/check-plan.mjs" "$tmp/plan.md"
sed 's/<N> lanes on `<swarm workers model>`/3 lanes on `haiku`/' "$tmp/plan.md" > "$tmp/plan-filled.md"
expect "check-plan: filled template passes" 0 node "$maestro/check-plan.mjs" "$tmp/plan-filled.md"

echo
[ "$fails" -eq 0 ] && echo "all script tests passed" || echo "$fails script test(s) failed"
[ "$fails" -eq 0 ]
