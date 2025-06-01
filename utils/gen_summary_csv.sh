#!/bin/sh
################################################################################
#
# NAME
#  gen_summary_csv.sh
# DESCRIPTION
#  Generate a summary CSV file from the raw CSV files.
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2025/06/01: initial version
# COPYRIGHT
#  Copyright (c) 2025 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
# USAGE
#  gen_summary_csv.sh [raw_csv_files...]
#
################################################################################

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

# Make a temporary file
TMP_FILE=$(mktemp /tmp/summary_csv.XXXXXX)

cat $@ |
    # Save the input to a temporary file to reuse it
    tee "$TMP_FILE" |
    # Read the first two fields of each line for grouping
    awk -F, 'BEGIN {OFS=","} NR > 1 {print $1, $2}' | uniq |
    while read -r line; do
        # Extract the first two fields
        field1=$(echo "$line" | cut -d, -f1)
        field2=$(echo "$line" | cut -d, -f2)

        cat "$TMP_FILE" |
            # Filter lines that match the first two fields
            awk -F, -v f1="$field1" -v f2="$field2" 'BEGIN {OFS=","} NR == 1 || ($1 == f1 && $2 == f2) {print $0}' |
            # Process the filtered lines with the awk script
            awk -f "$ROOT_DIR/gen_summary_csv.awk"
    done |
    # Remove duplicate lines
    awk '$0 in seen {next} {seen[$0] = 1; print $0}'

# Remove the temporary file
rm -f "$TMP_FILE"
