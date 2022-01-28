#!/bin/bash
# shellcheck disable=SC1091 # Skip sourced checks.
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
#180203 repeat iwconfig for slow-loading wifi modules (kernels 4+).
#200829 v2.0 resolve shellcheck warnings; remove unused/ineffective code.

grep -q '^frisbee_mode=1' /etc/frisbee/frisbee.conf || exit

if [ -d /usr/local/frisbee ]; then
	. /usr/local/frisbee/connect-func
else
	. /usr/lib/frisbee/connect-func
fi

[ -f /etc/default/frisbee ] && . /etc/default/frisbee #140531

if [ -h /etc/resolv.conf ] ; then  #pppoe creates a symlink
	rm /etc/resolv.conf
	touch /etc/resolv.conf
fi

start_wpa_supplicant() { #140826...
	#20140118 npierce: ensure wpa inactive or association/authentication complete...
	if grep -q '^wireless_enabled=1' /etc/frisbee/frisbee.conf; then #140303
	    export INTERFACE=$1
	    if ! pgrep -a 'wpa_supplicant' | grep -qw "\-i$INTERFACE"; then
	        start_wpa #in foreground
	        sleep 1
	    fi

	    COUNT=33
	    until wpa_cli -i "$INTERFACE" status 2> /dev/null | \
	      grep -qE 'wpa_state=COMPLETED|wpa_state=INACTIVE'; do
	        [ $(( --COUNT )) -le 0 ] && break
	        sleep 1
	    done
	    [ $COUNT -le 0 ] \
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

	    [ -x /usr/sbin/connectwizard_crd ] && connectwizard_crd >&2 #170612

	    WAITCNT=0; WAITMAX=30 #180203...
	    until WIFACES="$(get_ifs_wireless)" || [ $WAITCNT -ge $WAITMAX ]; do
	        sleep 1
	        (( WAITCNT++ ))
	    done
	    [ "$WAITCNT" -gt 0 ] \
	      && echo "frisbee.sh: waited for ethernet interfaces: seconds = ${WAITCNT}" >&2 #180203 end

	    if [ "$WIFACES" ];then #140824...
	        if [ -d /tmp/.network_tray ]; then
	            touch /tmp/.network_tray/use_wireless_control_menu_labels
	        else
	            touch /tmp/.network_tray-use_wireless_control_menu_labels
	        fi
	    else
	        if [ -d /tmp/.network_tray ]; then
	            rm -f /tmp/.network_tray/use_wireless_control_menu_labels
	        else
	            rm -f /tmp/.network_tray-use_wireless_control_menu_labels
	        fi
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

	    [ -n "$WIFI_IF" ] && [ -n "$WIFACES" ] \
	      && start_wpa_supplicant "$WIFI_IF" #140824 end, 140826
	    start_dhcp&
	    ;;

#160212...
#       stop)
#       wpa_cli terminate 2>/dev/null
#       dhcpcd -k 150410
#       ;;

	restart)
	    WIFI_IF=$(cat /etc/frisbee/interface 2>/dev/null) #140826...
	    WIFACES="$(get_ifs_wireless)"
	    [ -n "$WIFI_IF" ] && [ -n "$WIFACES" ] \
	      && start_wpa_supplicant "$WIFI_IF"
	    reset_dhcp
	    ;;
esac
