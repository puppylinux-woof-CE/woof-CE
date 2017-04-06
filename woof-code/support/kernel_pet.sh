#!/bin/sh
# simplified kernel pet stuff
# sourced by 3builddistro-Z
#
# .. inside sandbox3

KERNELPKG=${KERNEL_TARBALL_URL##*/} #basename

KERNELVER="`tar --list -f ../packages-pet/${KERNELPKG} 2>/dev/null | grep -o '/lib/modules/[23]\..*' | head -n 1 | cut -f 4 -d '/'`" #120502 hide error msg.
dotnum="`echo -n "$KERNELVER" | sed -e 's%[^\.]%%g' | wc -c`"
SUB_KERNELVER=`echo -n "$KERNELVER" | cut -f 1 -d '-' | cut -f 3 -d '.'`
MAJ_KERNELVER=`echo -n "$KERNELVER" | cut -f 1 -d '-' | cut -f 1 -d '.'` #111014 2 or 3.
#allow only 2.6.29 kernel+, mksquashfs v4.0...
if [ "$MAJ_KERNELVER" = "2" -a "$SUB_KERNELVER" != "" -a "$SUB_KERNELVER" -lt 29 ] ; then
	echo "ERROR: only kernel 2.6.29+ allowed "
	exit 1
fi

echo "You have chosen $KERNELPKG, which is version $KERNELVER."

#now do the kernel...
echo
rm -f $KERNELPKG
KERNPKGNAMEONLY="`basename $KERNELPKG .pet`"
rm -rf $KERNPKGNAMEONLY
cp ../packages-pet/${KERNELPKG} ./

pet2tgz $KERNELPKG
tar -xf $KERNPKGNAMEONLY.tar.?z
rm -rf zdrv/
mv -f $KERNPKGNAMEONLY zdrv/

mv -f zdrv/etc/modules/firmware.dep zdrv/etc/modules/firmware.dep.${KERNELVER}

#130613 kmod depmod wants these two... they are moved in later, but do it here also...
mkdir -p zdrv/lib/modules/$KERNELVER
[ -f zdrv/etc/modules/modules.builtin ] && cp -a -f zdrv/etc/modules/modules.builtin zdrv/lib/modules/$KERNELVER/
[ -f zdrv/etc/modules/modules.order ] && cp -a -f zdrv/etc/modules/modules.order zdrv/lib/modules/$KERNELVER/

USINGKMOD='no'
[ "`grep '^kmod' ../woof-installed-packages`" != "" ] && USINGKMOD='yes'
if [ "$USINGKMOD" = "no" ];then
 if [ ! -f zdrv/lib/modules/$KERNELVER/modules.dep ];then
  busybox depmod -b $WKGDIR/sandbox3/zdrv -F $WKGDIR/sandbox3/System.map $KERNELVER
 fi
else
 cp -f ../boot/kmod ./
 ln -snf kmod depmod
 if [ ! -f zdrv/lib/modules/$KERNELVER/modules.dep ];then
  ./depmod -b $WKGDIR/sandbox3/zdrv -F $WKGDIR/sandbox3/System.map $KERNELVER
 fi
fi

SCSIFLAG=""
SCSIDRVS="parport.ko"
if [ "$CHOICE_SCSI" = "Boot_SCSI" ];then #note, further down, scsi modules get moved to initrd.
 SCSIFLAG="-SCSI" #used in name of .iso file.
 #mkdir -p initrd-tree/lib/modules/$KERNELVER/kernel/drivers
 #cp -a -f zdrv/lib/modules/$KERNELVER/kernel/drivers/scsi initrd-tree/lib/modules/$KERNELVER/kernel/drivers/
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

echo "deleting big modem modules..."
for BIGMODS in agr hcf hsf intel5 Intel5 esscom pctel
do
  for ONEBIGMOD in `find zdrv/lib/modules/${KERNELVER}/ -type f -name ${BIGMODS}*.ko -o -name ${BIGMODS}*HIDE` #101222
  do
   BIGMODNAME="`basename $ONEBIGMOD`"
   echo -n "$BIGMODNAME "
   [ -f $ONEBIGMOD ] && rm -f $ONEBIGMOD
  done
done
rm -rf zdrv/lib/modules/all-firmware/hsfmodem 2>/dev/null
rm -f zdrv/lib/modules/all-firmware/hsfmodem.tar.gz 2>/dev/null
rm -rf zdrv/lib/modules/all-firmware/hcfpcimodem 2>/dev/null
rm -f zdrv/lib/modules/all-firmware/hcfpcimodem.tar.gz 2>/dev/null
rm -rf zdrv/lib/modules/all-firmware/intel536ep 2>/dev/null
rm -f zdrv/lib/modules/all-firmware/intel536ep.tar.gz 2>/dev/null
rm -rf zdrv/lib/modules/all-firmware/intel537* 2>/dev/null
rm -f zdrv/lib/modules/all-firmware/intel537*.tar.gz 2>/dev/null

if [ "$CHOICE_SCSI" != "Keep_SCSI" ];then #v431
 #get rid of scsi modules except some essentials...
 #note, above option to move some to initrd has left some old pre-PCI modules behind.
 rm -rf /tmp/scsi-keep
 mkdir /tmp/scsi-keep
 for ONEKEEP in imm.ko ppa.ko raid_class.ko sg.ko scsi_wait_scan.ko
 do
  ONEFND="`find zdrv/lib/modules/$KERNELVER/kernel/drivers/scsi -type f -name $ONEKEEP`"
  [ "$ONEFND" ] && cp -a $ONEFND /tmp/scsi-keep/
 done
 rm -rf zdrv/lib/modules/$KERNELVER/kernel/drivers/scsi
 cp -a /tmp/scsi-keep zdrv/lib/modules/$KERNELVER/kernel/drivers/scsi
fi

if [ "$USINGKMOD" = "no" ];then #130418
 #cp -f ../boot/depmod ./
 busybox depmod -b $WKGDIR/sandbox3/zdrv -F $WKGDIR/sandbox3/System.map $KERNELVER
else
 cp -f ../boot/kmod ./kmod
 ln -snf kmod depmod
 ./depmod -b $WKGDIR/sandbox3/zdrv -F $WKGDIR/sandbox3/System.map $KERNELVER
fi
sync

# move aufs-utils to zdrv
for r in auibusy auplink mount.aufs umount.aufs aufs libau.so* aufs aufs.5 aubrsync aubusy auchk
do
	find rootfs-complete/ -type f -name $r | sed 's|^rootfs-complete/||' | \
	while read f ; do
		dir=zdrv/$(dirname $f)
		mkdir -p $dir
		mv -f rootfs-complete/${f} $dir
	done
done

sync
#==========================================
${MKSQUASHFS} zdrv ${ZDRVSFS} ${COMPCHOICE}
#==========================================

sync
chmod 644 ${ZDRVSFS}

mv -f ${ZDRVSFS} build/

### END ###
