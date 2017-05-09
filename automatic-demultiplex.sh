#!/bin/bash

## USAGE: automatic-demultiplex.sh
## DESCRIPTION: This script will check for new Sample sheets in a dir, and if found
## will automatically start demultiplexing for the given run
## Samplesheet name format:
## <run_ID>-SampleSheet.csv
## example:
## 170426_NB501073_0008_AHCKY5BGX2-SampleSheet.csv

# ~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~ #
print_div () {
    local default_message=""
    local message="${1:-$default_message}"
    div="-----------------------------------"
    printf "\n%s\n%s\n" "$div" "$message"
}

print_error () {
    local default_message=""
    local message="${1:-$default_message}"
    div="###################################"
    printf "\n%s\n%s\n" "$div" "$message"
}


file_backup () {
    local input_file="$1"
    local basename_input_file="$(basename $input_file)"
    local old_ext="${basename_input_file##*.}"
    local backup_dir="$(dirname "$input_file")/processed"
    mkdir -p "$backup_dir"
    local backup_file="${backup_dir}/${basename_input_file}_$(date -u +%Y%m%dt%H%M%S).${old_ext}"
    print_div "$(printf "Moving file:\n%s\n\nto location:\n%s\n\n" "$input_file" "${backup_file}")"
    mv "$input_file" "${backup_file}" && printf "\nFile moved successfully\n\n"
    printf "\nTo undo file move, run command:\n\nmv %s %s\n\n" "${backup_file}" "$input_file"

}

print_log_info () {
    local auto_log_file="$1"
    print_div "$(printf "Log file:\n%s\n\n" "$auto_log_file")"
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
    local auto_log_file="${auto_log_dir}/$(basename "$0")_log_$(date -u +%Y%m%dt%H%M%S).txt"
    local demult_message="$(printf "Analysis ID:\n%s\n\nSampleSheet file:\n%s\n\nAnalysis Sequencing dir:\n%s\n\n" "$analysis_ID" "$sample_sheet_basename" "$analysis_sequencing_dir")"
    local demult_message="$(print_div "${demult_message}")"
    local start_message="$(print_div "$(printf "%s\n%s\n\n" "$start_script_message" "${demult_message}" )")"
    local demult_command="$demultiplex_580_script $analysis_ID"

    if [ -d "$analysis_sequencing_dir" ]; then # sequencing dir exists
        if [ ! -f "$samplesheet_output_file" ]; then # samplesheet doesn't already exist
            if [ ! -d "$analysis_sequencing_unaligned_dir" ]; then # Unaligned dir doesn't already exist
                ( # copy this portion to log file
                printf "$start_message"
                cat << E0F


Sample sheet file is not present:
$samplesheet_output_file

Copying over the samplesheet.

E0F
                /bin/cp "$item" "$samplesheet_output_file"

                cat << E0F

Unaligned dir not present:
$analysis_sequencing_unaligned_dir

Starting demultiplexing script, command is:

$demult_command
$(print_div)

E0F
                $demult_command && print_div "Demultiplexing job submitted successfully" && print_div || print_error "WARNING: Demultiplexing job may not have started successfully!!"
                file_backup "$item"
                print_log_info "$auto_log_file"
                ) 2>&1 | tee "$auto_log_file" # /copy this portion to log file
                email_log "$auto_log_file" "$analysis_ID"
            else # # Unaligned dir already exists
                (
                cat << E0F
$start_message
$(print_error)
ERROR: Unaligned dir already exists:

$analysis_sequencing_unaligned_dir

Demultiplexing script will NOT be run
$(print_error)

E0F
                file_backup "$item"
                print_log_info "$auto_log_file"
                ) 2>&1 | tee "$auto_log_file"
                email_log "$auto_log_file" "$analysis_ID"
            fi # /Unaligned dir doesn't already exist
        else # samplesheet already exists
            (
            cat << E0F
$start_message
$(print_error)
ERROR: Sample sheet file is already present:

$samplesheet_output_file

Demultiplexing script will NOT be run
$(print_error)

E0F
            file_backup "$item"
            print_log_info "$auto_log_file"
            ) 2>&1 | tee "$auto_log_file"
            email_log "$auto_log_file" "$analysis_ID"
        fi # /samplesheet doesn't already exist
    else # sequencing dir doesnt exists
        (
        cat << E0F
$start_message
$(print_error)
ERROR: Analysis Sequencing dir does not exist! Supplied directory is:

$analysis_sequencing_dir

Demultiplexing script will NOT be run
$(print_error)

E0F
        file_backup "$item"
        print_log_info "$auto_log_file"
        ) 2>&1 | tee "$auto_log_file"
        email_log "$auto_log_file" "$analysis_ID"
    fi # /sequencing dir exists
}

get_recipient_list () {
    # Default reciepient list
    # recipient_list="address1@gmail.com, address2@gmail.com"
    # local recipient_list="MolecularPathology@nyumc.org" "#MolecularPathology@nyumc.org"
    local recipient_list="kellys04@nyumc.org"

    # check for a saved email recipient list to use instead
    local email_recipient_file="email_recipients.txt"
    if [ -f "$email_recipient_file" ] ; then
        local recipient_list="$(tr -d '\n' < "$email_recipient_file" )"
    fi
    echo "$recipient_list"
}

email_log () {
    local auto_log_file="$1"
    local analysis_ID="$2"
    local recipient_list="$(get_recipient_list)"
    # local recipient_list="kellys04@nyumc.org"
    local subject_line="$(printf "[Demultiplexing] NextSeq Run %s" "$analysis_ID")"
    # export EMAIL="kellys04@nyumc.org"
    mutt -s "$subject_line" -- "$recipient_list" <<E0F
$(cat $auto_log_file)
E0F
}

# ~~~~~~~~~~ SETTINGS ~~~~~~~~~~ #
auto_input_dir="/ifs/data/molecpathlab/quicksilver/to_be_demultiplexed"
auto_log_dir="/ifs/data/molecpathlab/quicksilver/automatic_demultiplexing_logs"

sequencer_dir="/ifs/data/molecpathlab/quicksilver"
demultiplex_580_script="/ifs/data/molecpathlab/scripts/demultiplex-NGS580-WES.sh"

script_time="$(date -u +%Y-%m-%dT%H:%M:%S)"
script_timestamp="$(date -u +%Y%m%dt%H%M%S)"

start_script_message="$(print_div "$(printf "Now running script:\n%s\n\ncurrent time:\n%s\n\n" "$(readlink -f "$0")" "${script_time}")")"


# ~~~~~~~~~~ RUN ~~~~~~~~~~ #
find "$auto_input_dir" -maxdepth 1 -mindepth 1 -type f -name "*-SampleSheet.csv" -print0 | while read -d $'\0' item; do
    start_demultiplexing "$item"
done
