#!/bin/sh

# called from 3builddistro-Z
. ../etc/DISTRO_SPECS

pic=puppy
case ${DISTRO_FILE_PREFIX} in
	[Tt]ahr*)pic=tahrpup;;
	[Ss]lacko*)pic=slacko;;
esac

cp -a ${pic}.png 	build/
cp -a efi.img 		build/
ISOLINUX=`find ../sandbox3/rootfs-complete/usr -type f -name 'isolinux.bin' -maxdepth 3`
VESAMENU=`find ../sandbox3/rootfs-complete/usr -type f -name 'vesamenu.c32' -maxdepth 3`
cp -a $ISOLINUX		build/
cp -a $VESAMENU		build/
mkdir -p build/help/
cp -a help.msg 		build/help/
cp -a help2.msg 	build/help/

cat > build/grub.cfg <<GRUB
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

cat > build/isolinux.cfg <<ISO

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
Start ${DISTRO_FILE_PREFIX} without savefile, without KMS, and launch xorgwizard 
to choose video resolutions before starting graphical desktop.
endtext
ISO