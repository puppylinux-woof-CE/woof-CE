#!/bin/sh

# gets the latest intel and amd microcode for cpu bugs and builds
# a cpio archive containing this code in the correct hierarchy
# for early loading of microcode.
# refer https://www.kernel.org/doc/Documentation/x86/microcode.txt
# GPLv2

# the intent is for the script output to be fairly quiet

set -e
# only on supported CPU
case $(uname -m) in
	x86_64|i?86|amd64);;
	*)echo "$(uname -m) unsupported"; exit 2 ;;
esac

[ -e /etc/rc.d/PUPSTATE ] && . /etc/rc.d/PUPSTATE
rm -rf 
ver=0.1
PROG="${0##*\/}"

usage_() {
	echo "$PROG-$ver"
	echo
	echo "$PROG -h|--help : show this message"
	echo "$PROG amd : build AuthenticAMD.bin microcode"
	echo "$PROG intel : build GenuineIntel.bin microcode"
	echo "$PROG with no arguments build both AMD and Intel microcode"
	exit 2 
}

TMPDIR=/tmp/microcode
rm -rf $TMPDIR
PKG_INTEL=/initrd/mnt/tmpfs/tmp/microcode/kernel/x86/microcode
PKG_AMD=
AMDM=1
INTM=1
LABEL=''
intel_func() {
	# download - intel github
	SRC_URL_INTEL="https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/releases"
	PRE_URL_INTEL=$(curl -s $SRC_URL_INTEL | grep -om1 '\/intel.*tar\.gz')
	PKG_INTEL=${PRE_URL_INTEL##*\/}
	URL_INTEL="https://github.com/${PRE_URL_INTEL}"
	wget -q $URL_INTEL || return 1
	tar axf $PKG_INTEL || return 1
}

amd_func() {
	# refer https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/amd-ucode
	SRC_URL_AMD="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/amd-ucode/"
	mkdir -p amd-ucode
	curl -s https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/amd-ucode | grep -o 'plain.*bin' | sed 's/plain.*ucode\///' | sort | uniq |\
	while read AMD_UCODE
	do
		wget -q $SRC_URL_AMD/$AMD_UCODE -P amd-ucode || return 1
	done
}

case $1 in 
	*-h*|h*)usage_             ;;
	amd|AMD)AMDM=0; LABEL=$1       ;;
	intelIntel)INTM=0; LABEL=$1     ;;
	'')AMDM=0; INTM=0          ;;
	*)echo "wrong arg"; exit 1 ;;
esac
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

# generate ucode initrd
rm -f /tmp/ucode.* # clean up old file
find . | cpio -o -H newc > ../ucode.cpio || exit 1 # can't be compressed
cd - >/dev/null 2>&1
if [ -e /tmp/ucode.cpio ];then
	echo "$LABEL ucode.cpio is in /tmp"
else
	echo "$LABEL ucode.cpio failed to be generated"
	exit 1
fi
# copy to puphome
if [ -e /mnt/home/$PSUBDIR ];then
	# force copy to overwrite old version
	cp -af /tmp/ucode.cpio /mnt/home/$PSUBDIR/ || exit 1
else
	exit 1
fi
	
exit 0
