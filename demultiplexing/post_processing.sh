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

generate_demultiplexing_stats_report () {
    local project_ID="$1"
    local nextseq_dir="$nextseq_dir" # from settings
    local demultiplexing_stats_repo="$demultiplexing_stats_repo" # from settings

    # ~~~~~ LOCATIONS ~~~~~ #
    # RUN_DIR="/ifs/data/molecpathlab/quicksilver/${PROJ}"
    local RUN_DIR="${nextseq_dir}/${project_ID}"
    local BASECALLS_DIR="${RUN_DIR}/Data/Intensities/BaseCalls"
    local OUT_DIR="${BASECALLS_DIR}/Unaligned"

    local demultiplexing_stats_outdir="${OUT_DIR}/demultiplexing-stats"

    # setup the dir
    mkdir -p "$demultiplexing_stats_outdir"
    if [ -d "$demultiplexing_stats_outdir" ]; then
        set -x
        rsync -vrhPtr "${demultiplexing_stats_repo}/" "${demultiplexing_stats_outdir}/"
        (
        cd "${demultiplexing_stats_outdir}"
        bash ./run.sh "$OUT_DIR" "$project_ID"
        )
        set +x
    else
        printf "ERROR: could not change to desired output dir, demultiplexing results may not have been created"
    fi

}

demultiplexing_post_processing () {
    local project_ID="$1"
    local nextseq_dir="$nextseq_dir" # from settings
    # ~~~~~ LOCATIONS ~~~~~ #
    # RUN_DIR="/ifs/data/molecpathlab/quicksilver/${PROJ}"
    local RUN_DIR="${nextseq_dir}/${project_ID}"
    local BASECALLS_DIR="${RUN_DIR}/Data/Intensities/BaseCalls"
    local OUT_DIR="${BASECALLS_DIR}/Unaligned"
    local SAMPLE_SHEET="${BASECALLS_DIR}/SampleSheet.csv"

    # mail the results
    # $mail_demultiplexing_results_script "$project_ID"

}

#~~~~~ PARSE ARGS ~~~~~~#
# num_args_should_be "greater_than" "0" "$#"
# do some things even if there are no projects passed.
project_ID_list="${@:1}" # accept a space separated list of ID's starting at the first arg


#~~~~~ NO ARGS NEEDED ~~~~~~#
source "$activate_miniconda" # from settings
rebuild_index


#~~~~~ RUN POST PROCESSING ON EACH PROJECT ~~~~~~#
for i in $project_ID_list; do
    project_ID="$i"
    generate_demultiplexing_stats_report "$project_ID"
    demultiplexing_post_processing "$project_ID"
done
