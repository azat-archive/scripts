#!/usr/bin/env bash

# Show read/write end's, for pipes.
#
# Example: ./pipe_ends.sh ino $(pgrep nc)
#


function usage()
{
    printf "%s ino pid1[ pid2[ ...]]\n" >&2 $0
    printf "\tino is the inode number for pipe\n" >&2
    printf "\t(printed by lsof of can be obtained from /proc/pid/fd/)\n" >&2
}

ino=$1
shift

[ -z "$ino" ] && usage && exit 1

for i in $*; do
    lsof -np $i | grep $ino && echo pid $i
done

