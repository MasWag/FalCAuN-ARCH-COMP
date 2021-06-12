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
printf '"system","property","simulations","time","falsified","input"\n'

while [ $# -gt 0 ]; do
    input_path=$1
    input_filename=$(basename "$input_path")
    input_dirname=$(cd "$(dirname "$input_path")" && pwd)

    # Parse system and property from the filename
    system=$(dirname "$input_dirname" | xargs basename)
    property=$(echo "$input_filename" | sed 's/result-//;s/_.*//;')

    # Parse the falsification result
    simulations=$(awk '/Simulink Execution:/{print $3}' "$input_path")
    time=$(awk '/BBC Elapsed Time/{print $4}' "$input_path")
    step_time=$(awk '/Step time:/{print $3}' "$input_path")
    if grep 'The following properties are falsified' "$input_path" > /dev/null 2>&1; then
        falsified=yes
        input=$(grep -F 'Concrete Input' "$input_path" | # extract the line
                    sed 's/.*: //;' | # Remove the key
                    tr -d '[ ' | # Remove useless characters
                    awk -v step_time="$step_time" 'BEGIN {
                                FS = ","
                                RS = "]"
                                OFS = " "
                                ORS = "; "
                                printf "["
                            }
                            NR == 1 { ## Use the first input twice
                                $1 = $1 # change the separators
                                print 0, $0
                            }
                            !/^[[:space:]]*$/ {
                                $1 = $1 # change the separators
                                print step_time * NR, $0
                            }' |
                    sed 's/; $/]/;')
    else
        falsified=no
        input=""
    fi
    # Print each row
    printf '"%s","%s","%s","%s","%s","%s"\n' "$system" "$property" "$simulations" "$time" "$falsified" "$input"
    shift
done
