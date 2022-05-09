#!/bin/sh
# Restore old link to sns, if needed.
if [ -e /usr/sbin/sns-old.bak ];then
    mv -f /usr/sbin/sns-old.bak /usr/sbin/sns
    chmod +x
fi
