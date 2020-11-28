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
			arch = "$1";
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
			data = /incbin/("$2");
			type = "flat_dt";
			arch = "$1";
			compression = "none";
			hash {
				algo = "sha1";
			};
		};
		ramdisk {
			description = "initramfs";
			data = /incbin/("build/initrd.gz");
			type = "ramdisk";
			arch = "$1";
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
			ramdisk = "ramdisk";
		};
	};
};
EOF

echo "console=tty1 rootwait" > cmdline

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
wget -O- https://github.com/dimkr/devsus/releases/latest/download/devsus-firmware.tar.gz | tar -xzf- -C /mnt/sdimagep2 --strip-components=1
busybox umount /mnt/sdimagep2 2>/dev/null

OUT_IMG_SIZE=2048  ; ZSIZE=2gb

OUT_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-${ZSIZE}.img
OUT_IMG=../${WOOF_OUTPUT}/${OUT_IMG_BASE}

mv -f devuan-beowulf-c201-libre-2GB.img $OUT_IMG
