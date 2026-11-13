#!/usr/bin/env bash
# Pause-resume scenario fixture: a clean repo with a passing check. The master
# pauses the run, resumes it, and closes it.
set -eu

git init -q -b feat/lab
mkdir -p scripts
printf '#!/usr/bin/env bash\nexit 0\n' > scripts/check
chmod +x scripts/check
git add scripts/check
git commit -q -m "lab fixture"
