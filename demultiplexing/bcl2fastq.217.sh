#!/bin/bash

#$ -S /bin/bash
#$ -j y
#$ -m a

## USAGE: bcl2fastq.217.sh <projectID> -extra -params -to -use
## DESCRIPTION:

# based on Igor's script

# ~~~~~~~~~~ CUSTOM ENVIRONMENT ~~~~~~~~~~ #
source /ifs/data/molecpathlab/scripts/settings
source /ifs/data/molecpathlab/scripts/bash_settings.sh

# input
PROJ=$1
PARAMS=$(echo "$*" | cut -d ' ' -f 2-)

# ~~~~~ CHECK SCRIPT ARGS ~~~~~ #
num_args="$#"
args_should_be_greaterthan="0"
if (( "$num_args" <= "$args_should_be_greaterthan" )); then
            echo "ERROR: Wrong number of arguments supplied"
            echo "Number of script arguments should be at least: $args_should_be_greaterthan"
            grep '^##' $0
            exit
fi

# ~~~~~ LOCATIONS ~~~~~ #
# RUN_DIR="/ifs/data/molecpathlab/quicksilver/${PROJ}"
RUN_DIR="${nextseq_dir}/${PROJ}"
BASECALLS_DIR="${RUN_DIR}/Data/Intensities/BaseCalls"
OUT_DIR="${BASECALLS_DIR}/Unaligned"
SAMPLE_SHEET="${BASECALLS_DIR}/SampleSheet.csv"

# ~~~~~ CHECK FOR SAMPLESHEET ~~~~~ #
if [ ! -s $SAMPLE_SHEET ]
then
	printf "\n\n ERROR! $SAMPLE_SHEET DOES NOT EXIST \n\n"
	exit 1
fi

# ~~~~~ SETUP ~~~~~ #
mkdir -p $OUT_DIR

module unload gcc
module load bcl2fastq/2.17.1

echo " * RUN_DIR: $RUN_DIR "
echo " * OUT_DIR: $OUT_DIR "
echo " * SAMPLE_SHEET: $SAMPLE_SHEET "
echo " * PARAMS: $PARAMS "
echo " * bcl2fastq: $(readlink --canonicalize $(which bcl2fastq)) "

CMD="
bcl2fastq \
--min-log-level WARNING \
--fastq-compression-level 8 \
--loading-threads 2 \
--demultiplexing-threads 2 \
--processing-threads $NSLOTS \
--writing-threads 2 \
--sample-sheet $SAMPLE_SHEET \
--runfolder-dir $RUN_DIR \
--output-dir $OUT_DIR \
$PARAMS
"

# ~~~~~ RUN ~~~~~ #
echo $CMD
$CMD


# ~~~~~ POST-PROCESSING ~~~~~ #
# create Demultiplex_Stats.htm
cat ${OUT_DIR}/Reports/html/*/all/all/all/laneBarcode.html | grep -v "href=" > ${OUT_DIR}/Demultiplex_Stats.htm

# delete temp
rm -rf "${OUT_DIR}/Temp"

# fix permissions
chmod --recursive --silent g+w "${OUT_DIR}"

# ~~~~~ More POST-PROCESSING ~~~~~ #

$demultiplexing_postprocessing_script "$PROJ"

# end
