#!/bin/sh
# This small script will fix the "missing space" caused by dd-ing fatdog isohybrid to a flash drive
# making the rest of the space available again for use.
# Only run this after dd-ing fatdog iso and not after anything else.
# (C) jamesbond 2013, Jake SFR 2018

### configuration
RESERVED_SPACE=1048576 # reserve 512MB (1024k secotors) by default, it will be made larger if necessary.

### can't run from X to prevent accident
if ! [ -t 0 ]; then
	Xdialog --title "Error!" --infobox "Please run this from console." 0 0 10000
	exit
fi

### usage
if [ -z "$1" ]; then
	cat << EOF
This is a small tool to make the extra space that was lost when you dd
fatdog.iso to a USB flash drive to be usable again.

Usage: $0 /dev/xxx

Where xxx is the your USB flash drive (e.g. sdb, sdc etc).

Warning: Please make sure you pass the correct device, if you pass the wrong
one you can EASILY DESTROY your harddisk irrecoverably.

EOF
	exit
fi
DEV=${1##*/}

### paranoia check - make sure sfdisk exist
if ! which sfdisk > /dev/null; then
	echo "This tool needs to use sfdisk"
	echo "Aborting."
	exit
fi

### paranoia check - make sure we have rights to write to it
if ! [ -w $1 ]; then
	echo "You don't have the rights to write to $1"
	echo "Become root or become a member of the disk group first."
	echo "Aborting."
	exit
fi

### paranoia check - block device must exist
if ! [ -e /sys/block/$DEV ]; then
	echo "$1 isn't a block device. Please specify the block device (e.g. /dev/sdb)"
	echo "and NOT the partition (e.g. /dev/sdb1)"
	echo "Aborting."
	exit
fi

### paranoia check - must be removable
read check < /sys/block/$DEV/removable
if [ $check -eq 0 ]; then
	echo "$1 is non-removable, I don't think you want to do this."
	echo "Aborting."
	exit
fi

### paranoia check - must be symlinked to "usb" bus
case $(readlink -f /sys/block/$DEV) in
	*/usb[0-9]*) ;;
	*)	echo "$1 is not a USB device."
		echo "Aborting."
		exit
esac

### paranoia check - partition 3 must be empty
check=$(sfdisk -uS -l $1 2>/dev/null| grep "^${1}3")
case $check in
    *"Empty"*|'') ;;    # 1st for old sfdisk's output, 2nd for new sfdisk's output
	*)	echo "Partition 3 of $1 (${1}3) is not empty."
		echo "Aborting."
		exit
esac

### ask filesystem type
cat << EOF
Specify filesystem type (in hex number). These are common ones:
L  - linux (ext2/3/4)
b  - FAT32
7  - NTFS or exFAT
ef - UEFI boot partition
Default is FAT32
EOF
read partition
if [ -z "$partition" ]; then
	echo "No partition type is supplied, will assume FAT32"
	partition=b
fi
echo You choose \"$partition\" as the type.

### check reserved space
ACTUAL_USED=$(sfdisk -uS -l $1 2>/dev/null | awk '/^\/.*\*/ {print $4}')
if [ $RESERVED_SPACE -lt $ACTUAL_USED ]; then
	RESERVED_SPACE=$(( (($ACTUAL_USED/4096)+4)*4096 )) # round up to next nearest 4096 
fi
echo "Reserving space for $RESERVED_SPACE sectors."

### all checks go, one more time to confirm
read -p "Last chance to abort - are you sure to you want to fix $1 [y/N]? " check
case "$check" in
	y|Y|yes|Yes|YES) ;;
	*)	echo "Aborting."
		exit ;;
esac

### create the partition
echo "$RESERVED_SPACE,$(( $(sfdisk -s $1 2>/dev/null) * 2 - $RESERVED_SPACE)),$partition" | sfdisk -f -N3 -uS $1

### final message
cat << EOF

Done. Now you need to make filesystem in it. How to do it depends on the
filesystem you have chosen.
For FAT32, do "mkdosfs ${1}3"
For NTFS,  do "mkntfs ${1}3"
For exFAT, do "mkfs -t exfat ${1}3"
For Linux, do "mkfs -t ext4 ${1}3" (or ext3 or ext2 as you wish)
For other filesystem - I assume you know what you're doing :)

If you already have a previous filesystem there (ie you dd fatdog.iso to 
a USB flash drive that has previously been "fixed"), you may not need to 
format it.

If you need to format it, after formatting type "sfdisk -R $1" to refresh
the drive icons.

=== THE END ===

EOF
