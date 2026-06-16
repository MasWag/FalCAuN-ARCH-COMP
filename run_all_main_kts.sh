#!/bin/sh

set -u

scripts='
AT/AT1.main.kts
AT/AT2.main.kts
AT/AT6a.main.kts
AT/AT6abc.main.kts
AT/AT6b.main.kts
AT/AT6c.main.kts
CC/CC1.main.kts
CC/CC2.main.kts
CC/CC3.main.kts
CC/CC4.main.kts
CC/CCx.main.kts
SC/SCa.main.kts
PM/pacemaker.main.kts
'

status=0
for script in $scripts; do
    dir=$(dirname "$script")
    base=$(basename "$script")
    printf '%s\n' "===== $script ====="
    (
        cd "$dir" || exit 1
        "./$base" "$@"
    )
    rc=$?
    printf '%s\n' "===== $script exit $rc ====="
    if [ "$rc" -ne 0 ]; then
        status=$rc
    fi
done

exit "$status"
