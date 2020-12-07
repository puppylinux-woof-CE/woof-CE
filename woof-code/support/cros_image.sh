wget -O- https://github.com/dimkr/devsus/releases/latest/download/devsus-templates.tar.gz | tar -xzf-

mkdir -p /mnt/sdimagep2

BYTESPERSECTOR=512
P1BYTES=8192
P2STARTBYTES=$(((P1BYTES + 65536) * BYTESPERSECTOR))

mount-FULL -o loop,noatime,offset=${P2STARTBYTES} devuan-beowulf-c201-libre-2GB.img /mnt/sdimagep2
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

echo "console=tty1 root=PARTUUID=%U/PARTNROFF=1 init=/init rootfstype=ext4 rootwait rw" > cmdline

mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg
dd if=/dev/zero of=bootloader.bin bs=512 count=1
vbutil_kernel --pack build/vmlinux.kpart \
              --version 1 \
              --vmlinuz vmlinux.uimg \
              --arch arm \
              --keyblock /usr/share/vboot/devkeys/kernel.keyblock \
              --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
              --config cmdline \
              --bootloader bootloader.bin
dd if=build/vmlinux.kpart of=devuan-beowulf-c201-libre-2GB.img conv=notrunc seek=${P1BYTES}
cp -f build/*.sfs /mnt/sdimagep2/
echo -e '#!/bin/sh\nexec /sbin/init initrd_full_install' > /mnt/sdimagep2/init
chmod 755 /mnt/sdimagep2/init
busybox umount /mnt/sdimagep2 2>/dev/null

OUT_IMG_SIZE=2048  ; ZSIZE=2gb

OUT_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-${ZSIZE}.img
OUT_IMG=../${WOOF_OUTPUT}/${OUT_IMG_BASE}

mv -f devuan-beowulf-c201-libre-2GB.img $OUT_IMG
