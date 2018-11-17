#!/bin/bash
# efi.img/grub2 is thanks to jamesbond
# basic CD structure is the same as Fatdog64
# called from 3builddistro-Z

. ../DISTRO_SPECS
. ../_00build.conf

#set -x

PX=../sandbox3/rootfs-complete
FIXUSB=${PX}/usr/sbin/fix-usb.sh
BUILD=../sandbox3/build
BOOTLABEL=puppy
PPMLABEL=`which ppmlabel`
TEXT="-text $DISTRO_VERSION"
RESOURCES=${PX}/usr/share/grub2-efi
EFI64_SOURCE=${RESOURCES}/grubx64.efi #grub2_efi noarch pkg
EFI32_SOURCE=${RESOURCES}/grubia32.efi

if [ -f "$EFI32_SOURCE" -o -f "$EFI64_SOURCE" ] ; then
	SCREENRES='800 600'
	UEFI_ISO=yes
	UFLG=-uefi
else
	SCREENRES='640 480'
	UEFI_ISO=
fi

#===================================================

# make an UEFI iso
mk_iso() {
	tmp_isoroot=$1 	# input
	OUTPUT=$2 		# output
	if [ "$UEFI_ISO" ] ; then
		mkisofs -iso-level 4 -D -R -o $OUTPUT -b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
			-eltorito-alt-boot -eltorito-platform efi -b efi.img -no-emul-boot "$tmp_isoroot" || exit 100
		echo "Converting ISO to isohybrid."
		isohybrid -u $OUTPUT
	else
		mkisofs -iso-level 4 -D -R -o $OUTPUT -b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table "$tmp_isoroot" || exit 101
		echo "Converting ISO to isohybrid."
		isohybrid $OUTPUT
	fi
}

# make a grub2 efi image
mk_efi_img() {
	TGT=$1
	mkdir -p /tmp/efi_img # mount point
	echo "making ${TGT}/efi.img"
	size=8192 #4mb
	if [ -f "$EFI32_SOURCE" ] ; then
		size=$((size+4096)) #6 mb
	fi
	dd if=/dev/zero of=${TGT}/efi.img bs=512 count=${size} || return 1
	echo "formatting ${TGT}/efi.img - vfat"
	mkdosfs ${TGT}/efi.img
	FREE_DEV=`losetup -f`
	echo "mounting ${TGT}/efi.img on /tmp/efi_img"
	losetup $FREE_DEV ${TGT}/efi.img || return 2
	mount -t vfat $FREE_DEV /tmp/efi_img || \
		(losetup -d $FREE_DEV;return 3)
	sync
	echo "copying files"
	mkdir -p /tmp/efi_img/EFI/boot/ || return 4
	cp "$EFI64_SOURCE" /tmp/efi_img/EFI/boot/bootx64.efi 2>/dev/null
	cp "$EFI32_SOURCE" /tmp/efi_img/EFI/boot/bootia32.efi 2>/dev/null 
	sync
	echo "unmounting /tmp/efi_img"
	umount /tmp/efi_img || return 7
	losetup -d $FREE_DEV 2>/dev/null #precaution
	rm -r /tmp/efi_img
	return 0
}

WOOF_OUTPUT="woof-output-${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}"
[ -d ../$WOOF_OUTPUT ] || mkdir -p ../$WOOF_OUTPUT
OUT=../${WOOF_OUTPUT}/${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}.iso


#======================================================
#                  isolinux
#======================================================

ISOLINUX=
VESAMENU=

if [ -f ${PX}/usr/lib/ISOLINUX/isolinux.bin ] ; then
	#isolinux pkg (debian/ubuntu) xenial+
	ISOLINUX=${PX}/usr/lib/ISOLINUX/isolinux.bin
elif [ -f ${PX}/usr/share/syslinux/isolinux.bin ] ; then
	# standard location
	ISOLINUX=${PX}/usr/share/syslinux/isolinux.bin
fi

if [ -f ${PX}/usr/lib/syslinux/modules/bios/vesamenu.c32 ] ; then
	# syslinux 6
	VESAMENU=${PX}/usr/lib/syslinux/modules/bios
elif [ ${PX}/usr/share/syslinux/vesamenu.c32 ] ; then
	VESAMENU=${PX}/usr/share/syslinux
fi

[ -z "$ISOLINUX" ] && echo "Can't find isolinux" && exit 32
[ -z "$VESAMENU" ] && echo "Can't find vesamenu" && exit 33

cp -a $ISOLINUX		$BUILD
for i in ldlinux.c32 libcom32.c32 libutil.c32 vesamenu.c32 ; do
	if [ -f $VESAMENU/${i} ] ; then
		cp -a $VESAMENU/${i} $BUILD
	fi
done

#======================================================

[ -n "$FIXUSB" ] && cp -a $FIXUSB $BUILD

mkdir -p ${BUILD}/help
cp -f ${PX}/usr/share/boot-dialog/*.msg ${BUILD}/help/
cp -f ${PX}/usr/share/boot-dialog/isolinux.cfg ${BUILD}/
[ "$UEFI_ISO" ] && cp -f ${PX}/usr/share/boot-dialog/grub.cfg ${BUILD}/

sed -i "s/menu resolution.*/menu resolution ${SCREENRES}/" ${BUILD}/isolinux.cfg

sed -i -e "s/DISTRO_FILE_PREFIX/${DISTRO_FILE_PREFIX}/g" \
		-e "s/DISTRO_DESC/${DISTRO_FILE_PREFIX} ${DISTRO_VERSION}/g" \
		-e "s/BOOTLABEL/${BOOTLABEL}/g" \
		${BUILD}/*.cfg ${BUILD}/help/*.msg

#======================================================

# build the efi image
if [ "$UEFI_ISO" ] ; then
	# custom backdrop
	pic=puppy
	case ${DISTRO_FILE_PREFIX} in
		[Tt]ahr*)pic=tahr;;
		[Ss]lacko*)pic=slacko;;
		[Xx]enial*)pic=xenial;;
	esac

	# update and transfer the skeleton files
	if [ -n "$PPMLABEL" ];then # label the image with version
		GEOM="-x 680 -y 380"
		pngtopnm < ${RESOURCES}/${pic}.png | \
		${PPMLABEL} ${GEOM} ${TEXT} | \
		pnmtopng > ${BUILD}/splash.png
	else
		cp -a ${RESOURCES}/${pic}.png ${BUILD}/splash.png
	fi

	mk_efi_img $BUILD
	ret=$?
	if [ $ret -ne 0 ];then
		echo "An error occured and the program is aborting with $ret status."
		exit $ret
	fi
fi

# build the iso
sync
mk_iso $BUILD $OUT
sync

(
cd ../$WOOF_OUTPUT
md5sum ${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}.iso \
	> ${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}.iso.md5.txt
sha256sum ${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}.iso \
	> ${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}.iso.sha256.txt
)

### END ###