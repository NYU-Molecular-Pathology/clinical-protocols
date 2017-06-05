#!/bin/bash

## USAGE: post_processing.sh <project_ID> <project_ID> <project_ID> ...

## DESCRIPTION: This script will run extra downstream processing steps.

# ~~~~~~~~~~ CUSTOM ENVIRONMENT ~~~~~~~~~~ #
source /ifs/data/molecpathlab/scripts/settings
source /ifs/data/molecpathlab/scripts/bash_settings.sh

rebuild_index () {
    # rebuild the run index
    printf "Now running the sequencer index script to rebuild the run index\n\n"
    $sequencer_xml_parse_script --index
}

demultiplexing_post_processing () {
    local project_ID="$1"
    # ~~~~~ LOCATIONS ~~~~~ #
    # RUN_DIR="/ifs/data/molecpathlab/quicksilver/${PROJ}"
    local RUN_DIR="${nextseq_dir}/${project_ID}"
    local BASECALLS_DIR="${RUN_DIR}/Data/Intensities/BaseCalls"
    local OUT_DIR="${BASECALLS_DIR}/Unaligned"
    local SAMPLE_SHEET="${BASECALLS_DIR}/SampleSheet.csv"

    # mail the results
    $mail_demultiplexing_results_script "$project_ID"

}

#~~~~~ PARSE ARGS ~~~~~~#
# num_args_should_be "greater_than" "0" "$#"
# do some things even if there are no projects passed.
project_ID_list="${@:1}" # accept a space separated list of ID's starting at the first arg


#~~~~~ NO ARGS NEEDED ~~~~~~#
rebuild_index


#~~~~~ RUN POST PROCESSING ON EACH PROJECT ~~~~~~#
for i in $project_ID_list; do
    project_ID="$i"
    demultiplexing_post_processing "$project_ID"
done
