wget -O- https://github.com/dimkr/devsus/releases/latest/download/devsus-templates.tar.gz | tar -xzf-

mkdir -p /mnt/sdimagep2

BYTESPERSECTOR=512
P1BYTES=8192
P2STARTBYTES=$(((P1BYTES + 65536) * BYTESPERSECTOR))

mount-FULL -o loop,noatime,offset=${P2STARTBYTES} devuan-beowulf-c201-libre-2GB.img /mnt/sdimagep2
dd if=build/devsus-kernel/boot/vmlinux.kpart of=devuan-beowulf-c201-libre-2GB.img conv=notrunc seek=${P1BYTES}
cp -a build/devsus-kernel/lib /mnt/sdimagep2/
cp -a rootfs-complete/* /mnt/sdimagep2/
wget -O- https://github.com/dimkr/devsus/releases/latest/download/devsus-firmware.tar.gz | tar -xzf- -C /mnt/sdimagep2 --strip-components=1
mkdir -p /mnt/sdimagep2/opt/devsus
echo -e '#!/bin/sh\nexec /sbin/init initrd_full_install' > /mnt/sdimagep2/opt/devsus/init
chmod 755 /mnt/sdimagep2/opt/devsus/init
busybox umount /mnt/sdimagep2 2>/dev/null

OUT_IMG_SIZE=2048  ; ZSIZE=2gb

OUT_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-${ZSIZE}.img
OUT_IMG=../${WOOF_OUTPUT}/${OUT_IMG_BASE}

mv -f devuan-beowulf-c201-libre-2GB.img $OUT_IMG
