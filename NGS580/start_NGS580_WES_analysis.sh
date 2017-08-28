#!/bin/bash

## USAGE: start_NGS580_WES_analysis.sh <project ID> [/path/to/tumor-normal.pairs.csv]
## DESCRIPTION: This script will set up the Whole Exome Sequencing analysis for
## a clinical NGS 580 gene panel run project

# ~~~~~~~~~~ CUSTOM ENVIRONMENT ~~~~~~~~~~ #
source /ifs/data/molecpathlab/scripts/settings
source /ifs/data/molecpathlab/scripts/bash_settings.sh

# ~~~~~ CUSTOM FUNCTIONS ~~~~~ #
check_dirfile_exists () {
    local dirfile="$1"
    local dirfile_type="$2" # d or f or l
    local default_message="Checking to make sure an item was passed to check_dirfile_exists function..."
    local test_message="${3:-$default_message}"

    # watch out for ''
    error_on_zerolength "$dirfile" "TRUE" "$test_message"

    # check if dir exists
    if [ "$dirfile_type" == "d" ]; then
        [ ! -d "$dirfile" ] && echo -e "ERROR: Item is not a dir:\n$dirfile\nDoes it exist?\nExiting..." && exit
    fi

    # check if dir exists
    if [ "$dirfile_type" == "f" ]; then
        [ ! -f "$dirfile" ] && echo -e "ERROR: Item is not a file:\n$dirfile\nDoes it exist?\nExiting..." && exit
    fi

    # check if symlink exists
    if [ "$dirfile_type" == "l" ]; then
        [ ! -L "$dirfile" ] && echo -e "ERROR: Item is not a symlink:\n$dirfile\nDoes it exist?\nExiting..." && exit
    fi
}

error_on_zerolength () {
    local test_string="$1"
    local test_type="$2" # TRUE or FALSE
    local default_message="Testing for zero length string...\n"
    local test_message="${3:-$default_message}"

    echo -e "$test_message"

    # check if zero length string
    if [ "$test_type" == "TRUE" ]; then
        [ -z "$test_string" ] && echo -e "ERROR: String is length zero\nExiting..." && exit
    fi

    # check if non-zero length string
    if [ "$test_type" == "FALSE" ]; then
        [ ! -z "$test_string" ] && echo -e "ERROR: String is not length zero\nExiting..." && exit
    fi

}

find_fastq_dir () {
    # find the parent directory that contains fast files for the run
    local input_dir="$1"
    (
    find "${input_dir}" -type f -name "*.fastq.gz" ! -name "*Undetermined*" | while read i ; do
        echo "$(dirname "$i")"
    done
    ) | sort -u | head -1
}

find_top_level_fastq () {
    local input_dir="$1"
    find "${input_dir}" -mindepth 1 -maxdepth 2 -type f -name "*.fastq.gz" ! -name "*Undetermined*"
}

move_pairs_samplesheet () {
    local samples_pairs_sheet="$1"
    local timestamp="$2"
    local auto_demultiplex_processed_dir="$auto_demultiplex_processed_dir" # from settings
    local samples_pairs_sheet_basename="$(basename "$samples_pairs_sheet")"

    local processed_sheet_path="${auto_demultiplex_processed_dir}/${samples_pairs_sheet_basename}_$timestamp"

    if [ "$samples_pairs_sheet" != 'none' ]; then
        printf "moving file %s to %s\n\n" "$samples_pairs_sheet" "$processed_sheet_path"
        /bin/mv -v "$samples_pairs_sheet" "$processed_sheet_path" && printf 'Move successful\n'
    fi
}

# ~~~~~ CHECK SCRIPT ARGS ~~~~~ #
if (( "$#" > "2" )) || (( "$#" < "1" )); then
    echo "ERROR: Wrong number of arguments supplied"
    grep '^##' $0
    exit
fi

# ~~~~~ GET SCRIPT ARGS ~~~~~ #
project_ID="$1"
samples_pairs_sheet="${2:-none}"

echo "$project_ID $samples_pairs_sheet"

exit
# ~~~~~ LOCATIONS & FILES & SETTINGS ~~~~~ #
# sequencer_dir="/ifs/data/molecpathlab/quicksilver"
sequencer_dir="$nextseq_dir"
# analysis_dir="/ifs/data/molecpathlab/NGS580_WES"
analysis_dir="$NGS580_analysis_dir"
# scripts_dir="/ifs/data/molecpathlab/scripts"
scripts_dir="$script_dir"
sns_dir="${scripts_dir}/sns"
wes_targets_bed="${analysis_dir}/NGS580_targets.bed"
timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"

sequencer_project_dir="${sequencer_dir}/${project_ID}"
sequencer_project_parent_dir="$sequencer_project_dir"
analysis_project_dir="${analysis_dir}/${project_ID}"
analysis_project_results_dir="${analysis_project_dir}/results_${timestamp}"


# ~~~~~ VALIDATIONS ~~~~~ #
# make sure sequencing project dir exists
[ ! -d "$sequencer_project_dir" ] && printf "ERROR: Project directory does not exist:\n%s\n\n" "$sequencer_project_dir"

# make sure it contains fastq files
[ -z "$(find "$sequencer_project_dir" -name "*.fastq.gz" -print -quit)" ] && printf "ERROR: No fast.gz files found in directory:\n%s\n\n" "$sequencer_project_dir"

# make sure the fastq's are near the top of the directory tree, otherwise search for the fastq parent dir
if [ ! "$(find_top_level_fastq "${sequencer_project_dir}" | wc -l)" -gt 0 ]; then
    echo "Fastq files were not found near the top level of the parent dir, searching elsewhere..."
    sequencer_project_dir="$(find_fastq_dir "${sequencer_project_dir}")"
    printf "Sequencing project directory will be:\n%s\n" "$sequencer_project_dir"
    check_dirfile_exists "$sequencer_project_dir" "d" "Checking to make sure that sequencing project directory exists..."
fi


# ~~~~~ SETUP ~~~~~ #
# make the analysis results dir
mkdir -p "$analysis_project_results_dir"

# create symlink to the fastq dir
(
cd "$analysis_project_dir"
ln -fs "$sequencer_project_dir" fastq_dir
)

# find the RunParameters.xml file
RunParameters_source_file="${sequencer_project_parent_dir}/RunParameters.xml"
RunParameters_output_file="${analysis_project_results_dir}/RunParameters.xml"
RunParameters_message_file="${analysis_project_results_dir}/RunParameters.txt"
ExperimentName_file="${analysis_project_results_dir}/ExperimentName.txt"
if [ -f "$RunParameters_source_file" ]; then
    printf "Copying run params file...\n"
    /bin/cp -v "$RunParameters_source_file" "$RunParameters_output_file"
    $sequencer_xml_parse_script -f "$RunParameters_output_file" > "$RunParameters_message_file"
    $sequencer_xml_parse_script -f "$RunParameters_output_file" --name > "$ExperimentName_file"
fi
# exit

# copy over the targets BED
printf "Copying over the targes BED file to new analysis results directory..."
cp -v "$wes_targets_bed" "$analysis_project_results_dir"

# copy over sns pipeline to the directory
printf "Setting up analysis in directory:\n%s\n\n" "$analysis_project_results_dir"
rsync -vhPtr "$sns_dir" "${analysis_project_results_dir}/"

# start the SNS analysis WES pipeline
(
cd "$analysis_project_results_dir"

sns/gather-fastqs ../fastq_dir/
sns/generate-settings hg19
sns/run wes

# copy over the samples-pairs sheet if it was passed
if [ "$samples_pairs_sheet" != 'none' ]; then
    printf "Copying over the samples tumor-normal pairs samplesheet\n"
    /bin/cp -v "$samples_pairs_sheet" "${analysis_project_results_dir}/"
    /bin/cp -v "$samples_pairs_sheet" "${analysis_project_results_dir}/samples.pairs.csv"
    move_pairs_samplesheet "$samples_pairs_sheet"
fi

)
