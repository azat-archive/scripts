#!/usr/bin/env bash

# test connections on the remote server too
remoteServers=

function testUrl()
{
    line="$1"
    onTheServer="$2"

    [[ $line =~ http://(.*)/ ]] && host=${BASH_REMATCH[1]} || continue
    if [[ $host =~ :([0-9]+) ]]; then
        port=${BASH_REMATCH[1]}
        host=${host/:*}
    else
        port=80
    fi
    ipAddress=$(host $host | awk '/has address/ {print $NF; exit;}')

    cmd="nc.traditional -q0 -n -w5 -v $ipAddress $port"
    [[ -n $onTheServer ]] && cmd="ssh $onTheServer bash -c'$cmd'"
    $cmd < /dev/null >& /dev/null \
        && echo "[$onTheServer] Ok $host ($ipAddress:$port)" \
        || echo "[$onTheServer] Some error for $host ($ipAddress:$port)"
}
function testConnections()
{
    while read line; do
        testUrl "$line"
        for remoteServer in $remoteServers; do
            testUrl "$line" "$remoteServer"
        done
    done
}

testConnections "$@"
