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
project_subdir="$1" # ex: NS17-03/RUN_4
project_ID="$(dirname "$project_subdir")"
results_ID="$(basename "$project_subdir")"

# ~~~~~ LOCATIONS & FILES & SETTINGS ~~~~~ #
analysis_dir="/ifs/data/molecpathlab/NGS580_WES"
scripts_dir="/ifs/data/molecpathlab/scripts"
coverage_analysis_dir="${scripts_dir}/sns-wes-coverage-analysis"
downstream_analysis_dir="${scripts_dir}/sns-wes-downstream-analysis"
timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"
divider="---------------------------"
analysis_project_results_dir="${analysis_dir}/${project_subdir}"


# ~~~~~ VALIDATIONS ~~~~~ #
# make sure sequencing project dir exists
printf "\n%s\nValidating run..." "$divider"
[ ! -d "$analysis_project_results_dir" ] && printf "ERROR: Project directory does not exist:\n%s\n\n" "$analysis_project_results_dir"

# make sure it contains summary-combined.wes.csv file (some samples finished samples)
[ -z "$(find "$analysis_project_results_dir" -name "summary-combined.wes.csv" -print -quit)" ] && printf "ERROR: No summary-combined.wes.csv file found in directory:\n%s\n\n" "$sequencer_project_dir"

# ~~~~~ COVERAGE ANALYSIS ~~~~~ #
printf "\n%s\nStarting coverage analysis.." "$divider"
zip_filename="$(echo "${project_subdir}" | tr "/" "_")"
# copy the analysis scripts and run them, then zip the TSV and BED outputs
(
rsync -vhPtr "$coverage_analysis_dir" "${analysis_project_results_dir}/"
cd "${analysis_project_results_dir}/sns-wes-coverage-analysis"
ln -fs "$analysis_project_results_dir" run_analysis_output
./calculate_average_coverages.R
zip "${zip_filename}.zip" *.tsv *.bed
)

# ~~~~~ REPORTING ~~~~~ #
printf "\n%s\nStarting reporting analysis.." "$divider"
(
module load pandoc/1.13.1

rsync -vhPtr "$downstream_analysis_dir" "${analysis_project_results_dir}/"
cd "${analysis_project_results_dir}/sns-wes-downstream-analysis"

printf "%s" "$project_ID" > project_ID.txt
printf "%s" "$results_ID" > results_ID.txt

set -x
ln -fs ../ run_analysis_output
ln -fs ../sns-wes-coverage-analysis sns-wes-coverage-analysis

report_file="${project_ID}_${results_ID}_analysis_report.Rmd"
/bin/cp analysis_report.Rmd "$report_file"
./compile_RMD_report.R "$report_file"
)
