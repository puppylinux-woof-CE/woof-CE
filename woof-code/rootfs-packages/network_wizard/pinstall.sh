#!/bin/sh

# Replace placeholder with /usr/local/bin symlink
ln -snf /usr/local/network-wizard/net-setup.sh usr/local/bin/

# Remove files from old locations
if [ "`pwd`" = '/' ];then
    if [ -f usr/sbin/net-setup.sh ]; then
        [ ! -f etc/init.d/rc.network-start ] && rm -f etc/rc.d/rc.network
        rm -f usr/sbin/net-setup.sh
        rm -f usr/sbin/wag-profiles.sh
        rm -f usr/sbin/ndiswrapperGUI.sh
    fi
fi
