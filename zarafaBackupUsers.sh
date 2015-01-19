#!/bin/bash

#######################################
# Backup Script for users             #
# Written by Tom Van Humbeeck         #
#######################################

CONFIGFILE="/usr/local/sbin/backup-wrapper.cfg" 
. $CONFIGFILE

while getopts ":c:" opt; do
  case $opt in
    c)                                                                                                                                                                                                                           
        if [ -f $OPTARG ]; then CONFIGFILE=$OPTARG; else echo "File not found"; fi   
    ;;
  esac
done

function increase_error_count {
    ERRORCOUNT=$((${ERRORCOUNT}+1))
}

function not_found {
    echo "${1} not found!" >&2    
    exit 1
}

for soft in zarafa-backup mail
do
  which $soft &>/dev/null || not_found $soft
done

if [ ! -s ${USERS} ]; then
  exit 1;
fi

(

### CONTROLE MOUNT ###
if grep -qs "$MOUNT" /proc/mounts; then
  echo "It's mounted." 
else
  echo "It's not mounted." 
  mount -t ${MOUNTTYPE} -o username=${MOUNTUSER},password=${MOUNTPASS} ${HOST} ${MOUNT}
  if [ $? -eq 0 ]; then
   echo "Mount success!" 
  else
   echo "Something went wrong with the mount..." 
  fi
fi

### Run Backup ###
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for i in `cat ${USERS}`
do
    if ${BACKUP} -u $i -o ${ARCHIVE}; then
            echo "Zarafa Backup for user $i succeeded" 
        else
            echo "Zarafa Backup for user $i failed" 
                increase_error_count
        echo $ERRORCOUNT
    fi
done

echo "Gelieve removeusers.txt terug leeg te maken!" 

### Logging ###

if [[ $ERRORCOUNT -gt 0 ]]; then exit $ERRORCOUNT; fi

) > ${LOGS}/backup-custom-${DATE}.log 2>&1

  if [ $? -eq 0 ]
  then
    ${MAIL} -s "Zarafa Backup Specific Users [OK]" -r $SENDER $RCPT < ${LOGS}/backup-custom-${DATE}.log
  else
    ${MAIL} -s "Zarafa Backup Specific Users [FAILED]" -r $SENDER $RCPT < ${LOGS}/backup-custom-${DATE}.log
  fi
