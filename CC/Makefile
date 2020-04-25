doc: run_falcaun_CC1-3.html

%.html: %.sh
	robodoc --src $< --doc $(basename $@) --singlefile --html --tell --nosort --nopre

clean:
	$(RM) *.html *.css *.js

.PHONY: doc
