#!/bin/bash
# generate vnc password if not exist
if [ ! -f "$HOME/.vnc/passwd" ]; then
if [ -z "$VNCPASSWD" ]; then
    VNCPASSWD=`openssl rand -base64 6`
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++
    echo vnc password: $VNCPASSWD
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++
fi
echo $VNCPASSWD | vncpasswd -f > $HOME/.vnc/passwd
chmod 600 $HOME/.vnc/passwd
fi

# other user-overwriteable defaults
if [ -z "$VNCRES" ]; then VNCRES=1280x800; fi
if [ -z "$VNCDEPTH" ]; then VNCDEPTH=24; fi

# remove lock files from previous runs
rm -f $HOME/.vnc/debian-xfce-vnc:*.pid
rm -f /tmp/.xfsm*
rm -f /tmp/.X*-lock
rm -Rf /tmp/.ICE-unix
rm -Rf /tmp/.X11-unix

# start main process
vncserver -depth $VNCDEPTH -geometry $VNCRES

# control loop (to keep the container alive as the main process spawns away)
STATUS=0
while [ "$STATUS" -eq "0" ]; do
    sleep 10
    # we check on the xfce session process and if it has died we also kill the vnc server
    # - this will stop the container if the user does an interactive logout in xfce
    # (instead of keeping a zombie vnc server running forever)
    pgrep xfce4-session >/dev/null
    if [ "$?" -ne "0" ]; then
        vncserver -kill :1
        rm -f /tmp/.X*-lock
        STATUS=1     
    fi
done