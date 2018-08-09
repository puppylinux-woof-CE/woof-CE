#!/bin/bash
#Barry Kauler 2009
#w001 now in /usr/sbin in the distro, called from /etc/rc.d/rc.update.
#111027 make modinfo quiet.

KERNVER="`uname -r`"
DRIVERSDIR="/lib/modules/$KERNVER/kernel/drivers/net"

echo "Updating /etc/networkmodules..."

( #> /tmp/nm_rawlist$$

grep "^kernel/drivers/net/" /lib/modules/${KERNVER}/modules.dep | \
	sed -e 's/\.gz:/:/' | cut -f 1 -d ':'

# there are a few extra scattered around... needs to be manually updated...
echo "acx.ko
extra/rt2400.ko
extra/rt2500.ko
extra/rt2570.ko
extra/rt61.ko
extra/rt73.ko
extra/acx-mac80211.ko
extra/atl2.ko
extra/rt2860sta.ko
extra/rt2870sta.ko
madwifi/ath_pci.ko
net/ath_pci.ko
linux-wlan-ng/prism2_usb.ko
linux-wlan-ng/prism2_pci.ko
linux-wlan-ng/prism2_plx.ko
r8180/r8180.ko
"

) | sed 's%.*/%% ; s%\.ko.*%%' | sort -u > /tmp/nm_rawlist$$

#the list has to be cutdown to genuine network interfaces only...

(
 while read ONEBASE
 do
	[ -z "$ONEBASE" ] && continue #precaution
	ONETYPE=""
	ONEDESCR=""
	MODINFO=$(modinfo $ONEBASE 2>/dev/null) || continue
	while read F1 F2plus ; do
		case $F1 in
			"description:") ONEDESCR="$F2plus" ;;
			"alias:")
				case "${F2plus}" in "pci:"*|"pcmcia:"*|"usb:"*|"ssb:"*|"sdio:"*)
					#ssb=b43legacy.ko...  sdio=sdio interfaces...
					#echo "Adding $ONEBASE" >&2
					ONETYPE="${F2plus%%:*}" # remove :*
					break ;;
				esac
				;;
		esac
	done <<< "$MODINFO"
	if [ "$ONETYPE" ] ; then
		echo -e "$ONEBASE \"$ONETYPE: $ONEDESCR\""
	fi
	#-
 done < /tmp/nm_rawlist$$
) > /etc/networkmodules-${KERNVER}

# the generated networkmodules includes the kernel version
# /etc/networkmodules is a symlink to that file
rm -f /etc/networkmodules /tmp/nm_rawlist$$
ln -sv networkmodules-${KERNVER} /etc/networkmodules

### END ###
