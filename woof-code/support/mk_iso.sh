#!/bin/bash
#
# sandbox3 or $PX $BUILD
#
# efi.img/grub2 is thanks to jamesbond
# basic CD structure is the same as Fatdog64
# called from 3builddistro (or build-iso.sh)

#set -x

if [ -f ../_00build.conf ] ; then
	. ../_00build.conf
	. ../DISTRO_SPECS
elif [ -f ./build.conf ] ; then #zwoof-next
	. ./build.conf
	. ./DISTRO_SPECS
fi

if [ -z "$PX" ] ; then
	PX=rootfs-complete
fi
if [ -z "$BUILD" ] ; then
	BUILD=build
fi

TEXT="-text $DISTRO_VERSION"
EFI64_SOURCE=${PX}/usr/share/grub2-efi/grubx64.efi #grub2_efi noarch pkg
EFI32_SOURCE=${PX}/usr/share/grub2-efi/grubia32.efi

if [ -f "$EFI32_SOURCE" -o -f "$EFI64_SOURCE" ] ; then
	UEFI_ISO=yes
	UFLG=-uefi
else
	UEFI_ISO=
fi

#===================================================

# make an UEFI iso
mk_iso() {
	tmp_isoroot=$1 	# input
	OUTPUT=$2 		# output
	BOOT_CAT="-c boot/boot.catalog"
	if [ "$UEFI_ISO" ] ; then
		mkisofs -iso-level 4 -D -R -o $OUTPUT -b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table ${BOOT_CAT} \
			-eltorito-alt-boot -eltorito-platform efi -b boot/efi.img -no-emul-boot "$tmp_isoroot" || exit 100
		echo "Converting ISO to isohybrid."
		isohybrid -u $OUTPUT
	else
		mkisofs -iso-level 4 -D -R -o $OUTPUT -b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table ${BOOT_CAT} "$tmp_isoroot" || exit 101
		echo "Converting ISO to isohybrid."
		isohybrid $OUTPUT
	fi
}

# make a grub2 efi image
mk_efi_img() {
	TGT=$1
	mkdir -p /tmp/efi_img # mount point
	echo "making ${TGT}/boot/efi.img"
	size64=$(stat -c %s "$EFI64_SOURCE")
	size32=0
	if [ -f "$EFI32_SOURCE" ] ; then
		size32=$(stat -c %s "$EFI32_SOURCE")
	fi
	size=$((size64 + size32 + 524288)) # add 512k
	size=$((size / 512))
	dd if=/dev/zero of=${TGT}/boot/efi.img bs=512 count=${size} || return 1
	echo "formatting ${TGT}/boot/efi.img - vfat"
	mkdosfs ${TGT}/boot/efi.img
	FREE_DEV=`losetup -f`
	echo "mounting ${TGT}/boot/efi.img on /tmp/efi_img"
	losetup $FREE_DEV ${TGT}/boot/efi.img || return 2
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

ISO_BASENAME=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${UFLG}${XTRA_FLG}
WOOF_OUTPUT=../woof-output-${ISO_BASENAME}
if [ -L ../woof-code ] ; then #zwoof-next
	WOOF_OUTPUT=${WOOF_OUTPUT#../} #use current dir
fi
[ -d $WOOF_OUTPUT ] || mkdir -p $WOOF_OUTPUT
OUT=${WOOF_OUTPUT}/${ISO_BASENAME}.iso


#======================================================

# grub4dos
mkdir -p ${BUILD}/boot/grub/
cp -f ${PX}/usr/share/boot-dialog/menu.lst ${BUILD}/boot/grub/
cp -f ${PX}/usr/share/boot-dialog/menu_phelp.lst ${BUILD}/boot/grub/
sed -i 's%configfile.*/menu%configfile /boot/grub/menu%' ${BUILD}/boot/grub/menu*
if [ -f ${PX}/usr/share/boot-dialog/grldr ] ; then # 0.4.6a
	cp -f ${PX}/usr/share/boot-dialog/grldr ${BUILD}/boot/grub/
	sed -i 's%#graphicsmode%graphicsmode%' ${BUILD}/boot/grub/menu.lst
	sed -i 's%#splashimage%splashimage%' ${BUILD}/boot/grub/menu.lst
elif [ -f ${PX}/usr/lib/grub4dos/grldr ] ; then # grub4dosconfig
	cp -f ${PX}/usr/lib/grub4dos/grldr ${BUILD}/boot/grub/
fi

# isolinux 4.07
cp -af ${PX}/usr/share/boot-dialog/isolinux ${BUILD}/boot/
cp -f ${PX}/usr/share/boot-dialog/isolinux/isolinux.bin ${BUILD}/

# grub2
if [ "$UEFI_ISO" ] ; then
	cp -f ${PX}/usr/share/boot-dialog/grub.cfg ${BUILD}/
	cp -f ${PX}/usr/share/boot-dialog/grub.cfg ${BUILD}/boot/grub/
	GRUB_CFG="${BUILD}/grub.cfg ${BUILD}/boot/grub/grub.cfg"
	#mkdir -p ${BUILD}/EFI/debian
	#cp -f ${PX}/usr/share/boot-dialog/grub.cfg ${BUILD}/EFI/debian
	#GRUB_CFG="$GRUB_CFG ${BUILD}/EFI/debian/grub.cfg"
fi

if [ -f ${PX}/etc/os-release ] ; then
	. ${PX}/etc/os-release # need $PRETTY_NAME
else
	PRETTY_NAME="$DISTRO_NAME $DISTRO_VERSION"
fi

sed -i -e "s/DISTRO_FILE_PREFIX/${DISTRO_FILE_PREFIX}/g" \
		-e "s/DISTRO_DESC/${PRETTY_NAME}/g" \
		-e "s/#distrodesc#/${PRETTY_NAME}/g" \
		${GRUB_CFG} ${BUILD}/boot/grub/menu*

sed -i -e "s% /splash.jpg% /boot/splash.jpg%" ${GRUB_CFG} ${BUILD}/boot/grub/menu*
sed -i -e "s% /splash.png% /boot/splash.png%" ${GRUB_CFG} ${BUILD}/boot/grub/menu*

cp ${PX}/usr/sbin/fix-usb.sh $BUILD/boot

#======================================================

# build the efi image
if [ "$UEFI_ISO" ] ; then
	# update and transfer the skeleton files
	if type pngtopnm 2>/dev/null && type pnmtopng 2>/dev/null ; then
		# custom backdrop
		if [ -f ${PX}/usr/share/boot-dialog/splash.jpg ] ; then
			cp -f ${PX}/usr/share/boot-dialog/splash.jpg ${BUILD}/boot/splash.jpg
			pic='splash.jpg'
		elif [ -f ${PX}/usr/share/boot-dialog/splash.png ] ; then
			cp -f ${PX}/usr/share/boot-dialog/splash.png ${BUILD}/boot/splash.png
			pic='splash.png'
		else
			cp -f ${PX}/usr/share/boot-dialog/puppy.png ${BUILD}/boot/splash.png
			pic='puppy.png'
		fi
		case ${DISTRO_FILE_PREFIX} in
			[Tt]ahr*)   pic='tahr.png'   ;;
			[Ss]lacko*) pic='slacko.png' ;;
			[Xx]enial*) pic='xenial.png' ;;
		esac
		echo $pic
		#--
		case $pic in
			*.png)
				cp -f ${PX}/usr/share/boot-dialog/${pic} ${BUILD}/boot/splash.png
				pngtopnm < ${BUILD}/boot/splash.png | \
				pnmtojpeg -quality=100 > ${BUILD}/boot/splash.jpg
				;;
			*.jpg)
				cp -f ${PX}/usr/share/boot-dialog/${pic} ${BUILD}/boot/splash.jpg
				jpegtopnm < ${BUILD}/boot/splash.jpg | \
				pnmtopng > ${BUILD}/boot/splash.png
				;;
		esac
		#-
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
	cd $WOOF_OUTPUT
	md5sum ${ISO_BASENAME}.iso > ${ISO_BASENAME}.iso.md5.txt
	sha256sum ${ISO_BASENAME}.iso > ${ISO_BASENAME}.iso.sha256.txt
)

### END ###