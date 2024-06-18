#!/bin/sh
# Restore old link to sns, if needed.
if [ -e /usr/sbin/sns-old.bak ];then
    mv -f /usr/sbin/sns-old.bak /usr/sbin/sns
    chmod +x
fi

#v3.4 Restore old udev rules file.
[ -e /initrd/pup_ro2/etc/udev/rules.d/51-simple_network_setup.rules ] \
  && cp -n /initrd/pup_ro2/etc/udev/rules.d/51-simple_network_setup.rules /etc/udev/rules.d/
