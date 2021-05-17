#!/bin/bash

NOEXIT=false

# idiomatic parameter and option handling in sh
while test $# -gt 0
do
    case "$1" in
        --no-exit) NOEXIT=true
            ;;
        --*) echo "bad option $1"
            ;;
        *) echo "argument $1"
            ;;
    esac
    shift
done

mkdir -p ~/.vnc
if [ -n "$VNC_PASSWORD" ]; then
    echo -n "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd 
    export VNC_PASSWORD=
else
    echo -n "changeit" | vncpasswd -f > ~/.vnc/passwd 
fi
chmod 400 ~/.vnc/passwd

# We are using version 1.3.9 - the tightvncserver.conf support was added in 1.3.10
if [ -n "$VNC_GEOMETRY" ]; then
    tightvncserver -geometry $VNC_GEOMETRY
else
    tightvncserver
fi

# launch a user shell
if [ "$NOEXIT" = true ] ; then
  /bin/bash
fi
