#!/usr/bin/env bash

# XXX: call from root of repo

function git_remote_name()
{
    local r=$*
    r=${r/*:/}
    r=${r/.git/}
    r=${r/\/_}
    echo $r
}
function get_tag()
{
    git tag --sort=version:refname | tail -1
}
function clang_format_config()
{
    echo "{ $(sed -e 's/#.*//' -e '/---/d' -e '/\.\.\./d' "$@" | tr $'\n' ,) }"
}
function clang_format()
{
    local ref=$1

    if [ -z "$clang_format_config_path" ]; then
        return 0
    fi

    files=$(git diff --name-only $ref^..$ref | egrep "\.(cpp|cc|c|h|hpp|cxx)$" || echo "")
    for f in $files; do
        ranges=$(git diff $ref^..$ref -- $f | egrep -o '^@@ -[0-9]+,[0-9]+ \+[0-9]+(,[0-9]+|) @@' | cut -d' ' -f3)
        for r in $ranges; do
            [[ ! $r =~ ^\+([0-9]+)(,([0-9]+)|)$ ]] && continue
            start=${BASH_REMATCH[1]}
            [ -n "${BASH_REMATCH[3]}" ] && length=${BASH_REMATCH[3]} || length=1
            end=$((start + length))

            diff -u \
               <(git cat-file -p $ref:$f) \
               <(git cat-file -p $ref:$f | \
                 clang-format-3.6 \
                   -style "$(clang_format_config $clang_format_config_path)" \
                   -lines $start:$end) \
               | \
            sed -r -e "s#^--- /dev.*\$#--- a/$f#" \
                   -e "s#^\+\+\+ /dev.*\$#\+\+\+ b/$f#"
        done
    done
}

function printUsage()
{
    echo "$0 [ OPTS ]"
    echo " -r    - remote to fetch"
    echo " -b    - branch in remote"
    echo " -l    - already fetched branch"
    echo " -C    - no compile test"
    echo " -c    - config for clang-format"
}
function options()
{
    remote=
    branch="master"
    local_branch=pull
    compile=1
    clang_format_config_path=
    local branch_installed=0

    local OPTIND OPTARG c
    while getopts "r:b:l:Ch?c:" c; do
        case "$c" in
            [h?]) printUsage && exit 0;;
            r) remote=$OPTARG;;
            b) branch=$OPTARG;;
            l) local_branch=$OPTARG && branch_installed=1;;
            C) compile=0;;
            c) clang_format_config_path="$OPTARG";;
        esac
    done

    [ $branch_installed -eq 0 ] && \
        local_branch="pull-for-$(get_tag)-$(git_remote_name $remote)-$branch"

    [ "$remote" = "" ] && [ $branch_installed -eq 0 ] && exit 1
}

function main()
{
    options "$@"
    set -e

    local gitDir="$(readlink -f $(git rev-parse --git-dir))"
    local root="$(readlink -f "$gitDir/..")"
    cd $root

    if [ ! "$remote" = "" ]; then
        git fetch $remote $branch
        git branch --no-track $local_branch FETCH_HEAD
    fi

    git checkout $local_branch
    if [ $compile -eq 1 ]; then
        # go fix yourself! (ignore errors because it is up-to maintainer)
        git rebase -i --exec "cd .cmake-debug && ninja" origin/master || true
        cd $root

        git rebase -i --exec "cd .cmake-clang && ninja" origin/master || true
        cd $root

        git checkout -b $local_branch-clean
    fi

    mkdir -p pulls/$local_branch && rm -fr pulls/$local_branch/*

    local ref
    local f fixup
    local n
    for ref in $(git log --format=%h --reverse ...origin/master); do
        let ++n
        f=pulls/$local_branch/$(printf %.04i $n)-$ref.patch

        git format-patch $ref -1 --stdout > $f
        fixup=${f/.patch/.fixup}
        clang_format $ref > $fixup
    done

    git reset --hard origin/master
    for f in pulls/$local_branch/*.patch; do
        git am --keep-non-patch $f
        fixup=${f/.patch/.fixup}
        if [ -s $fixup ]; then
            git apply $fixup
            git commit -am"Fixup: $fixup"
        fi
    done
}

main "$@"
