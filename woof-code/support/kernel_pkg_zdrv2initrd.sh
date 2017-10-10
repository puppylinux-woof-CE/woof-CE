#!/bin/bash
# .. inside sandbox3

[ -f ../_00build.conf ] && . ../_00build.conf
[ -f ../DISTRO_SPECS ] && . ../DISTRO_SPECS
[ -z "$MKSQUASHFS" ] && MKSQUASHFS=mksquashfs
[ -z "$ZDRVSFS" ] && ZDRVSFS="zdrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
[ -z "$KERNELPKG" ] && KERNELPKG=${KERNEL_TARBALL_URL##*/} #basename
[ -z "$KERNELVER" ] && KERNELVER="`ls zdrv/lib/modules 2>/dev/null  | grep -o '[23456789]\..*' | head -n 1 | cut -f 4 -d '/'`" 

#BOOT_SCSI=yes

if [ "$BOOT_SCSI" = "yes" ] ; then
	SCSIDRVS="parport.ko"
	for ONESCSI in `find zdrv/lib/modules/$KERNELVER/kernel/drivers/scsi -type f -name \*.ko`
	do
	  #really only want those with pci interface...
	  SCSIBASE="`basename $ONESCSI`"
	  SCSINAMEONLY="`basename $ONESCSI .ko`"
	  ALIASFND="`modinfo -b zdrv -k ${KERNELVER} ${SCSINAMEONLY} 2>/dev/null | grep '^alias:'`"
	  if [ "$ALIASFND" ];then
	   SCSIDRVS="$SCSIDRVS $SCSIBASE"
	   #add any deps to list...
	   SCSIDEPS="`modinfo -b zdrv -k ${KERNELVER} ${SCSINAMEONLY} 2>/dev/null | grep '^depends:' | head -n 1 | tr -s ' ' | cut -f 2 -d ' ' | sed -e 's%,%.ko %g' -e 's%$%.ko%'`"
	   [ "$SCSIDEPS" != ".ko" ] && SCSIDRVS="$SCSIDRVS $SCSIDEPS"
	  fi
	done
fi

#091222 support laptop internal sd/mmc cards at bootup...
MEMXTRAMODS='tifm_core.ko tifm_7xx1.ko mmc_core.ko mmc_block.ko tifm_sd.ko led-class.ko sdhci.ko sdhci-pci.ko'
#v423 2.6.29/30 kernels have extra hid-* modules needed for wireless keyboard to work...
#HIDXTRAMODS='hid-a4tech.ko hid-apple.ko hid-belkin.ko hid-cherry.ko hid-chicony.ko hid-cypress.ko hid-ezkey.ko hid-gyration.ko hid-logitech.ko hid-microsoft.ko hid-monterey.ko hid-ntrig.ko hid-petalynx.ko hid-pl.ko hid-samsung.ko hid-sony.ko hid-sunplus.ko hid-topseed.ko'
#110712 reduce list a bit, exclude hid drivers that are not keyboard (note, 2.6.39-3 kernel configured with them builtin)...
#  removed: hid-gyration.ko hid-ntrig.ko hid-petalynx.ko hid-pl.ko hid-sony.ko hid-sunplus.ko hid-topseed.ko
HIDXTRAMODS='hid-a4tech.ko hid-apple.ko hid-belkin.ko hid-cherry.ko hid-chicony.ko hid-cypress.kohid-ezkey.ko hid-logitech.ko hid-microsoft.ko hid-monterey.ko hid-samsung.ko'
#copy some modules to initrd-tree/... w007 added nls_utf8.ko w468 added nls_cp850.ko w476 added nls_iso8859-2.ko, nls_cp850.ko, nls_cp852.ko. 100214 added floppy.ko, psmouse.ko
#100406 add btrfs.ko and its deps libcrc32c.ko,zlib_deflate.ko
#121227 if kernel has f.s. drivers as modules (quirky6), added ext2.ko ext3.ko ext4.ko fat.ko msdos.ko vfat.ko ntfs.ko reiserfs.ko udf.ko, and deps: jbd.ko mbcache.ko jbd2.ko
NEEDEDINITRDMODS=" ${SCSIDRVS} overlay.ko aufs.ko cdrom.ko fuse.ko ide-cd.ko
ide-floppy.ko nls_cp437.ko nls_cp850.ko nls_cp852.ko nls_iso8859-1.ko nls_iso8859-2.ko
nls_utf8.ko nls_cp850.ko sqlzma.ko squashfs.ko sr_mod.ko unlzma.ko
aes.ko aes_generic.ko blkcipher.ko crypto_blkcipher.ko cbc.ko cryptoloop.ko
rsrc_nonstatic.ko yenta_socket.ko ehci-hcd.ko ohci-hcd.ko uhci-hcd.ko usb-storage.ko
usbhid.ko hid.ko usbcore.ko usb-common.ko
scsi_wait_scan.ko ssb.ko
${HIDXTRAMODS} ${DISTRO_MODULES} ${MEMXTRAMODS}
floppy.ko psmouse.ko btrfs.ko libcrc32c.ko zlib_deflate.ko ext2.ko ext3.ko isofs.ko
ext4.ko crc16.ko jbd2.ko fscrypto.ko mbcache.ko
fat.ko msdos.ko vfat.ko ntfs.ko reiserfs.ko udf.ko crc-itu-t.ko
scsi_mod.ko sd_mod.ko sr_mod.ko sg.ko raid_class.ko raid_class.ko "
NEEDEDINITRDMODS="`echo -n "$NEEDEDINITRDMODS" | tr -s ' ' | tr ' ' '\n' | sort -u | tr '\n' ' '`"
for ONENEEDED in $NEEDEDINITRDMODS
do
	echo -n "$ONENEEDED "
	FNDONE="`find zdrv/lib/modules -type f -name $ONENEEDED | sed -e 's%zdrv/%/%'`"
	if [ "$FNDONE" != "" ];then
		FNDDIR="`dirname $FNDONE`"
		mkdir -p initrd-tree$FNDDIR
		cp -af zdrv${FNDONE} initrd-tree${FNDONE}
		#[ "$SDFLAG" = "" ] && rm -f zdrv${FNDONE} #avoid duplication. 120521 SD-image, do not delete.
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
