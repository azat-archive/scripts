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
    echo "Usage: $0 PID | /path/to/file [ PID]" >&2
    exit 2
fi

SRCFILE=$1
PID=$2

# Not existed file, or not set
if [ ! -f "$SRCFILE" ] && [ ! -b "$SRCFILE" ]; then
    if [[ $SRCFILE =~ ^[0-9]*$ ]]; then
        PID=$SRCFILE
    else
        echo "File $SRCFILE not exist"
        exit 1
    fi
fi

function getProcFiles()
{
    pid=$1
    src="$2"

    if [ "x$pid" = "x" ]; then
        lsof $src | tail -n+2 | awk '{printf "/proc/%u/fdinfo/%u\n", $2, substr($4, 1, length($4)-1)}'
    else
        pattern=".*"
        if [ ! "$src" = "$pid" ]; then
            pattern="$src"
        fi

        ls -l /proc/$pid/fd 2>/dev/null | awk '{printf "%s\t%s\n", $NF, $(NF-2)}' | grep "^$pattern"$'\t' | awk -F$'\t' '{print $NF}' | awk -vpid=$pid '{printf "/proc/%u/fdinfo/%u\n", pid, $1}'
    fi
}

function getFileInfoByProc()
{
    src="$1"
    if [ ! -f $src ]; then
        if $(file $src 2>/dev/null | grep -q "sticky block special"); then
            blockdev --getsize64 $src
            return
        else
            echo 0
            return
        fi
    fi

    wc -c $src | awk '{print $1}'
}

function getTerminalWidth()
{
    tput cols
}

for PROC_FD in $( getProcFiles "$PID" "$SRCFILE" ); do
    PROC_FD_INFO=$( head -n1 "$PROC_FD" 2>/dev/null )
    if [ $? -ne 0 ]; then
        echo "Can't access to $PROC_FD"
    else
        src=$(readlink -f ${PROC_FD/fdinfo/fd})
        size=$(getFileInfoByProc $src)
        cols=$(( $(getTerminalWidth) - 20))

        if [ "$size" = "0" ]; then
            percents=0
        else
            percents=$(( `echo $PROC_FD_INFO | awk '{print $2}'` * 100 / $size ))
        fi

        # TODO: trim common part at the beginning of file
        printf "[%${cols}s] %i %%\n" $src $percents
    fi
done

