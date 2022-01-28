#!/bin/sh
# Restore old link to sns, if needed.
if [ -e /usr/sbin/sns-old.bak ];then
    mv -f /usr/sbin/sns-old.bak /usr/sbin/sns
    chmod +x
fi

#Version 3.0:
[ -f /etc/simple_network_setup/connections-oldformat ] \
  && mv -f /etc/simple_network_setup/connections-oldformat /etc/simple_network_setup/connections
