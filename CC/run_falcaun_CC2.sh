#!/bin/sh -u
#****h* transmission/run_falcaun_CC2
# NAME
#  run_falcaun_CC2.sh
# DESCRIPTION
#  Script to falsify the CC2 formula by FalCAuN
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/05/23: initial version
#
# PORTABILITY
#  This script asuses the following:
#  - The environment variable MATLAB_HOME is set to the root directory of MATLAB, e.g., /Applications/MATLAB_R2020b.app/ or /usr/local/MATLAB/R2020b.
#  - FalCAuN is installed at ${HOME}/Codes/FalCAuN.
#
# USAGE
#  ./run_falcaun_CC2.sh
#  ./run_falcaun_CC2.sh [FROM] [TO]
# NOTES
#  By default, this script runs FalCAuN for 50 times. When you want to run for a different interval, specify the range by the first and the second arguments.
#
#******


cd "$(dirname "$0")" || exit 0


#****if* run_falcaun_CC2/configuration
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

#****d* run_falcaun_CC2/configuration
# DESCRIPTION
#  Define the constants for the execution
# PORTABILITY
#  We assume that FalCAuN is installed at ${HOME}/Codes/FalCAuN. Please modify the following definition if FalCAuN is installed somewhere else.
# SOURCE
#
readonly LENGTH=10
readonly SIGNAL_STEP=10.0
readonly POPULATION_SIZE=50
readonly CROSSOVER_PROB=0.9
readonly MUTATION_PROB=0.01
readonly TIMEOUT=$((5 * 60)) #$((240 * 60)) # 240 min.
readonly SELECTION_KIND=Tournament
readonly MAX_TEST=50000
readonly KIND=GA

#readonly FALCAUN_PATH=${HOME}/Codes/FalCAuN/
readonly FALCAUN_PATH=${HOME}/FalCAuN/
#******

input_mapper=$(mktemp /tmp/CC2.XXXXXX.imap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$input_mapper"
#****d* run_falcaun_CC2/input_mapper
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

signal_mapper=$(mktemp /tmp/CC2.XXXXXX.sigmap)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$signal_mapper"
#****d* run_falcaun_CC2/signal_mapper
# DESCRIPTION
#  Define the signal mapper
# NOTES
#  In the paper, signal are 1-origin while in FalCAuN, signals are 0-origin.
#
# SOURCE
#
signal(4) - signal(3)
signal(2) - signal(1)
#******
EOF


output_mapper=$(mktemp /tmp/CC2.XXXXXX.omap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$output_mapper"
#****d* run_falcaun_CC2/output_mapper
# DESCRIPTION
#  Define the output mapper
#
#  We distinguish the output by the following threshold:
#  - y1: none
#  - y2: none
#  - y3: none
#  - y4: none
#  - y5: none
#  - y5 - y4: 8, 15, 40
#  - y2 - y1: 20
#
# SOURCE
#
inf
inf
inf
inf
inf
15	40	inf
20	inf
#******
EOF

stl_file=$(mktemp /tmp/CC2.XXXXXX.stl)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$stl_file"
#****d* run_falcaun_CC2/stl_file
# DESCRIPTION
#  Define the STL formulas to be falsified
#
# NOTES
#  We note the following:
#  - Since the signal step is 10.0, the time bounds are divided by 10, i.e., 100 -> 10 and 70 -> 7.
#  - We use strinct operators (i.e., < and > ) rather than non-string operators (>= and <=).
#
# SOURCE
#
alw_[0, 10] (signal(5) < 40)
alw_[0, 7] (ev_[0,3] (signal(5) > 15))
alw_[0, 8] ((alw_[0,2] (signal(6) < 20)) || (ev_[0, 2] (signal(5) > 40)))
#******
EOF

from=${1:-1}
to=${2:-50}

mkdir -p results

#****f* run_falcaun_CC2/execute
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
    prefix="CC2_$t"
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

#****** run_falcaun_CC2/references
# SEE ALSO
# - [ARCH-COMP'20]: Ernst, Gidon, et al. "ARCH-COMP 2020 Category Report: Falsification." EPiC Series in Computing (2020).
#******
