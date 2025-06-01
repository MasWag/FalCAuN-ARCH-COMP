#!/usr/bin/awk -f
#****h* utils/gen_summary_csv
# NAME
#  gen_summary_csv
# DESCRIPTION
#  Script to summarize the results of each experiment
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/06/17: initial version
#   - 2024/06/29: Added mean simulation ratio
# COPYRIGHT
#  Copyright (c) 2021 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
#
# USAGE
#  ./gen_summary_csv [file1 file2 ...]
#
#******

BEGIN {
    # Initialize the variables
    num_falsifications = 0
    min_total_simulation = 9999999
    min_total_time = 99999999
    min_eq_simulation = 9999999
    min_simulation_time = 9999999

    # Configuration on the structure
    FS = ","
    OFS = ","
    # Constants
    MAX_TOTAL_SIMULATION = 1500
    # Print the header
    print "\"system\",\"property\",\"mean total simulations\",\"median total simulations\",\"sdev total simulations\",\"min total simulations\",\"max total simulations\",\"mean total time\",\"sdev total time\",\"min total time\",\"max total time\",\"mean simulations for equivalence testing\",\"sdev simulations for equivalence testing\",\"min simulations for equivalence testing\",\"max simulations for equivalence testing\",\"mean simulation time\",\"sdev simulation time\",\"min simulation time\",\"max simulation time\",\"num falsified\",\"mean simulation ratio\""
}

# remove the header
FNR == 1 {
    next
}

# Validate the system and property
NR == 2 {
    system_name = $1
    property = $2
    gsub("\"", "", system_name)
    gsub("\"", "", property)
}

{
    current_system_name = $1
    current_property = $2
    gsub("\"", "", current_system_name)
    gsub("\"", "", current_property)
}

system_name != current_system_name || property != current_property {
    print "Error: inconsistent system or property!" > "/dev/stderr"
    printf "Expected %s %s\n", system_name, property > "/dev/stderr"
    printf "Given %s %s\n", current_system_name, current_property > "/dev/stderr"
    exit 1
}

## Node on the input format: "$system" "$property" "$total_simulations" "$total_time" "$eq_simulations" "$simulation_time" "$falsified" "$input"
# cast relevant fields to int
{
    total_simulation = $3
    total_time = $4
    eq_simulation = $5
    simulation_time = $6
    falsified = $7
    
    # remove quotation
    gsub("\"", "", total_simulation)
    gsub("\"", "", total_time)
    gsub("\"", "", eq_simulation)
    gsub("\"", "", simulation_time)
    gsub("\"", "", falsified)

    # cast to number
    total_simulation *= 1.0
    total_time *= 1.0
    eq_simulation *= 1.0
    simulation_time *= 1.0
}

# accumulate the values for all executions
{
    # Sum
    sum_total_simulation_all += total_simulation
    sum_total_time_all += total_time
    sum_eq_simulation_all += eq_simulation
    sum_simulation_time_all += simulation_time
    # Square sum
    sq_sum_total_simulation_all += total_simulation * total_simulation
    sq_sum_total_time_all += total_time * total_time
    sq_sum_eq_simulation_all += eq_simulation * eq_simulation
    sq_sum_simulation_time_all += simulation_time * simulation_time
}


# Ignore the experiments with too many simulations (and failed experiments)
total_simulation > MAX_TOTAL_SIMULATION || total_simulation == 0 || falsified == "no" {
    next
}

## Update the variables
# update the minimum values
total_simulation < min_total_simulation {
    min_total_simulation = total_simulation
}
total_time < min_total_time {
    min_total_time = total_time
}
eq_simulation < min_eq_simulation {
    min_eq_simulation = eq_simulation
}
simulation_time < min_simulation_time {
    min_simulation_time = simulation_time
}
# update the maximum values
total_simulation > max_total_simulation {
    max_total_simulation = total_simulation
}
total_time > max_total_time {
    max_total_time = total_time
}
eq_simulation > max_eq_simulation {
    max_eq_simulation = eq_simulation
}
simulation_time > max_simulation_time {
    max_simulation_time = simulation_time
}
# accumulate the values for falsified executions
{
    num_falsified += 1
    # Sum
    sum_total_simulation += total_simulation
    sum_total_time += total_time
    sum_eq_simulation += eq_simulation
    sum_simulation_time += simulation_time
    # Square sum
    sq_sum_total_simulation += total_simulation * total_simulation
    sq_sum_total_time += total_time * total_time
    sq_sum_eq_simulation += eq_simulation * eq_simulation
    sq_sum_simulation_time += simulation_time * simulation_time
    # List
    total_simulation_list[NR] = total_simulation
}

function alen(a, i, count) {
    count = 0
    for(i in a) {
        count += 1
    }
    return count
}

END {
    if (num_falsified > 0) {
        # Compute mean
        mean_total_simulation = sum_total_simulation / num_falsified
        mean_total_time = sum_total_time / num_falsified
        mean_eq_simulation = sum_eq_simulation / num_falsified
        mean_simulation_time = sum_simulation_time / num_falsified

        # Compute sdev
        sdev_total_simulation = sqrt((sq_sum_total_simulation / num_falsified) - (mean_total_simulation * mean_total_simulation))
        sdev_total_time = sqrt((sq_sum_total_time / num_falsified) - (mean_total_time * mean_total_time))
        sdev_eq_simulation = sqrt((sq_sum_eq_simulation / num_falsified) - (mean_eq_simulation * mean_eq_simulation))
        sdev_simulation_time = sqrt((sq_sum_simulation_time / num_falsified) - (mean_simulation_time * mean_simulation_time))

        # Compute Median
        asort(total_simulation_list, total_simulation_sorted)
        if (alen(total_simulation_list) == 1) {
            median_total_simulation = int((total_simulation_sorted[int(alen(total_simulation_list) / 2)] + total_simulation_sorted[int(alen(total_simulation_list) / 2) + 1]) / 2)
        } else {
            median_total_simulation = total_simulation_sorted[int(alen(total_simulation_list) / 2)]
        }
    } else {
        # When we failed to falsify, we let everything 0.
        mean_total_simulation = 0
        mean_total_time = 0
        mean_eq_simulation = 0
        mean_simulation_time = 0

        sdev_total_simulation = 0
        sdev_total_time = 0
        sdev_eq_simulation = 0
        sdev_simulation_time = 0
        
        min_total_simulation = 0
        min_total_time = 0
        min_eq_simulation = 0
        min_simulation_time = 0

        median_total_simulation = 0
    }
    mean_simulation_ratio = 100.0 * sum_simulation_time_all / sum_total_time_all

    # Output the summary
    printf "\"%s\",\"%s\",", system_name, property
    printf "\"%g\",\"%g\",\"%g\",\"%d\",\"%d\",",
        mean_total_simulation, median_total_simulation, sdev_total_simulation, min_total_simulation, max_total_simulation
    printf "\"%g\",\"%g\",\"%d\",\"%d\",",
        mean_total_time, sdev_total_time, min_total_time, max_total_time
    printf "\"%g\",\"%g\",\"%d\",\"%d\",",
        mean_eq_simulation, sdev_eq_simulation, min_eq_simulation, max_eq_simulation
    printf "\"%g\",\"%g\",\"%d\",\"%d\",",
        mean_simulation_time, sdev_simulation_time, min_simulation_time, max_simulation_time
    printf "\"%d\",\"%g\"\n", num_falsified, mean_simulation_ratio
}
