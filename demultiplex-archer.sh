#!/bin/bash

## USAGE: demultiplex-archer.sh
## DESCRIPTION: This script will run demultiplexing for NexSeq Archer runs
## RESOURCES: http://archerdx.com/support/faqs/archer-fusionplex-variantplex-faqs/library-sequencing/demultiplex-nextseq-run-for-archer-analysis
## https://support.illumina.com/sequencing/sequencing_software/bcl2fastq-conversion-software.html

# Be sure to use the "--no-lane-splitting" option mentioned on page 28 of the Illumina's bcl2fastq2 Conversion Software v2.17 Guide. The default output from the software splits the data by lane for each sample, resulting in four sets of fastq files (one for each lane) per sample. A single set of fastq files is required for each sample uploaded to Archer Analysis. Therefore, using the "--no-lane-splitting" option is critical.


#!/bin/bash

# run demultiplexing - bcl2fastq 2.17.1


# make the output group-writeable
umask 007

# input
PROJ=$1
# PARAMS=$(echo "$*" | cut -d ' ' -f 2-)
PARAMS="--no-lane-splitting"


# ~~~~~ CHECK SCRIPT ARGS ~~~~~ #
num_args="$#"
args_should_be_greaterthan="0"
if (( "$num_args" <= "$args_should_be_greaterthan" )); then
            echo "ERROR: Wrong number of arguments supplied"
            echo "Number of script arguments should be at least: $args_should_be_greaterthan"
            grep '^##' $0
            exit
fi
# if [ -z "$3" ]
# then
# 	echo "ERROR! NO ARGUMENT SUPPLIED."
# 	exit 1
# fi

printf "\n\n ===== DEMULTIPLEX $PROJ ===== \n\n"

RUN_DIR="/ifs/data/molecpathlab/quicksilver/${PROJ}"
BASECALLS_DIR="${RUN_DIR}/Data/Intensities/BaseCalls"
OUT_DIR="${BASECALLS_DIR}/Unaligned"
SAMPLE_SHEET="${BASECALLS_DIR}/SampleSheet.csv"

# check if sample sheet exists
if [ ! -s "${SAMPLE_SHEET}" ]
then
	printf "\n\n ERROR! $SAMPLE_SHEET DOES NOT EXIST \n\n"
	exit 1
fi

# show settings
echo " * RUN DIR: $RUN_DIR "
echo " * OUT DIR: $OUT_DIR "
echo " * SAMPLE SHEET: $SAMPLE_SHEET "
echo " * PARAMS: $PARAMS "

sleep 3

# go to run dir so all the qsub logs end up there
mkdir -p "$OUT_DIR"
cd "${OUT_DIR}"

# bcl2fastq
qsub -cwd -M ${USER}@nyumc.org -pe threaded 6-16 \
/ifs/data/molecpathlab/scripts/bcl2fastq.217.sh $PROJ $PARAMS

# cleanup
# qsub -cwd -M ${USER}@nyumc.org /ifs/data/sequence/share/GTC/internal/cleanup-production.sh
#
# sleep 10
#
# # check if demultiplexing completed and summary stats file was generated
# while [ ! $(find $OUT_DIR -type f -name "DemultiplexingStats.xml") ]
# do
# 	# print time and dir size
# 	date +"%H:%M"
# 	du -sh "$OUT_DIR"
# 	# delete qsub .po files (always empty)
# 	rm -fv "${OUT_DIR}/*.sh.po*"
# 	# wait
# 	sleep 120
# done
#
# printf "\n\n ===== DONE ===== \n\n"
#
# printf "next step options (destination directory must be new to prevent overwriting): \n"
# printf "  /ifs/data/sequence/share/GTC/internal/demultiplex-copy.sh $PROJ /ifs/data/sequence/results/<etc> \n"
# printf "\n"
#
#
#
# # end
