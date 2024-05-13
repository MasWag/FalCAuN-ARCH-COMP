#!/usr/bin/awk -f
#****h* utils/cat_csv
# NAME
#  cat_csv
# DESCRIPTION
#  Script to concatenate CSV files
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2024/05/13: initial version
# COPYRIGHT
#  Copyright (c) 2024 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
#
# USAGE
#  ./cat_csv [file1 file2 ...]
#
# PORTABILITY
#  This script should work for any AWK implementation compliant with the POSIX standard.
#
#******

# Remember the header
NR == 1 {
    $header = $0
    print
}

# Validate the header for each file
FNR == 1 {
    if ($0 != $header) {
        print "Header mismatch in file " FILENAME > "/dev/stderr"
        exit 1
    }
}

# Print the rest of the lines
FNR > 1
