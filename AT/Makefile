BENCHMARKS := AT1 AT2 AT1_2 AT5 AT6 AT6a AT6b AT6c

doc: $(BENCHMARKS:%=run_falcaun_%.html) run_falcaun_AT1_2_constrained.html run_falcaun_AT6c_constrained.html

%.html: %.sh
	robodoc --src $< --doc $(basename $@) --singlefile --html --tell --nosort --nopre

clean:
	$(RM) *.html *.css *.js

.PHONY: doc
