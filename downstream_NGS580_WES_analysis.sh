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
printf "\nMaking sure directory exists...\n"
[ ! -d "$analysis_project_results_dir" ] && printf "ERROR: Project directory does not exist:\n%s\n\n" "$analysis_project_results_dir"

# make sure it contains summary-combined.wes.csv file (some samples finished samples)
printf "\nMaking sure sns pipeline analysis has completed...\n"
[ -z "$(find "$analysis_project_results_dir" -name "summary-combined.wes.csv" -print -quit)" ] && printf "ERROR: No summary-combined.wes.csv file found in directory:\n%s\n\n" "$sequencer_project_dir"

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
(
cd "$analysis_project_downstream_dir"

results_list="${analysis_project_downstream_dir}/results_list.txt"

find . -type f -name "*${project_ID}*" -name "*${results_ID}*" ! -name "*.md" ! -name "*.Rmd"  ! -name "*.html" ! -name "*.zip" -exec readlink -f {} \; > "$results_list"
find sns-wes-coverage-analysis/ -type f -name "*${project_ID}*" -name "*${results_ID}*" -exec readlink -f {} \; >> "$results_list"

zip_filename="${project_ID}_${results_ID}_results.zip"
cat "$results_list" | xargs zip "$zip_filename" # try with '-j' to get rid of paths in the zip file

report_file="${project_ID}_${results_ID}_analysis_report.html"

# make sure the report file exists
[ ! -f "$report_file" ] && printf "\nERROR: Report file not found:\n%s\n\n" "$report_file"

# make sure the zip file exists
[ ! -f "$zip_filename" ] && printf "\nERROR: Zip file not found:\n%s\n\n" "$zip_filename"

# make sure samples list exists
[ ! -f "../samples.fastq-raw.csv" ] && printf "\nERROR: Samples list file not found:\n%s\n\n" "../samples.fastq-raw.csv"

file_owner="$(ls -ld "$report_file" | awk '{print $3}')"
file_date="$(ls -l --time-style=long-iso "$report_file" | awk '{print $6 " " $7}')"
file_fullpath="$(readlink -f "$report_file")"

reply_to="kellys04@nyumc.org"
recipient_list="kellys04@nyumc.org, Yehonatan.Kane@nyumc.org, Matija.Snuderl@nyumc.org, Naima.Ismaili@nyumc.org, Aristotelis.Tsirigos@nyumc.org, Jared.Pinnell@nyumc.org, Varshini.Vasudevaraja@nyumc.org"
message_footer="- This message was sent automatically by $(whoami) -"
subject_line_report="[NGS580] ${project_ID} Report"
subject_line_results="[NGS580] ${project_ID} Results"

email_message_file="${analysis_project_downstream_dir}/email_message.txt"
cat > "$email_message_file" <<E02
NGS 580 Panel Target Exome Sequencing Clinical Report

Project ID:
${project_ID}

Results ID:
${results_ID}

System location:
${file_fullpath}

Samples List:
$(cat ../samples.fastq-raw.csv | cut -d ',' -f1 | sort -u)

${message_footer}
E02

set -x
./toolbox/mutt.py -r "${recipient_list}" -rt "$reply_to" -mf "$email_message_file" -s "$subject_line_report" "$report_file"
./toolbox/mutt.py -r "${recipient_list}" -rt "$reply_to" -mf "$email_message_file" -s "$subject_line_results" "$zip_filename"
)
