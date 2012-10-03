#!/bin/sh
# Wrapper for ginstall on aix.
#
# * add the -d option
# * add the -m option
#

mode=""

if [ "$1" = "-d" ]; then
    shift

    if [ "$1" = "-m" ]; then
        shift
        mode=$1
        shift
    fi

    folder="$@"

    mkdir -p "$folder"

    if [ "$mode" != "" ]; then
        chmod $mode $folder
    fi

else
    # Destination folder is the last argument.
    for destination_folder; do true; done

    if [ "$1" = "-m" ]; then
        shift
        mode=$1
        shift
    fi

    for file in $@; do
        if [ "$file" != "$destination_folder" ]; then
            cp $file $destination_folder
            if [ "$mode" != "" ]; then
                chmod $mode $destination_folder/$file
            fi
        fi 
    done

fi
