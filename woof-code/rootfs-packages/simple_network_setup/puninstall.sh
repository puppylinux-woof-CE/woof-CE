#!/bin/sh
# Restore old link to sns, if needed.
[ -x /usr/local/bin/sns ] \
 || ln -s /usr/local/simple_network_setup/sns /usr/sbin/
