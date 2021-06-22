#!/bin/sh -u
#****h* SC/run_falcaun_SC
# NAME
#  run_falcaun_SC.sh
# DESCRIPTION
#  Script to falsify the SC formulas by FalCAuN
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/05/05: initial version
#
# PORTABILITY
#  This script asuses the following:
#  - The environment variable MATLAB_HOME is set to the root directory of MATLAB, e.g., /Applications/MATLAB_R2020b.app/ or /usr/local/MATLAB/R2020b.
#  - FalCAuN is installed at ${HOME}/Codes/FalCAuN.
#
# USAGE
#    ./run_falcaun_SC.sh [from to]
#
# NOTES
#  By default, this script runs FalCAuN for 50 times. When you want to run for a different interval, specify the range by the first and the second arguments.
#
#******


cd "$(dirname "$0")" || exit 0


#****if* run_falcaun_SC/configuration
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

#****d* run_falcaun_SC/configuration
# DESCRIPTION
#  Define the constants for the execution
# PORTABILITY
#  We assume that FalCAuN is installed at ${HOME}/Codes/FalCAuN. Please modify the following definition if FalCAuN is installed somewhere else.
# SOURCE
#
readonly LENGTH=36
readonly SIGNAL_STEP=1.0
readonly POPULATION_SIZE=50
readonly CROSSOVER_PROB=0.5
readonly MUTATION_PROB=0.01
readonly TIMEOUT=$((5 * 60)) # 5 min
readonly SELECTION_KIND=Tournament
readonly MAX_TEST=50000
readonly KIND=ga

#readonly FALCAUN_PATH=${HOME}/Codes/FalCAuN/
readonly FALCAUN_PATH=${HOME}/FalCAuN/
#******

input_mapper=$(mktemp /tmp/SC.XXXXXX.imap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$input_mapper"
#****d* run_falcaun_SC/input_mapper
# DESCRIPTION
#  Define the input mapper
#
#  The input values are as follows:
#  - 3.99, 4.00, or 4.01
#
# SOURCE
#
3.99	4.00	4.01
#******
EOF

output_mapper=$(mktemp /tmp/SC.XXXXXX.omap.tsv)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$output_mapper"
#****d* run_falcaun_SC/output_mapper
# DESCRIPTION
#  Define the output mapper
#
#  We distinguish the output by the following threshold:
#  - T: none
#  - Fcw: none
#  - Q: none
#  - pressure: 87 or 87.5
#
# SOURCE
#
inf
inf
inf
87	87.5	inf
#******
EOF

stl_file=$(mktemp /tmp/SC.XXXXXX.stl)
cat <<EOF | sed 's/#.*$//;/^$/d;' > "$stl_file"
#****d* run_falcaun_SC/stl_file
# DESCRIPTION
#  Define the STL formulas to be falsified
#
# SOURCE
#
alw_[30, 35] (signal(0) > 87 && signal(0) < 87.5)
#******
EOF

from=${1:-1}
to=${2:-50}

mkdir -p results

#****f* run_falcaun_SC/execute
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
    prefix="SC_$t"
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
                   --param-names="input"\
                   --output-dot="./results/learned-$prefix.dot"\
                   --output-etf="./results/learned-$prefix.etf"\
                   --max-test=$MAX_TEST  |
        tee "./results/result-$prefix.txt"
done
#******

#****** run_falcaun_SC"/references
# SEE ALSO
# - [ARCH-COMP'20]: Ernst, Gidon, et al. "ARCH-COMP 2020 Category Report: Falsification." EPiC Series in Computing (2020).
#******
