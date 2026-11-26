#!/usr/bin/env bash
# Run the same checks as .github/workflows/validate.yml before pushing.
set -euo pipefail
cd "$(dirname "$0")/.."
for f in skills/maestro/scripts/*.sh skills/maestro/scripts/bottega skills/wizard/template.sh scripts/*.sh; do
	bash -n "$f"
done
python3 scripts/lint-skills.py
bash scripts/test-scripts.sh
if command -v shellcheck >/dev/null 2>&1; then
	shellcheck -S warning skills/maestro/scripts/bottega skills/maestro/scripts/gate-check.sh skills/maestro/scripts/log.sh skills/wizard/template.sh
else echo "note: shellcheck not installed; CI runs it"; fi
if command -v claude >/dev/null 2>&1; then claude plugin validate . --strict
else echo "note: claude not installed; CI validates the plugin"; fi
if command -v agy >/dev/null 2>&1; then agy plugin validate . --strict; fi
echo "check: all passed"
