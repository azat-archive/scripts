#!/usr/bin/env bash

#
# Progress by file descriptors (cp / gz / resize2fs e.t.c.)
#
# 2013-04-18:
# Ability to measure block devices added
# Useful to know progress of resize2fs for example.
# 
# Run using `watch` util
#

if [ $# -lt 1 ]; then
    echo "Usage: $0 /path/to/file [ PID]" >&2
    exit 2
fi

SRCFILE=$1
PID=$2

# Not existed file, or not set
if [ "x$SRCFILE" = "x" ]; then
    echo "File $SRCFILE not exist"
    exit 1
fi
SRCFILE=$(readlink -f $SRCFILE)

# Maybe not regular file
DEV=0
if [ ! -f $SRCFILE ]; then
    if $(file $SRCFILE 2>/dev/null | grep -q "sticky block special"); then
        DEV=1
    else
        echo "File $SRCFILE is not exist"
        exit 1
    fi
fi

# Find lsof, or PID
LSOF=`which lsof`
if [ "x$LSOF" = "x" ] && [ "x$PID" = "x" ]; then
    echo "No 'lsof' or PID"
    exit 1
fi

function getProcFiles()
{
    pid=$1

    if [ "x$pid" = "x" ]; then
        lsof $SRCFILE | tail -n+2 | awk '{printf "/proc/%u/fdinfo/%u\n", $2, substr($4, 1, length($4)-1)}'
    else
        ls -l /proc/$pid/fd 2>/dev/null | awk '{printf "%s\t%s\n", $NF, $(NF-2)}' | grep "^$SRCFILE"$'\t' | awk -F$'\t' '{print $NF}' | awk -vpid=$pid '{printf "/proc/%u/fdinfo/%u\n", pid, $1}'
    fi
}

for PROC_FD in $( getProcFiles $PID ); do
    PROC_FD_INFO=$( head -n1 "$PROC_FD" 2>/dev/null )
    if [ $? -ne 0 ]; then
        echo "Can't access to $PROC_FD"
    else
        # Echo processes
        FILESIZE=0
        if [ $DEV -eq 0 ]; then
            FILESIZE=$(wc -c $SRCFILE | awk '{print $1}')
        else
            FILESIZE=$(blockdev --getsize64 $SRCFILE)
        fi

        printf "[%20s] %i %%\n" $PROC_FD $(( `echo $PROC_FD_INFO | awk '{print $2}'` * 100 / $FILESIZE ))
    fi
done

