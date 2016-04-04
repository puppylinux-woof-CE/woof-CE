#!/bin/sh
# efi.img is thanks to jamesbond
# basic CD structure is the same as Fatdog64
# called from 3builddistro-Z
. ../DISTRO_SPECS

# make an UEFI iso
mk_iso() {
	tmp_isoroot=$1 	# input
	OUTPUT=$2 		# output

	mkisofs -iso-level 4 -D -R -o $OUTPUT -b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
		-eltorito-alt-boot -eltorito-platform efi -b efi.img -no-emul-boot "$tmp_isoroot"		
	isohybrid -u $OUTPUT
}

RESOURCES=`find ../ -type d -name UEFI -maxdepth 2`
ISOLINUX=`find ../sandbox3/rootfs-complete/usr -type f -name 'isolinux.bin' -maxdepth 3`
VESAMENU=`find ../sandbox3/rootfs-complete/usr -type f -name 'vesamenu.c32' -maxdepth 3`
BUILD=../sandbox3/build/
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

# custom backdrop
pic=puppy
case ${DISTRO_FILE_PREFIX} in
	[Tt]ahr*)pic=tahr;;
	[Ss]lacko*)pic=slacko;;
esac

# update and transfer the skeleton files
if [ -n "$PPMLABEL" ];then # label the image with version
	pngtopnm < ${RESOURCES}/${pic}.png | \
	${PPMLABEL} ${GEOM} ${TEXT} | \
	pnmtopng > ${BUILD}/${pic}.png
else
	cp -a ${RESOURCES}/${pic}.png 	$BUILD
fi
cp -a ${RESOURCES}/efi.img 		$BUILD
cp -a $ISOLINUX		$BUILD
cp -a $VESAMENU		$BUILD
mkdir -p $HELP
sed -e "s/DISTRO_FILE_PREFIX/${DISTRO_FILE_PREFIX}/g" \
	-e "s/BOOTLABEL/${BOOTLABEL}/g"< $MSG1 > $HELP/help.msg
sed "s/BOOTLABEL/${BOOTLABEL}/g" < $MSG2 > $HELP/help2.msg

# construct grub.cfg
cat > ${BUILD}/grub.cfg <<GRUB
insmod png
background_image /${pic}.png
set timeout=10
menuentry "Start $DISTRO_FILE_PREFIX" {
    linux /vmlinuz
    initrd /initrd.gz
}
menuentry "Start $DISTRO_FILE_PREFIX - RAM only" {
    linux /vmlinuz pfix=ram
    initrd /initrd.gz
}
menuentry "Start $DISTRO_FILE_PREFIX - No X" {
    linux /vmlinuz pfix=nox
    initrd /initrd.gz
}
menuentry "Start $DISTRO_FILE_PREFIX - check filesystem" {
    linux /vmlinuz pfix=fsck
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
#append rootfstype=ramfs
menu label ${DISTRO_FILE_PREFIX}
text help
Start ${DISTRO_FILE_PREFIX} normally.
endtext


label ${DISTRO_FILE_PREFIX}-ram
linux vmlinuz
initrd initrd.gz
append pfix=ram
menu label $DISTRO_FILE_PREFIX with no savefile
text help
Start Slacko64 with no savefile RAM only.
endtext


label ${DISTRO_FILE_PREFIX}-nox
linux vmlinuz
initrd initrd.gz
append pfix=nox
menu label ${DISTRO_FILE_PREFIX} without graphical desktop
text help
Start ${DISTRO_FILE_PREFIX} in command-line mode (Linux console). 
Graphical desktop later can be started by typing "xwin".
endtext


menu separator

label ${DISTRO_FILE_PREFIX}-nokms
linux vmlinuz
initrd initrd.gz
append pfix=ram,nox
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
