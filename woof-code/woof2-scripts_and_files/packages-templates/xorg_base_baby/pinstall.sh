#!/bin/sh

echo "xorg_base post-install script..."

fndLIBGL="`find ./usr/lib ./usr/X11/lib -maxdepth 1 -name libGL*`"

if [ "$fndLIBGL" ];then
 sed -i -e 's%.*#LOADGLX%#    Disable    "glx" #LOADGLX%' etc/X11/xorg.conf0
fi
