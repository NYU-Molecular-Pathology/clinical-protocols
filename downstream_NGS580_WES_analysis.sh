#!/bin/bash

## USAGE: downstream_NGS580_WES_analysis.sh project_ID/results_dir
## EXAMPLE: downstream_NGS580_WES_analysis.sh NS17-03/RUN_4
## DESCRIPTION: This script will set up and run the downstream analysis for the WES pipeline

# ~~~~~ CHECK SCRIPT ARGS ~~~~~ #
if (( "$#" != "1" )); then
    echo "ERROR: Wrong number of arguments supplied"
    grep '^##' $0
    exit
fi

# ~~~~~ GET SCRIPT ARGS ~~~~~ #
project_subdir="$1"


# ~~~~~ LOCATIONS & FILES & SETTINGS ~~~~~ #
analysis_dir="/ifs/data/molecpathlab/NGS580_WES"
scripts_dir="/ifs/data/molecpathlab/scripts"
coverage_analysis_dir="${scripts_dir}/sns-wes-coverage-analysis"
timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"

analysis_project_results_dir="${analysis_dir}/${project_subdir}"


# ~~~~~ VALIDATIONS ~~~~~ #
# make sure sequencing project dir exists
[ ! -d "$analysis_project_results_dir" ] && printf "ERROR: Project directory does not exist:\n%s\n\n" "$analysis_project_results_dir"

# make sure it contains summary-combined.wes.csv file (some samples finished samples)
[ -z "$(find "$analysis_project_results_dir" -name "summary-combined.wes.csv" -print -quit)" ] && printf "ERROR: No summary-combined.wes.csv file found in directory:\n%s\n\n" "$sequencer_project_dir"

# ~~~~~ SETUP ~~~~~ #
zip_filename="$(echo "${project_subdir}" | tr "/" "_")"
# copy the analysis scripts and run them, then zip the TSV and BED outputs
(
rsync -vhPtr "$coverage_analysis_dir" "${analysis_project_results_dir}/"
cd "${analysis_project_results_dir}/sns-wes-coverage-analysis"
ln -fs "$analysis_project_results_dir" run_analysis_output
./calculate_average_coverages.R
zip "${zip_filename}.zip" *.tsv *.bed
)
