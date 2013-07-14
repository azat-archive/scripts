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

# Find fdinfo file
if [ "x$PID" = "x" ]; then
        PROC_FD=$( lsof $SRCFILE | head -n2 | tail -n1 | awk '{printf "/proc/%u/fdinfo/%u", $2, substr($4, 1, length($4)-1)}' )
else
        PROC_FD_BASENAME=$( ls -l /proc/$PID/fd 2>&1 | grep "$SRCFILE" | head -n1 | sed -r 's/.+ ([0-9]+)\s+->.+/\1/' )
        PROC_FD="/proc/$PID/fdinfo/$PROC_FD_BASENAME"
fi

# Get fd info
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

        echo $(( `echo $PROC_FD_INFO | awk '{print $2}'` * 100 / $FILESIZE )) %
fi
