BYTESPERSECTOR=512
P1BYTES=8192
P2STARTBYTES=$(((P1BYTES + 65536) * BYTESPERSECTOR))

OUT_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-2gb.img
SSD_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-16gb.img
OUT_IMG=../${WOOF_OUTPUT}/${OUT_IMG_BASE}

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

mkdir -p /mnt/sdimagep2 /mnt/ssdimagep2

wget -O- https://github.com/dimkr/devsus/releases/latest/download/devsus-templates.tar.gz | tar -xzf-

dd if=build/vmlinux.kpart of=devuan-beowulf-c201-libre-16GB.img conv=notrunc seek=${P1BYTES}
dd if=build/vmlinux.kpart of=devuan-beowulf-c201-libre-2GB.img conv=notrunc seek=${P1BYTES}

mount-FULL -o loop,noatime,offset=${P2STARTBYTES} devuan-beowulf-c201-libre-16GB.img /mnt/ssdimagep2
mount-FULL -o loop,noatime,offset=${P2STARTBYTES} devuan-beowulf-c201-libre-2GB.img /mnt/sdimagep2

cp -f build/*.sfs /mnt/ssdimagep2/
wget --tries=1 --timeout=10 -O /mnt/ssdimagep2/init https://github.com/dimkr/frugalify/releases/latest/download/frugalify-aufs-arm
chmod 755 /mnt/ssdimagep2/init
cp -a /mnt/ssdimagep2/* /mnt/sdimagep2/

busybox umount /mnt/ssdimagep2 2>/dev/null

# put the 16 GB image inside the 2 GB one
cp -f --sparse=always devuan-beowulf-c201-libre-16GB.img /mnt/sdimagep2/${SSD_IMG_BASE}

busybox umount /mnt/sdimagep2 2>/dev/null

mv -f devuan-beowulf-c201-libre-2GB.img $OUT_IMG
