#!/bin/bash

MNT_PATH=/home/%user%/printer_data/gcodes/         # mount folder
DEV_PRE=$1
DEV_NAME=$2

if [ $ACTION == "add" ]; then
    sudo mkdir -p $MNT_PATH$DEV_PRE-$DEV_NAME
    sudo mount /dev/$DEV_NAME $MNT_PATH$DEV_PRE-$DEV_NAME
    if [[ $? -ne 0 ]]; then
        sudo rmdir $MNT_PATH$DEV_PRE-$DEV_NAME
    fi
elif [ $ACTION == "remove" ]; then
    if [[ -e  $MNT_PATH$DEV_PRE-$DEV_NAME ]] ; then
        sudo umount $MNT_PATH$DEV_PRE-$DEV_NAME
        /usr/bin/rmdir  $MNT_PATH$DEV_PRE-$DEV_NAME
    fi
fi

exit 0
