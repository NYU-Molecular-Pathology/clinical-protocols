SHELL:=/bin/bash

vcflib: 
	git clone --recursive https://github.com/ekg/vcflib.git

vcflib/bin/vcf2tsv: vcflib
	cd vcflib && \
	make

vcf2tsv: vcflib/bin/vcf2tsv
	ln -fs vcflib/bin/vcf2tsv

clean:
	[ -d vcflib ] && mv vcflib vcflibold && rm -rf vcflibold & 
