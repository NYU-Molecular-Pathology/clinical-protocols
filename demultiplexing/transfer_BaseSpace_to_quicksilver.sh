#!/bin/bash

## USAGE: /ifs/data/molecpathlab/scripts/transfer_BaseSpace_to_quicksilver.sh "ProjectID" "/path/to/BaseSpace_dir"
## DESCRIPTION: This script will copy .fastq.gz files from a cloud-based BaseSpace project
## directory to the 'quicksilver' directory which has been setup to hold DNA sequencer
## output.
##
## 'BaseSpace_dir' is a directory that has been mounted by BaseMount and contains
## data tied to your BaseSpace cloud account (sequencer projects & runs, etc.)
##
## 'ProjectID' is the ID of the project you are trying to copy files from, such as "NS17-03"
##
## By default all fastq files will be copied to a single common directory, but
## the script will first check to make sure that all fastq files have unique filenames
## and that their parent directory names do not contain ID's which are not also
## included in the fastq filename. If either of these are true, then the parent
## directories will be preserved as the files are copied.


# ~~~~~ CUSTOM FUNCTIONS ~~~~~ #
copy_to_common_dir () {
    # copy all files to a common output dir
    local source_dir="$1"
    local destination_dir="$2"
    local file_type="$3"
    find "${source_dir}" -name "${file_type}" -exec rsync -vtrPh {} "$destination_dir" \;
}

copy_with_parents () {
    # copy files from BaseSpace BaseMount, keep parent dirs
    # e.g.: /BaseSpace/Projects/NS17-03/Samples/B17-0091/Files/B17-0091_S6_L002_R2_001.fastq.gz
    # output_path=B17-0091/B17-0091_S6_L002_R2_001.fastq.gz
    local source_dir="$1"
    local destination_dir="$2"
    local file_type="$3"
    find "$source_dir" -name "${file_type}" | while read item; do
        parent_dir="${item##*Samples/}"
        parent_dir="${parent_dir%%/*}"
        output_path="${destination_dir}/${parent_dir}"
        printf "Copying to:\n%s\n\n" "${output_path}"
        rsync  -vtrPh "$item" "${output_path}/"
    done
}

print_copying () {
    # print_copying "$source_dir" "$destination_dir" "$file_type" "$message"
    local source_dir="$1"
    local destination_dir="$2"
    local file_type="$3"
    local message="$4"
    printf "\nCopying all %s files %s\n\nFrom:\n%s\n\nTo:\n%s\n\n" "$file_type" "$message" "$source_dir" "$destination_dir"
}

clean_path () {
    # remove bad characters from file or dir path
    # update this as more bad characters are found
    local input_path="$1"
    echo "$input_path" | sed -e 's| (|_|g' -e 's|)||g'
}


# ~~~~~ CHECK SCRIPT ARGS ~~~~~ #
if (( "$#" != "2" )); then
    echo "ERROR: Wrong number of arguments supplied"
    grep '^##' $0
    exit
fi



# ~~~~~ GET SCRIPT ARGS ~~~~~ #
# project to be transfered from BaseSpace
project_ID="$1" # "NS17-03"
# directory which has been mounted by BaseMount (user should have done this already)
basepace_dir="$2"



# ~~~~~ MISC PARAMS ~~~~~ #
# type of file we want to copy; pattern to be used in 'find'
file_type='*.fastq.gz'



# ~~~~~ SETUP DIRS ~~~~~ #
# parent directory for sequencer output
sequencer_dir="/ifs/data/molecpathlab/quicksilver"
# location where the project data will be copied to; make the dir
project_sequencer_dir="${sequencer_dir}/${project_ID}"
project_sequencer_dir="$(clean_path "$project_sequencer_dir")"
mkdir -p "$project_sequencer_dir"

# location where the BaseSpace projects will appear
basepace_projects="${basepace_dir}/Projects"

# BaseSpace dir for the project we want
project_BaseSpace_dir="${basepace_projects}/${project_ID}"



# ~~~~~ VALIDATIONS ~~~~~ #
divider="------------------------------------------------------------"
printf "%s\nStarting BaseSpace copy script\n\nProject Id:\n%s\n\nBaseMount directory:\n%s\n\nDestination directory:\n%s\n\nFile type to transfer:\n%s\n\n" "$divider" "$project_ID" "$basepace_dir" "$project_sequencer_dir" "$file_type"
printf "%s\nValidating BaseMount directory....\n\n" "$divider"
# make sure project_BaseSpace_dir exists
[ ! -d "$project_BaseSpace_dir" ] && printf "ERROR: Item is not a valid directory:\n%s\n\nDoes it exist? Exiting...\n\n" "$project_BaseSpace_dir" && exit

# make sure project_BaseSpace_dir contains projects
num_entries="$(ls -1 "$project_BaseSpace_dir" | wc -l)"
(( "$num_entries" < 1 )) && printf "ERROR: Directory contains %s items:\n%s\n\nExiting...\n\n" "$num_entries" "$project_BaseSpace_dir" && exit

# make sure that fastq files are present in the project_BaseSpace_dir
num_fastqs="$(find "$project_BaseSpace_dir" -type f -name "$file_type" | wc -l)"
(( "$num_fastqs" < 1 )) && printf "ERROR: Directory contains %s %s files:\n%s\n\nExiting...\n\n" "$num_fastqs" "$file_type" "$project_BaseSpace_dir" && exit

# check to see if any filenames DO NOT contain the parent ID
# use a psuedo-boolean flag; "True" or "False"
some_filenames_lack_parentID="False"
printf "Checking to see if any %s files lack sample ID from their parent directory " "$file_type"
find "$project_BaseSpace_dir" -type f -name "$file_type" | while read item; do
    # item="/ifs/home/kellys04/projects/Clinical_580_gene_panel/BaseSpace/Projects/NS17-03/Samples/B17-0247/Files/B17-0247_S12_L004_R2_001.fastq.gz"
    parent="${item##*Samples/}"
    parent="${parent%%/*}" # B17-0247
    file_base="$(basename "$item")" # B17-0247_S12_L004_R2_001.fastq.gz
    # if boolean isn't already "True", then set it to "True" if "parent" is not found in "file_base"
    if ! echo "$file_base" | grep -q "${parent}"; then
        # echo "string ${parent} is in string $file_base"
        [ "$some_filenames_lack_parentID" != "True" ] && some_filenames_lack_parentID="True"
    fi
    # printf "${parent}\t${file_base}\t${some_filenames_lack_parentID}\n"
    printf "."
done
printf " %s\n" "$some_filenames_lack_parentID"


# the fastq files are currently in subdirs but we want to copy all of them to a common dir;
# check to make sure that none have duplicate names
num_all_fastq_files="$(find "${project_BaseSpace_dir}" -name "$file_type" | wc -l)"
num_unique_filenames="$(find "${project_BaseSpace_dir}" -name "$file_type" -exec basename {} \; | sort -u | wc -l)"
printf "\nNumber of %s files found: %s\n\n" "$file_type" "$num_all_fastq_files"
printf "\nChecking to make sure that all %s files have unique names...\n\n" "$file_type"
printf "\nNumber of unique %s filenames found: %s\n\n" "$file_type" "$num_unique_filenames"


# ~~~~~ COPY THE SAMPLESHEET ~~~~~ #
find "${project_BaseSpace_dir}/AppSessions/" -path "*FASTQ*" -path "*Generation*" -path "*Logs*" -name "SampleSheetUsed.csv" -print0 | while read -d $'\0' item; do
    samplesheet_output_file="${project_sequencer_dir}/SampleSheet.csv"
    printf "Found sample sheet file:\n%s\n\nCopying sample sheet file to:\n%s\n\n" "$item" "$samplesheet_output_file"
    /bin/cp "$item" "$samplesheet_output_file"
done


# ~~~~~ COPY THE RUN INFO XMLs ~~~~~ #
find "${project_BaseSpace_dir}" -name "*.xml" -name "Run*" -print0 | while read -d $'\0' item; do
    /bin/cp -v "$item" "${project_sequencer_dir}/"
done

# ~~~~~ COPY THE FILES ~~~~~ #
printf "%s\nStarting file transfer.... This might take a while.... \n\n" "$divider"

# if False, then check for duplicate file basenames; if True, keep parent dirs
if [ "$some_filenames_lack_parentID" == "False" ]; then
    printf "\nNo %s filenames lacked parent directory ID's\n" "$file_type"
    # if there are no duplicates, the values should be equal
    if [ "$num_all_fastq_files" -eq "$num_unique_filenames"  ]; then
        # it is safe to copy all fastq files to a common dir
        printf "\nNumber of %s files matches number of unique filenames\n" "$file_type"
        print_copying "$project_BaseSpace_dir" "$project_sequencer_dir" "$file_type" "to common dir"
        copy_to_common_dir "$project_BaseSpace_dir" "$project_sequencer_dir" "$file_type"
    elif [ ! "$num_all_fastq_files" -eq "$num_unique_filenames"  ]; then
        # not equal; some fastq's have same filename, need to preserve parent dir's
        printf "\nNumber of %s files does not match number of unique filenames\n" "$file_type"
        print_copying "$project_BaseSpace_dir" "$project_sequencer_dir" "$file_type" ", preserving parent dirs"
        copy_with_parents "$project_BaseSpace_dir" "$project_sequencer_dir" "$file_type"
    fi
elif [ "$some_filenames_lack_parentID" == "True" ]; then
    printf "\nSome %s filenames lacked parent directory ID's\n" "$file_type"
    print_copying "$project_BaseSpace_dir" "$project_sequencer_dir" "$file_type" " to common dir"
    copy_with_parents "$project_BaseSpace_dir" "$project_sequencer_dir" "$file_type"
fi

# ~~~~~ FINISHED ~~~~~ #
unmount_command="basemount --unmount $basepace_dir"
remount_command="basemount ${basepace_dir}/"
printf "\n%s\nBaseSpace copy script finished. Destination directory:\n%s\n\nPlease check to make sure files were successfully transferred\n\n" "$divider" "$project_sequencer_dir"
printf "If you are finished with all file transfers, remember to unmount your BaseMount directory with this command:\n%s\n\n" "$unmount_command"
