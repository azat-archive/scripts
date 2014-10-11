#!/bin/sh

# see https://github.com/azat/linux/commit/5b0b442cdc1049

ls /proc/$1/maps | \
    xargs grep stack: | cut -d: -f3 | tr -d ] | sort -n | \
    xargs -I{} sh -c "echo {} && cat /proc/{}/stack && echo"
