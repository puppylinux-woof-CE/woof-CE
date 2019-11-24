#!/bin/bash
#
# sandbox3 or $PX $BUILD
#
# efi.img/grub2 is thanks to jamesbond
# basic CD structure is the same as Fatdog64
# called from 3builddistro (or build-iso.sh)

# this file contains the cd 'skeleton'
CDBOOT='https://sourceforge.net/projects/wstuff/files/w/cdboot-20191118.tar.xz'
CDBOOT_TAR=${CDBOOT##*/}           #basename
dlfile_sh=${0%/*}/download_file.sh #dirname + /download_file.sh

if [ -f ../_00build.conf ] ; then
	. ../_00build.conf
	if [ -f ../_00build_2.conf ] ; then
		. ../_00build_2.conf
	fi
	. ../DISTRO_SPECS
	${dlfile_sh} ${CDBOOT} ../../local-repositories/ .
elif [ -f ./build.conf ] ; then #zwoof-next
	. ./build.conf
	. ./DISTRO_SPECS
	${dlfile_sh} ${CDBOOT} ../../../local-repositories/ .
fi

[ -z "$PX" ]    && PX=rootfs-complete
[ -z "$BUILD" ] && BUILD=build

tar -C ${BUILD} -xaf ${CDBOOT_TAR} || exit 1

rm -f ${BUILD}/boot/*.sh # scripts

if [ "$(ls ${PX}/usr/share/grub2-efi/grub*.efi* 2>/dev/null)" ] ; then
	UEFI_ISO=yes
else
	UEFI_ISO=
	rm -f ${BUILD}/boot/efi.img
fi

if [ "$LICK_IN_ISO" != "yes" ]; then #build.conf
	rm -rf ${BUILD}/Windows_Installer
fi

#===================================================

ISO_BASENAME=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${XTRA_FLG}
WOOF_OUTPUT=../woof-output-${ISO_BASENAME}
if [ -L ../woof-code ] ; then #zwoof-next
	WOOF_OUTPUT=${WOOF_OUTPUT#../} #use current dir
fi
[ -d $WOOF_OUTPUT ] || mkdir -p $WOOF_OUTPUT
OUT=${WOOF_OUTPUT}/${ISO_BASENAME}.iso

#===================================================

case $(uname -m) in
	i686)   ISOHYBRID=${BUILD}/boot/isolinux/isohybrid   ;;
	x86_64) ISOHYBRID=${BUILD}/boot/isolinux/isohybrid64 ;;
esac

case $DISTRO_TARGETARCH in
	x86)    ISOHYBRID_TARGET=${BUILD}/boot/isolinux/isohybrid   ;;
	x86_64) ISOHYBRID_TARGET=${BUILD}/boot/isolinux/isohybrid64 ;;
	*) ISOHYBRID_TARGET=$(which isohybrid 2>/dev/null) ;;
esac

if [ "$ISOHYBRID_TARGET" ] ; then
	if [ ! -f ${PX}/usr/bin/isohybrid ] ; then
		cp -fv ${ISOHYBRID_TARGET} ${PX}/usr/bin/isohybrid
	fi
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
		UEFI_OPT=-u
	else
		mkisofs -iso-level 4 -D -R -o $OUTPUT -b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table ${BOOT_CAT} "$tmp_isoroot" || exit 101
		UEFI_OPT=''
	fi
	if [ "$ISOHYBRID" ] ; then
		echo "Converting ISO to isohybrid."
		echo "$ISOHYBRID ${UEFI_OPT} ${OUTPUT}"
		${ISOHYBRID} ${UEFI_OPT} ${OUTPUT}
	fi
}
#======================================================

pic='puppy.png'
case ${DISTRO_FILE_PREFIX} in
	[Tt]ahr*)   pic='tahr.png'   ;;
	[Ss]lacko*) pic='slacko.png' ;;
	[Xx]enial*) pic='xenial.png' ;;
esac
echo $pic
if [ -f ${PX}/usr/share/boot-dialog/${pic} ] ; then
	cp -fv ${PX}/usr/share/boot-dialog/${pic} ${BUILD}/boot/splash.png
fi

#======================================================

# grub4dos
mkdir -p ${BUILD}/boot/grub/
cp -f ${PX}/usr/share/boot-dialog/menu.lst ${BUILD}/boot/grub/
cp -f ${PX}/usr/share/boot-dialog/menu_phelp.lst ${BUILD}/boot/grub/
sed -i 's%configfile.*/menu%configfile /boot/grub/menu%' ${BUILD}/boot/grub/menu*
sed -i 's%#graphicsmode%graphicsmode%' ${BUILD}/boot/grub/menu.lst
sed -i 's%#splashimage%splashimage%' ${BUILD}/boot/grub/menu.lst

# grub2
if [ "$UEFI_ISO" ] ; then
	cp -f ${PX}/usr/share/boot-dialog/grub.cfg ${BUILD}/boot/grub/
	GRUB_CFG="${BUILD}/boot/grub/grub.cfg"
	cp -f ${PX}/usr/share/boot-dialog/grub.cfg ${BUILD}/
	GRUB_CFG="$GRUB_CFG ${BUILD}/grub.cfg"
	cp -f ${PX}/usr/share/boot-dialog/loopback.cfg ${BUILD}/boot/grub/
	GRUB_CFG="$GRUB_CFG ${BUILD}/boot/grub/loopback.cfg"
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

#======================================================

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