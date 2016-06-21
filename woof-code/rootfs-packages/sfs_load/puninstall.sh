#!/bin/sh
SYSINIT=./etc/rc.d/rc.sysinit
[ -s $SYSINIT.org ] && mv -f $SYSINIT.org $SYSINIT
[ -x  $SYSINIT ] || chmod +x $SYSINIT