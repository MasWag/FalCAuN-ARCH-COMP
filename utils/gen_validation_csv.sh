#!/bin/sh -u
#****h* utils/gen_validation_csv
# NAME
#  gen_validation_csv
# DESCRIPTION
#  Script to generate a row of the validation CSV for ARCH-COMP from the log file of FalCAuN. See https://gitlab.com/gernst/ARCH-COMP/-/blob/FALS/2021/FALS/Validation.md for the information on the CSV file.
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/05/18: initial version
#   - 2021/06/13: updated for FalCAuN v0.4
#   - 2023/03/15: updated for FalCAuN v0.4
#   - 2023/04/04: added the column simulation_time for ARCH-COMP 2023
# COPYRIGHT
#  Copyright (c) 2021 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
#
# USAGE
#  ./gen_validation_csv file1 [file2 ...]
#
#******

if [ $# -le 0 ]; then
    echo 'Usage: gen_validation_csv file1 [file2 ...]'
    exit 0
fi

# Print the header
printf '"system","property","simulations","time","simulation_time","falsified","input"\n'

while [ $# -gt 0 ]; do
    input_path=$1
    input_filename=$(basename "$input_path")
    input_dirname=$(cd "$(dirname "$input_path")" && pwd)

    # Parse system and property from the filename
    system=$(dirname "$input_dirname" | xargs basename)
    property=$(echo "$input_filename" | sed 's/result-//;s/_.*//;')

    # Parse the falsification result
    simulations=$(awk '/Simulink Execution:/{print $8}' "$input_path")
    time=$(awk '/BBC Elapsed Time/{print $9}' "$input_path")
    simulation_time=$(awk '/Simulink Execution Time/{print $9}' "$input_path")
    if grep 'The following properties are falsified' "$input_path" > /dev/null 2>&1; then
        falsified=yes
        input=$(grep -F 'Concrete Input' "$input_path" | # extract the line
                    sed 's/.*: //;') # Remove the key
    else
        falsified=no
        input=""
    fi
    # Print each row
    printf '"%s","%s","%s","%s","%s","%s","%s"\n' "$system" "$property" "$simulations" "$time" "$simulation_time" "$falsified" "$input"
    shift
done
