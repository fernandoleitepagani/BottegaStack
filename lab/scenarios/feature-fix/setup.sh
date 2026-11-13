#!/usr/bin/env bash
# Feature-fix scenario fixture: scripts/check requires both the feature file and
# the file a revision must add.
set -eu

git init -q -b feat/lab
mkdir -p scripts
printf '#!/usr/bin/env bash\nset -eu\n[ "$(cat feature.txt 2>/dev/null)" = feature ]\n[ "$(cat fixed.txt 2>/dev/null)" = fixed ]\n' > scripts/check
chmod +x scripts/check
printf 'baseline\n' > baseline.txt
git add baseline.txt scripts/check
git commit -q -m "lab fixture"
