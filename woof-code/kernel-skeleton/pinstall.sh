#!/bin/sh
#when this executes, working directory is in sandbox3/rootfs-complete.
#called from script 3builddistro, after content of kernel-skeleton copied into sandbox3/rootfs-complete.

echo "setup for kernel-skeleton..."

#the brcm firmware is rather large. remove if modules not present.
#This is Broadcom wireless. The modules are in the 2.6.39.x kernel, not in 2.6.32.x.
BRCMFMAC="`find ./lib/modules -type f -name brcmfmac.ko`" #and brcmsmac.ko
if [ ! "$BRCMFMAC" ];then
 #rm -f ./lib/modules/all-firmware/brcm.tar.gz
 rm -r -f ./lib/modules/all-firmware/brcm #120127 no longer tarballs.
fi

#pemasu, oct.2011
ATH9KHTC="`find ./lib/modules -type f -name ath9k_htc.ko`"
if [ ! "$ATH9KHTC" ];then
 #rm -f ./lib/modules/all-firmware/ath9k_htc.tar.gz
 rm -r -f ./lib/modules/all-firmware/ath9k_htc #120127 no longer tarballs.
fi

#not sure, b43 may be fixed if move firmware...
#mv -f ./lib/modules/all-firmware/b43/lib/firmware/b43 ./lib/firmware/b43
#120126 comment-out, fixed uevent replay for ssb at bootup, see http://bkhome.org/blog/?viewDetailed=02651

#120310
KERNMAJ3="`find ./lib/modules -mindepth 1 -maxdepth 1 -type d -name '3.*'`"
if [ "$KERNMAJ3" ];then
 rm -rf ./lib/modules/all-firmware/ar9170usb #replaced by carl9170.
 sed -i -e '/^ar9170usb/d' ./etc/modules/firmware.dep
 rm -rf ./lib/modules/all-firmware/rt2860sta-fw #replaced by new firmware in rt2x00
 sed -i -e '/^rt2860sta/d' ./etc/modules/firmware.dep
 rm -rf ./lib/modules/all-firmware/rt2870sta-fw #replaced by new firmware in rt2x00
 sed -i -e '/^rt2870sta/d' ./etc/modules/firmware.dep
 rm -rf ./lib/modules/all-firmware/rtl8192se #firmware now in rtlwifi
 sed -i -e '/^rtl8192se/d' ./etc/modules/firmware.dep
else
 rm -rf ./lib/modules/all-firmware/carl9170
 sed -i -e '/^carl9170/d' ./etc/modules/firmware.dep
 rm -rf ./lib/modules/all-firmware/rtlwifi #use older rtl8192se
 sed -i -e '/^rtlwifi/d' ./etc/modules/firmware.dep #use older rtl8192se
fi

