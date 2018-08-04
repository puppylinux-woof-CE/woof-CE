#!/bin/sh
#Restore deleted files in frugal installaions...
if [ -d /initrd/pup_ro2 ];then
 cp -f /initrd/pup_ro2/usr/sbin/gen_modem_init_string /usr/sbin/
 cp -f /initrd/pup_ro2/usr/sbin/modemdisconnect /usr/sbin/
 cp -f /initrd/pup_ro2/usr/sbin/modemprobe /usr/sbin/
 cp -f /initrd/pup_ro2/usr/sbin/modemprobe_erase /usr/sbin/
 cp -f /initrd/pup_ro2/usr/sbin/modemprobe_help /usr/sbin/
 cp -f /initrd/pup_ro2/usr/sbin/modemtest /usr/sbin/
 cp -f /initrd/pup_ro2/usr/sbin/pupdial /usr/sbin/
 cp -f /initrd/pup_ro2/usr/sbin/pupdial_init_hotpluggable /usr/sbin/
 cp -f /initrd/pup_ro2/usr/sbin/pupdial_wizard_helper /usr/sbin/
fi
