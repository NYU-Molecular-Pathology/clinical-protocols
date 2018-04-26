#!/bin/bash
set -e

# script for syncing the contents of the phoenix server data with the MCIT location for desktop access
# dont copy any files with ':' in the name because the remote filesystem does not support them

remote_dir="/production"
remote_server="nyu.edu"
local_dir="/ifs/data/molecpathlab/NGS580_WES"
results_dir_file="/ifs/data/molecpathlab/NGS580_WES/results_dirs.txt"
production_dir="/ifs/data/molecpathlab/production"

mkdir -p "sync_logs"
sync_log="sync_logs/log_$(date +"%Y-%m-%d_%H-%M-%S").txt"

{
	set -x
	rsync -vrthP -e ssh "${production_dir}/" "$(whoami)"@"${remote_server}":"${remote_dir}/" \
	--include="Demultiplexing" \
	--include="Demultiplexing/*" \
	--include="Demultiplexing/*/output/***" \
	--exclude="*:*" \
	--exclude="*" 

} 2>&1 | tee -a "$sync_log"
