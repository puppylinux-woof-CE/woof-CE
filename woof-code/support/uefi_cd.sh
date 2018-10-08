#!/bin/bash
# efi.img/grub2 is thanks to jamesbond
# basic CD structure is the same as Fatdog64
# called from 3builddistro-Z
. ../DISTRO_SPECS

# make an UEFI iso
mk_iso() {
	tmp_isoroot=$1 	# input
	OUTPUT=$2 		# output

	mkisofs -iso-level 4 -D -R -o $OUTPUT -b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
		-eltorito-alt-boot -eltorito-platform efi -b efi.img -no-emul-boot "$tmp_isoroot"		
	echo "Converting ISO to isohybrid."
	isohybrid -u $OUTPUT
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

# RESOURCES=`find ../ -type d -name UEFI -maxdepth 2`
RESOURCES=`find ../sandbox3/rootfs-complete/usr/share/ -maxdepth 2 -type d -name 'grub2-efi'`
ISOLINUX=`find ../sandbox3/rootfs-complete/usr -maxdepth 3 -type f -name 'isolinux.bin'`
VESAMENU=`find ../sandbox3/rootfs-complete/usr -maxdepth 3 -type f -name 'vesamenu.c32'`
FIXUSB=`find ../sandbox3/rootfs-complete/usr -maxdepth 2 -type f -name 'fix-usb.sh'`
GRUBNAME=grubx64.efi
NEWNAME=bootx64.efi
GRUB2=`find ../sandbox3/rootfs-complete/usr/share -maxdepth 2 -type f -name "${GRUBNAME}*"`
BUILD=../sandbox3/build
HELP=${BUILD}/help
BOOTLABEL=puppy
PPMLABEL=`which ppmlabel`
TEXT="-text $DISTRO_VERSION"
GEOM="-x 680 -y 380"
UFLG=-uefi
WOOF_OUTPUT="woof-output-${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}"
[ -d ../$WOOF_OUTPUT ] || mkdir -p ../$WOOF_OUTPUT
OUT=../${WOOF_OUTPUT}/${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}${XTRA_FLG}.iso

[ -z "$ISOLINUX" ] && echo "Can't find isolinux" && exit 32
[ -z "$VESAMENU" ] && echo "Can't find vesamenu" && exit 33
[ -z "$GRUB2" ] && echo "Can't find Grub2" && exit 34

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
# cp -a ${RESOURCES}/efi.img 		$BUILD
cp -a $ISOLINUX		$BUILD
cp -a $VESAMENU		$BUILD
[ -n "$FIXUSB" ] && cp -a $FIXUSB $BUILD

mkdir -p ${BUILD}/help
cp -f ../boot/boot-dialog/*.msg ${BUILD}/help/
cp -f ../boot/boot-dialog/*.cfg ${BUILD}/

sed -i -e "s/DISTRO_FILE_PREFIX/${DISTRO_FILE_PREFIX}/g" \
		-e "s/BOOTLABEL/${BOOTLABEL}/g" \
		${BUILD}/*.cfg ${BUILD}/help/*.msg

# build the efi image
mk_efi_img $BUILD $GRUB2 $NEWNAME
ret=$?
if [ $ret -ne 0 ];then
	echo "An error occured and the program is aborting with $ret status."
	exit $ret
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
