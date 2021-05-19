#!/bin/bash

# Start vfb
# Start vnc
if [ -z "$VNCPASSWD" ]; then
    VNCPASSWD=`openssl rand -base64 6`
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++
    echo vnc password: $VNCPASSWD
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++
fi
############################################

# This cannot be done during install, except if we want a static password
if [ ! -f $HOME/.vnc/passwd ]
then
    mkdir $HOME/.vnc
    echo $VNCPASSWD | vncpasswd -f > $HOME/.vnc/passwd
    chmod 600 $HOME/.vnc/passwd
    x11vnc -storepasswd $VNCPASSWD $HOME/.vnc/passwd
fi

Xvfb -screen 0 1440x900x16 -ac &
sleep 15
env DISPLAY=:0.0 x11vnc -noxrecord -noxfixes -noxdamage -forever -display :0 &
env DISPLAY=:0.0 fluxbox 

if [ -f start-notebook.sh ]
then
   start-notebook.sh
fi

