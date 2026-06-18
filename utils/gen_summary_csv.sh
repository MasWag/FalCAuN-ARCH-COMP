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

# The gen_summary_csv.awk script uses gawk-specific features (asort), so we must use gawk.
if command -v gawk >/dev/null 2>&1; then
    AWK_CMD="gawk"
elif command -v awk >/dev/null 2>&1 && awk --version 2>&1 | grep -q "GNU Awk"; then
    AWK_CMD="awk"
else
    echo "Error: GNU Awk (gawk) is required but not found." >&2
    exit 1
fi



# Make a temporary file
TMP_FILE=$(mktemp /tmp/summary_csv.XXXXXX)

# Concatenate CSV files with awk, keeping only the first header
cat "$@" |
    # Save the input to a temporary file to reuse it
    tee "$TMP_FILE" |
    # Read the first two fields of each line for grouping
    $AWK_CMD -F, 'BEGIN {OFS=","} NR > 1 {print $1, $2}' | sort | uniq |
    while read -r line; do
        # Extract the first two fields
        field1=$(echo "$line" | cut -d, -f1)
        field2=$(echo "$line" | cut -d, -f2)

        # Filter lines that match the first two fields
        $AWK_CMD -F, -v f1="$field1" -v f2="$field2" 'BEGIN {OFS=","} NR == 1 || ($1 == f1 && $2 == f2) {print $0}' < "$TMP_FILE" |
            # Process the filtered lines with the awk script
            $AWK_CMD -f "$ROOT_DIR/gen_summary_csv.awk"
    done |
    # Remove duplicate lines and filter out empty system/property lines
    $AWK_CMD 'BEGIN {header_printed=0}
         $0 ~ /^"system","property"/ {
             if (!header_printed) {
                 print $0
                 header_printed=1
             }
             next
         }
         $1 != "\"\"" && $1 != "\"system\"" {
             print $0
         }'

# Remove the temporary file
rm -f "$TMP_FILE"
