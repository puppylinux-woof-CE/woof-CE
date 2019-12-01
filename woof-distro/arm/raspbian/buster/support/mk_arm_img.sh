#!/bin/sh

# called from 3builddistro

# see https://unix.stackexchange.com/questions/87183/how-to-create-a-formatted-partition-image-file-from-scratch
if cat /sys/module/loop/parameters/max_part | grep -q '0' ; then
	echo "Please add -"
	if lsmod | grep -q 'loop' ; then
		echo "options loop max_part=31
to /etc/modprobe.d/loop.conf"
	else
		echo "loop.max_part=31
to your kernel commandline"
	fi
	exit 1
fi

CWD=`pwd`
[ -e "$CWD/tmp" ] || mkdir -p $CWD/tmp
TMP=$CWD/tmp

TSIZE=${TSIZE:-2000}
FMT=${FMT:-ext4nj}
SWAP=${SWAP:-y}
fatSIZE=${fatSIZE:-512}
swapSIZE=${swapSIZE:-512}
LOOPDEV=''
case $SWAP in
	y)PNUM=3
	nswap='-swap';;
	*)PNUM=2;;
esac

# -------------------- functions ---------------------------------------
_help() {
	echo 'usage:'
	echo "${0##*/} [OS]"
	echo "where OS is the zipped file from recently built woof process"
}

_mk_img() {
	echo "making $1"
	if dd --help 2>&1 | grep -q progress ; then
		progress='status=progress'
	fi
	dd bs=1M count=${TSIZE} if=/dev/zero of=$1 ${progress} && sync
}

_parted_img() {
	IM=$1
	echo "partitioning $IM"
	echo "$fatSIZE ."
	# make partition table
	parted -s "$IM" mklabel msdos || return 1
	# make vfat partition 
	parted -s "$IM" mkpart primary fat32 2048s $fatSIZE || return 1
	sync
	# make swap partition 
	NEXTPART=$((1 + $fatSIZE))
	if [ "$SWAP" = 'y' ] ; then  
		SWAPART=$((1 + $fatSIZE + $swapSIZE))
		parted -s "$IM" mkpart primary linux-swap $((1 + $fatSIZE)) $SWAPART || return 1
		sync
		NEXTPART=$SWAPART
	fi
	# make the other partition
	parted -s "$IM" mkpart primary ext2 $SWAPART -- -1 || return 1
	sync
	return 0
}

_format() {
	echo "Formatting $IMG"
	LOOPDEV=`losetup -f --show $1`
	# vfat
	mkfs.vfat -F 32 "${LOOPDEV}p1" || return 1
	sync
	# swap
	if [ "$SWAP" = 'y' ] ; then
		mkswap "${LOOPDEV}p2" || return 1
		sync
	fi
	# linux
	case $FMT in
		ext2) mkfs.ext2 -F "${LOOPDEV}p${PNUM}" || return 2;;
		ext3) mkfs.ext3 -F "${LOOPDEV}p${PNUM}" || return 3;;
		ext4) mkfs.ext4 -F "${LOOPDEV}p${PNUM}" || return 4;;
		ext4nj) mkfs.ext4 -F -O ^has_journal "${LOOPDEV}p${PNUM}" || return 4;;
		f2fs) mkfs.f2fs "${LOOPDEV}p${PNUM}" || return 5;;
		*)return 10 ;;
	esac
	sync
	mkdir -p ${TMP}/vfat # mountpoint
	mount -t vfat ${LOOPDEV}p1 ${TMP}/vfat || return 10
	return 0
}

_copy_to_vfat() {
	unzip $1 -d ${TMP}/vfat >/dev/null 2>&1 || return 1
	sleep 2
	sync
	umount ${TMP}/vfat >/dev/null 2>&1
	sync
	losetup -a | grep -q "${LOOPDEV}" && losetup -d "${LOOPDEV}" >/dev/null 2>&1
	return 0
}

#-----------------------------------------------------------------------

[ ! $1 ] && _help
[ ! -e "$1" ] && echo "$1 not found" && exit 1
OS=${1##*/}
OS=${OS%\.*}
echo
echo "Now converting $OS to a flashable image file."
echo "params: size - $TSIZE; swap - $SWAP; filesystem - $FMT;"
echo
newTSIZE=$(($TSIZE / 1000))
IMG=${TMP}/${OS}-${newTSIZE}gb-${FMT}${nswap}.img
_mk_img $IMG || exit $?
_parted_img $IMG || exit $?
_format $IMG || exit $?
_copy_to_vfat $1 || exit $?
echo "back to 3builddistro"
echo
# hand back to 3builddistro
