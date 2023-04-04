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
EXPERIMENT_NUMBERS := $(shell seq 1 10)
AT_BENCHMARKS := AT1 AT2 AT6a AT6b AT6c AT1_constrained AT2_constrained AT6c_constrained 
CC_BENCHMARKS := CC1 CC2 CC3
SC_BENCHMARKS := SC
PACEMAKER_BENCHMARKS := pacemaker
BENCHMARKS := $(AT_BENCHMARKS)
#******

#****h* Makefile/all
# DESCRIPTION
#  It defines the goal of this Makefile: to generate summary.csv representing the summary of all the experiment results.
# SOURCE
#
all: summary.csv validation.csv
#******

#****h* Makefile/summary.csv
# DESCRIPTION
#  It generates a summary CSV file for all the benchmarks.
# SOURCE
#
summary.csv: $(AT_BENCHMARKS:%=/tmp/AT/results/summary-%.csv) $(CC_BENCHMARKS:%=/tmp/CC/results/summary-%.csv) $(SC_BENCHMARKS:%=/tmp/SC/results/summary-%.csv) $(PACEMAKER_BENCHMARKS:%=/tmp/pacemaker/results/summary-%.csv)
	awk 'FNR > 1 || NR == 1' $^ > $@

summary-eq.csv: $(AT_BENCHMARKS:%=/tmp/AT/results/summary-eq-%.csv) $(CC_BENCHMARKS:%=/tmp/CC/results/summary-eq-%.csv) $(SC_BENCHMARKS:%=/tmp/SC/results/summary-eq-%.csv) $(PACEMAKER_BENCHMARKS:%=/tmp/pacemaker/results/summary-eq-%.csv)
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

summary-eq-%.csv: ./utils/gen_summary_eq_limit_csv.awk $(foreach i,$(EXPERIMENT_NUMBERS), result-%_$i.csv)
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

#****h* Makefile/validation.csv
# DESCRIPTION
#  It generates a CSV file for validation
# SOURCE
#
validation.csv: $(foreach i,$(EXPERIMENT_NUMBERS),$(AT_BENCHMARKS:%=./AT/results/result-%_$i.txt)) $(foreach i,$(EXPERIMENT_NUMBERS),$(CC_BENCHMARKS:%=./CC/results/result-%_$i.txt)) $(foreach i,$(EXPERIMENT_NUMBERS),$(SC_BENCHMARKS:%=./SC/results/result-%_$i.txt)) $(foreach i,$(EXPERIMENT_NUMBERS),$(PACEMAKER_BENCHMARKS:%=./pacemaker/results/result-%_$i.txt))
	./utils/gen_validation_csv.sh $^ > $@
