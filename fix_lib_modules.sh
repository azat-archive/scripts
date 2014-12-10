#!/usr/bin/env bash

for f in /lib/modules/*/{build,source}; do
    [[ $f =~ /lib/modules/(.+)/ ]] && \
        version=${BASH_REMATCH[1]} || \
        continue
    headers=/usr/src/linux-headers-$version

    mv $f ${f}.bak
    ln -s $headers $f
done

