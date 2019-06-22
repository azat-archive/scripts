#!/bin/bash
################################################################################
# tmuxlogin - Open multiple tmux panes, each logged into a different server
#-------------------------------------------------------------------------------
# 20110302 dale bewley net
#
# Run this within your current session to open a new window, or run it in the
# absence of a tmux session to create a new one. A new window will be created
# and split it into multiple panes. They are all synchronized by default and
# will each be ready to login to a different server.
#
# TODO:
#   o Option to ssh directly rather than just send keys.
#   o Option to do something other than login to a server. I guess that would
#     make 'tmuxlogin' a bad name.
#
# BUGS:
#   o Even if you give a new name, creating a new session does not work if you
#     are attached to any existing session. This is becuese the existance of
#     $TMUX is tested before the arguments are parsed.
#
#     This can be forced if $TMUX is temporarily unset long enough to run
#     new-session. However, it seems the orignial session is killed when the
#     2nd session is closed.
#
#   o Sometimes my main session has crashed when closing the tmuxlogin window.
#
# Original at http://tofu.org/drupal/node/181
#
################################################################################

# defaults
SESSION=$USER
SSH_USER=$USER
SSH_COMMAND=ssh
TMUX_SOCKET=
WINDOW=$(basename "$0")
# synchronize panes: 1=yes, 0=no
SYNC=1
SERVERS='localhost'

function tmux()
{
    if [[ -n $TMUX_SOCKET ]]; then
        command tmux -L $TMUX_SOCKET "$@"
    else
        command tmux "$@"
    fi
}

usage() {
    cat <<EOF >&2
$0 - Open multiple tmux panes, each logged into a different server.

Usage: $0 [OPTS] <hosts ...>

Arguments:

 -h help
    This screen.

 -n no_synchronize
    Do not synchronize panes.

 -L tmux socket
    Custom socket for the tmux

 -t tmux_session
    Name of existing tmux session to target, or new session.
    Default: "$SESSION"

 -u ssh_user
    User to ssh as.

 -e ssh_command
    Overwrite ssh command.

 -v verbose
    Tell me something interesting.

 -w tmux_window
    Name of new tmux window to places panes in.
    Default: "$WINDOW"

EOF
}

debug() {
    echo "    Session: $SESSION"
    echo "     Window: $WINDOW"
    echo "Synchronize: $SYNC"
    echo "    Servers: $SERVERS"
    echo "   SSH User: $SSH_USER"
    echo "SSH Command: $SSH_COMMAND"
    echo "TMUX socket: $TMUX_SOCKET"
}

while getopts hvnt:u:w:e:L: opt
do
    case "$opt" in
      n)  SYNC="0";;
      t)  SESSION="$OPTARG";;
      u)  SSH_USER="$OPTARG";;
      v)  verbose=on;;
      w)  WINDOW="$OPTARG";;
      e)  SSH_COMMAND="$OPTARG";;
      L)  TMUX_SOCKET="$OPTARG";;
      h) usage && exit 0;;
      \?) usage && exit 1;; # unknown flag
    esac
done

shift $((OPTIND - 1))
if [ -n "$*" ]; then
    SERVERS=$*
fi

open_windows() {
    # true if this is a brand new session
    local new_session=$1

    if tmux list-windows -t "$SESSION" 2>/dev/null | grep -q "$WINDOW"; then
        echo "Window '$SESSION:$WINDOW' already exists. Aborting."
        return
    fi

    # split window and echo servers to each pane
    # sending keys gives you a chance to decide when to type in password
    for server in $SERVERS; do
        tmux split-window  -t "$SESSION:$WINDOW" -h
        tmux send-keys     -t "$SESSION:$WINDOW" "$SSH_COMMAND $SSH_USER@$server"
        # split -h seems to stop at 5 unless layout is changed
        tmux select-layout -t "$SESSION:$WINDOW" tiled
    done

    # if this is a new session then there is no point in creating a new window
    if [ -n "$new_session" ]; then
        # this is a brand new session with only 1 window, so just rename it
        tmux rename-window  -t "$SESSION:0" "$WINDOW"
    else
        # create new window in this pre-existing session
        tmux new-window    -t "$SESSION" -a -n "$WINDOW"
    fi

    tmux kill-pane     -t "$SESSION:$WINDOW.0"     # remove the original pane
    tmux select-pane   -t "$SESSION:$WINDOW.0"     # select the first pane
    tmux select-layout -t "$SESSION:$WINDOW" tiled # tile panes evenly

    # synchronize input to all panes unless turned off
    if [ "$SYNC" -gt 0 ]; then
        tmux set-window-option -t "$SESSION:$WINDOW" synchronize-panes on
    fi
}

if [ -n "$verbose" ]; then
    debug # show status
    sleep 1
fi

# does this session already exist?
if ! tmux has-session -t "$SESSION" >& /dev/null; then
    if [ -n "$TMUX" ]; then
        # we are attached to a session of another name
        attached=`tmux list-sessions | grep attached | cut -d: -f1`
        echo "Creating new session '$SESSION' while attached to '$attached' is not well supported."
        exit 1
    else
        # session does not exist. create it.
        # this won't work if we are attached. even if the session name is different
        # the hack is to remove $TMUX temporarily
        tmux new-session -d -s "$SESSION" || exit 1
        split_only=1
    fi
fi
# time to open a window and chop it up
open_windows $split_only

if [ -z "$TMUX" ]; then
    # now let's attach to the session if we aren't already attached
    # to some session
    tmux attach -t "$SESSION"
fi
