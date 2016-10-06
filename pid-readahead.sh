#!/usr/bin/env bash

function pid_files()
{
    ls -l /proc/$1/fd/* | awk -v p=$pattern '$0 ~ p {fd=$(NF-2); sub(/^.*\/fd\//, "", fd); printf("%s %s\n", fd, $NF);}'
}
function pid_files_offsets()
{
    ls -1 /proc/$1/fdinfo/* | awk '{ fd=f=$NF; sub(/^.*\/fdinfo\//, "", fd); getline < f; pos=$NF; printf("%s %s\n", fd, pos); }'
}
function j_sort() { sort -k 1b,1; }
function pid_files_extend()
{
    join -o 1.2,2.2 -j1 \
        <(pid_files $1 | j_sort) \
        <(pid_files_offsets $1 | j_sort)
}

function usage()
{
    cat -<<EOL
Usage: $0 [ OPTIONS ] pid1[ pid2 ...]

It will preload X bytes fo every file patched with pattern
this PID with holes, to free space back to fs.

Options:
 -p    - pattern for files that can be modified
 -P    - processes in parallel
 -D    - disable dry run mode
 -l    - size of readahead (in bytes)
 -b    - block size (in bytes)
EOL
}
function options()
{
    pattern=".*"
    dry_run=1
    processes=1
    export limit=$((1<<20))
    export block_size=$((1<<18))

    if [ $# -eq 0 ]; then
        usage
        exit
    fi

    local OPTIND c OPTARG
    while getopts "P:p:l:b:D" c; do
        case "$c" in
            P) processes="$OPTARG";;
            p) pattern="$OPTARG";;
            D) dry_run=0;;
            l) limit="$OPTARG";;
            b) block_size="$OPTARG";;
        esac
    done

    shift $((OPTIND - 1))
    pids=( "$@" )
}
function dry_run_mode()
{
    function dd() { echo "[dd]" "$@"; }
    export -f dd
    function xargs() { command xargs -t "$@"; }
}
function main()
{
    options "$@"

    [ $dry_run -eq 0 ] || dry_run_mode

    for p in "${pids[@]}"; do
        pid_files_extend $p | \
            sort -u | \
            tee /dev/stderr | \
            xargs -P$processes -r -n1 -i bash -c \
            'l=({}); f=${l[0]}; s=${l[1]}; dd if=$f of=/dev/null skip=$((s/block_size)) bs=${block_size}c count=$((limit/block_size))'
    done
}

main "$@"
