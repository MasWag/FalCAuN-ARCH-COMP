#!/bin/sh -u
#****h* utils/gen_result_csv
# NAME
#  gen_result_csv
# DESCRIPTION
#  Script to generate a row of the resulting CSV for ARCH-COMP from the log file of FalCAuN.
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/06/17: initial version
# COPYRIGHT
#  Copyright (c) 2021 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
#
# USAGE
#  ./gen_result_csv.sh file1 [file2 ...]
#
#******

if [ $# -le 0 ]; then
    echo 'Usage: gen_result_csv file1 [file2 ...]'
    exit 0
fi

# Print the header
printf '"system","property","total simulations","total time","simulations for equivalence testing","simulation time","falsified","input"\n'

while [ $# -gt 0 ]; do
    input_path=$1
    input_filename=$(basename "$input_path")
    input_dirname=$(cd "$(dirname "$input_path")" && pwd)

    # Parse system and property from the filename
    system=$(dirname "$input_dirname" | xargs basename)
    property=$(echo "$input_filename" | sed 's/result-//;s/_[0-9]*.\.txt//;')

    # Parse the falsification result
    total_simulations=$(awk '/Simulink Execution:/{print $3}' "$input_path")
    total_time=$(awk '/BBC Elapsed Time/{print $4}' "$input_path")
    eq_simulations=$(awk '/Simulink Execution for Equivalence Testing:/{print $6}' "$input_path")
    simulation_time=$(awk '/Simulink Execution Time/{print $4}' "$input_path")
    if grep 'The following properties are falsified' "$input_path" > /dev/null 2>&1; then
        falsified=yes
        input=$(grep -F 'Concrete Input' "$input_path" | # extract the line
                    sed 's/.*: //;') # Remove the key
    else
        falsified=no
        input=""
    fi
    # Print each row
    printf '"%s","%s","%s","%s","%s","%s","%s","%s"\n' "$system" "$property" "$total_simulations" "$total_time" "$eq_simulations" "$simulation_time" "$falsified" "$input"
    shift
done
