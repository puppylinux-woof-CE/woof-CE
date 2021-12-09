BYTESPERSECTOR=512
P1BYTES=8192
P2STARTBYTES=$(((P1BYTES + 65536) * BYTESPERSECTOR))

# we create two bootable 2 GB images: one of contains a 16 GB SSD image that can be dd'ed to the internal SSD
SD_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-2gb.img
INSTALL_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-2gb-install.img

SSD_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-16gb.img

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
echo -e '#!/bin/sh\nexec /sbin/init initrd_full_install' > /mnt/ssdimagep2/init
chmod 755 /mnt/ssdimagep2/init
cp -a /mnt/ssdimagep2/* /mnt/sdimagep2/

busybox umount /mnt/sdimagep2 2>/dev/null
busybox umount /mnt/ssdimagep2 2>/dev/null

cp -f --sparse=always ${SD_IMG_BASE} ../${WOOF_OUTPUT}/

# put the 16 GB image inside the 2 GB one
mount-FULL -o loop,noatime,offset=${P2STARTBYTES} ${SD_IMG_BASE} /mnt/sdimagep2
cp -f --sparse=always ${SSD_IMG_BASE} /mnt/sdimagep2/
busybox umount /mnt/sdimagep2 2>/dev/null

mv -f ${SD_IMG_BASE} ../${WOOF_OUTPUT}/${INSTALL_IMG_BASE}

set +e
