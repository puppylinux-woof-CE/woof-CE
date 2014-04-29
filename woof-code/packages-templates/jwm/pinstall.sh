#!/bin/sh
#post-install script.
#Puppy Linux
#Woof: if current directory is rootfs-complete, it has the final filesystem.

if [ "`pwd`" != "/" ];then

 if [ ! -f ./usr/X11R7/bin/fvwm95 ];then
  if [ ! -f ./usr/bin/fbpanel ];then
   if [ ! -f ./usr/bin/lxpanel ];then
    echo -n "jwm" > ./etc/windowmanager
   fi
  fi
 fi

fi

#end#
