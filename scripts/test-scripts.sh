#!/usr/bin/env bash
# Smoke tests for bottega's bundled scripts. Run from anywhere; exits 1 on any failure.
# Works on Linux and macOS (bash 3.2, BSD or GNU tools). Uses temp dirs only.
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
maestro="$root/skills/maestro/scripts"
logsh="$root/skills/maestro/scripts/log.sh"
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
git mv -k a.py "moved file.py" && echo y > "sub dir.txt"
expect "gate-check: a rename and a spaced name are changed files" 2 "$maestro/gate-check.sh"
"$maestro/gate-check.sh" >"$tmp/out" 2>&1
grep -q "  - moved file.py" "$tmp/out" && grep -q "  - a.py" "$tmp/out" \
	&& pass "gate-check: lists both sides of a rename" || fail "gate-check: lists both sides of a rename"
expect "gate-check: globs with spaces cover them" 0 "$maestro/gate-check.sh" --expect "moved file.py" --expect "sub *.txt"
rm "sub dir.txt"
expect "gate-check: removing a run-created file leaves nothing to cover" 0 "$maestro/gate-check.sh"

# gate-check.sh: committed renames and deletions, options after the ledger, no snapshot, guarded globs.
cd "$tmp" && mkdir gate7 && cd gate7 && git init -q -b main
echo a > a.py && echo b > b.py && git_q add -A && git_q commit -qm init
"$maestro/gate-check.sh" --start "goal" --condition "ok" >/dev/null
git_q mv a.py c.py && git_q commit -qm rename
expect "gate-check: a committed rename's old path needs --expect" 2 "$maestro/gate-check.sh" --proof "ok" "ran" PASS --expect "c.py"
expect "gate-check: covering both sides of a committed rename approves" 0 "$maestro/gate-check.sh" --expect "a.py"
git_q rm -q b.py && git_q commit -qm delete
expect "gate-check: a committed deletion outside --expect blocks" 2 "$maestro/gate-check.sh"
expect "gate-check: options after the ledger path still apply" 0 "$maestro/gate-check.sh" .bottega/proofs.tsv --expect "b.py"
expect "gate-check: two ledger paths are a usage error" 2 "$maestro/gate-check.sh" .bottega/proofs.tsv other.tsv
echo d > "-dash.txt" && echo e > "+plus.txt"
expect "gate-check: files starting with - or + need --expect" 2 "$maestro/gate-check.sh"
expect "gate-check: --expect globs starting with - and + match" 0 "$maestro/gate-check.sh" --expect "-dash.txt" --expect "+plus*"
rm .bottega/run-start.tsv
expect "gate-check: a git run with no snapshot is incomplete" 2 "$maestro/gate-check.sh"

# gate-check.sh: risk declared at --start holds even when the final call omits --risk.
cd "$tmp" && mkdir gate6 && cd gate6
"$maestro/gate-check.sh" --start "goal" --condition "ok" --risk high >/dev/null
expect "gate-check: high risk from --start needs crossfire" 2 "$maestro/gate-check.sh" --proof "ok" "ran" PASS
"$logsh" .bottega/proofs.tsv crossfire diff solo "FINDINGS: 0" PASS
expect "gate-check: high risk from --start approves with crossfire" 0 "$maestro/gate-check.sh"

cd "$tmp" && mkdir gate3 && cd gate3
"$maestro/gate-check.sh" --start "goal" --condition "docs updated" >/dev/null
"$logsh" .bottega/proofs.tsv proof "docs updated" "by hand" "no reason" WAIVED
expect "gate-check: hand-logged waiver without the user's words is missing" 2 "$maestro/gate-check.sh"

# .bottega/ ignores itself: log.sh writes .bottega/.gitignore, never overwrites it.
cd "$tmp" && mkdir gi1 && cd gi1
"$logsh" .bottega/x.tsv p d w e r
[ "$(cat .bottega/.gitignore 2>/dev/null)" = "*" ] && pass "log.sh creates .bottega/.gitignore" || fail "log.sh creates .bottega/.gitignore"
cd "$tmp" && mkdir gi2 && cd gi2 && mkdir .bottega && echo keep > .bottega/.gitignore
"$logsh" .bottega/x.tsv p d w e r
[ "$(cat .bottega/.gitignore)" = "keep" ] && pass "log.sh keeps existing .gitignore" || fail "log.sh keeps existing .gitignore"
cd "$tmp" && mkdir gi3 && cd gi3
"$logsh" other/x.tsv p d w e r
[ ! -e other/.gitignore ] && [ ! -e .bottega ] && pass "log.sh outside .bottega adds no .gitignore" || fail "log.sh outside .bottega adds no .gitignore"
cd "$tmp" && mkdir gi5 && cd gi5 && git init -q
"$logsh" .bottega/x.tsv p d w e r; "$root/skills/maestro/scripts/gate-check.sh" --start g --condition c >/dev/null
[ -z "$(git status --porcelain)" ] && pass "git status clean for .bottega" || fail "git status clean for .bottega"
cd "$tmp"

# worktree-audit.sh: classifies a worktree with uncommitted work, with and without sizes.
cd "$tmp" && git init -q --bare -b main origin.git && git clone -q origin.git main 2>/dev/null && cd main
echo a > a && git_q add -A && git_q commit -qm i && git push -q origin main && git remote set-head origin main
git worktree add -q -b feat ../feat && echo wip >> ../feat/a
for flag in "" --no-sizes; do
	# shellcheck disable=SC2086
	if "$maestro/worktree-audit.sh" $flag 2>/dev/null | grep -q "hold-wip"; then pass "worktree-audit ${flag:-(sizes)}: wip worktree held"
	else fail "worktree-audit ${flag:-(sizes)}: wip worktree held"; fi
done
git worktree add -q -b spaced "../with space" && echo junk > "../with space/new.txt"
git worktree add -q -b runstate ../runstate && mkdir -p ../runstate/.bottega && echo x > ../runstate/.bottega/proofs.tsv
out=$("$maestro/worktree-audit.sh" --no-sizes 2>/dev/null)
printf '%s\n' "$out" | grep -F "with space" | grep -q "scratch:1" && pass "worktree-audit: path with a space, untracked file counted" || fail "worktree-audit: path with a space, untracked file counted"
printf '%s\n' "$out" | grep -F "with space" | grep -qv "safe" && pass "worktree-audit: untracked files keep a worktree out of safe" || fail "worktree-audit: untracked files keep a worktree out of safe"
printf '%s\n' "$out" | grep -F "/runstate" | grep -q "bottega-state" && pass "worktree-audit: ignored .bottega run state is flagged" || fail "worktree-audit: ignored .bottega run state is flagged"

# bottega CLI wrapper: start, verify (pass/fail), and CLAUDE.md hygiene warning.
cd "$tmp" && mkdir bcli && cd bcli && git init -q
echo hi > a.txt && git_q add -A && git_q commit -qm i
"$maestro/bottega" start "cli smoke" --risk normal --condition "a works" >/dev/null \
	&& pass "bottega start opens run" || fail "bottega start opens run"
echo hi2 > a.txt
"$maestro/bottega" verify --check "grep -q hi2 a.txt" --risk normal --expect "a.txt" --proof "a works" "grep hi2" PASS >/dev/null \
	&& pass "bottega verify approves passing check" || fail "bottega verify approves passing check"
if "$maestro/bottega" verify --check "false" >/dev/null 2>&1; then fail "bottega verify fails on red check"
else pass "bottega verify fails on red check"; fi
yes "rule" | head -n 160 > CLAUDE.md
if "$maestro/bottega" start "hygiene" --condition "c" 2>&1 >/dev/null | grep -q "CLAUDE.md is 160 lines"; then
	pass "bottega start warns on >150-line CLAUDE.md"
else fail "bottega start warns on >150-line CLAUDE.md"; fi
if "$maestro/bottega" hygiene 2>&1 | grep -q "CLAUDE.md is 160 lines"; then
	pass "bottega hygiene warns on >150-line CLAUDE.md"
else fail "bottega hygiene warns on >150-line CLAUDE.md"; fi
"$maestro/bottega" followup add "fix cache" "src/cache.ts:12" "stale read" "invalidate on write" >/dev/null \
	&& grep -qF -- "- [ ] fix cache | src/cache.ts:12 | stale read | invalidate on write" .bottega/followups.md \
	&& pass "bottega followup add writes formatted row" || fail "bottega followup add writes formatted row"
"$maestro/bottega" garden add "unsafe cast" "src/a.ts:9" "3 commits use as any" >/dev/null \
	&& grep -qF -- "- [ ] unsafe cast | src/a.ts:9 | 3 commits use as any" .bottega/garden.md \
	&& pass "bottega garden add writes formatted row" || fail "bottega garden add writes formatted row"
"$maestro/bottega" worktree audit -b HEAD --no-sizes >/dev/null 2>&1 \
	&& pass "bottega worktree audit wraps worktree-audit.sh" || fail "bottega worktree audit wraps worktree-audit.sh"
git checkout -q -b feat-migration && mkdir -p migrations && echo "DROP TABLE x;" > migrations/001.sql && git_q add migrations/001.sql && git_q commit -qm "add migration"
if "$maestro/bottega" ship --ready --title "drop x" --body "test" 2>&1 | grep -q "one-way-door"; then
	pass "bottega ship --ready blocks one-way-door migration"
else fail "bottega ship --ready blocks one-way-door migration"; fi
if "$maestro/bottega" --help | grep -qv "set -euo pipefail"; then
	pass "bottega --help prints usage without set -euo pipefail"
else fail "bottega --help prints usage without set -euo pipefail"; fi
printf 'true\n' > .bottega/checks.env
if "$maestro/bottega" verify --run-detected >/dev/null 2>&1; then
	fail "bottega verify --run-detected should still enforce gate-check.sh"
else pass "bottega verify --run-detected enforces gate-check.sh"; fi

# Harness installer smoke tests (install, idempotent re-run, --help, unknown flag, --uninstall).
inst_dir="$tmp/agy-skills"
repo_root="$(cd "$maestro/../../.." && pwd -P)"
BOTTEGA_AGY_SKILLS_DIR="$inst_dir" "$repo_root/harnesses/antigravity/install.sh" >/dev/null \
	&& [ -L "$inst_dir/bottega-maestro" ] \
	&& pass "install.sh symlinks skills into target dir" || fail "install.sh symlinks skills into target dir"
BOTTEGA_AGY_SKILLS_DIR="$inst_dir" "$repo_root/harnesses/antigravity/install.sh" --help >/dev/null \
	&& pass "install.sh --help exits 0" || fail "install.sh --help exits 0"
if BOTTEGA_AGY_SKILLS_DIR="$inst_dir" "$repo_root/harnesses/antigravity/install.sh" --bogus >/dev/null 2>&1; then
	fail "install.sh rejects unknown flags"
else pass "install.sh rejects unknown flags"; fi
BOTTEGA_AGY_SKILLS_DIR="$inst_dir" "$repo_root/harnesses/antigravity/install.sh" --uninstall >/dev/null \
	&& [ ! -e "$inst_dir/bottega-maestro" ] \
	&& pass "install.sh --uninstall removes bottega symlinks" || fail "install.sh --uninstall removes bottega symlinks"

echo
[ "$fails" -eq 0 ] && echo "all script tests passed" || echo "$fails script test(s) failed"
[ "$fails" -eq 0 ]
