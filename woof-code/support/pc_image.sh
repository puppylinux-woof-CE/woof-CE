BIOS_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-2gb-bios.img
UEFI_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-2gb-uefi.img
TAR_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}.tar

set -e

if [ "$FRUGALIFY" = "yes" ]; then
	case $WOOF_TARGETARCH in
	x86_64) FRUGALIFYEXEC=frugalify-overlayfs-x86_64;;
	x86) FRUGALIFYEXEC=frugalify-overlayfs-i386 ;;
	arm|aarch64) FRUGALIFYEXEC=frugalify-overlayfs-arm ;;
	esac
	[ -f ../../local-repositories/${FRUGALIFYEXEC} ] || wget --tries=1 --timeout=10 -O ../../local-repositories/${FRUGALIFYEXEC} https://github.com/puppylinux-woof-CE/frugalify/releases/latest/download/${FRUGALIFYEXEC}
fi

echo "Building ${BIOS_IMG_BASE}"

dd if=/dev/zero of=${BIOS_IMG_BASE} bs=50M count=40 conv=sparse
parted --script ${BIOS_IMG_BASE} mklabel msdos
parted --script ${BIOS_IMG_BASE} mkpart primary ext4 2048s 100%
parted --script ${BIOS_IMG_BASE} set 1 boot on
LOOP=`losetup -Pf --show ${BIOS_IMG_BASE}`
PARTUUID=`blkid -s PARTUUID -o value ${LOOP}p1`
mkfs.ext4 -F -b 4096 -m 0 -O ^has_journal,encrypt -L "${DISTRO_FILE_PREFIX}_bios" ${LOOP}p1

mkdir -p /mnt/biosimagep1
mount -o noatime ${LOOP}p1 /mnt/biosimagep1

extlinux -i /mnt/biosimagep1
dd if=/usr/lib/EXTLINUX/mbr.bin of=${LOOP}
if [ "$FRUGALIFY" = "yes" ]; then
	if [ -e build/ucode.cpio ]; then
		cp -f build/ucode.cpio /mnt/biosimagep1/
		cat << EOF > /mnt/biosimagep1/extlinux.conf
DEFAULT ${DISTRO_FILE_PREFIX}

LABEL ${DISTRO_FILE_PREFIX}
	LINUX vmlinuz
	INITRD ucode.cpio
	APPEND root=PARTUUID=$PARTUUID init=/frugalify rootfstype=ext4 rootwait rw
EOF
	else
		cat << EOF > /mnt/biosimagep1/extlinux.conf
DEFAULT ${DISTRO_FILE_PREFIX}

LABEL ${DISTRO_FILE_PREFIX}
	LINUX vmlinuz
	APPEND root=PARTUUID=$PARTUUID init=/frugalify rootfstype=ext4 rootwait rw
EOF
	fi

	install -m 755 ../../local-repositories/${FRUGALIFYEXEC} /mnt/biosimagep1/frugalify
else
	if [ -e build/ucode.cpio ]; then
		cp -f build/ucode.cpio /mnt/biosimagep1/
		cat << EOF > /mnt/biosimagep1/extlinux.conf
DEFAULT ${DISTRO_FILE_PREFIX}

LABEL ${DISTRO_FILE_PREFIX}
	LINUX vmlinuz
	INITRD ucode.cpio,initrd.gz
EOF
	else
		cat << EOF > /mnt/biosimagep1/extlinux.conf
DEFAULT ${DISTRO_FILE_PREFIX}

LABEL ${DISTRO_FILE_PREFIX}
	LINUX vmlinuz
	INITRD initrd.gz
EOF
	fi

	cp -f build/initrd.gz /mnt/biosimagep1/
fi
cp -f build/vmlinuz /mnt/biosimagep1/
cp -a build/*.sfs /mnt/biosimagep1/
umount /mnt/biosimagep1 2>/dev/null
losetup -d ${LOOP}
mv -f ${BIOS_IMG_BASE} ../${WOOF_OUTPUT}/

if [ "$WOOF_TARGETARCH" = "x86_64" ]; then
	echo "Building ${UEFI_IMG_BASE}"

	dd if=/dev/zero of=${UEFI_IMG_BASE} bs=50M count=40 conv=sparse
	parted --script ${UEFI_IMG_BASE} mklabel gpt
	parted --script ${UEFI_IMG_BASE} mkpart fat32 1MiB 261MiB
	parted --script ${UEFI_IMG_BASE} set 1 esp on
	parted --script ${UEFI_IMG_BASE} mkpart ext4 261MiB 100%
	LOOP=`losetup -Pf --show ${UEFI_IMG_BASE}`
	mkfs.fat -F 32 ${LOOP}p1
	PARTUUID=`blkid -s PARTUUID -o value ${LOOP}p2`
	mkfs.ext4 -F -b 4096 -m 0 -O ^has_journal,encrypt ${LOOP}p2

	mkdir -p /mnt/uefiimagep1 /mnt/uefiimagep2

	mount -o noatime ${LOOP}p1 /mnt/uefiimagep1
	[ -f ../../local-repositories/efilinux.efi ] || wget --tries=1 --timeout=10 -O ../../local-repositories/efilinux.efi https://github.com/puppylinux-woof-CE/efilinux/releases/latest/download/efilinux.efi
	install -D -m 644 ../../local-repositories/efilinux.efi /mnt/uefiimagep1/EFI/BOOT/BOOTX64.EFI
	install -m 644 build/vmlinuz /mnt/uefiimagep1/EFI/BOOT/vmlinuz
	if [ "$FRUGALIFY" = "yes" ]; then
		if [ -e build/ucode.cpio ]; then
			install -m 644 build/ucode.cpio /mnt/uefiimagep1/EFI/BOOT/ucode.cpio
			echo "-f 0:\EFI\BOOT\vmlinuz initrd=0:\EFI\BOOT\ucode.cpio root=PARTUUID=$PARTUUID init=/frugalify rootfstype=ext4 rootwait rw" > /mnt/uefiimagep1/EFI/BOOT/efilinux.cfg
		else
			echo "-f 0:\EFI\BOOT\vmlinuz root=PARTUUID=$PARTUUID init=/frugalify rootfstype=ext4 rootwait rw" > /mnt/uefiimagep1/EFI/BOOT/efilinux.cfg
		fi
	else
		if [ -e build/ucode.cpio ]; then
			install -m 644 build/ucode.cpio /mnt/uefiimagep1/EFI/BOOT/ucode.cpio
			echo "-f 0:\EFI\BOOT\vmlinuz initrd=0:\EFI\BOOT\ucode.cpio initrd=0:\EFI\BOOT\initrd.gz" > /mnt/uefiimagep1/EFI/BOOT/efilinux.cfg
		else
			echo "-f 0:\EFI\BOOT\vmlinuz initrd=0:\EFI\BOOT\initrd.gz" > /mnt/uefiimagep1/EFI/BOOT/efilinux.cfg
		fi

		install -m 644 build/initrd.gz /mnt/uefiimagep1/EFI/BOOT/initrd.gz
	fi
	umount /mnt/uefiimagep1 2>/dev/null

	mount -o noatime ${LOOP}p2 /mnt/uefiimagep2
	[ "$FRUGALIFY" != "yes" ] || install -m 755 ../../local-repositories/${FRUGALIFYEXEC} /mnt/uefiimagep2/frugalify
	cp -a build/*.sfs /mnt/uefiimagep2/
	umount /mnt/uefiimagep2 2>/dev/null

	losetup -d ${LOOP}

	mv -f ${UEFI_IMG_BASE} ../${WOOF_OUTPUT}/
fi

echo "Building ${TAR_BASE}"
rm -f build/README.txt
[ "$WOOF_TARGETARCH" != "x86_64" ] || cp -f ../../local-repositories/efilinux.efi build/
if [ "$FRUGALIFY" = "yes" ]; then
	cp -f ../../local-repositories/${FRUGALIFYEXEC} build/frugalify
	rm -f build/initrd.gz
fi
cd build
sha256sum * > sha256.sum
tar -c * > ../../${WOOF_OUTPUT}/${TAR_BASE}
cd ..

set +e