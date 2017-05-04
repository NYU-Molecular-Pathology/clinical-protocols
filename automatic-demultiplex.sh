#!/bin/bash

## USAGE:
## DESCRIPTION: This script will check

auto_input_dir="/ifs/data/molecpathlab/quicksilver/to_be_demultiplexed"
auto_log_dir="/ifs/data/molecpathlab/quicksilver/automatic_demultiplexing_logs"

sequencer_dir="/ifs/data/molecpathlab/quicksilver"
demultiplex_580_script="/ifs/data/molecpathlab/scripts/demultiplex-NGS580-WES.sh"

file_backup () {
    local input_file="$1"
    local basename_input_file="$(basename $input_file)"
    local old_ext="${basename_input_file##*.}"
    local backup_dir="$(dirname "$input_file")/processed"
    mkdir -p "$backup_dir"
    local backup_file="${backup_dir}/${basename_input_file}_$(date -u +%Y%m%dt%H%M%S).${old_ext}"
    printf "Moving $input_file to %s\n" "${backup_file}"
    mv "$input_file" "${backup_file}" && echo "File moved to: ${backup_file}"

}

start_demultiplexing () {
    local item="$1"
    local file_basename="$(basename "$item")"
    local analysis_ID="$(echo "$file_basename" | cut -d '-' -f1)"
    local sample_sheet_basename="$(echo "$file_basename" | cut -d '-' -f2)"
    local analysis_sequencing_dir="${sequencer_dir}/${analysis_ID}"
    local analysis_sequencing_basecalls_dir="${analysis_sequencing_dir}/Data/Intensities/BaseCalls"
    local analysis_sequencing_unaligned_dir="${analysis_sequencing_basecalls_dir}/Unaligned"
    local samplesheet_output_file="${analysis_sequencing_basecalls_dir}/SampleSheet.csv"
    local auto_log_file="${auto_log_dir}/$0_log_$(date -u +%Y%m%dt%H%M%S).txt"

    if [ -d "$analysis_sequencing_dir" ]; then # sequencing dir exists
        if [ ! -f "$samplesheet_output_file" ]; then # samplesheet doesn't already exist
            if [ ! -d "$analysis_sequencing_unaligned_dir" ]; then # Unaligned dir doesn't already exist
                ( # copy this portion to log file
                printf "Analysis ID: %s\nSampleSheet file: %s\nAnalysis Sequencing dir: %s\n\n" "$analysis_ID" "$sample_sheet_basename" "$analysis_sequencing_dir"

                printf "Sample sheet file is not present:\n%s\n\n" "$samplesheet_output_file"
                printf "Copying over the samplesheet.\n"
                /bin/cp "$item" "$samplesheet_output_file"

                printf "Unaligned dir not present:\n%s\n\nStarting demultiplexing script:\n%s\n\n" "$analysis_sequencing_unaligned_dir" "$demultiplex_580_script"
                $demultiplex_580_script "$analysis_ID"
                file_backup "$item"
                ) | tee "$auto_log_file" # /copy this portion to log file
            fi # /Unaligned dir doesn't already exist
        else # samplesheet already exists
            printf "Sample sheet file is already present:\n%s\n\n" "$samplesheet_output_file"
        fi # /samplesheet doesn't already exist
    else # sequencing dir doesnt exists
        echo "$analysis_sequencing_dir is NOT there"
    fi # /sequencing dir exists
}

printf "\nNow running script %s at time %s\n\n" "$0" "$(date -u +%Y%m%dt%H%M%S)"

find "$auto_input_dir" -type f -name "*-SampleSheet.csv" -print0 | while read -d $'\0' item; do
    start_demultiplexing "$item"
done
