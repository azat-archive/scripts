#!/usr/bin/env bash

function pid_files()
{
    ls -l /proc/$1/fd/* | awk -v p=$pattern '$0 ~ p {fd=$(NF-2); sub(/^.*\/fd\//, "", fd); printf("%s %s\n", fd, $NF);}'
}
function pid_files_offsets()
{
    # flags: 0100001 -- write
    # flags: 0100002 -- read|write
    # flags: 0100000 -- read
    ls -1 /proc/$1/fdinfo/* | awk -vmode=$mode '{ fd=f=$NF; sub(/^.*\/fdinfo\//, "", fd); getline < f; pos=$NF; getline < f; flags=$NF; if (mode == "all" || (mode == "read" && flags == "0100000") || (mode == "write" && flags == "0100001")) { printf("%s %s\n", fd, pos); } }'
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

It will replace first X bytes that already readed by PID in file that opened by
this PID with holes, to free space back to fs.

Options:
 -p    - pattern for files that can be modified
 -D    - disable dry run mode
 -l    - minimal offset after which hole is appropriate

 -r    - apply holes only for files that opened for READ
 -w    - apply holes only for files that opened for WRITE
EOL
}
function options()
{
    pattern=".*"
    dry_run=1
    limit=$((4096 * 10))
    mode=all

    if [ $# -eq 0 ]; then
        usage
        exit
    fi

    local OPTIND c OPTARG
    while getopts "p:l:Drw" c; do
        case "$c" in
            p) pattern="$OPTARG";;
            D) dry_run=0;;
            l) limit="$OPTARG";;
            r) mode="read";;
            w) mode="write";;
        esac
    done

    shift $((OPTIND - 1))
    pids=( "$@" )
}
function dry_run_mode()
{
    function fallocate() { echo "[fallocate]" "$@"; }
    export -f fallocate
    function xargs() { command xargs -t "$@"; }
}
function main()
{
    options "$@"

    [ $dry_run -eq 0 ] || dry_run_mode

    # otherwise we can't save extents info, that could help us to revert this?
    if ! which filefrag >& /dev/null; then
        echo "No filefrag"
        exit 1
    fi

    for p in "${pids[@]}"; do
        pid_files_extend $p | \
            sort -u | \
            awk -v limit=$limit '$2 > limit' | \
            tee /dev/stderr | \
            xargs -r -n1 -i bash -c \
                'l=({}); f=${l[0]}; s=${l[1]}; filefrag -v $f && fallocate -p -o 0 -l $((s-limit)) $f'
    done
}

main "$@"
