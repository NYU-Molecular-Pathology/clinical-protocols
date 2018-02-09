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



# ~~~~~ ANNOVAR ~~~~~ # 
# RUN cd /opt/bin && wget http://www.openbioinformatics.org/annovar/download/0wgxR2rIVP/annovar.revision150617.tar.gz && tar xvfz annovar.revision150617.tar.gz && rm -f annovar.revision150617.tar.gz
# RUN mkdir -p "${ANNOVAR_DB_DIR}"
# RUN "${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar clinvar_20150629 "${ANNOVAR_DB_DIR}"
# RUN "${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar cytoBand "${ANNOVAR_DB_DIR}"
ANNOVAR_DIR:=/ifs/data/molecpathlab/bin/annovar
ANNOVAR_DB_DIR:=/ifs/data/molecpathlab/bin/annovar/db/hg19

annovar.revision150617.tar.gz:
	wget http://www.openbioinformatics.org/annovar/download/0wgxR2rIVP/annovar.revision150617.tar.gz

$(ANNOVAR_DB_DIR)/hg19_ALL.sites.2015_08.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar 1000g2015aug "${ANNOVAR_DB_DIR}"

1000g2015aug: $(ANNOVAR_DB_DIR)/hg19_ALL.sites.2015_08.txt

$(ANNOVAR_DB_DIR)/hg19_refGene.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar refGene "${ANNOVAR_DB_DIR}" 

refGene: $(ANNOVAR_DB_DIR)/hg19_refGene.txt

$(ANNOVAR_DB_DIR)/hg19_cosmic70.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar cosmic70 "${ANNOVAR_DB_DIR}"

cosmic70: $(ANNOVAR_DB_DIR)/hg19_cosmic70.txt

$(ANNOVAR_DB_DIR)/hg19_clinvar_20170905.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar clinvar_20170905 "${ANNOVAR_DB_DIR}"

clinvar_20170905: $(ANNOVAR_DB_DIR)/hg19_clinvar_20170905.txt

$(ANNOVAR_DB_DIR)/hg19_intervar_20170202.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar intervar_20170202 "${ANNOVAR_DB_DIR}"

intervar_20170202: $(ANNOVAR_DB_DIR)/hg19_intervar_20170202.txt


$(ANNOVAR_DB_DIR)/hg19_dbnsfp33a.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar dbnsfp33a "${ANNOVAR_DB_DIR}"
	
dbnsfp33a: $(ANNOVAR_DB_DIR)/hg19_dbnsfp33a.txt

$(ANNOVAR_DB_DIR)/hg19_esp6500siv2_all.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar esp6500siv2_all "${ANNOVAR_DB_DIR}"

esp6500siv2_all: $(ANNOVAR_DB_DIR)/hg19_esp6500siv2_all.txt

$(ANNOVAR_DB_DIR)/hg19_kaviar_20150923.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar kaviar_20150923 "${ANNOVAR_DB_DIR}"

kaviar_20150923: $(ANNOVAR_DB_DIR)/hg19_kaviar_20150923.txt


$(ANNOVAR_DB_DIR)/hg19_gnomad_exome.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar gnomad_exome "${ANNOVAR_DB_DIR}"

gnomad_exome: $(ANNOVAR_DB_DIR)/hg19_gnomad_exome.txt

$(ANNOVAR_DB_DIR)/hg19_gnomad_genome.txt: 
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar gnomad_genome "${ANNOVAR_DB_DIR}"

gnomad_genome: $(ANNOVAR_DB_DIR)/hg19_gnomad_genome.txt

$(ANNOVAR_DB_DIR)/hg19_avsnp150.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar avsnp150 "${ANNOVAR_DB_DIR}"

avsnp150: $(ANNOVAR_DB_DIR)/hg19_avsnp150.txt

$(ANNOVAR_DB_DIR)/hg19_cadd13gt10.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar cadd13gt10 "${ANNOVAR_DB_DIR}"

cadd13gt10: $(ANNOVAR_DB_DIR)/hg19_cadd13gt10.txt

$(ANNOVAR_DB_DIR)/hg19_fathmm.txt:
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar fathmm "${ANNOVAR_DB_DIR}"

fathmm: $(ANNOVAR_DB_DIR)/hg19_fathmm.txt

$(ANNOVAR_DB_DIR)/hg19_eigen.txt.gz: 
	"${ANNOVAR_DIR}/annotate_variation.pl" -downdb -buildver hg19 -webfrom annovar eigen "${ANNOVAR_DB_DIR}"

eigen: $(ANNOVAR_DB_DIR)/hg19_eigen.txt

annovar_db: 1000g2015aug refGene clinvar_20170905 intervar_20170202 dbnsfp33a esp6500siv2_all kaviar_20150923 gnomad_exome gnomad_genome avsnp150 fathmm eigen


	

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
	unlink vcf2tsv
