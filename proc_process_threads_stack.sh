#!/bin/sh

# see https://github.com/azat/linux/commit/5b0b442cdc1049

ls /proc/$1/task/*/stack | \
    xargs -I{} sh -c "echo {} && cat {} && echo"
