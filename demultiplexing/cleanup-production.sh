#!/bin/bash

#$ -S /bin/bash
#$ -m a
#$ -j y

# remove temp files in production dir (thumbnail and focus images)


# today's date as string
TODAY=$(date +"%y%m%d")
YEAR=$(date +"%Y")

# make the output group-writeable
umask 007

# logs dir
LOGS_DIR="/ifs/data/sequence/share/GTC/internal/logs"
LOGS_DIR=${LOGS_DIR}/${YEAR}
mkdir -p $LOGS_DIR


# fix permissions
# IFS is needed to work with filenames with spaces
# checks for everything directly in BaseCalls, directories will be processed recursively
# minimum time limit to prevent hitting directories where files are still being generated
OIFS="$IFS"
IFS=$'\n'
for P in $(find /ifs/data/sequence/Illumina/production/1*/Data/Intensities/BaseCalls/* -maxdepth 0 -mmin +60 -user $USER -not -perm /g+w) ; do
	stat $P | grep -E "File|Uid" >> ${LOGS_DIR}/production-permissions.${TODAY}.txt ;
	chmod --recursive --silent g+w $P ;
	sleep 30 ;
	stat $P | grep -E "File|Uid" >> ${LOGS_DIR}/production-permissions.${TODAY}.txt ;
done
IFS="$OIFS"


# remove focus images (present in some miseq runs)
for FI in $(find /ifs/data/sequence/Illumina/production/1*/Images -maxdepth 1 -mtime +30 -type d -name Focus | sort) ; do
	du -s $FI >> ${LOGS_DIR}/dir-size-focus.${TODAY}.txt ;
	rm -rf $FI ;
done


# remove thumbnail images
for RUNINFOXML in $(find /ifs/data/sequence/Illumina/production/1*/ -maxdepth 1 -mtime +50 -type f -name "RunInfo.xml" | shuf) ; do
	RUN_DIR=$(dirname $RUNINFOXML) ;
	for TI in $(find $RUN_DIR -maxdepth 1 -type d -name "Thumbnail_Images" -not -empty) ; do
		du -s ${TI}/L00* >> ${LOGS_DIR}/dir-size-thumbnail.${TODAY}.txt ;
	 	rm -rf ${TI}/L00* ;
	done
done



# end
