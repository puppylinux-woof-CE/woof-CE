#!/bin/sh
#
# sandbox3 or $PX $BUILD
#
# efi.img/grub2 is thanks to jamesbond
# basic CD structure is the same as Fatdog64
# called from 3builddistro (or build-iso.sh)

if [ -f ../_00build.conf ] ; then
	. ../_00build.conf
	if [ -f ../_00build_2.conf ] ; then
		. ../_00build_2.conf
	fi
	. ../DISTRO_SPECS
elif [ -f ./build.conf ] ; then #zwoof-next
	. ./build.conf
	. ./DISTRO_SPECS
fi

[ -z "$PX" ]    && PX=rootfs-complete
[ -z "$BUILD" ] && BUILD=build

NAME="$DISTRO_NAME $DISTRO_VERSION"

## functions -----------------------------------------------------------
# boot menus
prepend_grub() {
	outfile="$1"
	cat > $outfile <<EOF

loadfont /boot/grub/font.pf2
set gfxmode=800x600
set gfxpayload=keep

insmod efi_gop
insmod efi_uga

insmod all_video
insmod video_bochs
insmod video_cirrus
insmod gfxterm
insmod png
insmod jpeg
terminal_output gfxterm

insmod ext2
insmod f2fs
insmod ntfs
insmod exfat

insmod loopback
insmod iso9660
insmod udf

background_image /boot/splash.png
set timeout=10

# https://help.ubuntu.com/community/Grub2/Displays
color_normal=cyan/black
#menu_color_highlight=black/light-gray
menu_color_highlight=yellow/red
menu_color_normal=light-gray/black

if [ -e /ucode.cpio ]; then
  ucode_parm="/ucode.cpio"
else
  ucode_parm=
fi

EOF
}

prepend_loop() {
	outfile="$1"
	cat > $outfile <<EOF

loadfont /boot/grub/font.pf2

# https://help.ubuntu.com/community/Grub2/Displays
color_normal=cyan/black
#menu_color_highlight=black/light-gray
menu_color_highlight=yellow/red
menu_color_normal=light-gray/black

if [ -z "\$rootuuid" ]; then
  if search --file --set=iso_part --no-floppy \$iso_path; then
    probe --set=rootuuid --fs-uuid \$iso_part
  fi
fi
if [ -z "\$rootuuid" ]; then
  dev_parm=
else
  dev_parm="img_dev=\${rootuuid}"
fi
if [ -e /ucode.cpio ]; then
  ucode_parm="/ucode.cpio"
else
  ucode_parm=
fi
if [ -e /local-initrd.gz ]; then
  local_parm="/local-initrd.gz"
else
  local_parm=
fi

EOF
}

prepend_menu() {
	outfile="$1"
	cat > $outfile <<EOF
#
# menu.lst
#

#color NORMAL            HIGHLIGHT       HELPTEXT       HEADING
#       f/b               f/b              f/b           f/b
color light-gray/black yellow/red cyan/black light-blue/black

timeout 10
default 0

# 0.4.6a
graphicsmode -1 800 600
splashimage /boot/splash.jpg

EOF
}

build_grub2_cfg() {
	outfile="$1" # /path/to/grub.cfg or /path/to/loopback.cfg
	distrodesc="$2" # "Slacko Puppy $ver Fossa Puppy $ver etc 
	bootopts="$3" # pfix=fsck pmedia=cd etc
	loopback=''
	echo $outfile | grep -q 'loopback' && loopback='${dev_parm} img_loop=${iso_path}'
	if [ "$loopback" ]; then
		INITRDMSG='echo "Loading ${ucode_parm} /initrd.gz ${local_parm}"'
		INITRDG='initrd ${ucode_parm} /initrd.gz ${local_parm}'
	else
		INITRDMSG='echo "Loading ${ucode_parm} /initrd.gz"'
		INITRDG='initrd ${ucode_parm} /initrd.gz'
	fi
	cat >> $outfile <<EOF # append
menuentry "${distrodesc}" {
    linux /vmlinuz pmedia=cd $bootopts $loopback
    $INITRDMSG
    $INITRDG
}

EOF
}

build_menu_lst() {
	outfile="$1" # /path/to/grub.cfg or /path/to/loopback.cfg
	distrodesc="$2" # "Slacko Puppy $ver Fossa Puppy $ver etc 
	bootopts="$3" # pfix=fsck pmedia=cd etc
	micro="$4" # bool - add option to load ucode.cpio
	if [ "$micro" = 'true' ] ; then
		INITRDM='errorcheck off
  initrd /initrd.gz
  initrd /ucode.cpio /initrd.gz'
	else
		INITRDM='initrd /initrd.gz'
	fi
	cat >> $outfile <<EOF # append
title ${distrodesc}
  kernel /vmlinuz    pmedia=cd $bootopts
  $INITRDM

EOF
}

append_grub() {
	outfile="$1"
	cat >> $outfile <<EOF
menuentry "Shutdown" {
	halt
}

menuentry "Reboot" {
	reboot
}
EOF
}

append_menu_lst() {
	outfile="$1"
	cat >> $outfile <<EOF
title
  root

title Help - Boot Params
  configfile /boot/grub/menu_phelp.lst

title
  root
  
# Boot from Partition Boot Sector

title Boot first hard drive (hd0,0)
  root (hd0,0)
  chainloader +1 || chainloader /grldr || chainloader /bootmngr

title
  root

# additionals

title Grub4Dos commandline (for experts only)
  commandline

title Reboot computer
  reboot

title Halt computer
  halt
EOF
}

isolinux_menu() {
	outfile="$1"
	cat > $outfile <<EOF
default grub4dos
LABEL grub4dos
COM32 /boot/isolinux/chain.c32
APPEND ntldr=/boot/grub/grldr
EOF
}

menu_help() {
	outfile="$1"
	cat > $outfile <<EOF
# help

title pfix=ram     Run totally in RAM ignore saved sessions\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pfix=<n>     number of saved sessions to ignore (multisession-CD)\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pfix=nox     commandline only, do not start X (graphical desktop)\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pfix=xorgwizard force xorgwizard-cli for the current session\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pfix=copy    copy .sfs files to RAM (slower boot, faster running)\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pfix=nocopy  do not copy .sfs files to RAM (faster boot, slower running)\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pfix=fsck    do filesystem check on savefile (and host partition)\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pfix=clean   file cleanup (simulate version upgrade)\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title plang=<xxxx> Locale -- not normally required as asked after bootup\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pkeys=<xx>   Keyboard layout\n br-latin1-abnt2 br-latin1-us by cf croat cz de de-latin1 dk dvorak dvorak-l \ndvorak-r es et fi fr gr hu101 hu il it jp106 lt mk nl no pl pt-latin1 ro ru \nse sg sk-qwerty sk-qwertz slovene sv-latin1 uk us wangbe
  configfile /boot/grub/menu.lst

title Example: acpi=off pkeys=fr pfix=nox,ram\nDESKTOP FAIL: Black-screen/hangs, press reset or hold power-button down 4 secs\nnext bootup will force run of Video Wizard: choose alternate driver/settings.
  configfile /boot/grub/menu.lst


title
  root

title These help locating files at bootup. Examples:
  configfile /boot/grub/menu.lst
title
  root

title pdev1=sdc1      The boot partition.\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title psubdir=/pathto/slacko64 Path in which the OS is installed.\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title punionfs=aufs Union file system to use.\n aufs overlay
  configfile /boot/grub/menu.lst

title psavemark=2     Partition no. (in boot drive) to save session to.\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pmedia=usbflash Type of media booting from. Choose one of these:\n usbflash usbhd usbcd ataflash atahd atacd atazip scsihd scsicd cd
  configfile /boot/grub/menu.lst

title
  root

title pupsfs=X zdrv=X fdrv=X adrv=X ydrv=X Override auto search\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title X has this format: paramater=partition:filename \npartition can be a name "sdc1", a Label "Work" or UUID "49baa82d-8c69"\nfilename can be "/path/filename", "filename" or absent (":" not needed)\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title
  root

title The following are for debugging, for experts only:\nMore help here: http://kernel.org/doc/Documentation/kernel-parameters.txt
  configfile /boot/grub/menu.lst
title
  root

title loglevel=<n>    Bootup verbosity. 7 is high verbosity for debugging\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst

title pfix=rdsh       Execute 'init' then dropout to prompt in initramfs\nPress Enter to go back to main menu
  configfile /boot/grub/menu.lst
EOF
}

# end boot menus

# make a grub2 efi image
mk_efi_img() {
	TGT=$1
	gfp=$2
	gcer=$3
	root=$4
	if [ -n "$UEFI_32" ] ; then
		xFEILD='*'
	else
		xFEILD='*64*'
		echo "${xFEILD}"
	fi
	echo "field: ${xFEILD}"
	mkdir -p /tmp/efi_img # mount point
	echo "making ${TGT}/efi.img"
	cc=524288
	for i in $gfp/${xFEILD} ; do
		xx=`stat -c %s $i`
		cc=$(($cc + $xx))
	done # get size of the image file
	echo $cc
	echo $(($cc / 512))
	zz=$(($cc / 512))
	dd if=/dev/zero of=${TGT}/efi.img bs=512 count=$zz || return 1
	echo "formatting ${TGT}/efi.img - vfat"
	mkdosfs ${TGT}/efi.img
	FREE_DEV=`losetup -f`
	echo "mounting ${TGT}/efi.img on /tmp/efi_img"
	losetup $FREE_DEV ${TGT}/efi.img || return 2
	mount -t vfat $FREE_DEV /tmp/efi_img || \
		(losetup -d $FREE_DEV;return 3)
	echo "copying files"
	mkdir -p /tmp/efi_img/EFI/boot/ || return 4
	cp -a $gfp/${xFEILD} /tmp/efi_img/EFI/boot/ || return 5
	if [ -n "$gcer" ]; then
		cp $gcer /tmp/efi_img/EFI/boot/ || return 5
	fi
	rm -f /tmp/efi_img/EFI/boot/grub.cfg
	cp -r /tmp/efi_img/EFI $root/ || return 6 # required for UEFI support in UNetbootin
	echo "unmounting /tmp/efi_img"
	umount /tmp/efi_img || return 7
	losetup -a | grep -o -q "${FREE_DEV##*/}" && losetup -d $FREE_DEV
	rm -r /tmp/efi_img
	return 0
}



# make an UEFI iso
mk_iso() {
	tmp_isoroot=$1 	# input
	OUTPUT=$2 		# output
	BOOT_CAT="-c boot/boot.catalog"
	MKISOFS="mkisofs"
	command -v mkisofs > /dev/null || MKISOFS="xorriso -as mkisofs"
	if [ "$UEFI_ISO" ] ; then
		${MKISOFS} -iso-level 4 -D -R -o $OUTPUT -b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table ${BOOT_CAT} \
			-eltorito-alt-boot -eltorito-platform efi -b boot/efi.img -no-emul-boot "$tmp_isoroot" || exit 100
		[ $? -ne 0 ] && exit 1
		UEFI_OPT=-u
	else
		${MKISOFS} -iso-level 4 -D -R -o $OUTPUT -b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table ${BOOT_CAT} "$tmp_isoroot" || exit 101
		[ $? -ne 0 ] && exit 1
		UEFI_OPT=''
	fi
	if type isohybrid >/dev/null 2>&1 ; then
		echo "Converting ISO to isohybrid."
		echo "isohybrid ${UEFI_OPT} ${OUTPUT}"
		isohybrid ${UEFI_OPT} ${OUTPUT} || exit 1
	fi
}
## end functions -------------------------------------------------------

## vars  ---------------------------------------------------------------
ISO_BASENAME=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${XTRA_FLG}
WOOF_OUTPUT=../woof-output-${ISO_BASENAME}
if [ -L ../woof-code ] ; then #zwoof-next
	WOOF_OUTPUT=${WOOF_OUTPUT#../} #use current dir
fi
[ -d $WOOF_OUTPUT ] || mkdir -p $WOOF_OUTPUT
OUT=${WOOF_OUTPUT}/${ISO_BASENAME}.iso

# RESOURCES
ISOLINUX=`find $PX/usr -maxdepth 3 -type f -name 'isolinux.bin'`
CHAIN32=`find $PX/usr -maxdepth 5 -type f -name 'chain.c32' | grep -v efi`
#FIXUSB=`find $PX/usr -maxdepth 2 -type f -name 'fix-usb.sh'`
if [ -f "devx/usr/lib/shim/shimx64.efi.signed" -a -f "devx/usr/lib/grub/x86_64-efi-signed/gcdx64.efi.signed" -a -f "devx/usr/share/grub/unicode.pf2" ] && [ -f "devx/usr/lib/shim/mmx64.efi.signed" -o -f "devx/usr/lib/shim/mmx64.efi" ] ; then
	(
		mkdir -p /tmp/grub2/EFI/boot
		cp -f devx/usr/lib/shim/shimx64.efi.signed /tmp/grub2/EFI/boot/bootx64.efi
		if [ -f devx/usr/lib/shim/mmx64.efi.signed ]; then
			cp -f devx/usr/lib/shim/mmx64.efi.signed /tmp/grub2/EFI/boot/mmx64.efi
		else
			cp -f devx/usr/lib/shim/mmx64.efi /tmp/grub2/EFI/boot/mmx64.efi
		fi
		cp -f devx/usr/lib/grub/x86_64-efi-signed/gcdx64.efi.signed /tmp/grub2/EFI/boot/grubx64.efi
		cat << EOF > /tmp/grub2/EFI/boot/grub.cfg
# The real config file for grub is /grub.cfg
configfile /grub.cfg
EOF
		install -D /tmp/grub2/EFI/boot/grub.cfg /tmp/grub2/boot/grub/grub.cfg
		cd /tmp/grub2
		tar -c * | xz -1 > /tmp/grub2-efi.tar.xz
		cd ..
		rm -rf grub2
	)
	UEFI_ISO=yes
	FPGRUB2XZ=/tmp/grub2-efi.tar.xz
	FPBOOT=/tmp/grub2/EFI/boot
	CER=
	FONT=devx/usr/share/grub/unicode.pf2
elif [ -e "${PX}/usr/local/frugalpup" ] ; then
	UEFI_ISO=yes
	FPGRUB2XZ=`find $PX/usr/local/frugalpup -maxdepth 1 -name 'grub2-efi.tar.xz'`
	FPBOOT=/tmp/grub2/EFI/boot
	CER=/tmp/grub2/puppy.cer
	FONT=$PX/usr/share/boot-dialog/font.pf2
else
	UEFI_ISO=
	rm -f ${BUILD}/boot/efi.img
fi

GRLDR=$PX/usr/share/boot-dialog/grldr

## main ----------------------------------------------------------------
mkdir -p $BUILD/boot/{grub,isolinux}
mkdir -p /tmp/grub2

# build boot menus
prepend_grub $BUILD/grub.cfg
prepend_loop $BUILD/boot/grub/loopback.cfg
prepend_menu $BUILD/boot/grub/menu.lst

for e in "$NAME" \
		"$NAME - Copy SFS files to RAM" \
		"$NAME - Don't copy SFS files to RAM" \
		"$NAME - Force xorgwizard (xorgwizard)" \
		"$NAME - No X. Try 'xorgwizard' after bootup" \
		"$NAME - No Kernel Mode Setting" \
		"$NAME - Safe mode, no X" \
		"$NAME - RAM only - no pupsave" \
		"$NAME - Ram Disk Shell" ; do
		case "$e" in
			"$NAME")opt='pfix=fsck' ;;
			*"- Copy"*)opt='pfix=fsck,copy' ;;
			*"- Don't copy"*)opt='pfix=fsck,nocopy' ;;
			*"- Force xorgwizard"*)opt='pfix=xorgwizard,fsck'; gandl=no ;;
			*"- No X"*)opt='pfix=nox,fsck' ;;
			*"- No Kernel Mode"*)opt='nomodeset pfix=fsck'; gandl=no ;;
			*"- Safe mode"*)opt='pfix=ram,nox,fsck' ;;
			*"- RAM only"*)opt='pfix=ram,fsck' ;;
			*"- Ram Disk"*)opt='pfix=rdsh' ;;
		esac
		[ "$gandl" = 'no' ] || build_grub2_cfg $BUILD/grub.cfg "$e" "$opt"
		[ "$gandl" = 'no' ] || build_grub2_cfg $BUILD/boot/grub/loopback.cfg "$e" "$opt"
		build_menu_lst $BUILD/boot/grub/menu.lst "$e" "$opt" true
		gandl=''
done


append_grub $BUILD/grub.cfg
append_grub $BUILD/boot/grub/loopback.cfg
append_menu_lst $BUILD/boot/grub/menu.lst
isolinux_menu $BUILD/boot/isolinux/isolinux.cfg
menu_help $BUILD/boot/grub/menu_phelp.lst
# end build menus

cp -a $BUILD/grub.cfg $BUILD/boot/grub/

if [ -n "$UEFI_ISO" ] ; then
	# extract grub2
	tar -xvf $FPGRUB2XZ -C /tmp/grub2
	cp -a $FONT $BUILD/boot/grub/font.pf2
else
	# rm grub2 configs
	rm -f $BUILD/boot/grub/*.cfg
	rm -f $BUILD/*.cfg
fi

# copy files
cp -a $ISOLINUX $BUILD
cp -a $ISOLINUX $BUILD/boot/isolinux
cp -a $CHAIN32 $BUILD/boot/isolinux
MODDIR=`dirname $CHAIN32`
for MOD in ldlinux.c32 libutil.c32 libcom32.c32; do
	[ -f $MODDIR/$MOD ] && cp -a $MODDIR/$MOD $BUILD/boot/isolinux/
done
cp -a $GRLDR $BUILD/boot/grub
if [ "$LICK_IN_ISO" = 'yes' ] ; then
	[ -d "${PX}/usr/share/boot-dialog/Windows_Installer" ] && \
	cp -arf ${PX}/usr/share/boot-dialog/Windows_Installer $BUILD
fi
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
cp -fv ${PX}/usr/share/boot-dialog/splash.jpg ${BUILD}/boot/

# build efi image
if [ -n "$UEFI_ISO" ] ; then
	mk_efi_img $BUILD/boot $FPBOOT "$CER" $BUILD || exit $?
	rm -rf /tmp/grub2 # cleanup
fi

# build the iso
mk_iso $BUILD $OUT

(
	cd $WOOF_OUTPUT
	md5sum ${ISO_BASENAME}.iso > ${ISO_BASENAME}.iso.md5.txt
	sha256sum ${ISO_BASENAME}.iso > ${ISO_BASENAME}.iso.sha256.txt
)
