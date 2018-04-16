#!/bin/bash
set -e

# script for syncing the contents of the phoenix server NGS580 run data with the MCIT location for desktop access
# dont copy any files with ':' in the name because the remote filesystem does not support them

remote_dir="/home/kellys04/acc_pathology/Validations/NGS-580"
remote_server="nyu.edu"
local_dir="/ifs/data/molecpathlab/NGS580_WES"
results_dir_file="/ifs/data/molecpathlab/NGS580_WES/results_dirs.txt"

sync_log="sync_log_$(date +"%Y-%m-%d_%H-%M-%S").txt"

{
    cat "$results_dir_file" | while read line; do
        if [ ! -z "$line" ]; then
            echo ">>> Processing directory for sync: $line" # /ifs/data/molecpathlab/NGS580_WES/170512_NB501073_0009_AHF5H2BGX2/results_2017-06-29_11-15-02
            run_dir="$(dirname "$line")"

            ssh $(whoami)@${remote_server} -A <<E0F
cd "${remote_dir}"
echo ">>> remote run dir is: $run_dir" # /ifs/data/molecpathlab/NGS580_WES/170512_NB501073_0009_AHF5H2BGX2
rsync -vrthP "$run_dir" . --exclude="*:*" # --dry-run
E0F
            sleep 1
        fi
    done

} 2>&1 | tee -a "$sync_log"

