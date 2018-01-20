# makefile for installing software for the clinical lab
# this does not contain all the software just the ones from after I started this Makefile
SHELL:=/bin/bash

HG19_FA:=/local/data/iGenomes/Homo_sapiens/UCSC/hg19/Sequence/WholeGenomeFasta/genome.fa

# no default action to take
none:

all: bcftools tabix bgzip samtools vcf2tsv IGV pandoc msisensor

# ~~~~~ MSI SENSOR ~~~~~ #
# https://github.com/ding-lab/msisensor
msisensor/msisensor:
	git clone https://github.com/ding-lab/msisensor.git && \
	cd msisensor && \
	module load samtools/0.1.19 && \
	make

# takes about ~5min
msisensor/hg19_microsatellites.list: msisensor/msisensor
	cd msisensor && \
	module load samtools/0.1.19 && \
	./msisensor scan -d "$(HG19_FA)" -o hg19_microsatellites.list

msisensor: msisensor/hg19_microsatellites.list

msisensor-test: msisensor
	cd msisensor/test && \
	module load samtools/0.1.19 && \
	bash run.sh


# ~~~~~ bcftools ~~~~~ #
# http://www.htslib.org/download/
bcftools-1.3.1.tar.bz2:
	wget https://github.com/samtools/bcftools/releases/download/1.3.1/bcftools-1.3.1.tar.bz2
	

bcftools-1.3.1: bcftools-1.3.1.tar.bz2
	tar xvfj bcftools-1.3.1.tar.bz2
	
bcftools-1.3.1/bcftools: bcftools-1.3.1
	cd bcftools-1.3.1 && \
	make

bcftools: bcftools-1.3.1/bcftools
	ln -s bcftools-1.3.1/bcftools


# ~~~~~ hstlib ~~~~~ #
htslib-1.3.1.tar.bz2: 
	wget https://github.com/samtools/htslib/releases/download/1.3.1/htslib-1.3.1.tar.bz2

htslib-1.3.1: htslib-1.3.1.tar.bz2
	tar xvfj htslib-1.3.1.tar.bz2

htslib-1.3.1/htsfile: htslib-1.3.1
	cd htslib-1.3.1 && \
	make

htslib-1.3.1/tabix: htslib-1.3.1/htsfile

htslib-1.3.1/bgzip: htslib-1.3.1/htsfile

tabix: htslib-1.3.1/tabix
	ln -s htslib-1.3.1/tabix

bgzip: htslib-1.3.1/bgzip
	ln -s htslib-1.3.1/bgzip


# ~~~~~ SAMTOOLS ~~~~~ #
samtools-1.3.1.tar.bz2: 
	wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2

samtools-1.3.1: samtools-1.3.1.tar.bz2
	tar xvfj samtools-1.3.1.tar.bz2

samtools-1.3.1/samtools: samtools-1.3.1
	cd samtools-1.3.1 && \
	make

samtools: samtools-1.3.1/samtools
	ln -s samtools-1.3.1/samtools


# ~~~~~ vcflib ~~~~~ #
# https://github.com/vcflib/vcflib
vcflib: 
	git clone --recursive https://github.com/ekg/vcflib.git

vcflib/bin/vcf2tsv: vcflib
	cd vcflib && \
	make

vcf2tsv: vcflib/bin/vcf2tsv
	ln -fs vcflib/bin/vcf2tsv



# ~~~~~ PANDOC ~~~~~ #
pandoc-1.13.1.zip: 
	wget https://s3.amazonaws.com/rstudio-buildtools/pandoc-1.13.1.zip

pandoc-1.13.1/linux/rpm/x86_64/pandoc: pandoc-1.13.1.zip
	unzip pandoc-1.13.1.zip

pandoc: pandoc-1.13.1/linux/rpm/x86_64/pandoc
	ln -s pandoc-1.13.1/linux/rpm/x86_64/pandoc


# ~~~~~ IGV ~~~~~ # 
IGV_2.3.81.zip: 
	wget http://data.broadinstitute.org/igv/projects/downloads/2.3/IGV_2.3.81.zip -O tmp && mv tmp IGV_2.3.81.zip

IGV_2.3.81: IGV_2.3.81.zip
	unzip IGV_2.3.81.zip

IGV: IGV_2.3.81

# ~~~~~ CLEAN UP ~~~~~ #
clean:
	rm -rf msisensor
	rm -rf bcftools-1.3.1 
	rm -f bcftools-1.3.1.tar.bz2
	rm -f htslib-1.3.1.tar.bz2
	rm -rf htslib-1.3.1
	rm -f samtools-1.3.1.tar.bz2
	rm -rf samtools-1.3.1
	rm -rf vcflib
	rm -f pandoc-1.13.1.zip
	rm -rf pandoc-1.13.1
	rm -f IGV_2.3.81.zip
	rm -rf IGV_2.3.81
	unlink samtools
	unlink tabix
	unlink bcftools
	unlink bgzip
	unlink vcf2tsv
	unlink pandoc
