#!/bin/sh
# James way of making iso
# Download kernel, make initrd, output iso.

### config
OUTPUT_DIR=${OUTPUT_DIR:-iso}
OUTPUT_ISO=${OUTPUT_ISO:-puppy.iso}
ISO_ROOT=${ISO_ROOT:-$OUTPUT_DIR/iso-root}

PUPPY_SFS=${PUPPY_SFS:-puppy.sfs}
KERNEL_VERSION=${KERNEL_VERSION:-3.12.9}
PARENT_DISTRO=${PARENT_DISTRO:-ubuntu} # or debian

WOOF_ISO_ROOT=${WOOF_ISO_ROOT:-boot}
WOOF_INITRD=${WOOF_INITRD:-boot/initrd-tree0}


### helpers

install_boot_files() {
	cp $WOOF_ISO_ROOT/isolinux.bin $ISO_ROOT
	for p in boot.msg help.msg help2.msg isolinux.cfg logo1.16; do
		! [ -e $ISO_ROOT/$p ] && cp $WOOF_ISO_ROOT/boot-dialog/$p $ISO_ROOT
	done
	grep -q logo.16 $ISO_ROOT/boot.msg && sed -i -e 's/logo.16/logo1.16/' $ISO_ROOT/boot.msg 
	! grep -q pfix=nox $ISO_ROOT/isolinux.cfg && sed -i -e 's|pmedia=cd|& pfix=nox|' $ISO_ROOT/isolinux.cfg
}

install_kernel() {
	for p in vmlinuz kernel-modules.sfs; do
		! [ -e $ISO_ROOT/$p ] &&
		wget -P $ISO_ROOT -c http://distro.ibiblio.org/fatdog/kernels/700/$p-$KERNEL_VERSION
		mv $ISO_ROOT/$p-$KERNEL_VERSION $ISO_ROOT/$p
	done
}

install_initrd() {
	if ! [ -e $ISO_ROOT/initrd.gz ]; then
		# create minimal distro specs, read woof's docs to get the meaning
		> $WOOF_INITRD/DISTRO_SPECS cat << EOF
DISTRO_NAME='$PARENT_DISTRO Puppy'
DISTRO_VERSION=7.0
DISTRO_BINARY_COMPAT='$PARENT_DISTRO'
DISTRO_FILE_PREFIX='$PARENT_DISTRO'
DISTRO_COMPAT_VERSION='$PARENT_DISTRO'
DISTRO_XORG_AUTO='yes'
DISTRO_TARGETARCH='x86'
DISTRO_DB_SUBNAME='$PARENT_DISTRO'
DISTRO_PUPPYSFS=$PUPPY_SFS
DISTRO_ZDRVSFS=kernel-modules.sfs
EOF
		( cd $WOOF_INITRD; find . | cpio -o -H newc ) | gzip -9 > $ISO_ROOT/initrd.gz
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
