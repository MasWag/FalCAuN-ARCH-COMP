#!/bin/sh -u
#****h* transmission/run_falcaun_CC_new
# NAME
#  run_falcaun_CC_new.sh
# DESCRIPTION
#  Script to falsify the CC_new formula by FalCAuN
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/06/15: initial version
# COPYRIGHT
#  Copyright (c) 2021 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
#
# STATUS
#   FalCAuN cannot handle this benchmark because the size of the translated LTL formula is too huge.
#
# PORTABILITY
#  This script asuses the following:
#  - The environment variable MATLAB_HOME is set to the root directory of MATLAB, e.g., /Applications/MATLAB_R2020b.app/ or /usr/local/MATLAB/R2020b.
#  - FalCAuN is installed at ${HOME}/Codes/FalCAuN.
#
# USAGE
#  ./run_falcaun_CC_new.sh [from to]
# NOTES
#  By default, this script runs FalCAuN for 50 times. When you want to run for a different interval, specify the range by the first and the second arguments.
#
#******


cd "$(dirname "$0")" || exit 0


#****if* run_falcaun_CC_new/configuration
# DESCRIPTION
#
# SOURCE
#
atexit() {
  [ -n "${input_mapper-}" ] && rm -f "$input_mapper"
  [ -n "${output_mapper-}" ] && rm -f "$output_mapper"
  [ -n "${signal_mapper-}" ] && rm -f "$signal_mapper"
  [ -n "${stl_file-}" ] && rm -f "$stl_file"
}

trap atexit EXIT
trap 'rc=$?; trap - EXIT; atexit; exit $?' INT PIPE TERM
#******

#****d* run_falcaun_CC_new/configuration
# DESCRIPTION
#  Define the constants for the execution
# PORTABILITY
#  We assume that FalCAuN is installed at ${HOME}/Codes/FalCAuN. Please modify the following definition if FalCAuN is installed somewhere else.
# SOURCE
#
readonly LENGTH=11
readonly SIGNAL_STEP=5.0
readonly POPULATION_SIZE=50
readonly CROSSOVER_PROB=0.9
readonly MUTATION_PROB=0.01
readonly TIMEOUT=$((5 * 60)) #$((240 * 60)) # 240 min.
readonly SELECTION_KIND=Tournament
readonly MAX_TEST=50000
readonly KIND=GA

readonly FALCAUN_PATH=${HOME}/Codes/FalCAuN/
#readonly FALCAUN_PATH=${HOME}/FalCAuN/
#******

input_mapper=$(mktemp /tmp/CC_new.imap.tsv.XXXXXX)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$input_mapper"
#****d* run_falcaun_CC_new/input_mapper
# DESCRIPTION
#  Define the input mapper
#
#  The input values are as follows:
#  - In1 (Throttle): 0 or 1
#  - In2 (Brake): 0 or 1
#
# SOURCE
#
0	1
0	1
#******
EOF

y1="signal(0)"
y2="signal(1)"
y3="signal(2)"
y4="signal(3)"
y5="signal(4)"
y2_minus_y1="signal(5)"
y3_minus_y2="signal(6)"
y4_minus_y3="signal(7)"
y5_minus_y4="signal(8)"

signal_mapper=$(mktemp /tmp/CC_new.sigmap.XXXXXX)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$signal_mapper"
#****d* run_falcaun_CC_new/signal_mapper
# DESCRIPTION
#  Define the signal mapper
# NOTES
#  In the paper, signal are 1-origin while in FalCAuN, signals are 0-origin.
#
# SOURCE
#
$y2 - $y1
$y3 - $y2
$y4 - $y3
$y5 - $y4
#******
EOF

output_mapper=$(mktemp /tmp/CC_new.omap.tsv.XXXXXX)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$output_mapper"
#****d* run_falcaun_CC_new/output_mapper
# DESCRIPTION
#  Define the output mapper
#
#  We distinguish the output by the following threshold:
#  - y1: none
#  - y2: none
#  - y3: none
#  - y4: none
#  - y5: none
#  - y2 - y1: 7.5
#  - y3 - y2: 7.5
#  - y4 - y3: 7.5
#  - y5 - y4: 7.5
#
# SOURCE
#
inf
inf
inf
inf
inf
7.5	inf
7.5	inf
7.5	inf
7.5	inf
#******
EOF

stl_file=$(mktemp /tmp/CC_new.stl.XXXXXX)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$stl_file"
#****d* run_falcaun_CC_new/stl_file
# DESCRIPTION
#  Define the STL formulas to be falsified
#
# NOTES
#  We note the following:
#  - Since the signal step is 5.0, the time bounds are divided by 5, i.e., 50 -> 10.
#
# SEE ALSO
#   https://gitlab.com/goranf/ARCH-COMP/-/blob/master/models/FALS/chasing-cars/requirements.txt
#
# SOURCE
#
(alw_[0,10]($y2_minus_y1 > 7.5)) && (alw_[0,10]($y3_minus_y2 > 7.5)) && (alw_[0,10]($y4_minus_y3 > 7.5)) && (alw_[0,10]($y5_minus_y4 > 7.5))
#******
EOF

from=${1:-1}
to=${2:-50}

mkdir -p results

#****f* run_falcaun_CC_new/execute
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
    prefix="CC_new_$t"
    rm -f Autotrans_shift.mdl.autosave

    "${FALCAUN_PATH}falcaun" \
                   --stl-file="$stl_file" \
                   --input-mapper="$input_mapper" \
                   --output-mapper="$output_mapper" \
                   --signal-mapper="$signal_mapper" \
                   --signal-length=$LENGTH\
                   --step-time=$SIGNAL_STEP\
                   --equiv=$KIND\
                   --timeout $TIMEOUT\
                   --ga-crossover-prob=$CROSSOVER_PROB\
                   --ga-mutation-prob=$MUTATION_PROB\
                   --population-size=$POPULATION_SIZE\
                   --ga-selection-kind=$SELECTION_KIND\
                   --init="mdl = 'cars'; load_system(mdl);"\
                   --param-names="In1 In2"\
                   --output-dot="./results/learned-$prefix.dot"\
                   --output-etf="./results/learned-$prefix.etf"\
                   --max-test=$MAX_TEST  |
        tee "./results/result-$prefix.txt"
done
#******

#****** run_falcaun_CC_new/references
# SEE ALSO
# - [ARCH-COMP'20]: Ernst, Gidon, et al. "ARCH-COMP 2020 Category Report: Falsification." EPiC Series in Computing (2020).
#******
