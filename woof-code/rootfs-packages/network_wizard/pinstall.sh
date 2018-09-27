#!/bin/sh
ln -snf /usr/local/network-wizard/net-setup.sh usr/local/bin/

if [ "`pwd`" = '/' ];then
 rm -f etc/rc.d/rc.network
 rm -f usr/sbin/net-setup.sh
 rm -f usr/sbin/wag-profiles
 rm -f usr/sbin/ndiswrapperGUI.sh
fi
