#!/usr/bin/env bash

#
# Use this script, when you forget to run program under time at start
# (and you can't stop execution of the program, or you didn't want to)
#

pid=${1:-"0"}
interval=${2:-"1"}
etime=0

while [ 1 ]; do
    etime_new=$(ps -o etimes $pid | tr -d ' ' | egrep '^[0-9]*$') || break
    etime="$etime_new"
    sleep $interval
done

echo "etime: $etime (secs)"

