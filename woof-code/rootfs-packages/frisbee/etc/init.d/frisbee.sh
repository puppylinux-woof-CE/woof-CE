#!/bin/bash
### BEGIN DEBIAN INIT INFO
# Provides:          frisbee wpa_supplicant & dhcpcd up/down
# Required-Start:    
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Wireless authentication supplicant & DHCP client
# Description:       Daemons for ethernet and wireless networking - ensures wpa_supplicant ready before starting dhcpcd
### END DEBIAN INIT INFO

#140118 npierce: before starting dhcpcd, ensure wpa supplicant either is inactive (no enabled networks) or its network scan has completed.
#140224 Scooby: For restart, obtain and export saved wifi interface name.
#140531 rerwin: Add compatibility with DebianDog - INIT INFO, optional default file.
#140824 Fix multiple interfaces test to detect changes in connected devices; correct selection of active wifi i/f.
#140826 Moved common wpa_supplelment code into internal procedure.
#150410 1.3.4 for stop, leave dhcpcd running for other uses (e.g., samba) -- 'stop' no longer used by frisbee_mode_disable.
#160212 rcrsn51: Remove unnecessary 'stop' case because it impacts shutdown by disconnecting networks before samba terminates -- dhcpcd and wpa_supplicant are terminated as part of shutdown.
#170612 verify wifi country of regulation matches user specified country.

grep -q '^frisbee_mode=1' /etc/frisbee/frisbee.conf || exit

#set -x

[ -d /usr/local/frisbee ] && . /usr/local/frisbee/func || . /usr/lib/frisbee/func

[ -f /etc/default/frisbee ] && . /etc/default/frisbee #140531

if [ -h /etc/resolv.conf ] ; then  #pppoe creates a symlink
	rm /etc/resolv.conf
	touch /etc/resolv.conf
fi

start_wpa_supplicant() #140826...
{
	#Requires WIFI_IF, WIFACES
	#20140118 npierce: ensure wpa inactive or association/authentication complete...
	if grep -q '^wireless_enabled=1' /etc/frisbee/frisbee.conf; then #140303
		export INTERFACE=$WIFI_IF
		WPAPAT="wpa_supplicant .*\-i *$WIFI_IF "
		[ "$(busybox ps | grep "$WPAPAT" | grep -v ' grep ')" = "" ] \
		 && start_wpa #in foreground

		COUNT=33
		while [ $(( COUNT-- )) -gt 0 ];do
			wpa_cli -i $INTERFACE status 2> /dev/null \
			 | grep -qE 'wpa_state=COMPLETED|wpa_state=INACTIVE' && break
			sleep 1
		done
		[ $COUNT -lt 0 ] \
		 && echo "$0: wpa scan on $INTERFACE found no wireless networks" \
		 && return 1
	fi
	return 0 #20140118 end
}

case "$1" in
	start|'')
		[ -d /tmp/.frisbee ] || mkdir /tmp/.frisbee
		
		if grep -q '^announce_state_changes=1' /etc/frisbee/frisbee.conf; then
			[ ! -f /etc/dhcpcd_state_notify ] && touch /etc/dhcpcd_state_notify
		elif grep -q '^announce_state_changes=0' /etc/frisbee/frisbee.conf; then
			[ -f /etc/dhcpcd_state_notify ] && rm -f /etc/dhcpcd_state_notify
		fi

		sleep 5

		[ -x /usr/sbin/connectwizard_crd ] && connectwizard_crd >&2 #170612

		WIFACES="$(get_ifs_wireless)" #140824...
		if [ "$WIFACES" ];then
			[ -d /tmp/.network_tray ] \
			 && touch /tmp/.network_tray/use_wireless_control_menu_labels \
			 || touch /tmp/.network_tray-use_wireless_control_menu_labels
		else
			[ -d /tmp/.network_tray ] \
			 && rm -f /tmp/.network_tray/use_wireless_control_menu_labels \
			 || rm -f /tmp/.network_tray-use_wireless_control_menu_labels
		fi #140224 end

		USERIF=$(cat /etc/frisbee/userif 2>/dev/null) #140824...

		WIFI_IF=""
		if [ "$USERIF" ] && echo -n "$WIFACES" | grep -q -w "$USERIF"; then
			WIFI_IF="$USERIF"
			echo -n "$WIFI_IF" > /etc/frisbee/interface #140303
			rm -f /etc/frisbee/userif
		else
			WIFI_IF="$(cat /etc/frisbee/interface 2>/dev/null)"
			if [ -z "$WIFI_IF" ] \
			 || [ "$(echo -n "$WIFACES" | grep -q -w "$WIFI_IF")" = "" ]; then
				WIFI_IF="$(echo -n "$WIFACES" | head  -n 1)" #140303
				echo -n "$WIFI_IF" > /etc/frisbee/interface #140303
			fi
		fi

		if [ "$WIFI_IF" ];then #140824 end

			INTMODULE=$(readlink /sys/class/net/$WIFI_IF/device/driver/module)
			INTMODULE=${INTMODULE##*/}
			case "$INTMODULE" in
				hostap*) DRIVER="hostap" ;;
				rt61|rt73) DRIVER="ralink" ;;
				*) DRIVER="wext" ;;
			esac
			[ -d /etc/acpi ] && echo "$INTMODULE" > /etc/acpi/wifi-driver

			[ "$WIFACES" ] && start_wpa_supplicant #140826

		fi
		start_dhcp&
		;;

#160212...
#		stop)
#		wpa_cli terminate 2>/dev/null
#		dhcpcd -k 150410
#		;;

	restart)
		WIFI_IF=`cat /etc/frisbee/interface 2>/dev/null` #140826...
		WIFACES="$(get_ifs_wireless)"
		[ "$WIFI_IF" -a "$WIFACES" ] && start_wpa_supplicant
		reset_dhcp
		;;
esac
