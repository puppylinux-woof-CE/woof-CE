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

FIXUSB=${PX}/usr/sbin/fix-usb.sh
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

ISO_BASENAME=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${UFLG}${XTRA_FLG}
WOOF_OUTPUT=../woof-output-${ISO_BASENAME}
if [ -L ../woof-code ] ; then #zwoof-next
	WOOF_OUTPUT=${WOOF_OUTPUT#../} #use current dir
fi
[ -d $WOOF_OUTPUT ] || mkdir -p $WOOF_OUTPUT
OUT=${WOOF_OUTPUT}/${ISO_BASENAME}.iso


#======================================================

[ -n "$FIXUSB" ] && cp -a $FIXUSB $BUILD

# grub4dos
mkdir -p ${BUILD}/boot/grub/
cp -f ${PX}/usr/share/boot-dialog/menu.lst ${BUILD}/boot/grub/
cp -f ${PX}/usr/share/boot-dialog/menu_phelp.lst ${BUILD}/boot/grub/
sed -i 's%configfile.*/menu%configfile /boot/grub/menu%' ${BUILD}/boot/grub/menu*
if [ -f ${PX}/usr/share/boot-dialog/grldr ] ; then # 0.4.6a
	cp -f ${PX}/usr/share/boot-dialog/grldr ${BUILD}/boot/grub/
	sed -i 's%#splashimage%splashimage% ; s%#graphicsmode%graphicsmode%' ${BUILD}/boot/grub/menu.lst
elif [ -f ${PX}/usr/lib/grub4dos/grldr ] ; then # grub4dosconfig
	cp -f ${PX}/usr/lib/grub4dos/grldr ${BUILD}/boot/grub/
fi

# isolinux 4.07
cp -f ${PX}/usr/share/boot-dialog/isolinux/chain.c32 ${BUILD}/boot/
cp -f ${PX}/usr/share/boot-dialog/isolinux/isolinux.bin ${BUILD}/
cp -f ${PX}/usr/share/boot-dialog/isolinux/isolinux.cfg ${BUILD}/

# grub2
if [ "$UEFI_ISO" ] ; then
	cp -f ${PX}/usr/share/boot-dialog/grub.cfg ${BUILD}/
fi

sed -i -e "s/DISTRO_FILE_PREFIX/${DISTRO_FILE_PREFIX}/g" \
		-e "s/DISTRO_DESC/${DISTRO_FILE_PREFIX} ${DISTRO_VERSION}/g" \
		-e "s/#distrodesc#/${DISTRO_FILE_PREFIX} ${DISTRO_VERSION}/g" \
		${BUILD}/*.cfg ${BUILD}/boot/grub/menu*

sed -i -e "s% /splash.jpg% /boot/splash.jpg%" ${BUILD}/*.cfg ${BUILD}/boot/grub/menu*

#======================================================

# build the efi image
if [ "$UEFI_ISO" ] ; then
	# update and transfer the skeleton files
	if type pngtopnm 2>/dev/null && type pnmtojpeg 2>/dev/null ; then
		# custom backdrop
		pic=puppy
		case ${DISTRO_FILE_PREFIX} in
			[Tt]ahr*)pic=tahr;;
			[Ss]lacko*)pic=slacko;;
			[Xx]enial*)pic=xenial;;
		esac
		#--
		if type ppmlabel 2>/dev/null ; then # label the image with version
			pngtopnm < ${PX}/usr/share/boot-dialog/${pic}.png | \
			ppmlabel -x 680 -y 380 ${TEXT} | \
			pnmtojpeg -quality=100 > ${BUILD}/boot/splash.jpg
		else
			pngtopnm < ${PX}/usr/share/boot-dialog/${pic}.png | \
			pnmtojpeg -quality=100 > ${BUILD}/boot/splash.jpg
		fi
		#-
		if [ -f ${BUILD}/boot/splash.png ] ; then
			# someone is cheating
			pngtopnm < ${BUILD}/boot/splash.png | \
			pnmtojpeg -quality=100 > ${BUILD}/boot/splash.jpg
			rm -f ${BUILD}/boot/splash.png
		fi
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