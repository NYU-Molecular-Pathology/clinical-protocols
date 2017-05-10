#!/bin/bash

# this script will submit a qsub job and check on host information for the cluster
# node which it ends up running on

submit_job () {
    local job_name="$1"
    qsub -j y -N "$job_name" -o :${PWD}/ -e :${PWD}/ <<E0F
set -x
hostname
cat /etc/hosts
python -c "import socket; print socket.gethostbyname(socket.gethostname())"
E0F
}

printf "Submitting cluster job to get node hostname and IP\n\n"

job_name="get_node_hostnames"
# Your job 832606 ("get_node_hostnames") has been submitted
job_id="$(submit_job "$job_name")"
job_id="$(echo "$job_id" | sed -e 's|.*[[:space:]]\([[:digit:]]*\)[[:space:]].*|\1|g' )"

printf "Job ID:\t%s\nJob Name:\t%s\n\n" "$job_id" "$job_name"

# if ! qstat | grep -q "$job_id" ; then
#     echo "its there"
# else
#     echo "not there"
# fi

printf "waiting for job to finish"
while qstat | grep -q "$job_id"
do
    printf "."
done
printf "\n\n"
job_stdout_log="${job_name}.o${job_id}"
printf "\n\nReading log file ${job_stdout_log}\n\n"
[ -f "$job_stdout_log" ] && cat "$job_stdout_log"
printf "\n\nRemoving log file ${job_stdout_log}\n\n"
[ -f "$job_stdout_log" ] && rm -f "$job_stdout_log"
