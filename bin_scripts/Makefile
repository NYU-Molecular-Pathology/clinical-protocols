# makefile for installing software for the clinical lab
# this does not contain all the software just the ones from after I started this Makefile
SHELL:=/bin/bash

HG19_FA:=/local/data/iGenomes/Homo_sapiens/UCSC/hg19/Sequence/WholeGenomeFasta/genome.fa

# no default action to take
none:

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