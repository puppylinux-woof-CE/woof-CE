#!/bin/sh
# * sourced by 3builddistro
# * we're in sandbox3

# see http://distro.ibiblio.org/puppylinux/arm/sd-skeleton-images
if ! [ "$SD_IMAGE" ] ; then #build.conf
	echo "SD_IMAGE not defined (url/img.xz)"
	exit 1
fi

SD_IMAGE="${SD_IMAGE% *}"
SDIMAGE=${URL##*/}
SDBASE=${SDIMAGE%.xz}

../support/download_file.sh $SD_IMAGE ../../local-repositories
[ $? -ne 0 ] && exit 1

echo
SDBASEBASE="`basename $SDBASE .img | sed -e 's%-201[0-9]*%-%' -e 's%-skeleton%-%' | cut -f 1,2,3 -d '-'`"
PUPIMG="${SDBASEBASE}-${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}.img"
 
#need to know uncompressed size of image...
echo "Uncompressing image, please wait..."
[ -f ../${WOOF_OUTPUT}/${PUPIMG} ] && rm -f ../${WOOF_OUTPUT}/${PUPIMG}
unxz --stdout ../../local-repositories/${SDIMAGE} > ../${WOOF_OUTPUT}/${PUPIMG}
if [ $? -ne 0 ];then
	[ -f ../${WOOF_OUTPUT}/${PUPIMG} ] && rm -f ../${WOOF_OUTPUT}/${PUPIMG}
	echo "Uncompress fail. Aborting."
	exit 1
fi
sync

SDIMGINFO="`LANG=C fdisk -l ../${WOOF_OUTPUT}/${PUPIMG}`"
IS_EXT2="`echo "$SDIMGINFO" | grep 'Linux'`"
if ! [ "$IS_EXT2" ] ; then
	echo -n "need ext4 in the second partition of ${SDIMAGE}, aborting."
	exit 1
fi

SDFS2=ext4

# better to write everything to the image file first, then write to sd afterward...
# need to know the offsets of the filesystems...
#Units: sectors of 1 * 512 = 512 bytes
BYTESPERSECTOR="`echo "$SDIMGINFO" | grep 'sectors of' | cut -f 2 -d '=' | cut -f 2 -d ' '`"
p1=`echo "$SDIMGINFO" | grep "${PUPIMG}1" | tr -s ' '`
p2=`echo "$SDIMGINFO" | grep "${PUPIMG}2" | tr -s ' '`

if [ "`echo "$SDIMGINFO" | grep 'StartCHS'`" ] ; then
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
 
echo
echo "Copying Linux kernel to SD image file..."
mkdir -p /mnt/sdimagep1
mkdir -p /mnt/sdimagep2
mount-FULL -t vfat -o loop,offset=${P1STARTBYTES} ../${WOOF_OUTPUT}/${PUPIMG} /mnt/sdimagep1
if [ $? -ne 0 ];then
	echo "Sorry, mounting vfat partition 1 (at offset ${P1STARTBYTES}) of ${PUPIMG} failed. Aborting script."
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
mount-FULL -t ${SDFS2} -o loop,offset=${P2STARTBYTES} ../${WOOF_OUTPUT}/${PUPIMG} /mnt/sdimagep2
if [ $? -ne 0 ];then
	echo "Sorry, mounting ${SDFS2} partition 2 (at offset ${P2STARTBYTES}) of ${PUPIMG} failed. Aborting script."
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
 
IMGBYTES=`stat -c %s ../${WOOF_OUTPUT}/$PUPIMG`

echo
IMGM=$(($IMGBYTES / 1024 / 1024))
echo "Output SD Image:"
echo "  ../${WOOF_OUTPUT}/${PUPIMG} (${IMGM}MB)"
echo

case "$SD_IMG_OUTPUT_COMP" in xz|gz) #build.conf
	echo "Compressing, please wait..."
	COMP=$SD_IMG_OUTPUT_COMP
	[ -f ../${WOOF_OUTPUT}/${PUPIMG}.${COMP} ] && rm -f ../${WOOF_OUTPUT}/${PUPIMG}.${COMP}
	if [ "$COMP" = 'xz' ]; then
		xz --stdout ../${WOOF_OUTPUT}/${PUPIMG} > ../${WOOF_OUTPUT}/${PUPIMG}.xz
	elif [ "$COMP" = 'gz' ]; then
		gzip --stdout ../${WOOF_OUTPUT}/${PUPIMG} > ../${WOOF_OUTPUT}/${PUPIMG}.gz
	fi
	sync
	echo " ../${WOOF_OUTPUT}/${PUPIMG}.${COMP} created."
	COMPRIMGBYTES=`stat -c %s ../${WOOF_OUTPUT}/${PUPIMG}.${COMP}`
	echo
	echo "The image is now ${PUPIMG}.${COMP} and is ${COMPRIMGBYTES}bytes."
	COMPRIMGM=$(( $COMPRIMGBYTES / 1024 / 1024))
	echo "(${COMPRIMGM}MB)"
	echo
	;;
esac

echo
echo "Would you like to write it to a SD card?  ENTER only for no,"
echo -n "or any printable char then ENTER to write image to SD card: "
read writeSD
if [ "$writeSD" = "" ];then
	WRITE_SD="no"
else
	WRITE_SD="yes"
fi

if [ "$WRITE_SD" = "yes" ];then
	echo
	echo "Please insert the SD card. Make sure that it is the same size or bigger than 
indicated on the filename of the skeleton image file that you chose."
	echo -n "Press ENTER after it is inserted: "
	read waitinsert
	sleep 2
	while [ 1 ];do
		CNT=1
		echo -n "" > /tmp/3builddistro-probedisk
		probedisk |
		while read ONEPROBE
		do
			echo "${CNT} ${ONEPROBE}" >> /tmp/3builddistro-probedisk
			CNT=`expr $CNT + 1`
		done
		echo
		echo "Type number which is your SD card:"
		cat /tmp/3builddistro-probedisk
		read sdnumber
		SDDEVICE="`cat /tmp/3builddistro-probedisk | head -n $sdnumber | tail -n 1 | cut -f 2 -d ' ' | cut -f 1 -d '|'`"
		echo -n "You chose ${SDDEVICE} Press ENTER if correct: "
		read sdcorrect
		[ "$sdcorrect" = "" ] && break
	done
	echo -e "\nSanity check: ${PUPIMG}\n is to be written to ${SDDEVICE}."
	echo -n "Press ENTER to continue: "
	read yepgo

	# check that sd card big enough...
	SDCARDBYTES=`LANG=C fdisk -l ${SDDEVICE} | grep "${SDDEVICE}:" | cut -f 2 -d ',' | cut -f 2 -d ' '`
	if [ $IMGBYTES -gt $SDCARDBYTES ];then
		echo -e "\nSorry, the image file is ${IMGBYTES}bytes, however the
SD card is only ${SDCARDBYTES}bytes. Cannot continue."
		exit 1
	fi

	echo
	echo "Writing image file ${PUPIMG} to SD card ${SDDEVICE}..."
		dd if=../${WOOF_OUTPUT}/${PUPIMG} of=${SDDEVICE} bs=4M #120704 added bs=4M
	if [ $? -ne 0 ];then
		echo "Sorry, operation failure. Aborting script."
		exit 1
	fi
	sync
fi # if WRITE_SD

if [ "$SD_IMG_OUTPUT_COMP" != 'none' ]; then
	rm -f ../${WOOF_OUTPUT}/${PUPIMG}
fi

if [ "$WRITE_SD" = "yes" ];then
	THEDRIVE="`echo -n "$SDDEVICE" | cut -f 3 -d '/'`"
	echo change  > /sys/block/${THEDRIVE}/uevent 
	echo "If the SD card currently plugged in is bigger than the image, for example
you have a 4GB card and used a 1GB image, optionally now you may increase the
${SDFS2} partition to fill the remaining space -- this is for your own use."
	echo -n "ENTER only to decline: "
	read makebig
	if [ "$makebig" != "" ];then
		if [ "`which gparted`" = "" ];then
			echo "ERROR, gparted not installed!!!"
		else
			gparted $SDDEVICE
			sync
			echo
			echo "Checking the ${SDFS2} filesystem..."
			fsck.${SDFS2} -p ${SDDEVICE}2
			sync
			echo change > /sys/block/${THEDRIVE}/uevent 
		fi
	fi
fi # if WRITE_SD

