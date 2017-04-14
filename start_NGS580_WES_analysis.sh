#!/bin/bash

## USAGE: start_NGS580_WES_analysis.sh <project ID>
## DESCRIPTION: This script will set up the Whole Exome Sequencing analysis for
## a clinical NGS 580 gene panel run project

# ~~~~~ CHECK SCRIPT ARGS ~~~~~ #
if (( "$#" != "1" )); then
    echo "ERROR: Wrong number of arguments supplied"
    grep '^##' $0
    exit
fi

# ~~~~~ GET SCRIPT ARGS ~~~~~ #
project_ID="$1"


# ~~~~~ LOCATIONS & FILES & SETTINGS ~~~~~ #
sequencer_dir="/ifs/data/molecpathlab/quicksilver"
analysis_dir="/ifs/data/molecpathlab/NGS580_WES"
scripts_dir="/ifs/data/molecpathlab/scripts"
sns_dir="${scripts_dir}/sns"
wes_targets_bed="${analysis_dir}/NGS580_targets.bed"
timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"

sequencer_project_dir="${sequencer_dir}/${project_ID}"
analysis_project_dir="${analysis_dir}/${project_ID}"
analysis_project_results_dir="${analysis_project_dir}/results_${timestamp}"

# ~~~~~ VALIDATIONS ~~~~~ #
# make sure sequencing project dir exists
[ ! -d "$sequencer_project_dir" ] && printf "ERROR: Project directory does not exist:\n%s\n\n" "$sequencer_project_dir"

# make sure it contains fastq files
[ -z "$(find "$sequencer_project_dir" -name "*.fastq.gz" -print -quit)" ] && printf "ERROR: No fast.gz files found in directory:\n%s\n\n" "$sequencer_project_dir"

# ~~~~~ SETUP ~~~~~ #
# make the analysis results dir
mkdir -p "$analysis_project_results_dir"

# create symlink to the fastq dir
(
cd "$analysis_project_dir"
ln -fs "$sequencer_project_dir" fastq_dir
)

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
)
