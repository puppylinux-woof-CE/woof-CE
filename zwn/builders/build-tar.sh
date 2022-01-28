#!/bin/sh
# James way of making iso
# Copyright (C) James Budiono 2014
# License: GNU GPL Version 3 or later.
#
# Download kernel, make initrd, output iso.

### config
OUTPUT_DIR=${OUTPUT_DIR:-iso}
OUTPUT_ISO=${OUTPUT_ISO:-puppy.iso}
ISO_ROOT=${ISO_ROOT:-$OUTPUT_DIR/iso-root}
DISTRO_PREFIX=${DISTRO_PREFIX:-puppy}

PUPPY_SFS=${PUPPY_SFS:-puppy.sfs}
SOURCE=${PARENT_DISTRO:-ubuntu}       # informative only
DISTRO_VERSION=${DISTRO_VERSION:-900} # informative only
TARGET_ARCH=${TARGET_ARCH:-arm}       # informative only

WOOF_TARGETARCH=${TARGET_ARCH}

KERNEL_URL=${KERNEL_URL:-http://distro.ibiblio.org/puppylinux/huge_kernels}
KERNEL_TARBALL=${KERNEL_TARBALL:-huge-3.4.93-slacko32FD4G.tar.bz2}

WOOFCE=${WOOFCE:-..}

###
BUILD_CONFIG=${BUILD_CONFIG:-./build.conf}
[ -e $BUILD_CONFIG ] && . $BUILD_CONFIG
[ -z "$NAME" ] && NAME=$SOURCE

### helpers
install_kernel() {
	# check that kernel is already installed
	for p in vmlinuz kernel-modules.sfs; do
		if ! [ -e $ISO_ROOT/$p ]; then
			install_extract_kernel && return # attempt to use existing
			echo Downloading kernel $KERNEL_TARBALL ...
			if [ $KERNEL_URL ]; then
				wget -c $KERNEL_URL/$KERNEL_TARBALL
				wget -c $KERNEL_URL/${KERNEL_TARBALL}.md5.txt
				install_extract_kernel && return # attempt to use existing
			else
				echo "Missing kernel. You can build one with kernel-kit. Fatdog-style kernel is required." &&
				exit
			fi
		fi
	done
}
install_boot_code() {
	[ -d ${CHROOT_DIR}/boot ] && cp -arf ${CHROOT_DIR}/boot/* $ISO_ROOT/
}
install_extract_kernel() {
	if md5sum -c ${KERNEL_TARBALL}.md5.txt 2>/dev/null; then
		tar -xf ${KERNEL_TARBALL} -C $ISO_ROOT
		mv $ISO_ROOT/vmlinuz* $ISO_ROOT/kernel7.img
		mv $ISO_ROOT/kernel-modules*.sfs* $ISO_ROOT/kernel-modules.sfs
		return 0
	fi
	return 1
}

install_initrd() {

	# create minimal distro specs, read woof's docs to get the meaning
	> initrd-progs/DISTRO_SPECS cat << EOF
DISTRO_NAME='$DISTRO_PREFIX Puppy'
DISTRO_VERSION='$DISTRO_VERSION'
DISTRO_BINARY_COMPAT='$SOURCE'
DISTRO_FILE_PREFIX='${DISTRO_PREFIX}pup'
DISTRO_COMPAT_VERSION='$VERSION'
DISTRO_XORG_AUTO='yes'
DISTRO_TARGETARCH='$TARGET_ARCH'
DISTRO_DB_SUBNAME='$SOURCE'
DISTRO_PUPPYSFS=$PUPPY_SFS
DISTRO_ZDRVSFS=kernel-modules.sfs
DISTRO_FDRVSFS=fdrv.sfs
DISTRO_ADRVSFS=adrv.sfs
DISTRO_YDRVSFS=ydrv.sfs
EOF

	(
		cd initrd-progs
		rm -f initrd.[gx]z
		./build.sh -prebuilt -auto -arch ${WOOF_TARGETARCH:-default} ${INITRD_LANG} ${INITRD_KM}
		mv -f initrd.[gx]z ..
	)

	mv initrd.gz $ISO_ROOT/
	cp initrd-progs/DISTRO_SPECS .
}

make_iso() {
	. ./build.conf
	export PX=$CHROOT_DIR
	export BUILD=$ISO_ROOT
	../woof-code/support/mk_iso.sh
}

make_tar() {
	( cd iso/iso-root 
	cp -arf ./boot*/* . 
	rm -rf boot*/
	cat > config.txt <<EOF
initramfs initrd.gz followkernel
ramfsfile=initrd.gz
ramfsaddr=-1
dtparam=audio=on	
EOF
	cat > bootmenu.txt << EOL
# Timeout is in tenths of a second, 0 disables it.
TIMEOUT 100

DEFAULT ${DISTRO_PREFIX}pup

LABEL ${DISTRO_PREFIX}pup
	PMEDIA usbflash

LABEL "${DISTRO_PREFIX}pup pfix-ram"
	PFIX ram

LABEL "${DISTRO_PREFIX}pup pfix-nox"
	PFIX nox

LABEL search
	SEARCH_DRIVE all

LABEL "ram disk shell"
	PFIX rdsh	
EOL
	tar -cvf ../${DISTRO_PREFIX}-${DISTRO_VERSION}.tar *
	)
}

### main
mkdir -p $ISO_ROOT
! [ -e $ISO_ROOT/$PUPPY_SFS ] && echo Put $PUPPY_SFS to $ISO_ROOT. && exit 1
install_kernel
install_boot_code
install_initrd
make_tar
