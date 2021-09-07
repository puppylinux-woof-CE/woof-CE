#!/bin/sh
# suspend.sh 28sep09 by shinobar
# 12feb10 pass poweroff
# 23apr12 fix was not suspend from acpi_poweroff.sh
#20140526 shinobar: avoid multiple run
#20140629 shinobar: ACPI_CONFIG
ACPI_CONFIG=/etc/acpi/acpi.conf
[ -s "$ACPI_CONFIG" ] && . "$ACPI_CONFIG"
case "$DISABLE_SUSPEND" in
y*|Y*|true|True|TRUE|1) exit;;
esac

#avoid multiple run
LOCKFILE=/tmp/acpi_suspend-flg
if [ -f "$LOCKFILE" ]; then
  PID=$(cat "$LOCKFILE")
  ps| grep "^[ ]*$PID " && exit
fi
echo -n $$ > "$LOCKFILE"
sync
[ "$(cat "$LOCKFILE")" = $$ ] || exit 0 

# do not suspend at shutdown proccess
#111129 added suspend to acpi_poweroff.sh
PS=$(ps)
[ ! -f /tmp/suspend ] && echo "$PS"| grep -qE 'sh[ ].*poweroff' && rm -f "$LOCKFILE" && exit 0
rm -f /tmp/suspend

# do not suspend if usb media mounted
USBS=$(probedisk2|grep '|usb' | cut -d'|' -f1 )
for USB in $USBS
do
	mount | grep -q "^$USB" && rm -f "$LOCKFILE" && exit 0
done

# process before suspend
# sync for non-usb drives
sync
rmmod ehci_hcd

#suspend
case "$DISABLE_LOCK" in
y*|Y*|true|True|TRUE|1) echo -n mem > /sys/power/state ;;
*)
  if [ -n "$DISPLAY" -a -z "`pidof xlock`" ]; then
    xlock -startCmd "echo mem > /sys/power/state"
  else
    echo -n mem > /sys/power/state
  fi
  ;;
esac

# process at recovery from suspend
#restartwm
modprobe ehci_hcd
#/etc/rc.d/rc.network restart

rm -f "$LOCKFILE"
