#!/bin/sh -u
#****h* transmission/run_falcaun_AT1_2_constrained
# NAME
#  run_falcaun_AT1_2_constrained.sh
# DESCRIPTION
#  Script to falsify the AT1_2 formulas by FalCAuN
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/05/05: initial version
#
# PORTABILITY
#  This script asuses the following:
#  - The environment variable MATLAB_HOME is set to the root directory of MATLAB, e.g., /Applications/MATLAB_R2020b.app/ or /usr/local/MATLAB/R2020b.
#  - FalCAuN is installed at ${HOME}/FalCAuN.
#
# USAGE
#  ./run_falcaun_AT1_2_constrained.sh [from to]
# NOTES
#  By default, this script runs FalCAuN for 50 times. When you want to run for a different interval, specify the range by the first and the second arguments.
#
#******


cd "$(dirname "$0")" || exit 0


#****if* run_falcaun_AT1_2_constrained/configuration
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

#****d* run_falcaun_AT1_2_constrained/configuration
# DESCRIPTION
#  Define the constants for the execution
# PORTABILITY
#  We assume that FalCAuN is installed at ${HOME}/FalCAuN. Please modify the following definition if FalCAuN is installed somewhere else.
# SOURCE
#
readonly LENGTH=6
readonly SIGNAL_STEP=5.0
readonly POPULATION_SIZE=50
readonly CROSSOVER_PROB=0.9
readonly MUTATION_PROB=0.01
readonly TIMEOUT=$((20 * 60)) #$((240 * 60)) # 240 min.
readonly SELECTION_KIND=Tournament
readonly MAX_TEST=50000
readonly KIND=GA
#readonly KIND=WP

readonly FALCAUN_PATH="${HOME}"/FalCAuN/
#******

input_mapper=$(mktemp /tmp/AT.XXXXXX.imap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$input_mapper"
#****d* run_falcaun_AT1_2_constrained/input_mapper
# DESCRIPTION
#  Define the input mapper
#
#  The input values are as follows:
#  - throttle: 0, 25, 50, 75, or 100
#  - brake: 0, 81.25, 162.5, 243.75, or 325
#
# SOURCE
#
0.0	25.0	50.0	75.0	100.0
0.0	81.25	162.5	243.75	325.0
#******
EOF

output_mapper=$(mktemp /tmp/AT.XXXXXX.omap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$output_mapper"
#****d* run_falcaun_AT1_2_constrained/output_mapper
# DESCRIPTION
#  Define the output mapper
#
#  We distinguish the output by the following threshold:
#  - velocity: 120
#  - rotation: 4750
#  - gear: none
#
# SOURCE
#
120	inf
4750	inf
inf
#******
EOF

stl_file=$(mktemp /tmp/AT.XXXXXX.stl)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$stl_file"
#****d* run_falcaun_AT1_2_constrained/stl_file
# DESCRIPTION
#  Define the STL formulas to be falsified
#
# NOTES
#  Since the signal step is 2.0, the time bounds are divided by two, i.e., 20 -> 10 and 10 -> 5.
#
# SOURCE
#
alw_[0, 4] (signal(0) < 120)
alw_[0, 2] (signal(1) < 4750)
#******
EOF

from=${1:-1}
to=${2:-50}

mkdir -p results

#****f* run_falcaun_AT1_2_constrained/execute
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
    prefix="AT1_2_constrained_$t"
    rm -f Autotrans_shift.mdl.autosave
    # Kill MathWorks Service Host if it is running
    killall MathWorksServiceHost

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
                   --wp-max-depth=$LENGTH\
                   --init="init_falcaun"\
                   --param-names="throttle brake"\
                   --output-dot="./results/learned-$prefix.dot"\
                   --output-etf="./results/learned-$prefix.etf"\
                   --max-test=$MAX_TEST  |
        tee "./results/result-$prefix.txt"
done
#******

#****** run_falcaun_AT1_2_constrained/references
# SEE ALSO
# - [ARCH-COMP'20]: Ernst, Gidon, et al. "ARCH-COMP 2020 Category Report: Falsification." EPiC Series in Computing (2020).
#******
