#!/bin/sh
#BK may 2011

if [ "`pwd`" = "/" ];then #installing in a running puppy (not in woof)
 yaf-splash -bg pink -close box -placement center -text "You have installed Dbus, but it will not work until after Puppy is rebooted. Please do so before trying to run any application that depends on Dbus." &
fi
