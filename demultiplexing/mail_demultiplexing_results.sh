#!/bin/bash

## USAGE: mail_demultiplexing_results.sh "<project_ID>"
## DESCRIPTION: This script will send an email with summary demultiplexing results

# ~~~~~~~~~~ CUSTOM ENVIRONMENT ~~~~~~~~~~ #
source /ifs/data/molecpathlab/scripts/settings
source /ifs/data/molecpathlab/scripts/bash_settings.sh

# ~~~~~~~~~~ CUSTOM FUNCTIONS ~~~~~~~~~~ #
email_log () {
    local log_file="$1"
    local analysis_ID="$2"
    local demultiplexing_stats_file="$3"
    local run_params_file="$4"
    local recipient_list="$(get_recipient_list)"
    # local recipient_list="kellys04@nyumc.org"
    local subject_line="$(printf "[Demultiplexing] NextSeq Run %s" "$analysis_ID")"
    local NextSeq_index_file="$(copy_index_file)" # from settings

    # get email server info; server with mutt installed (qsub nodes dont always have it)
    local email_server_address_file="$email_server_address_file" # from settings
    local email_server_address="$(head -1 "$email_server_address_file" | tr -d '\n')"

    # need to ssh back into the server with mutt installed for emailing
    ssh ${USER}@${email_server_address} <<E0F2
# reply-to email address
# export EMAIL="kellys04@nyumc.org"

/usr/bin/mutt -s "$subject_line" -a "$demultiplexing_stats_file" -a "$run_params_file" -a "$NextSeq_index_file" -- "$recipient_list" <<E0F

$(cat $log_file)
E0F

E0F2
}

print_success () {
    local project_ID="$1"
    print_div
    $sequencer_xml_parse_script "$project_ID"
    print_div
}

copy_index_file () {
    # make a timestamped copy of the index, to be sent in the email
    local NextSeq_index_file="$NextSeq_index_file" # from settings
    # file_timestamp
    # local unaligned_dir="$1"
    local index_basename="$(basename $NextSeq_index_file)"
    local index_basename="${index_basename%%.csv}"
    local new_NextSeq_index_file="${unaligned_dir}/${index_basename}_$(file_timestamp).csv" # use the global var here
    /bin/cp "$NextSeq_index_file" "$new_NextSeq_index_file" && echo "$new_NextSeq_index_file"

}

# ~~~~~ CHECK SCRIPT ARGS ~~~~~ #
echo_script_name
num_args_should_be "equal" "1" "$#"

# ~~~~~ LOCATIONS ~~~~~ #
project_ID="$1"
project_dir="${nextseq_dir}/${project_ID}"
basecalls_dir="${project_dir}/Data/Intensities/BaseCalls"
unaligned_dir="${basecalls_dir}/Unaligned"

samplesheet_file="${basecalls_dir}/SampleSheet.csv"
run_params_file="${project_dir}/RunParameters.xml"
RTAComplete_file="${project_dir}/RTAComplete.txt"
RunCompletionStatus_file="${project_dir}/RunCompletionStatus.xml"
demultiplexing_stats_file="${unaligned_dir}/Demultiplex_Stats.htm"
email_message_file="${basecalls_dir}/demultiplexing_completion_log.$(file_timestamp).txt"

new_demultiplexing_stats_file="${unaligned_dir}/${project_ID}_Demultiplex_Stats.htm"
# ~~~~~ RUN ~~~~~ #
(
print_div
printf "Demultiplexing results for NextSeq Run %s" "$project_ID"
print_div
( # subshell so it sends email even the validations fail...
printf "\nChecking for demultiplexing completion status...\n\n"
check_dirfile_exists "$samplesheet_file" "f" "Checking that the samplesheet file exists..."
check_dirfile_exists "$run_params_file" "f" "Checking that the run params file exists..."
check_dirfile_exists "$RTAComplete_file" "f" "Checking that the RTAComplete_file file exists..."
check_dirfile_exists "$RunCompletionStatus_file" "f" "Checking that the RunCompletionStatus_file file exists..."
check_dirfile_exists "$demultiplexing_stats_file" "f" "Checking that the Demultiplexing stats file exists..."

print_div

cat "$RTAComplete_file"
print_div

/bin/cp "$demultiplexing_stats_file" "$new_demultiplexing_stats_file"

) && print_success "$project_ID" || print_error "WARNING: Demultiplexing job may not have finished successfully!!"

print_log_info "$email_message_file"
) 2>&1 | tee "$email_message_file" && email_log "$email_message_file" "$project_ID" "$new_demultiplexing_stats_file" "$run_params_file"
