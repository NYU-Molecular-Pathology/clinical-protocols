#!/bin/bash

## USAGE: demultiplex-NGS580-WES.sh <Project ID>
## EXAMPLE: demultiplex-NGS580-WES.sh 170308_NB501073_0004_AHHFKYBGX2
## DESCRIPTION: This script will run demultiplexing for NexSeq NGS580 Whole Exome sequencing runs
## RESOURCES: https://support.illumina.com/sequencing/sequencing_software/bcl2fastq-conversion-software.html

## Sample BaseSpace Command
## /opt/illumina/Isas/1.26.0/bcl2fastq2/bin/bcl2fastq  --ignore-missing-bcls --ignore-missing-filter --ignore-missing-positions --ignore-missing-controls --auto-set-to-zero-barcode-mismatches --find-adapters-with-sliding-window --adapter-stringency 0.9 --mask-short-adapter-reads 35 --minimum-trimmed-read-length 35 -R "/data/scratch/workspace/RunFolder" --sample-sheet "/data/scratch/workspace/RunFolder/SampleSheet.csv" -o "/data/scratch/workspace/RunFolder/Analysis/Temp_01.01-GenerateFASTQ.FastqGeneration"

## Using bcl2fastq 2.17.1
# copied from Igor's script

# make the output group-writeable
umask 007


# ~~~~~~~~~~ CUSTOM ENVIRONMENT ~~~~~~~~~~ #
source /ifs/data/molecpathlab/scripts/settings
# dont use bash settings here because we set bcl2fastq specific environment

# ~~~~~~~~~~ GET SCRIPT ARGS ~~~~~~~~~~ #
PROJ="$1"
PARAMS="--ignore-missing-bcls --ignore-missing-filter --ignore-missing-positions --ignore-missing-controls --auto-set-to-zero-barcode-mismatches --find-adapters-with-sliding-window --adapter-stringency 0.9 --mask-short-adapter-reads 35 --minimum-trimmed-read-length 35"


# ~~~~~ CHECK SCRIPT ARGS ~~~~~ #
num_args="$#"
args_should_be_greaterthan="0"
if (( "$num_args" <= "$args_should_be_greaterthan" )); then
            echo "ERROR: Wrong number of arguments supplied"
            echo "Number of script arguments should be at least: $args_should_be_greaterthan"
            grep '^##' $0
            exit
fi

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

# make the qsub log dir
qsub_log_dir="${OUT_DIR}/qsub_logs"
mkdir -p "$qsub_log_dir"

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
-o :${qsub_log_dir}/ -e :${qsub_log_dir}/ \
$bcl2fastq_217_script "$PROJ" $PARAMS
#


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
