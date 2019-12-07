#!/bin/sh
#Settings for network privacy
#Dynamic Hardware ID: Change hardware id every boot
#Dynamic MAC: Change mac address every boot
#Reboot required to apply the settings

if [ "$(whoami)" != "root" ]; then
exec sudo -A $0 $@
exit
fi

if [ ! -e /etc/net-random.cfg ]; then
echo "RANDOM_HWID=\"ON\"
RANDOM_MAC=\"ON\"
" > /etc/net-random.cfg
fi

. /etc/net-random.cfg

retval=$(yad --title "Network Privacy" --fixed --center --window-icon="gtk-network" --text "\nThe applied settings will took effect on reboot\n" --form --field="Dynamic Hardware ID:CB" "ON!OFF" --field="Dynamic MAC Address:CB" "ON!OFF" "ON" "OFF" --button="gtk-ok:0" --button="gtk-cancel:1")

if [ $? -ne 0 ]; then
 exit
fi

echo "RANDOM_HWID=\"$(echo "$retval" | cut -f 1 -d '|')\"
RANDOM_MAC=\"$(echo "$retval" | cut -f 2 -d '|')\"
" > /etc/net-random.cfg

yad --title "Network Privacy" --fixed --center --window-icon="gtk-network" --text "\nConfiguration Saved. Reboot the system now?\n" --button="gtk-yes:0" --button="gtk-no:1"

if [ $? -ne 0 ]; then
 exit
else
 reboot
fi
