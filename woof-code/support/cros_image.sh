BYTESPERSECTOR=512
P1BYTES=8192
P2STARTBYTES=$(((P1BYTES + 65536) * BYTESPERSECTOR))

# we create two bootable 2 GB images: one of contains a 16 GB SSD image that can be dd'ed to the internal SSD
SD_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-2gb.img
INSTALL_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-2gb-install.img

SSD_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-16gb.img
LEGACY_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-2gb-legacy.img
UEFI_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-2gb-uefi.img

echo "console=tty1 root=PARTUUID=%U/PARTNROFF=1 init=/init rootfstype=ext4 rootwait rw" > cmdline
vmlinuz=build/vmlinuz
if [ "$WOOF_TARGETARCH" = "arm" ]; then
    case "$BOOT_BOARD" in
    veyron-speedy)
        cat << EOF > kernel.its
/dts-v1/;

/ {
	description = "Linux kernel image with one or more FDT blobs";
	#address-cells = <1>;
	images {
		kernel {
			description = "vmlinuz";
			data = /incbin/("build/vmlinuz");
			type = "kernel_noload";
			arch = "arm";
			os = "linux";
			compression = "none";
			load = <0>;
			entry = <0>;
			hash {
				algo = "sha1";
			};
		};
		fdt {
			description = "dtb";
			data = /incbin/("`echo build/boot-*/rk3288-veyron-speedy.dtb`");
			type = "flat_dt";
			arch = "arm";
			compression = "none";
			hash {
				algo = "sha1";
			};
		};
	};
	configurations {
		default = "conf";
		conf{
			kernel = "kernel";
			fdt = "fdt";
		};
	};
};
EOF
        mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg
        vmlinuz=vmlinux.uimg
        ;;
    *)
        echo "Unknown board!"
        exit 1
        ;;
    esac
fi

set -e

dd if=/dev/zero of=bootloader.bin bs=512 count=1
vbutil_kernel --pack build/vmlinux.kpart \
              --version 1 \
              --vmlinuz $vmlinuz \
              --arch $WOOF_TARGETARCH \
              --keyblock /usr/share/vboot/devkeys/kernel.keyblock \
              --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
              --config cmdline \
              --bootloader bootloader.bin

mkdir -p /mnt/sdimagep2 /mnt/ssdimagep2

create_image() {
	# it's a sparse file - that's how we fit a 16GB image inside a 2GB one
	dd if=/dev/zero of=$1 bs=$2 count=$3 conv=sparse
	parted --script $1 mklabel gpt
	cgpt create $1
	cgpt add -i 1 -t kernel -b 8192 -s 65536 -l Kernel -S 1 -T 5 -P 10 -u B361601A-103D-374C-BA2C-35B8533A199D $1
	start=$((8192 + 65536))
	end=`cgpt show $1 | grep 'Sec GPT table' | awk '{print $1}'`
	size=$(($end - $start))
	cgpt add -i 2 -t data -b $start -s $size -l Root $1
	# $size is in 512 byte blocks while encrypted ext4 uses a block size of 4096 bytes
	mkfs.ext4 -F -b 4096 -m 0 -O ^has_journal,encrypt -E offset=$(($start * 512)) $1 $(($size / 8))
}

create_image ${SD_IMG_BASE} 50M 40
create_image ${SSD_IMG_BASE} 512 30785536

dd if=build/vmlinux.kpart of=${SSD_IMG_BASE} conv=notrunc seek=${P1BYTES}
dd if=build/vmlinux.kpart of=${SD_IMG_BASE} conv=notrunc seek=${P1BYTES}

mount-FULL -o loop,noatime,offset=${P2STARTBYTES} ${SSD_IMG_BASE} /mnt/ssdimagep2
mount-FULL -o loop,noatime,offset=${P2STARTBYTES} ${SD_IMG_BASE} /mnt/sdimagep2

cp -a rootfs-complete/* /mnt/ssdimagep2/
[ ! -e build/ucode.cpio ] || install -m 644 build/ucode.cpio /mnt/ssdimagep2/ucode.cpio
echo -e '#!/bin/sh\nexec /sbin/init initrd_full_install' > /mnt/ssdimagep2/init
chmod 755 /mnt/ssdimagep2/init
cp -a /mnt/ssdimagep2/* /mnt/sdimagep2/

case $WOOF_TARGETARCH in
x86*)
	dd if=/dev/zero of=${LEGACY_IMG_BASE} bs=50M count=40 conv=sparse
	parted --script ${LEGACY_IMG_BASE} mklabel msdos
	parted --script ${LEGACY_IMG_BASE} mkpart primary "" ext4 2048s 100%
	parted --script ${LEGACY_IMG_BASE} set 1 boot on
	LOOP=`losetup -Pf --show ${LEGACY_IMG_BASE}`
	PARTUUID=`blkid -s PARTUUID -o value ${LOOP}p1`
	mkfs.ext4 -F -b 4096 -m 0 -O ^has_journal,encrypt ${LOOP}p1

	mkdir -p /mnt/legacyimagep1
	mount-FULL -o noatime ${LOOP}p1 /mnt/legacyimagep1

	extlinux -i /mnt/legacyimagep1
	dd if=/usr/lib/EXTLINUX/mbr.bin of=${LOOP}
	if [ -e /mnt/ssdimagep2/ucode.cpio ]; then
		cat << EOF > /mnt/legacyimagep1/extlinux.conf
DEFAULT puppy

LABEL puppy
	LINUX vmlinuz
	INITRD ucode.cpio
	APPEND root=PARTUUID=$PARTUUID init=/init rootfstype=ext4 rootwait rw
EOF
	else
		cat << EOF > /mnt/legacyimagep1/extlinux.conf
DEFAULT puppy

LABEL puppy
	LINUX vmlinuz
	APPEND root=PARTUUID=$PARTUUID init=/init rootfstype=ext4 rootwait rw
EOF
	fi
	cp -a /mnt/ssdimagep2/* /mnt/legacyimagep1/
	cp -f build/vmlinuz /mnt/legacyimagep1/
	busybox umount /mnt/legacyimagep1 2>/dev/null
	losetup -d ${LOOP}
	mv -f ${LEGACY_IMG_BASE} ../${WOOF_OUTPUT}/
	;;
esac

if [ "$WOOF_TARGETARCH" = "x86_64" ]; then
	dd if=/dev/zero of=${UEFI_IMG_BASE} bs=50M count=40 conv=sparse
	parted --script ${UEFI_IMG_BASE} mklabel gpt
	parted --script ${UEFI_IMG_BASE} mkpart "${DISTRO_FILE_PREFIX}_esp" fat32 1MiB 261MiB
	parted --script ${UEFI_IMG_BASE} set 1 esp on
	parted --script ${UEFI_IMG_BASE} mkpart "${DISTRO_FILE_PREFIX}_root" ext4 261MiB 100%
	LOOP=`losetup -Pf --show ${UEFI_IMG_BASE}`
	mkfs.fat -F 32 ${LOOP}p1
	mkfs.ext4 -F -b 4096 -m 0 -O ^has_journal,encrypt ${LOOP}p2

	mkdir -p /mnt/uefiimagep1 /mnt/uefiimagep2

	unsquashfs -d kernel_sources ../kernel-kit/output/kernel_sources-*.sfs
	cd kernel_sources/usr/src/linux
	cat << EOF >> .config
CONFIG_EFI_STUB=y
CONFIG_CMDLINE_BOOL=y
CONFIG_CMDLINE="root=PARTLABEL=${DISTRO_FILE_PREFIX}_root init=/init rootfstype=ext4 rootwait rw"
EOF
	make -j`nproc` bzImage
	mount-FULL -o noatime ${LOOP}p1 /mnt/uefiimagep1
	install -D -m 644 arch/x86/boot/bzImage /mnt/uefiimagep1/EFI/BOOT/BOOTX64.EFI
	busybox umount /mnt/uefiimagep1 2>/dev/null
	cd ../../../..
	[ -n "$GITHUB_ACTIONS" ] && rm -rf kernel_sources

	mount-FULL -o noatime ${LOOP}p2 /mnt/uefiimagep2
	cp -a /mnt/ssdimagep2/* /mnt/uefiimagep2/
	busybox umount /mnt/uefiimagep2 2>/dev/null
	losetup -d ${LOOP}

	mv -f ${UEFI_IMG_BASE} ../${WOOF_OUTPUT}/
fi

busybox umount /mnt/sdimagep2 2>/dev/null
busybox umount /mnt/ssdimagep2 2>/dev/null

cp -f --sparse=always ${SD_IMG_BASE} ../${WOOF_OUTPUT}/

# put the 16 GB image inside the 2 GB one
mount-FULL -o loop,noatime,offset=${P2STARTBYTES} ${SD_IMG_BASE} /mnt/sdimagep2
cp -f --sparse=always ${SSD_IMG_BASE} /mnt/sdimagep2/
busybox umount /mnt/sdimagep2 2>/dev/null

mv -f ${SD_IMG_BASE} ../${WOOF_OUTPUT}/${INSTALL_IMG_BASE}

set +e
