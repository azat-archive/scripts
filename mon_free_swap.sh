#!/usr/bin/env bash

# Useful to kill/stop process if it will eat to much memory

maxPercents=97
interval=10
cmd=:

function printUsage()
{
    echo "$0 [ -m max_percents ] [ -i interval_secs ] [ cmd ]" >&2
    exit 1
}

function parseOptions()
{
    local OPTIND o
    while getopts "m:i:" o; do
        case "$o" in
            m) maxPercents=$OPTARG;;
            i) interval=$OPTARG;;
            *) printUsage;;
        esac
    done
    shift $((OPTIND-1))
    [ -n "$*" ] && cmd=$(printf '"%s" ' "$@")
}

function swapUsedPercents()
{
    free -m | awk '/Swap:/ {printf("%.f\n", ($3/$2)*100);}'
}

function main()
{
    while :; do
        sleep $interval
        if [ $(swapUsedPercents) -lt $maxPercents ]; then
            continue
        fi
        echo "Too much swap used, executing user specified command"
        eval "$cmd"
        break
    done
}

parseOptions "$@"
main
