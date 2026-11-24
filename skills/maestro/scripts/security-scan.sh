#!/usr/bin/env bash
# Read-only pre-ship security scan of a branch diff. Never prints a secret value.
#
# Usage: security-scan.sh [-b|--base <ref>] [repo-path]
#   Diffs <merge-base of base and HEAD> through the working tree.
#   Base defaults to origin/HEAD, then origin/main, then origin/master, then main.
#
# Sections:
#   secrets  added lines that look like credentials (gitleaks --redact when installed,
#            else a built-in pattern list). Prints file:line and the rule, never the value.
#   deps     changed dependency manifests or lockfiles, and the audit command to run
#            for each ecosystem when its tool is installed (output goes to .bottega/).
#   surface  changed files on a sensitive path (auth, crypto, CI, Docker, IaC, env).
#
# Exit 0 clean, 1 when secrets or audit findings need a look, 2 on usage error.
set -u

base=""
while [ $# -gt 0 ]; do
	case "$1" in
	-b|--base) [ $# -ge 2 ] || { echo "error: $1 needs a ref" >&2; exit 2; }; base="$2"; shift 2 ;;
	-h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
	-*) echo "error: unknown option: $1" >&2; exit 2 ;;
	*) break ;;
	esac
done

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$repo" ] && { echo "error: not in a git repo; pass a repo path" >&2; exit 2; }
cd "$repo" || exit 2

if [ -z "$base" ]; then
	for cand in "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" origin/main origin/master main master; do
		[ -n "$cand" ] && git rev-parse --verify --quiet "$cand^{commit}" >/dev/null && { base="$cand"; break; }
	done
fi
[ -z "$base" ] && { echo "error: no base ref found; pass -b <ref>" >&2; exit 2; }
mb=$(git merge-base "$base" HEAD 2>/dev/null) || { echo "error: no merge base with $base" >&2; exit 2; }

out_dir=".bottega/security"
mkdir -p "$out_dir"
status=0
changed=$( { git diff --name-only "$mb"; git ls-files --others --exclude-standard; } | grep -v '^\.bottega/' | sort -u)

echo "== secrets (base $base)"
# SECURITY_SCAN_NO_GITLEAKS=1 forces the built-in patterns (used by the script tests).
if [ -z "${SECURITY_SCAN_NO_GITLEAKS:-}" ] && command -v gitleaks >/dev/null 2>&1; then
	if ! gitleaks git --log-opts="$mb..HEAD" --redact --no-banner --report-path "$out_dir/gitleaks.json" . >/dev/null 2>&1 \
		|| ! gitleaks dir --redact --no-banner --report-path "$out_dir/gitleaks-tree.json" . >/dev/null 2>&1; then
		echo "gitleaks found leaks; redacted reports in $out_dir/"
		status=1
	else
		echo "gitleaks: clean"
	fi
else
	# name<TAB>extended regex. Kept narrow on purpose: a noisy scan gets ignored.
	# Added lines with their new-file line numbers, from the diff plus untracked files.
	added_file="$out_dir/.added.tsv"
	rules_file="$out_dir/.rules.tsv"
	# The added lines can hold the very secrets being scanned for: owner-only, removed on exit.
	trap 'rm -f "$added_file" "$rules_file"' EXIT
	umask 077
	# Written straight to the file: bash 3.2 misparses quotes in a heredoc inside $( ).
	cat > "$rules_file" <<'EOF'
aws-access-key	AKIA[0-9A-Z]{16}
github-token	gh[pousr]_[A-Za-z0-9]{36,}
anthropic-key	sk-ant-[A-Za-z0-9_-]{20,}
openai-key	sk-(proj-)?[A-Za-z0-9]{32,}
slack-token	xox[baprs]-[A-Za-z0-9-]{10,}
stripe-key	(sk|rk)_live_[A-Za-z0-9]{20,}
google-api-key	AIza[0-9A-Za-z_-]{35}
private-key	-----BEGIN ([A-Z]+ )?PRIVATE KEY-----
jwt	eyJ[A-Za-z0-9_-]{10,}[.]eyJ[A-Za-z0-9_-]{10,}[.][A-Za-z0-9_-]{10,}
assigned-secret	([Pp]ass(word|wd)|PASS(WORD|WD)|[Ss]ecret|SECRET|[Aa]pi_?[Kk]ey|API_?KEY|[Tt]oken|TOKEN)["']?[[:space:]]*[:=][[:space:]]*["'][^"'[:space:]]{12,}["']
EOF
	{ git diff -U0 --no-color --no-ext-diff --src-prefix=a/ --dst-prefix=b/ "$mb" | awk '
		/^\+\+\+ b\// { file = substr($0, 7); next }
		/^@@/ { split($3, a, ","); line = substr(a[1], 2) + 0; next }
		/^\+/ && file != "" { print file "\t" line "\t" substr($0, 2); line++ }'
		git ls-files --others --exclude-standard -z -- . ':!.bottega' | while IFS= read -r -d '' f; do
			[ -f "$f" ] && grep -Iq . "$f" 2>/dev/null && awk -v f="$f" '{ print f "\t" NR "\t" $0 }' "$f" 2>/dev/null
		done; } > "$added_file"
	# One pass over the added lines checks every rule. Prints file:line and the rule, never the line.
	report=$(awk -F'\t' 'FNR == NR { if ($1 != "") { name[++n] = $1; re[n] = $2 }; next }
		{ text = $0; sub(/^[^\t]*\t[^\t]*\t/, "", text)
		  for (i = 1; i <= n; i++) if (text ~ re[i]) print $1 ":" $2 ": " name[i] }' "$rules_file" "$added_file")
	hits=0
	if [ -n "$report" ]; then
		printf '%s\n' "$report"
		hits=$(printf '%s\n' "$report" | grep -c .)
	fi
	if [ "$hits" -gt 0 ]; then
		echo "$hits possible secret(s). Values not shown. Install gitleaks for a fuller scan."
		status=1
	else
		echo "built-in patterns: clean (install gitleaks for a fuller scan)"
	fi
fi

echo "== deps"
run_audit() { # <label> <tool> <command...>
	local label="$1" tool="$2"; shift 2
	if command -v "$tool" >/dev/null 2>&1; then
		if "$@" >"$out_dir/$label.txt" 2>&1; then
			echo "$label: clean"
		else
			echo "$label: findings, see $out_dir/$label.txt (tail below)"
			tail -n 5 "$out_dir/$label.txt"
			status=1
		fi
	else
		echo "$label: manifest changed but '$tool' is not installed; audit skipped"
	fi
}
dep_hit=0
has() { printf '%s\n' "$changed" | grep -Eq "$1"; }
if has '(^|/)(package\.json|package-lock\.json|npm-shrinkwrap\.json)$'; then dep_hit=1; if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then run_audit npm-audit npm npm audit --omit=dev; else echo "npm-audit: no lockfile; audit skipped"; fi; fi
if has '(^|/)pnpm-lock\.yaml$'; then dep_hit=1; run_audit pnpm-audit pnpm pnpm audit --prod; fi
if has '(^|/)yarn\.lock$'; then dep_hit=1; run_audit yarn-audit yarn yarn npm audit; fi
if has '(^|/)(requirements[^/]*\.txt|pyproject\.toml|poetry\.lock|uv\.lock|Pipfile\.lock)$'; then dep_hit=1; run_audit pip-audit pip-audit pip-audit; fi
if has '(^|/)Cargo\.(toml|lock)$'; then dep_hit=1; run_audit cargo-audit cargo-audit cargo-audit audit; fi
if has '(^|/)go\.(mod|sum)$'; then dep_hit=1; run_audit govulncheck govulncheck govulncheck ./...; fi
if has '(^|/)Gemfile\.lock$'; then dep_hit=1; run_audit bundle-audit bundle-audit bundle-audit check --update; fi
[ "$dep_hit" -eq 0 ] && echo "no dependency manifests changed"
[ "$dep_hit" -eq 1 ] && echo "new dependencies also need a license check against the project's license"

echo "== surface"
# Kept in a variable: bash 3.2 misparses a quoted regex with parentheses inside $( ).
surface_re='(auth|login|session|token|crypto|password|permission|acl|secret|oauth|saml|jwt)|(^|/)\.github/workflows/|(^|/)Dockerfile|\.tf$|(^|/)k8s/|(^|/)helm/|(^|/)\.env'
surface=$(printf '%s\n' "$changed" | grep -Ei "$surface_re" || true)
if [ -n "$surface" ]; then
	printf '%s\n' "$surface" | sed 's/^/sensitive: /'
	echo "sensitive paths changed: run a security review before shipping"
else
	echo "no sensitive paths changed"
fi

exit "$status"
