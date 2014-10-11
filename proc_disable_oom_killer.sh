#!/usr/bin/env bash

# usage: ./proc_disable_oom_killer.sh $(pgrep pattern)

for p in $@; do echo -1000 >| /proc/$p/oom_score_adj; done
