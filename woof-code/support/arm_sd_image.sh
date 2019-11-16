#!/bin/sh
# * sourced by 3builddistro
# * we're in sandbox3

#OUT_IMG_SIZE=4096 ; ZSIZE=4gb
OUT_IMG_SIZE=2048  ; ZSIZE=2gb
#OUT_IMG_SIZE=1024 ; ZSIZE=1gb

OUT_IMG_BASE=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}-ext4-${ZSIZE}.img
OUT_IMG=../${WOOF_OUTPUT}/${OUT_IMG_BASE}

#=======================================================

if ! type parted >/dev/null ; then
	echo 'parted not found'
	exit 1
fi

#if [ -f ${OUT_IMG} ] ; then
#	CREATE=
#else
	CREATE=1
#fi

if [ "$CREATE" ] ; then
	rm -f ${OUT_IMG}
	if dd --help 2>&1 | grep -q progress ; then
		progress='status=progress'
	fi
	dd if=/dev/zero of=${OUT_IMG} bs=1M count=${OUT_IMG_SIZE} ${progress}
	if [ $? -ne 0 ] ; then
		echo "dd failed.. aborting."
		exit 1
	fi
	LOOPDEV=$(losetup -f)
	losetup ${LOOPDEV} ${OUT_IMG}
	sync
	sleep 1

	parted --script -- \
		${LOOPDEV} \
		mklabel msdos \
		mkpart primary fat32 4MiB 80MiB \
		mkpart primary ext2 100MiB 100% \
		set 1 boot on

	sync
	sleep 1
	losetup -d ${LOOPDEV}
fi

#=======================================================

IMGINFO="`LANG=C fdisk -l ${OUT_IMG}`"
SDFS2=ext4

# better to write everything to the image file first, then write to sd afterward...
# need to know the offsets of the filesystems...
#Units: sectors of 1 * 512 = 512 bytes
BYTESPERSECTOR="`echo "$IMGINFO" | grep 'sectors of' | cut -f 2 -d '=' | cut -f 2 -d ' '`"
p1=`echo "$IMGINFO" | grep "${OUT_IMG_BASE}1" | tr -s ' '`
p2=`echo "$IMGINFO" | grep "${OUT_IMG_BASE}2" | tr -s ' '`

if [ "`echo "$IMGINFO" | grep 'StartCHS'`" ] ; then
	#busybox
	case "$p1" in
	*"*"*) read IMG BOOT STARTCHS ENDCHS P1STARTSECTORS P1ENDSECTOR P1SECTORS ETC <<< "$p1" ;;
	*)     read IMG      STARTCHS ENDCHS P1STARTSECTORS P1ENDSECTOR P1SECTORS ETC <<< "$p1" ;;
	esac
	read IMG STARTCHS ENDCHS P2STARTSECTORS P2ENDSECTOR P2SECTORS ETC <<< "$p2"
else
	case "$p1" in
	*"*"*) read IMG BOOT P1STARTSECTORS P1ENDSECTOR P1SECTORS ETC <<< "$p1" ;;
	*)     read IMG      P1STARTSECTORS P1ENDSECTOR P1SECTORS ETC <<< "$p1" ;;
	esac
	read IMG P2STARTSECTORS P2ENDSECTOR P2SECTORS ETC <<< "$p2"
fi

P1BYTES=$((P1SECTORS * BYTESPERSECTOR))
P1STARTBYTES=$((P1STARTSECTORS * BYTESPERSECTOR))
P2BYTES=$((P2SECTORS * BYTESPERSECTOR))
P2STARTBYTES=$((P2STARTSECTORS * BYTESPERSECTOR))

#=======================================================
 
echo
echo "Copying Linux kernel to SD image file..."
mkdir -p /mnt/sdimagep1
mkdir -p /mnt/sdimagep2

mount-FULL -t vfat -o loop,offset=${P1STARTBYTES} ${OUT_IMG} /mnt/sdimagep1
if [ $? -ne 0 ];then
	echo "Sorry, mounting vfat partition 1 (at offset ${P1STARTBYTES}) of ${OUT_IMG_BASE} failed. Aborting script."
	exit 1
fi

# restore correct kernel image name...
case $REALKERNAME in
	uImage)
		cp -f build/vmlinuz /mnt/sdimagep1/uImage ;;
	kernel.img)
		mv -f rootfs-complete/boot/* /mnt/sdimagep1/ #move firmware to first partition, /boot should be empty in second partition.
		[ -f build/vmlinuz ] && cp -f build/vmlinuz /mnt/sdimagep1/kernel.img #kernel for original pi.
		[ -f build/vmlinuz7 ] && cp -f build/vmlinuz7 /mnt/sdimagep1/kernel7.img #kernel for pi2.
		[ -f build/vmlinuz7l ] && cp -f build/vmlinuz7l /mnt/sdimagep1/kernel7l.img #kernel for pi4.
		;;
	*)
		cp -f build/vmlinuz /mnt/sdimagep1/ ;;
esac

echo -n "$REALKERNAME" > /mnt/sdimagep1/REALKERNAME #just in case need to know, in a running puppy.
sync
busybox umount /mnt/sdimagep1 2>/dev/null
echo "...done"
 
echo
echo "Copying Puppy filesystem to SD image file, please wait..."
mount-FULL -t ${SDFS2} -o loop,offset=${P2STARTBYTES} ${OUT_IMG} /mnt/sdimagep2
if [ $? -ne 0 ];then
	echo "Sorry, mounting ${SDFS2} partition 2 (at offset ${P2STARTBYTES}) of ${OUT_IMG_BASE} failed. Aborting script."
	exit 1
fi
cp -a rootfs-complete/* /mnt/sdimagep2/
sync

# add to /etc/fstab...
#not sure if the root partition is referred to as /dev/root or /dev/mmcblk0p2 on the raspi
echo "/dev/mmcblk0p2     /       ${SDFS2}     defaults,noatime      0 1" >> /mnt/sdimagep2/etc/fstab
echo "/dev/mmcblk0p1     /boot   vfat     defaults,noatime      0 2" >> /mnt/sdimagep2/etc/fstab
sync
echo "...done"
busybox umount /mnt/sdimagep2 2>/dev/null
 
IMGBYTES=`stat -c %s ${OUT_IMG}`

echo
IMGM=$(($IMGBYTES / 1024 / 1024))
echo "Output SD Image:"
echo "  ${OUT_IMG} (${IMGM}MB)"
echo

case "$SD_IMG_OUTPUT_COMP" in xz|gz) #build.conf
	echo "Compressing, please wait..."
	COMP=$SD_IMG_OUTPUT_COMP
	[ -f ${OUT_IMG}.${COMP} ] && rm -f ${OUT_IMG}.${COMP}
	if [ "$COMP" = 'xz' ]; then
		xz --stdout ${OUT_IMG} > ${OUT_IMG}.xz	
	elif [ "$COMP" = 'gz' ]; then
		gzip --stdout ${OUT_IMG} > ${OUT_IMG}.gz
	fi
	sync
	echo " ${OUT_IMG}.${COMP} created."
	COMPRIMGBYTES=`stat -c %s ${OUT_IMG}.${COMP}`
	echo
	echo "The image is now ${OUT_IMG}.${COMP} and is ${COMPRIMGBYTES}bytes."
	COMPRIMGM=$(( $COMPRIMGBYTES / 1024 / 1024))
	echo "(${COMPRIMGM}MB)"
	echo
	;;
esac
