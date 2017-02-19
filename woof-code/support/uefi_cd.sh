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
RESOURCES=`find ../sandbox3/rootfs-complete/usr/share/ -type d -name 'grub2-efi' -maxdepth 2`
ISOLINUX=`find ../sandbox3/rootfs-complete/usr -type f -name 'isolinux.bin' -maxdepth 3`
VESAMENU=`find ../sandbox3/rootfs-complete/usr -type f -name 'vesamenu.c32' -maxdepth 3`
FIXUSB=`find ../sandbox3/rootfs-complete/usr -type f -name 'fix-usb.sh' -maxdepth 2`
GRUBNAME=grubx64.efi
NEWNAME=bootx64.efi
GRUB2=`find ../sandbox3/rootfs-complete/usr/share -type f -name "${GRUBNAME}*" -maxdepth 2`
BUILD=../sandbox3/build
HELP=${BUILD}/help
MSG1=../boot/boot-dialog/help.msg
MSG2=../boot/boot-dialog/help2.msg
BOOTLABEL=puppy
PPMLABEL=`which ppmlabel`
TEXT="-text $DISTRO_VERSION"
GEOM="-x 680 -y 380"
UFLG=-uefi
WOOF_OUTPUT="woof-output-${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}"
[ -d ../$WOOF_OUTPUT ] || mkdir -p ../$WOOF_OUTPUT
OUT=../${WOOF_OUTPUT}/${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}.iso

[ -z "$ISOLINUX" ] && echo "Can't find isolinux" && exit
[ -z "$VESAMENU" ] && echo "Can't find vesamenu" && exit
[ -z "$GRUB2" ] && echo "Can't find Grub2" && exit

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
	pnmtopng > ${BUILD}/${pic}.png
else
	cp -a ${RESOURCES}/${pic}.png 	$BUILD
fi
# cp -a ${RESOURCES}/efi.img 		$BUILD
cp -a $ISOLINUX		$BUILD
cp -a $VESAMENU		$BUILD
[ -n "$FIXUSB" ] && cp -a $FIXUSB $BUILD
mkdir -p $HELP
sed -e "s/DISTRO_FILE_PREFIX/${DISTRO_FILE_PREFIX}/g" \
	-e "s/BOOTLABEL/${BOOTLABEL}/g"< $MSG1 > $HELP/help.msg
sed "s/BOOTLABEL/${BOOTLABEL}/g" < $MSG2 > $HELP/help2.msg

# build the efi image
mk_efi_img $BUILD $GRUB2 $NEWNAME
ret=$?
if [ $ret -ne 0 ];then
	echo "An error occured and the program is aborting with $ret status."
	exit $ret
fi

# construct grub.cfg
cat > ${BUILD}/grub.cfg <<GRUB
insmod png
background_image /${pic}.png
set timeout=10
menuentry "Start $DISTRO_FILE_PREFIX" {
    linux /vmlinuz pmedia=cd
    initrd /initrd.gz
}
menuentry "Start $DISTRO_FILE_PREFIX - RAM only" {
    linux /vmlinuz pfix=ram pmedia=cd
    initrd /initrd.gz
}
menuentry "Start $DISTRO_FILE_PREFIX - No X" {
    linux /vmlinuz pfix=nox pmedia=cd
    initrd /initrd.gz
}
menuentry "Start $DISTRO_FILE_PREFIX - check filesystem" {
    linux /vmlinuz pfix=fsck pmedia=cd
    initrd /initrd.gz
}
menuentry "Start $DISTRO_FILE_PREFIX - No KMS" {
    linux /vmlinuz nomodeset
    initrd /initrd.gz
}
menuentry "Shutdown" {
	halt
}
menuentry "Reboot" {
	reboot
}
GRUB

# construct isolinux.cfg
cat > ${BUILD}/isolinux.cfg <<ISO
#display help/boot.msg
default $DISTRO_FILE_PREFIX
prompt 1
timeout 100

#F1 help/boot.msg
F2 help/help.msg
F3 help/help2.msg


ui vesamenu.c32
menu resolution 800 600
menu title $DISTRO_FILE_PREFIX Live
menu background ${pic}.png
menu tabmsg Press Tab to edit entry, F2 for help, Esc for boot prompt
menu color border 37;40  #80ffffff #00000000 std
menu color sel 7;37;40 #80ffffff #20ff8000 all
menu margin 1
menu rows 20
menu tabmsgrow 26
menu cmdlinerow -2
menu passwordrow 19
menu timeoutrow 28
menu helpmsgrow 30



label ${DISTRO_FILE_PREFIX}
linux vmlinuz
initrd initrd.gz
append pmedia=cd
menu label ${DISTRO_FILE_PREFIX}
text help
Start ${DISTRO_FILE_PREFIX} normally.
endtext


label ${DISTRO_FILE_PREFIX}-ram
linux vmlinuz
initrd initrd.gz
append pfix=ram pmedia=cd
menu label $DISTRO_FILE_PREFIX with no savefile
text help
Start Slacko64 with no savefile RAM only.
endtext


label ${DISTRO_FILE_PREFIX}-nox
linux vmlinuz
initrd initrd.gz
append pfix=nox pmedia=cd
menu label ${DISTRO_FILE_PREFIX} without graphical desktop
text help
Start ${DISTRO_FILE_PREFIX} in command-line mode (Linux console). 
Graphical desktop later can be started by typing "xwin".
endtext


menu separator

label ${DISTRO_FILE_PREFIX}-nokms
linux vmlinuz
initrd initrd.gz
append pfix=ram,nox pmedia=cd
menu label For machines with severe video problems
text help
Start ${DISTRO_FILE_PREFIX} without savefile, without KMS, and run xorgwizard 
to choose video resolutions before starting graphical desktop.
endtext
ISO

# build the iso
sync
mk_iso $BUILD $OUT
sync
(cd ../$WOOF_OUTPUT
md5sum ${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}.iso \
> ${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${SCSIFLAG}${UFLG}.iso.md5.txt)
