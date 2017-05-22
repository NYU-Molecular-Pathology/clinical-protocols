#!/bin/bash

# bash functions to use for clinical scripts
# activate this file by source'ing /ifs/data/molecpathlab/scripts/bash_settings.sh in your script

# ~~~~~~~~~~ CUSTOM ENVIRONMENT ~~~~~~~~~~ #
# might need variables set from these
source /ifs/data/molecpathlab/scripts/settings


echo_script_name () {
    print_div "Now running script: ${0}"
}

num_args_should_be () {
    # USAGE: num_args_should_be "equal" "0" "$#"
    local func_type="$1" # "less_than", "greater_than", "equal"
    local arg_limit="$2"
    local num_args="$3"

    if [ "$func_type" == "less_than" ]; then
        if (( "$num_args" >= "$arg_limit" )); then
            printf "ERROR: Wrong number of arguments supplied\n"
            grep '^##' $0
            exit 1
        fi
    fi

    if [ "$func_type" == "greater_than" ]; then
        if (( "$num_args" <= "$arg_limit" )); then
            printf "ERROR: Wrong number of arguments supplied\n"
            grep '^##' $0
            exit 1
        fi
    fi

    if [ "$func_type" == "equal" ]; then
        if (( "$num_args" != "$arg_limit" )); then
            printf "ERROR: Wrong number of arguments supplied\n"
            grep '^##' $0
            exit 1
        fi
    fi

}

check_dirfile_exists () {
    # check_dirfile_exists "file.txt" "f" "Checking some file..."
    local dirfile="$1"
    local dirfile_type="$2" # d or f or l
    local default_message="Checking to make sure an item was passed to check_dirfile_exists function..."
    local test_message="${3:-$default_message}"

    # watch out for ''
    error_on_zerolength "$dirfile" "TRUE" "$test_message"

    # check if dir exists
    if [ "$dirfile_type" == "d" ]; then
        [ ! -d "$dirfile" ] && printf "ERROR: Directory not found:\n$dirfile\nExiting...\n" && exit 1 || printf ' ...Success\n'
    fi

    # check if dir exists
    if [ "$dirfile_type" == "f" ]; then
        [ ! -f "$dirfile" ] && printf "ERROR: File not found:\n$dirfile\nExiting...\n" && exit 1 || printf ' ...Success\n'
    fi

    # check if symlink exists
    if [ "$dirfile_type" == "l" ]; then
        [ ! -L "$dirfile" ] && printf "ERROR: Symlink not found:\n$dirfile\nExiting...\n" && exit 1 || printf ' ...Success\n'
    fi
}

error_on_zerolength () {
    local test_string="$1"
    local test_type="$2" # TRUE or FALSE
    local default_message="Testing for zero length string...\n"
    local test_message="${3:-$default_message}"

    printf "${test_message}\n"

    # check if zero length string
    if [ "$test_type" == "TRUE" ]; then
        [ -z "$test_string" ] && printf "ERROR: String is length zero\nExiting...\n" && exit 1
    fi

    # check if non-zero length string
    if [ "$test_type" == "FALSE" ]; then
        [ ! -z "$test_string" ] && printf "ERROR: String is not length zero\nExiting...\n" && exit 1
    fi

}

check_num_file_lines () {
    local input_file="$1"
    local min_number_lines="$2"

    num_lines="$(cat "$input_file" | wc -l)"
    (( $num_lines <  $min_number_lines )) && printf "ERROR: File has fewer than $min_number_lines lines:\n$input_file\nExiting...\n" && exit 1
}

print_div () {
    local default_message=""
    local message="${1:-$default_message}"
    local div="-----------------------------------"
    printf "\n%s\n%s\n" "$div" "$message"
}

print_error () {
    local default_message=""
    local message="${1:-$default_message}"
    local div="###################################"
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

get_recipient_list () {
    # Default reciepient list
    # recipient_list="address1@gmail.com, address2@gmail.com"
    local recipient_list="kellys04@nyumc.org"

    # check for a saved email recipient list to use instead
    local email_recipient_file="$email_recipients_file" # from settings

    if [ -f "$email_recipient_file" ] ; then
        local recipient_list="$(tr -d '\n' < "$email_recipient_file" )"
    fi
    echo "$recipient_list"
}

file_timestamp () {
    printf "$(date -u +%Y-%m-%d-%H-%M-%S)"
}

log_timestamp () {
    printf "$(date -u +%Y-%m-%dT%H:%M:%S)"
}


print_log_info () {
    local auto_log_file="$1"
    print_div "$(printf "Log file:\n%s\n\n" "$auto_log_file")"
}
