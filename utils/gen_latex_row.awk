#!/usr/bin/awk -f
#****h* utils/gen_latex_row
# NAME
#  gen_latex_row
# DESCRIPTION
#  Script to make a row of LaTeX table
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2023/04/12: initial version
# COPYRIGHT
#  Copyright (c) 2023 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
#
# USAGE
#  cat [file1 file2 ...] | ./gen_latex_row 
#
#******

BEGIN {
    FS = ","
    # Header
    #E "\"system\",\"property\",\"mean total simulations\",\"median total simulations\",\"sdev total simulations\",\"min total simulations\",\"max total simulations\",\"mean total time\",\"sdev total time\",\"min total time\",\"max total time\",\"mean simulations for equivalence testing\",\"sdev simulations for equivalence testing\",\"min simulations for equivalence testing\",\"max simulations for equivalence testing\",\"mean simulation time\",\"sdev simulation time\",\"min simulation time\",\"max simulation time\",\"num falsified\""
}

{
	gsub("\"","",$0)
}

# Print the rowValidate the system and property
NR > 1 && $20 > 0 {
    printf "%s: %d & & %.1f & %d & %.1f &\n",$2,$20,$3,$4,(100 * $16 / $8) 
}

