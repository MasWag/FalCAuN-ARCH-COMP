#!/bin/sh -u
#****h* transmission/run_falcaun_AT6b
# NAME
#  run_falcaun_AT6b.sh
# DESCRIPTION
#  Script to falsify the AT6b formula by FalCAuN
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/03/05: initial version
#
# COPYRIGHT
#  Copyright (c) 2021 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
#
# PORTABILITY
#  This script asuses the following:
#  - The environment variable MATLAB_HOME is set to the root directory of MATLAB, e.g., /Applications/MATLAB_R2020b.app/ or /usr/local/MATLAB/R2020b.
#  - FalCAuN is installed at ${HOME}/FalCAuN.
#
# USAGE
#  ./run_falcaun_AT6b.sh [from to]
#
# NOTES
#  By default, this script runs FalCAuN for 50 times. When you want to run for a different interval, specify the range by the first and the second arguments.
#
#******


cd "$(dirname "$0")" || exit 0


#****if* run_falcaun_AT6b/configuration
# DESCRIPTION
#
# SOURCE
#
atexit() {
  [ -n "${input_mapper-}" ] && rm -f "$input_mapper"
  [ -n "${output_mapper-}" ] && rm -f "$output_mapper"
  [ -n "${stl_file-}" ] && rm -f "$stl_file"
}

trap atexit EXIT
trap 'rc=$?; trap - EXIT; atexit; exit $?' INT PIPE TERM
#******

#****d* run_falcaun_AT6b/configuration
# DESCRIPTION
#  Define the constants for the execution
# PORTABILITY
#  We assume that FalCAuN is installed at ${HOME}/FalCAuN. Please modify the following definition if FalCAuN is installed somewhere else.
# SOURCE
#
readonly LENGTH=25
readonly SIGNAL_STEP=2.0
readonly POPULATION_SIZE=50
readonly CROSSOVER_PROB=0.9
readonly MUTATION_PROB=0.01
readonly TIMEOUT=$((20 * 60)) # 20 min.
readonly SELECTION_KIND=Tournament
readonly MAX_TEST=1000
readonly KIND=ga

readonly FALCAUN_PATH=${HOME}/FalCAuN/
#******

input_mapper=$(mktemp /tmp/AT.XXXXXX.imap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$input_mapper"
#****d* run_falcaun_AT6b/input_mapper
# DESCRIPTION
#  Define the input mapper
#
#  The input values are as follows:
#  - throttle: 0 or 100
#  - brake: 0 or 325
#
# SOURCE
#
0.0	50.0	100.0
0.0	325.0
#******
EOF

output_mapper=$(mktemp /tmp/AT.XXXXXX.omap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$output_mapper"
#****d* run_falcaun_AT6b/output_mapper
# DESCRIPTION
#  Define the output mapper
#
#  We distinguish the output by the following threshold:
#  - velocity: 35, 50, 65
#  - rotation: 3000
#  - gear: none
#
# SOURCE
#
35	50	65	inf
3000	inf
inf
#******
EOF

stl_file=$(mktemp /tmp/AT.XXXXXX.stl)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$stl_file"
#****d* run_falcaun_AT6b/stl_file
# DESCRIPTION
#  Define the STL formulas to be falsified
#
# NOTES
#  Since the signal step is 2.0, the time bounds are divided by two, e.g., 30 -> 15 and 4 -> 2.
#
# SOURCE
#
(alw_[0, 15] (signal(1) < 3000.0)) -> (alw_[0, 4] (signal(0) < 50.0))
#******
EOF

from=${1:-1}
to=${2:-50}

mkdir -p results

#****f* run_falcaun_AT6b/execute
# DESCRIPTION
#  Execute FalCAuN for falsification
# OUTPUT
#  This script output the following files for each iteration:
#  - ./results/learned-$prefix.dot: the dot file representing the learned Mealy machine.
#  - ./results/learned-$prefix.etf: the etf file representing the counterexamples.
#  - ./results/result-$prefix.txt: the log of the execution.
#
# SOURCE
for t in $(seq "$from" "$to"); do
    prefix="AT6b_$t"
    rm -f Autotrans_shift.mdl.autosave

    "${FALCAUN_PATH}falcaun" \
                   --stl-file="$stl_file" \
                   --input-mapper="$input_mapper" \
                   --output-mapper="$output_mapper" \
                   --signal-length=$LENGTH\
                   --step-time=$SIGNAL_STEP\
                   --equiv=$KIND\
                   --timeout $TIMEOUT\
                   --ga-crossover-prob=$CROSSOVER_PROB\
                   --ga-mutation-prob=$MUTATION_PROB\
                   --population-size=$POPULATION_SIZE\
                   --ga-selection-kind=$SELECTION_KIND\
                   --init="init_falcaun"\
                   --param-names="throttle brake"\
                   --output-dot="./results/learned-$prefix.dot"\
                   --output-etf="./results/learned-$prefix.etf"\
                   --max-test=$MAX_TEST  |
        tee "./results/result-$prefix.txt"
done
#******

#****** run_falcaun_AT6b/references
# SEE ALSO
# - [ARCH-COMP'20]: Ernst, Gidon, et al. "ARCH-COMP 2020 Category Report: Falsification." EPiC Series in Computing (2020).
#******
