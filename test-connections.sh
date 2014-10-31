#!/usr/bin/env bash
function testConnections()
{
    while read line; do
        [[ $line =~ http://(.*)/ ]] && host=${BASH_REMATCH[1]} || continue
        if [[ $host =~ :([0-9]+) ]]; then
            port=${BASH_REMATCH[1]}
            host=${host/:*}
        else
            port=80
        fi
        ipAddress=$(host $host | awk '/has address/ {print $NF; exit;}')
        nc.traditional -q0 -n -w5 -v $ipAddress $port < /dev/null || echo "Some error for $host"
    done
}

testConnections "$@"
