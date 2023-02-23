#!/bin/bash
#
#  prune_dir - delete oldest files in a specified directory if the directory is occupying more disk space
#                than the capacity_limit specified
#

# DIR - the path to the folder that is being checked
DIR=$1

# CAPACITY_LIMIT - the disk usage threshold above which the deletion of oldest files will occur if passed
#                - needs to be in human readable format i.e. 500M; 40K; 1G
#                - default value: 5G
CAPACITY_LIMIT=$(numfmt --from=iec $2)

if [ "$DIR" == "" ]
then
    echo "ERROR: directory not specified"
    exit 1
fi

if ! cd $DIR
then
    echo "ERROR: unable to cd to directory '$DIR'"
    exit 2
fi

if [ "$CAPACITY_LIMIT" == "" ]
then
    CAPACITY_LIMIT=5368709120   # default limit of 5G
fi

echo "pruning dir $DIR with capacity limit $CAPACITY_LIMIT"

CAPACITY=$(du -sb . | cut -f1)

if [ $CAPACITY -gt $CAPACITY_LIMIT ]
then

    while true; do

        # Find and delete the oldest file
        # in subdirectories of the directory
        find . -mindepth 2 -type d -printf '%T+ %p\n' | sort | awk 'NR==1{print $2}' | xargs rm -vr

        # Check capacity
        CAPACITY=$(du -sb . | cut -f1)

        if [ $CAPACITY -le $CAPACITY_LIMIT ]
        then
            # we're below the limit, so stop deleting
            exit
        fi

    done

fi

echo "pruning complete"
