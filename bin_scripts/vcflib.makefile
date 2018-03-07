SHELL:=/bin/bash

vcflib/bin/vcf2tsv: 
	git clone --recursive https://github.com/vcflib/vcflib.git && \
	cd vcflib && \
	make

vcf2tsv: vcflib/bin/vcf2tsv
	ln -fs vcflib/bin/vcf2tsv

clean:
	[ -d vcflib ] && mv vcflib vcflibold && rm -rf vcflibold & 
