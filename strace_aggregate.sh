#!/usr/bin/env bash

#
# Simple strace aggregator
#
# arguments: syscalls for which info will be aggregated
#
# Example: ./strace_aggregate.sh /path/to/strace.log write read socket connect
#
# For script strace -T must be run
# If you run with -tttt see https://github.com/joewilliams/strace_analyzer_ng
#
# TODO: support multiple files/read from stdin
# TODO: grep only once
#

file=$1
shift

for syscall in $*; do
    echo "# $syscall"
    cat $file | grep ^$syscall | awk '{count++; time=$NF; sub(/</, "", time); sub(/>/, "", time); elapsed += time; ret += $(NF-1)} END {printf "count: %i, elapsed: %.8f, ret: %.f\n", count, elapsed, ret}'
done

