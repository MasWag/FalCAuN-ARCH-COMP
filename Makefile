#****h* FalCAuN/Makefile
# NAME
#  Makefile
# DESCRIPTION
#  Makefile to generate a summary CSV of the experiment results.
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2021/06/16: initial version
# COPYRIGHT
#  Copyright (c) 2021 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
#
# USAGE
#  make
#******


#****h* Makefile/Benchmarks
# DESCRIPTION
#  Define the benchmarks
# SOURCE
#
EXPERIMENT_NUMBERS := $(shell seq 1 50)
AT_BENCHMARKS := AT1 AT2 AT6a AT6b AT6c AT1_constrained AT2_constrained AT6c_constrained 
CC_BENCHMARKS := CC1 CC2 CC3
SC_BENCHMARKS := SC
BENCHMARKS := $(AT_BENCHMARKS)
#******

test: /tmp/AT/results/result-AT1_1.csv /tmp/AT/results/result-AT1_2.csv
	@echo This rule must be removed before deployment.

#****h* Makefile/all
# DESCRIPTION
#  It defines the goal of this Makefile: to generate summary.csv representing the summary of all the experiment results.
# SOURCE
#
all: summary.csv
#******

#****h* Makefile/summary.csv
# DESCRIPTION
#  It generates a summary CSV file for all the benchmarks.
# SOURCE
#
summary.csv: $(AT_BENCHMARKS:%=/tmp/AT/results/summary-%.csv) $(CC_BENCHMARKS:%=/tmp/CC/results/summary-%.csv) $(SC_BENCHMARKS:%=/tmp/SC/results/summary-%.csv)
	awk 'FNR > 1 || NR == 1' $^ > $@
#******

#****h* Makefile/gen_summary_csv
# DESCRIPTION
#  It generates a summary CSV file for each benchmark
# SOURCE
#
summary-%.csv: ./utils/gen_summary_csv.awk $(foreach i,$(EXPERIMENT_NUMBERS), result-%_$i.csv)
	chmod +x $<
	$^ > $@
#******


#****h* Makefile/gen_result_csv
# DESCRIPTION
#  It generates a CSV file for each experiment result.
# SOURCE
#
/tmp/%.csv: %.txt ./utils/gen_result_csv.sh
	mkdir -p $(dir $@)
	./utils/gen_result_csv.sh $< > $@
#******
