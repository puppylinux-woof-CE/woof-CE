#!/bin/bash

# bashism
# gets the latest intel and amd microcode for cpu bugs and builds
# a cpio archive containing this code in the correct hierarchy
# for early loading of microcode.
# refer https://www.kernel.org/doc/Documentation/x86/microcode.txt
# GPLv2

# the intent is for the script output to be fairly quiet
LANG=C
set -e
# only on supported CPU
case $(uname -m) in
	x86_64|i?86|amd64);;
	*)echo "$(uname -m) unsupported"; exit 2 ;;
esac

[ -e /etc/rc.d/PUPSTATE ] && . /etc/rc.d/PUPSTATE

ver=0.2
PROG="${0##*\/}"

usage_() {
	echo "$PROG-$ver"
	echo
	echo " $PROG -h|--help : show this message"
	echo " $PROG amd : build AuthenticAMD.bin microcode"
	echo " $PROG intel : build GenuineIntel.bin microcode"
	echo " $PROG [amd|intel|b|''] install : build microcode and install"
	echo " $PROG ucode-r : get the existing microcode release date and exit"
	echo " $PROG remote-r : get the remote microcode release date and exit"
	echo " $PROG b | OR with no arguments build both AMD and Intel microcode"
	exit 2 
}

TMPDIR=/tmp/microcode
rm -rf $TMPDIR
rm -f /tmp/ucode*.log /tmp/ucode*.tmp
PKG_INTEL=
PKG_AMD=
PUPMNT=${PUPSFS%%,*}
grep -q "$PUPMNT" /proc/mounts && MTD=$?
if [ $MTD -ne 0 ];then
	MTPT=/mnt/ucode
else
	read x y MTPT z <<<$(mount|grep ${PUPSFS%%,*})
fi
PUPDIR=$MTPT/${PUPSFS##*,}
PUPINSTALL=${PUPDIR%/*}
AMDM=1
INTM=1
LABEL=''
grep -q "$PUPMNT" /proc/mounts && MTD=$?
if [ $MTD -ne 0 ];then
	mkdir -p /mnt/special
	mount /dev/$PUPMNT /mnt/special || exit 1
fi


intel_func() {
	Q=$1
	# download - intel github
	SRC_URL_INTEL="https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/releases"
	PRE_URL_INTEL=$(curl -s $SRC_URL_INTEL | grep -om1 '\/intel.*tar\.gz')
	INTEL_TIMESTAMP=$(curl -s $SRC_URL_INTEL | grep -om1 '202[0-9][01][0-9][0-3][0-9]' | sort -u)
	echo $INTEL_TIMESTAMP > /tmp/ucode_intel.log
	[ -n "$Q" ] && return
	PKG_INTEL=${PRE_URL_INTEL##*\/}
	URL_INTEL="https://github.com/${PRE_URL_INTEL}"
	wget -q $URL_INTEL || return 1
	tar axf $PKG_INTEL || return 1
}

amd_func() {
	R=$1
	# refer https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/amd-ucode
	SRC_URL_AMD="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/amd-ucode/"
	LOGURL="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/log/amd-ucode"
	curl -s https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/amd-ucode | grep -o 'plain.*bin' | sed 's/plain.*ucode\///' | sort | uniq > /tmp/amd_ucode.lst
	while read ver
	do
		curl -s $LOGURL/$AMD_UCODE | grep -om1 '20[0-2][0-9]\-[01][0-9]\-[0-3][0-9]' | sort -u | tr -d '-' >> /tmp/ucode_amd.tmp	
	done < /tmp/amd_ucode.lst
	sort -r < /tmp/ucode_amd.tmp | head -n1 > /tmp/ucode_amd.log && rm /tmp/ucode_amd.tmp
	[ -n "$R" ] && rm /tmp/amd_ucode.lst && return
	# download
	mkdir -p amd-ucode
	while read AMD_UCODE
	do
		wget -q $SRC_URL_AMD/$AMD_UCODE -P amd-ucode || return 1

	done < /tmp/amd_ucode.lst
	
}

# get microcode release date and exit
installed_release_func() {
	if [ -e "$PUPINSTALL/ucode.cpio" ];then
		mkdir -p /tmp/ucode-release
		( cd /tmp/ucode-release
		cat "$PUPINSTALL/ucode.cpio" | cpio -i -d >/dev/null 2>&1 # quiet
		)
		for F in /tmp/ucode-release/microcode*
		do 
			read RELEASE <$F
			E=${F##*\-}
			E=${E%\.*}
			echo "$RELEASE $E"
		done
		rm -rf /tmp/ucode-release/ # cleanup
		exit 0
	else
		# unreadable or not present
		RELEASE=0
		echo $RELEASE
	fi
	exit 0
}

remote_release_func() {
	echo "Please wait while we retrieve remote versions"
	amd_release
	intel_release
	exit 0
}

amd_release() {
	amd_func r
	read LATEST_AMD </tmp/ucode_amd.log
	echo "AMD release: $LATEST_AMD"
	rm /tmp/ucode_amd.log
}

intel_release() {
	intel_func r
	read LATEST_INTEL </tmp/ucode_intel.log
	echo "INTEL release: $LATEST_INTEL"
	rm /tmp/ucode_intel.log
}

exit_umnt() { 
	umount $1
	rm -rf $1
	exit $2
}

INSTALL=0
case $1 in 
	*-h*|h*)usage_                     ;;
	amd|AMD)AMDM=0; LABEL=$1           ;;
	intel|Intel)INTM=0; LABEL=$1       ;;
	''|b)AMDM=0; INTM=0; LABEL=combined;;
	ucode-r)installed_release_func     ;;
	remote-r)remote_release_func       ;;
	*)echo "wrong arg"; exit 1         ;;
esac

if [ "$2" = 'install' ];then
	INSTALL=1
fi

echo "Please wait while microcode is downloaded and built"

mkdir -p $TMPDIR
cd $TMPDIR
TGTDIR=kernel/x86/microcode
mkdir -p $TGTDIR

if [ $INTM -eq 0 ];then
	intel_func || exit 1
	INTEL_DIR=$(ls | grep "Intel\-Linux")
	cat $INTEL_DIR/intel-ucode/* > $TGTDIR/GenuineIntel.bin
	rm -rf $INTEL_DIR *gz # clean up to build ucode.cpio
fi

if [ $AMDM -eq 0 ];then
	amd_func || exit 1
	cat amd-ucode/*.bin > $TGTDIR/AuthenticAMD.bin
	rm -rf amd-ucode/ # clean up to build ucode.cpio
fi

# install the timestamp
if [ -e /tmp/ucode_amd.log ];then 
	read a </tmp/ucode_amd.log && echo $a >> /tmp/ucode.tmp
fi
if [ -e /tmp/ucode_intel.log ];then 
	read b </tmp/ucode_intel.log && echo $b >> /tmp/ucode.tmp
fi
sort -r /tmp/ucode.tmp | head -n1 > /tmp/ucode.log
read TIMESTAMP < /tmp/ucode.log
[ -n "$TIMESTAMP" ] && echo $TIMESTAMP > $TMPDIR/microcode-release-${LABEL}.txt

# generate ucode initrd
rm -f /tmp/ucode.* # clean up old files
find . | cpio -o -H newc > ../ucode.cpio || exit 1 # can't be compressed
cd - >/dev/null 2>&1
if [ -e /tmp/ucode.cpio ];then
	echo "$LABEL ucode.cpio is in /tmp"
else
	echo "$LABEL ucode.cpio failed to be generated"
	exit 1
fi

# install ucode.cpio
if [ $INSTALL -ne 0 ];then
	grep -q "$PUPMNT" /proc/mounts && MTD=$?
	if [ $MTD -ne 0 ];then
		mkdir -p $MTPT
		mount /dev/$PUPMNT $MTPT || exit 1
		XDIR=$MTPT
	fi
	# copy to MTPT
	if [ -e $PUPINSTALL ];then
		# force copy to overwrite old version
		echo "Installing $LABEL ucode.cpio"
		cp -af /tmp/ucode.cpio $PUPINSTALL/ || exit_umnt $XDIR 1
	else
		echo "Failed Installing $LABEL ucode.cpio"
		exit 1
	fi
	[ -n "$XDIR" ] && exit_umnt $XDIR 0 || exit 0
else
	echo "NOT Installing $LABEL ucode.cpio"
fi
exit 0
