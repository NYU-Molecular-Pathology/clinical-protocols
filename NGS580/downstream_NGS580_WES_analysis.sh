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

[ "$(echo "$project_subdir" | tr '/' ' ' | wc -w)" -ne 2 ] && printf "ERROR: Input argument not formatted correctly. The correct format is:\n%s\n\nFor example (dont run this):\n%s\n\nYou entered:\n%s\n\n" "project_ID/results_dir" "NS17-05/results_2017-05-01_14-03-29" "$project_subdir" && exit

project_ID="$(echo "$project_subdir" | cut -d '/' -f1)"
results_ID="$(echo "$project_subdir" | cut -d '/' -f2)"

printf "Project ID is:\n%s\n\n" "$project_ID"
printf "Results ID is:\n%s\n\n" "$results_ID"


# ~~~~~ LOCATIONS & FILES & SETTINGS ~~~~~ #
analysis_dir="/ifs/data/molecpathlab/NGS580_WES"
scripts_dir="/ifs/data/molecpathlab/scripts"
source_coverage_analysis_dir="${scripts_dir}/sns-wes-coverage-analysis"
source_downstream_analysis_dir="${scripts_dir}/sns-wes-downstream-analysis"
timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"
divider="---------------------------"

analysis_project_results_dir="${analysis_dir}/${project_subdir}"
analysis_project_coverage_dir="${analysis_project_results_dir}/sns-wes-coverage-analysis"
analysis_project_downstream_dir="${analysis_project_results_dir}/sns-wes-downstream-analysis"

# ~~~~~ VALIDATIONS ~~~~~ #
printf "\n%s\nValidating project:\n%s\n\n" "$divider" "$analysis_project_results_dir"

# make sure sequencing project dir exists
printf "\nMaking sure directory exists... "
[ ! -d "$analysis_project_results_dir" ] && printf "ERROR: Project directory does not exist:\n%s\n\n" "$analysis_project_results_dir" && exit || printf "Passed\n"

# make sure it contains summary-combined.wes.csv file (some samples finished samples)
printf "\nMaking sure sns pipeline analysis has completed... "
[ -z "$(find "$analysis_project_results_dir" -name "summary-combined.wes.csv" -print -quit)" ] && printf "ERROR: No summary-combined.wes.csv file found in directory:\n%s\n\n" "$sequencer_project_dir" && exit || printf "Passed\n"


# ~~~~~ COVERAGE ANALYSIS ~~~~~ #
printf "\n%s\nStarting coverage analysis..\n" "$divider"

(
mkdir -p "$analysis_project_coverage_dir"
rsync -vhPtrl "$source_coverage_analysis_dir/" "$analysis_project_coverage_dir/"
cd "$analysis_project_coverage_dir"

./run.sh "$project_ID" "$results_ID"
)

# ~~~~~ REPORTING ~~~~~ #
printf "\n%s\nStarting reporting analysis.." "$divider"
(
mkdir -p "$analysis_project_downstream_dir"
rsync -vhPtrl "${source_downstream_analysis_dir}/" "${analysis_project_downstream_dir}/"
cd "${analysis_project_downstream_dir}"

./run.sh "$project_ID" "$results_ID"
)

# ~~~~~ EMAIL RESULTS ~~~~~ #
# don't do this
printf "\nTo mail the results, run the following commands:\n\n"

echo "cd $analysis_project_downstream_dir"
echo "./mail.sh $project_ID $results_ID"

# (
# cd "$analysis_project_downstream_dir"
#
# ./mail.sh "$project_ID" "$results_ID"
# )
