#!/bin/bash
# simplified kernel pet stuff
# sourced by 3builddistro-Z
#
# .. inside sandbox3

[ -f ../_00build.conf ] && . ../_00build.conf
[ -f ../DISTRO_SPECS ] && . ../DISTRO_SPECS
[ -z "$MKSQUASHFS" ] && MKSQUASHFS=mksquashfs
[ -z "$ZDRVSFS" ] && ZDRVSFS="zdrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"

(
	cd ..
	case "$KERNEL_TARBALL_URL" in *.pet|*.deb|*.txz|*.tgz)
		mkdir -p ../local-repositories/kernel_pkgs
		ln -sf ../local-repositories/kernel_pkgs kernel_pkgs 2>/dev/null
		if [ ! -f kernel_pkgs/${KERNEL_TARBALL_URL##*/} ] ; then
			echo -e "\nDownloading kernel pkg..."
			wget -P kernel_pkgs -c ${WGET_SHOW_PROGRESS} "$KERNEL_TARBALL_URL"
		fi ;;
	esac
)

KERNELPKG=${KERNEL_TARBALL_URL##*/} #basename

if [ ! -f ../kernel_pkgs/${KERNELPKG} ] ; then
	echo "file not found: ../kernel_pkgs/${KERNELPKG}"
	exit 1
fi

case $KERNELPKG in
	*.pet|*.txz|*.tgz) cmd='tar --list -f' ;;
	*.deb) cmd='dpkg-deb --contents' ;;
esac
KERNELVER="`$cmd ../kernel_pkgs/${KERNELPKG} 2>/dev/null | grep -o '/lib/modules/[23456789]\..*' | head -n 1 | cut -f 4 -d '/'`" #120502 hide error msg.

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
rm -rf zdrv
mkdir -p zdrv
echo
case $KERNELPKG in
	*.pet)
		rm -f $KERNELPKG
		KERNPKGNAMEONLY="`basename $KERNELPKG .pet`"
		rm -rf $KERNPKGNAMEONLY
		cp ../kernel_pkgs/${KERNELPKG} ./
		pet2tgz $KERNELPKG
		tar -xf $KERNPKGNAMEONLY.tar.?z
		rm -rf zdrv/
		mv -f $KERNPKGNAMEONLY zdrv/
		;;
	#*.txz|*.tgz) #TODO
	*.deb)
		dpkg-deb -x ../kernel_pkgs/${KERNELPKG} zdrv 1>/dev/null
		;;
esac

mv -f zdrv/etc/modules/firmware.dep zdrv/etc/modules/firmware.dep.${KERNELVER}

mkdir -p zdrv/lib/modules/$KERNELVER
[ -f zdrv/etc/modules/modules.builtin ] && cp -a -f zdrv/etc/modules/modules.builtin zdrv/lib/modules/$KERNELVER/
[ -f zdrv/etc/modules/modules.order ] && cp -a -f zdrv/etc/modules/modules.order zdrv/lib/modules/$KERNELVER/

cp -a zdrv/boot/System.map* ./System.map 2>/dev/null
depmod -b zdrv -F System.map $KERNELVER

#echo "deleting big modem modules..."
for i in agr hcf hsf intel5 Intel5 esscom pctel ; do
  find zdrv/lib/modules/${KERNELVER}/ -type f -name ${i}*.ko -o -name ${i}*HIDE -delete
done
rm -rf zdrv/lib/modules/all-firmware/{hsfmodem*,hcfpcimodem*,intel536ep*,intel537*} 2>/dev/null

depmod -b zdrv -F System.map $KERNELVER
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

mv zdrv/boot/vmlinuz* build/vmlinuz

sync
#==========================================
${MKSQUASHFS} zdrv ${ZDRVSFS} ${COMPCHOICE}
#==========================================

sync
chmod 644 ${ZDRVSFS}

mv -f ${ZDRVSFS} build/

rm -rf rootfs-complete/boot 2>/dev/null
rm -rf rootfs-complete/lib/modules 2>/dev/null

### END ###
