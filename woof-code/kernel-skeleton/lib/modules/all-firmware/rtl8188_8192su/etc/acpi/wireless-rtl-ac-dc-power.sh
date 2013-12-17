#! /bin/sh
# Power saving for rtl8192 using the Realtek rtl drivers.
# This script relies upon the name of the driver.
#
CONTROL_RTL_POWER=1
VERBOSE="[ 1 = 1 ]"
OUTPUT="/dev/stdout"

if [ x$CONTROL_RTL_POWER = x1 ] ; then
	# Provide defaults for config file settings
	[ "$RTL8192_AC_POWER" ]   || RTL8192_AC_POWER=0
	[ "$RTL8192_BATT_POWER" ] || RTL8192_BATT_POWER=6

	R8192_DRIVERNAME=rtl819xE
	R8192_DRVMODNAME=r8192_pci 

	# find executables
	if [ -x /sbin/iwpriv ] ; then
		IWPRIV=/sbin/iwpriv
	elif [ -x /usr/sbin/iwpriv ] ; then
		IWPRIV=/usr/sbin/iwpriv
	else
		$VERBOSE && echo "iwpriv is not installed" >> $OUTPUT
	fi
	if [ -x /sbin/iwconfig ] ; then
		IWCONFIG=/sbin/iwconfig
	elif [ -x /usr/sbin/iwconfig ] ; then
		IWCONFIG=/usr/sbin/iwconfig
	else
		$VERBOSE && echo "iwconfig is not installed" >> $OUTPUT
	fi

	SET_R8192_AC_PARMS="set_power $RTL8192_AC_POWER"
	SET_R8192_BAT_PARMS="set_power $RTL8192_BATT_POWER"

	#
	# Find all the wireless devices using the supplied driver names.
	# Place the interface names on the list WIFI_IFNAMES.
	#
	findWifiIfsByDriver() {
		local DEVICE;
		local LINK_TARGET;
		WIFI_IFNAMES=""

		for DEVICE in /sys/class/net/*; do
			if [ -d $DEVICE/wireless -a -h $DEVICE/device/driver ]; then
				# See if the driver for $DEVICE matches the supplied one by checking the link to
				# the driver.
				LINK_TARGET=`readlink $DEVICE/device/driver`
				LINK_TARGET=${LINK_TARGET##*/}

				if [ "$LINK_TARGET" = "$1" ]; then

					# add the interface name to the list
		    			WIFI_IFNAMES="$WIFI_IFNAMES ${DEVICE##*/}"
				fi
			fi
		done
		echo $WIFI_IFNAMES
	}


	#
	# Set all the adaptors using the supplied driver into the supplied
	# power saving mode
	#
	# $1 - driver name
	# $2 - power command
	# $3 - power command arguments
	#
	setWifiPwrSave () {
		local DEVICE;
		findWifiIfsByDriver $1;
		for DEVICE in $WIFI_IFNAMES; do
			$VERBOSE && echo "Wireless power saving: $2 $DEVICE $3" >> $OUTPUT
			$2 $DEVICE $3
		done
	}

	rtl8192_AcPwrSave () {
		setWifiPwrSave "$R8192_DRIVERNAME" "$IWPRIV" "$SET_R8192_AC_PARMS"
	}

	rtl8192_BatPwrSave () {
		setWifiPwrSave "$R8192_DRIVERNAME" "$IWPRIV" "$SET_R8192_BAT_PARMS"
	}
	grep -q off-line /proc/acpi/ac_adapter/*/state
        if [ $? = 0 ]
        then
            [ -d /sys/module/$R8192_DRVMODNAME ] && rtl8192_BatPwrSave
	else
            [ -d /sys/module/$R8192_DRVMODNAME ] && rtl8192_AcPwrSave
	fi
	
else
	$VERBOSE && echo "Realtek rtl Wireless power setting is disabled." >> $OUTPUT
fi
