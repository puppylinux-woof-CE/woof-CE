#!/bin/bash
#Barry Kauler 2009
#w001 now in /usr/sbin in the distro, called from /etc/rc.d/rc.update.
#w474 bugfix for 2.6.29 kernel, modules.dep different format.
#w478 old k2.6.18.1 has madwifi modules (ath_pci.ko) in /lib/modules/2.6.18.1/net.
#v423 now using busybox depmod, which generates modules.dep in "old" format.
#111027 make modinfo quiet.
#120507 improve kernel version test. add 'sdio' interfaces.

KERNVER="`uname -r`"
DRIVERSDIR="/lib/modules/$KERNVER/kernel/drivers/net"

echo "Updating /etc/networkmodules..."

DEPFORMAT='new'
if vercmp $KERNVER lt 2.6.29; then #120507
	DEPFORMAT='old'
fi

#v423 need better test, as now using busybox depmod...
[ "`grep '^/lib/modules' /lib/modules/${KERNVER}/modules.dep`" != "" ] && DEPFORMAT='old'

if [ "$DEPFORMAT" = "old" ];then
	OFFICIALLIST="`cat /lib/modules/${KERNVER}/modules.dep | grep "^/lib/modules/$KERNVER/kernel/drivers/net/" | sed -e 's/\.gz:/:/' | cut -f 1 -d ':'`"
else
	OFFICIALLIST="`cat /lib/modules/${KERNVER}/modules.dep | grep "^kernel/drivers/net/" | sed -e 's/\.gz:/:/' | cut -f 1 -d ':'`"
fi

#there are a few extra scattered around... needs to be manually updated...
EXTRALIST="extra/acx.ko
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
RAWLIST="$OFFICIALLIST
$EXTRALIST"

#the list has to be cutdown to genuine network interfaces only...
echo -n "" > /tmp/networkmodules
(
 echo "$RAWLIST" | while read ONERAW
 do

	[ "$ONERAW" = "" ] && continue #precaution

	#ONEBASE="`basename $ONERAW .ko`"
	#ONEINFO="`modinfo $ONEBASE 2>/dev/null | tr '\t' ' ' | tr -s ' '`" #111027 make it quiet.
	#ONETYPE="`echo "$ONEINFO" | grep '^alias:' | head -n 1 | cut -f 2 -d ' ' | cut -f 1 -d ':'`"
	#ONEDESCR="`echo "$ONEINFO" | grep '^description:' | head -n 1 | cut -f 2 -d ':'`"

	ONEBASE=${ONERAW##*/}
	ONEBASE=${ONEBASE%.ko}
	ONETYPE=""
	ONEDESCR=""
	MODINFO=$(modinfo $ONEBASE 2>/dev/null)
	[ "$MODINFO" = "" ] && continue

	while read line ; do
		case $line in
			"description:"*) read -r zz ONEDESCR <<< "$line" ;;
			"alias:"*) read -r alias ONETYPE <<< "$line" ; break ;;
		esac
	done <<< "$MODINFO"

	ONETYPE=${ONETYPE%%:*}
	case "$ONETYPE" in pci|pcmcia|usb|ssb|sdio)
		#ssb=b43legacy.ko...  sdio=sdio interfaces...
		echo "Adding $ONEBASE" >&2
		echo -e "$ONEBASE \"$ONETYPE:  $ONEDESCR\""
	esac

 done
) | sort -u > /etc/networkmodules-${KERNVER}

# the generated networkmodules includes the kernel version
# /etc/networkmodules is a symlink to that file
rm -f /etc/networkmodules
ln -sv networkmodules-${KERNVER} /etc/networkmodules

### END ###
