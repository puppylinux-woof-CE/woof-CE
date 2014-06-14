#!/bin/sh
# James way of making iso
# Download kernel, make initrd, output iso.

### config
OUTPUT_DIR=${OUTPUT_DIR:-iso}
OUTPUT_ISO=${OUTPUT_ISO:-puppy.iso}
ISO_ROOT=${ISO_ROOT:-$OUTPUT_DIR/iso-root}

PUPPY_SFS=${PUPPY_SFS:-puppy.sfs}
KERNEL_VERSION=${KERNEL_VERSION:-3.12.9}
SOURCE=${PARENT_DISTRO:-ubuntu} # or debian

WOOFCE=${WOOFCE:-..}
ISOLINUX_BIN=${ISOLINUX_BIN:-$WOOFCE/woof-arch/x86/build/boot/isolinux.bin}
ISOLINUX_CFG=${ISOLINUX_FILES:-$WOOFCE/woof-code/boot/boot-dialog}
INITRD_ARCH=${INITRD_ARCH:-$WOOFCE/woof-arch/x86/target/boot/initrd-tree0}
INITRD_CODE=${INITRD_CODE:-$WOOFCE/woof-code/boot/initrd-tree0}

###
BUILD_CONFIG=${BUILD_CONFIG:-./build.conf}
[ -e $BUILD_CONFIG ] && . $BUILD_CONFIG


### helpers
install_boot_files() {
	cp $ISOLINUX_BIN $ISO_ROOT
	for p in boot.msg help.msg help2.msg isolinux.cfg logo1.16; do
		! [ -e $ISO_ROOT/$p ] && cp $ISOLINUX_CFG/$p $ISO_ROOT
	done
	grep -q logo.16 $ISO_ROOT/boot.msg && sed -i -e 's/logo.16/logo1.16/' $ISO_ROOT/boot.msg 
	! grep -q pfix=nox $ISO_ROOT/isolinux.cfg && sed -i -e 's|pmedia=cd|& pfix=nox|' $ISO_ROOT/isolinux.cfg
}

install_kernel() {
	for p in vmlinuz kernel-modules.sfs; do
		! [ -e $ISO_ROOT/$p ] &&
		wget -P $ISO_ROOT -c http://distro.ibiblio.org/fatdog/kernels/700/$p-$KERNEL_VERSION &&
		mv $ISO_ROOT/$p-$KERNEL_VERSION $ISO_ROOT/$p
	done
}

install_initrd() {
	local initrdtmp=/tmp/initrd.tmp.$$
	if ! [ -e $ISO_ROOT/initrd.gz ]; then
		mkdir -p $initrdtmp
		
		# copy over source files and cleanup
		cp -a $INITRD_ARCH/* $INITRD_CODE/* $initrdtmp
		find $initrdtmp -name '*MARKER' -delete
		( cd $initrdtmp/bin; sh bb-create-symlinks; )

		# create minimal distro specs, read woof's docs to get the meaning
		> $initrdtmp/DISTRO_SPECS cat << EOF
DISTRO_NAME='$SOURCE Puppy'
DISTRO_VERSION=7.0
DISTRO_BINARY_COMPAT='$SOURCE'
DISTRO_FILE_PREFIX='$SOURCE'
DISTRO_COMPAT_VERSION='$SOURCE'
DISTRO_XORG_AUTO='yes'
DISTRO_TARGETARCH='x86'
DISTRO_DB_SUBNAME='$SOURCE'
DISTRO_PUPPYSFS=$PUPPY_SFS
DISTRO_ZDRVSFS=kernel-modules.sfs
EOF
		( cd $initrdtmp; find . | cpio -o -H newc ) | gzip -9 > $ISO_ROOT/initrd.gz
		rm -rf $initrdtmp
	fi
}

make_iso() {
	mkisofs -o "$OUTPUT_DIR/$OUTPUT_ISO" \
	-volid "Puppy-Linux" \
	-iso-level 4 -D -R  \
	-b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table $ISO_ROOT/
	isohybrid -o 64 "$OUTPUT_DIR/$OUTPUT_ISO"
}

### main
mkdir -p $ISO_ROOT
! [ -e $ISO_ROOT/$PUPPY_SFS ] && echo Put the $PUPPY_SFS to $ISO_ROOT. && exit 1
install_boot_files
install_kernel
install_initrd
make_iso
