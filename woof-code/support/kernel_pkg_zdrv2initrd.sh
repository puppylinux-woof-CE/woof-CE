#!/bin/bash
# .. inside sandbox3

[ -f ../_00build.conf ] && . ../_00build.conf
[ -f ../DISTRO_SPECS ] && . ../DISTRO_SPECS
[ -z "$MKSQUASHFS" ] && MKSQUASHFS=mksquashfs
[ -z "$ZDRVSFS" ] && ZDRVSFS="zdrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
[ -z "$KERNELPKG" ] && KERNELPKG=${KERNEL_TARBALL_URL##*/} #basename
[ -z "$KERNELVER" ] && KERNELVER="`ls zdrv/lib/modules 2>/dev/null  | grep -o '[23456789]\..*' | head -n 1 | cut -f 4 -d '/'`" 

ln -snf ../initrd-progs/ initrd-tree

#091222 support laptop internal sd/mmc cards at bootup...
MEMXTRAMODS='tifm_core.ko tifm_7xx1.ko mmc_core.ko mmc_block.ko tifm_sd.ko
led-class.ko sdhci.ko sdhci-pci.ko'

#110712 reduce list a bit, exclude hid drivers that are not keyboard (note, 2.6.39-3 kernel configured with them builtin)...
#  removed: hid-gyration.ko hid-ntrig.ko hid-petalynx.ko hid-pl.ko hid-sony.ko hid-sunplus.ko hid-topseed.ko
HIDXTRAMODS='hid-a4tech.ko hid-apple.ko hid-belkin.ko hid-cherry.ko
hid-chicony.ko hid-cypress.kohid-ezkey.ko hid-logitech.ko
hid-microsoft.ko hid-monterey.ko hid-samsung.ko'

NEEDEDINITRDMODS=" overlay.ko aufs.ko cdrom.ko fuse.ko ide-cd.ko
nls_cp437.ko nls_cp850.ko nls_cp852.ko nls_iso8859-1.ko nls_iso8859-2.ko
nls_utf8.ko nls_cp850.ko sqlzma.ko squashfs.ko sr_mod.ko unlzma.ko
aes.ko aes_generic.ko blkcipher.ko crypto_blkcipher.ko cbc.ko cryptoloop.ko
rsrc_nonstatic.ko yenta_socket.ko ehci-hcd.ko ohci-hcd.ko uhci-hcd.ko usb-storage.ko
usbhid.ko hid.ko usbcore.ko usb-common.ko scsi_wait_scan.ko ssb.ko
${HIDXTRAMODS} ${DISTRO_MODULES} ${MEMXTRAMODS}
psmouse.ko libcrc32c.ko zlib_deflate.ko
ext2.ko ext3.ko ext4.ko crc16.ko jbd2.ko fscrypto.ko mbcache.ko
isofs.ko fat.ko msdos.ko vfat.ko ntfs.ko udf.ko crc-itu-t.ko
scsi_mod.ko sd_mod.ko sr_mod.ko sg.ko raid_class.ko raid_class.ko "

for ONENEEDED in $NEEDEDINITRDMODS
do
	echo -n "$ONENEEDED "
	FNDONE="`find zdrv/lib/modules -type f -name $ONENEEDED | sed -e 's%zdrv/%/%'`"
	if [ "$FNDONE" != "" ];then
		FNDDIR="`dirname $FNDONE`"
		mkdir -p initrd-tree$FNDDIR
		cp -af zdrv${FNDONE} initrd-tree${FNDONE}
	fi
done

dirs="zdrv/lib/modules/${KERNELVER}/kernel/drivers/ata
zdrv/lib/modules/${KERNELVER}/kernel/drivers/block"

for dir in $dirs
do
	for ONENEEDED in $(find $dir -type f) ; do
		echo -n "${ONENEEDED##*/} "
		DEST="${ONENEEDED/zdrv/initrd-tree}"
		mkdir -p `dirname $DEST`
		cp -af ${ONENEEDED} ${DEST}
	done
done

busybox depmod -b initrd-tree -F System.map $KERNELVER
sync

### END ###
