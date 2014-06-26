#!/usr/bin/env bash

# Here we use pmap(1), but it can use smaps instead of it
# not do depends from pmap, but for now it's simpler

pid="$1"

# pmap -x $pid | tail -n+3 | awk '{ size = $2; addr = sprintf("%.f\n", "0x" $1); if (addr-size == prev_addr) { printf "%s # can merged with prev", $1}; prev_addr = addr; }'
pmap -x $pid | tail -n+3 | awk '{ size = $2; addr = sprintf("%.f\n", "0x" $1); printf("%.f vs %.f diff %.f\n", prev_addr, addr-size, addr-size-prev_addr); prev_addr = addr; }'  | awk '{print $NF}' | sort | uniq -c | sort -nr -k1,1 | head

