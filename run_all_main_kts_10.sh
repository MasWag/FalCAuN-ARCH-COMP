#!/bin/sh

set -u

cd "$(dirname "$0")" || exit 1
exec ./run_all_main_kts.sh 10
