#!/usr/bin/env bash

function elf()
{
    readelf -S $@ | gawk '{if ($1 ~ /^[0-90-f]+$/ && name ~ /^\./) { printf "%s %.0f\n", name, strtonum("0x" $1); } name=$(NF > 3 ? NF-3 : ""); }' | sort -k1,1
}
function diff()
{
    awk '{diff=($3-$2)/1024; if (diff < -10) { printf "%18s: %.3fKB\n", $1, diff}; total += diff; } END { printf "Total: %.fKB\n", total }'
}

join -j1 <(elf $1) <(elf $2) | diff
