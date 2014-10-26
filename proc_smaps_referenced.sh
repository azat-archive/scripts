#!/usr/bin/env bash

# examples:
# proc_smaps_referenced.sh 10015 | tr -d , | awk '($2 > 8192) && ($(NF-1) > 0) && ($(NF-1) < 80)'

smaps=/proc/$1/smaps
awk '/^(Size|Referenced):/ { if ($1 ~ /^Size:/) { size = $(NF-1) } else { refs = $(NF-1); printf("size: %10.f, referenced: %10.f (%7.2f %%)\n", size, refs, size ? (refs / size * 100) : 0) } }' < $smaps
