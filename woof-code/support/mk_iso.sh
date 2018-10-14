#!/bin/bash
# efi.img/grub2 is thanks to jamesbond
# basic CD structure is the same as Fatdog64
# called from 3builddistro-Z

. ../DISTRO_SPECS
. ../_00build.conf
[ "$UFEI_ISO" ] && UEFI_ISO=${UFEI_ISO} #UFEI is a typo

# make an UEFI iso
mk_iso() {
	tmp_isoroot=$1 	# input
	OUTPUT=$2 		# output

	if [ "$UEFI_ISO" = "yes" ] ; then
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
	TGT=$1; GRUB=$2; NEW=$3
	mkdir -p /tmp/efi_img # mount point
	echo "making ${TGT}/efi.img"
	dd if=/dev/zero of=${TGT}/efi.img bs=512 count=8192 || return 1
	echo "formatting ${TGT}/efi.img - vfat"
	mkdosfs ${TGT}/efi.img
	FREE_DEV=`losetup -f`
	echo "mounting ${TGT}/efi.img on /tmp/efi_img"
	losetup $FREE_DEV ${TGT}/efi.img || return 2
	mount -t vfat $FREE_DEV /tmp/efi_img || \
		(losetup -d $FREE_DEV;return 3)
	echo "copying files"
	mkdir -p /tmp/efi_img/EFI/boot/ || return 4
	tar -xJvf $GRUB -C /tmp/efi_img/EFI/boot/ || return 5
	mv /tmp/efi_img/EFI/boot/${GRUBNAME} /tmp/efi_img/EFI/boot/${NEW} \
		|| return 6
	echo "unmounting /tmp/efi_img"
	umount /tmp/efi_img || return 7
	losetup -a | grep -o -q "${FREE_DEV##*/}" && losetup -d $FREE_DEV
	rm -r /tmp/efi_img
	return 0
}

PX=../sandbox3/rootfs-complete

FIXUSB=${PX}/usr/sbin/fix-usb.sh
BUILD=../sandbox3/build
BOOTLABEL=puppy
PPMLABEL=`which ppmlabel`
TEXT="-text $DISTRO_VERSION"
RESOURCES=${PX}/usr/share/grub2-efi # rootfs-package
SCREENRES='640 480'

if [ "$UEFI_ISO" = "yes" ] ; then
	SCREENRES='800 600'
	GEOM="-x 680 -y 380"
	GRUBNAME=grubx64.efi
	NEWNAME=bootx64.efi
	GRUB2=${PX}/usr/share/grub2-efi/${GRUBNAME}*
	UFLG=-uefi
fi

WOOF_OUTPUT="woof-output-${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}"
[ -d ../$WOOF_OUTPUT ] || mkdir -p ../$WOOF_OUTPUT
OUT=../${WOOF_OUTPUT}/${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}.iso

#======================================================
# isolinux

ISOLINUX=
VESAMENU=

# syslinux 6 - pet pkg
if [ -d ${PX}/usr/share/syslinux/efi64 ] ; then
	if [ -f ${PX}/usr/share/syslinux/isolinux.bin ] ; then
		ISOLINUX=${PX}/usr/share/syslinux/isolinux.bin
		VESAMENU="
		${PX}/usr/share/syslinux/ldlinux.c32
		${PX}/usr/share/syslinux/libcom32.c32
		${PX}/usr/share/syslinux/libutil.c32
		${PX}/usr/share/syslinux/vesamenu.c32"
	fi
fi

# syslinux 4 -standard- syslinux,syslinux-common
if [ -z "$ISOLINUX" -a -f ${PX}/usr/share/syslinux/isolinux.bin ] ; then
	ISOLINUX=${PX}/usr/share/syslinux/isolinux.bin
	VESAMENU=${PX}/usr/share/syslinux/vesamenu.c32
	CHAIN=${PX}/usr/share/syslinux/chain.c32
fi

# syslinux 6 - debian
#isolinux pkg (debian/ubuntu) xenial+
if [ -z "$ISOLINUX" -a -f ${PX}/usr/lib/ISOLINUX/isolinux.bin ] ; then
	ISOLINUX=${PX}/usr/lib/ISOLINUX/isolinux.bin
fi
if [ -z "$VESAMENU" -a -f ${PX}/usr/lib/syslinux/modules/bios/vesamenu.c32 ] ; then
	VESAMENU="
		${PX}/usr/lib/syslinux/modules/bios/ldlinux.c32
		${PX}/usr/lib/syslinux/modules/bios/libcom32.c32
		${PX}/usr/lib/syslinux/modules/bios/libutil.c32
		${PX}/usr/lib/syslinux/modules/bios/vesamenu.c32"
fi

[ -z "$ISOLINUX" ] && echo "Can't find isolinux" && exit 32
[ -z "$VESAMENU" ] && echo "Can't find vesamenu" && exit 33

#======================================================

cp -a $ISOLINUX		$BUILD
cp -a $VESAMENU		$BUILD
[ -n "$FIXUSB" ] && cp -a $FIXUSB $BUILD

mkdir -p ${BUILD}/help
cp -f ../boot/boot-dialog/*.msg ${BUILD}/help/
cp -f ../boot/boot-dialog/isolinux.cfg ${BUILD}/
[ "$UEFI_ISO" = "yes" ] && cp -f ../boot/boot-dialog/grub.cfg ${BUILD}/

sed -i "s/menu resolution.*/menu resolution ${SCREENRES}/" ${BUILD}/isolinux.cfg

sed -i -e "s/DISTRO_FILE_PREFIX/${DISTRO_FILE_PREFIX}/g" \
		-e "s/DISTRO_DESC/${DISTRO_FILE_PREFIX} ${DISTRO_VERSION}/g" \
		-e "s/BOOTLABEL/${BOOTLABEL}/g" \
		${BUILD}/*.cfg ${BUILD}/help/*.msg

#======================================================

# build the efi image
if [ "$UEFI_ISO" = "yes" ] ; then
	# custom backdrop
	pic=puppy
	case ${DISTRO_FILE_PREFIX} in
		[Tt]ahr*)pic=tahr;;
		[Ss]lacko*)pic=slacko;;
		[Xx]enial*)pic=xenial;;
	esac

	# update and transfer the skeleton files
	if [ -n "$PPMLABEL" ];then # label the image with version
		pngtopnm < ${RESOURCES}/${pic}.png | \
		${PPMLABEL} ${GEOM} ${TEXT} | \
		pnmtopng > ${BUILD}/splash.png
	else
		cp -a ${RESOURCES}/${pic}.png ${BUILD}/splash.png
	fi

	mk_efi_img $BUILD $GRUB2 $NEWNAME
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