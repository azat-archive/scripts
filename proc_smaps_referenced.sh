#!/usr/bin/env bash

# examples:
# proc_smaps_referenced.sh $$ | tr -d , | awk '($2 > 8192) && ($(NF-1) > 0) && ($(NF-1) < 80)'

script=$(cat - <<'EOF'
/^(Size|Referenced):/ {
    if ($1 ~ /^Size:/) {
        size = $(NF-1);
        tsize += size;
    } else {
        refs = $(NF-1);
        trefs += refs;
        p = size ? (refs / size * 100) : 0;
        printf("size: %10.f, referenced: %10.f (%7.2f %%)\n", size, refs, p);
    }
}
END {
    p = tsize ? (trefs / tsize * 100) : 0;
    printf("[total] size: %10.f, referenced: %10.f (%7.2f %%)\n", tsize, trefs, p);
}
EOF
)

smaps=/proc/$1/smaps
awk "$script" < $smaps
