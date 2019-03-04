#!/bin/sh
if [ "$(pwd)" = "/" ];then
 #Remove copies from old location.
 rm -f usr/sbin/gen_modem_init_string
 rm -f usr/sbin/get_bluetooth_connection
 rm -f usr/sbin/modemdisconnect
 rm -f usr/sbin/modemprobe
 rm -f usr/sbin/modemprobe_erase
 rm -f usr/sbin/modemprobe_help
 rm -f usr/sbin/modemtest
 rm -f usr/sbin/pupdial
 rm -f usr/sbin/pupdial_init_hotpluggable
 rm -f usr/sbin/pupdial_wizard_helper
fi

if [ "$(pwd)" = "/" ];then
 #v2.2 compensate for old, adapted wvdial packages
 mv -f etc/ppp/wvdial* etc/ppp/peers/
fi

#Replace placeholders with links.
ln -snf /usr/local/pupdial/pupdial usr/sbin/
ln -snf /usr/local/pupdial/modemdisconnect usr/sbin/
