#!/bin/sh

echo "xorg_base post-install script..."

fndLIBGL="`find ./usr/lib ./usr/X11/lib -maxdepth 1 -name libGL*`"

if [ "$fndLIBGL" ];then
 [ -f etc/X11/xorg.conf0 ] && sed -i -e 's%.*#LOADGLX%#    Disable    "glx" #LOADGLX%' etc/X11/xorg.conf0
fi

echo "Removing legacy X11R7 directory and links"
rm -rf usr/X11*
