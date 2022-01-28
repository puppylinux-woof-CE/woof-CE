#!/bin/sh
#Restore deleted files in frugal installaions...
if [ -d /initrd/pup_ro2 ];then
 if [ ! -d /initrd/pup_ro2/usr/local/pupdial ];then
  cp -f /initrd/pup_ro2/usr/sbin/gen_modem_init_string /usr/sbin/
  cp -f /initrd/pup_ro2/usr/sbin/get_bluetooth_connection /usr/sbin/
  cp -f /initrd/pup_ro2/usr/sbin/modemdisconnect /usr/sbin/
  cp -f /initrd/pup_ro2/usr/sbin/modemprobe /usr/sbin/
  cp -f /initrd/pup_ro2/usr/sbin/modemprobe_erase /usr/sbin/
  cp -f /initrd/pup_ro2/usr/sbin/modemprobe_help /usr/sbin/
  cp -f /initrd/pup_ro2/usr/sbin/modemtest /usr/sbin/
  cp -f /initrd/pup_ro2/usr/sbin/pupdial /usr/sbin/
  cp -f /initrd/pup_ro2/usr/sbin/pupdial_init_hotpluggable /usr/sbin/
  cp -f /initrd/pup_ro2/usr/sbin/pupdial_wizard_helper /usr/sbin/
 fi
fi

#v2.2 restore for old, adapted wvdial pet packages.
if [ -f /etc/ppp/READMEwvdial.txt ];then
 mv -f /etc/ppp/peers/wvdial* /etc/ppp/
fi
