#!/usr/bin/env bash
# Trivial scenario fixture: a clean repo whose check fails until the builder
# appends the missing line.
set -eu

git init -q -b feat/lab
mkdir -p scripts
printf 'hello\n' > greeting.txt
printf '#!/usr/bin/env bash\nset -eu\ngrep -qx bye greeting.txt\n' > scripts/check
chmod +x scripts/check
git add greeting.txt scripts/check
git commit -q -m "lab fixture"
