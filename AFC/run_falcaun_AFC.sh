#!/bin/sh -u
#****h* transmission/run_falcaun_AFC
# NAME
#  run_falcaun_AFC.sh
# DESCRIPTION
#  Script to falsify the AFC formulas by FalCAuN
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/03/05: initial version
#
# PORTABILITY
#  This script asuses the following:
#  - The environment variable MATLAB_HOME is set to the root directory of MATLAB, e.g., /Applications/MATLAB_R2020b.app/ or /usr/local/MATLAB/R2020b.
#  - FalCAuN is installed at ${HOME}/Codes/FalCAuN.
#
# USAGE
#  ./run_falcaun_AFC.sh
#  ./run_falcaun_AFC.sh [FROM] [TO]
# NOTES
#  By default, this script runs FalCAuN for 50 times. When you want to run for a different interval, specify the range by the first and the second arguments.
#
#******


cd "$(dirname "$0")" || exit 0


#****if* run_falcaun_AFC/configuration
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

#****d* run_falcaun_AFC/configuration
# DESCRIPTION
#  Define the constants for the execution
# PORTABILITY
#  We assume that FalCAuN is installed at ${HOME}/Codes/FalCAuN. Please modify the following definition if FalCAuN is installed somewhere else.
# SOURCE
#
readonly LENGTH=50
readonly SIGNAL_STEP=1.0
readonly POPULATION_SIZE=50
readonly CROSSOVER_PROB=0.9
readonly MUTATION_PROB=0.01
readonly TIMEOUT=$((5 * 60)) #$((240 * 60)) # 240 min.
readonly SELECTION_KIND=Tournament
readonly MAX_TEST=50000
readonly KIND=ga

readonly FALCAUN_PATH=${HOME}/Codes/FalCAuN/
#readonly FALCAUN_PATH=${HOME}/FalCAuN/
#******

input_mapper=$(mktemp /tmp/AFC.XXXXXX.imap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$input_mapper"
#****d* run_falcaun_AFC/input_mapper
# DESCRIPTION
#  Define the input mapper
#
#  The input values are as follows:
#  - throttle: 0, 61.2, or 81.2
#  - engine: 900 or 1100
#
# SOURCE
#
0.0	8.8	40	61.2	81.2
900	1100
#******
EOF

signal_mapper=$(mktemp /tmp/AFC.XXXXXX.sigmap)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$signal_mapper"
#****d* run_falcaun_AFC/signal_mapper
# DESCRIPTION
#  Define the signal mapper
# NOTES
#  In the paper, signal are 1-origin while in FalCAuN, signals are 0-origin.
#
# SOURCE
#
input(0)
#******
EOF

output_mapper=$(mktemp /tmp/AFC.XXXXXX.omap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$output_mapper"
#****d* run_falcaun_AFC/output_mapper
# DESCRIPTION
#  Define the output mapper
#
#  We distinguish the output by the following threshold:
#  - mu: 0.007 and 0.008
#  - mode: 0 and 1
#  - throttle: 8.8, 40.0, 61.2, and 81.2
#
# SOURCE
#
0.007	0.008	inf
0	1	inf
8.8	40.0	61.2	81.2	inf
#******
EOF

stl_file=$(mktemp /tmp/AFC.XXXXXX.stl)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$stl_file"
#****d* run_falcaun_AFC/stl_file
# DESCRIPTION
#  Define the STL formulas to be falsified
#
# NOTES
#  Since the signal step is 1.0, the time bounds are divided by one, i.e., 50 -> 50 and 11 -> 11.
#
# SOURCE
#
alw_[11, 50] ((((signal(2) < 8.8) && X(signal(2) > 40.0)) || ((signal(2) > 40.0) && X(signal(2) < 8.8))) -> alw_[1,5] ((signal(0) < 0.008) && (signal(0) > -0.008)))
alw ((0 <= signal(2)) && (signal(2) < 61.2)) -> alw_[11, 50] ((signal(0) < 0.007) && (signal(0) > -0.007))
alw ((61.2 <= signal(2)) && (signal(2) <= 81.2)) -> alw_[11, 50] ((signal(0) < 0.007) && (signal(0) > -0.007))
#******
EOF

from=${1:-1}
to=${2:-50}

mkdir -p results

#****f* run_falcaun_AFC/execute
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
    prefix="AFC_$t"
    rm -f AbstractFuelControl_M1.slx.autosave

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
                   --init="init_falcaun"\
                   --param-names="throttle mode"\
                   --output-dot="./results/learned-$prefix.dot"\
                   --output-etf="./results/learned-$prefix.etf"\
                   --max-test=$MAX_TEST  |
        tee "./results/result-$prefix.txt"
done
#******

#****** run_falcaun_AFC/references
# SEE ALSO
# - [ARCH-COMP'20]: Ernst, Gidon, et al. "ARCH-COMP 2020 Category Report: Falsification." EPiC Series in Computing (2020).
#******
