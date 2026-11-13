#!/usr/bin/env bash
# Stub builder side effect for the bugfix scenario: make answer.sh print 4.
set -eu

printf '#!/usr/bin/env bash\necho 4\n' > answer.sh
chmod +x answer.sh
git add answer.sh
git commit -q -m "lab: fix answer"
