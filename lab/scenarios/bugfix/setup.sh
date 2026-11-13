#!/usr/bin/env bash
# Bugfix scenario fixture: answer.sh prints the wrong number, so scripts/check
# fails until the builder fixes it.
set -eu

git init -q -b feat/lab
mkdir -p scripts
printf '#!/usr/bin/env bash\necho 3\n' > answer.sh
printf '#!/usr/bin/env bash\nset -eu\n[ "$(bash answer.sh)" = 4 ]\n' > scripts/check
chmod +x answer.sh scripts/check
git add answer.sh scripts/check
git commit -q -m "lab fixture"
