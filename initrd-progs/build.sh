#!/bin/bash

ARCH_LIST="i686 x86_64 arm aarch64"

INITRD_STATIC='initrd_progs-20191121-static.tar.xz'
PREBUILT_BINARIES="https://sourceforge.net/projects/wstuff/files/w/${INITRD_STATIC}"

ARCH=`uname -m`

exit_error() { echo -e "$@" ; exit 1 ; }

help_msg() {
	echo "Usage:
  $0 <-arch target> [options]

Options:
  -specs file : DISTRO_SPECS file to use

  Valid <targets> for -arch:
      ${ARCH_LIST} default
"
}

## command line ##
while [ "$1" ] ; do
	case $1 in
		-prebuilt|-auto|-pkg|-pet) shift ;;
		-a|-arch)  TARGET_ARCH="$2"    ; shift 2
			       [ "$TARGET_ARCH" = "" ] && exit_error "$0 -arch: Specify a target arch" ;;
		-specs)    DISTRO_SPECS="$2"   ; shift 2
			       [ ! -f "$DISTRO_SPECS" ] && exit_error "$0 -specs: '${DISTRO_SPECS}' is not a regular file" ;;
	-h|-help|--help) help_msg ; exit ;;
		*) echo "Unrecognized option: $1" ; shift ;;
	esac
done

#=======================================================

use_prebuilt_binaries() {
	zfile=0sources/${PREBUILT_BINARIES##*/}
	if [ -f "$zfile" ] ; then
		#verify file integrity
		tar -tf "$zfile" >/dev/null 2>&1 || rm -f "$zfile"
	fi
	if [ ! -f "$zfile" ] ; then
		mkdir -p 0sources
		wget -P 0sources --no-check-certificate "$PREBUILT_BINARIES"
		if [ $? -ne 0 ] ; then
			rm -f "$zfile"
			exit_error "ERROR downloading $zfile"
		fi
	fi
	echo "* Extracting ${zfile##*/}..."
	tar -xf "$zfile" || {
		rm -f "$zfile"
		exit_error "ERROR extracting $zfile"
	}
}

select_target_arch() {
	if ! [ "$TARGET_ARCH" ] ; then
		echo -e "\nMust specify target arch: -a <arch>"
		echo "  <arch> can be one of these: $ARCH_LIST default"
		echo -e "\nSee also: $0 --help"
		exit 1
	fi
	#-- defaults
	case $TARGET_ARCH in
		default) TARGET_ARCH=${ARCH} ;;
		x86|i?86)TARGET_ARCH=i686    ;;
		arm64)   TARGET_ARCH=aarch64 ;;
		arm*)    TARGET_ARCH=arm     ;;
	esac
	if echo "$ARCH_LIST" | grep -qw "$TARGET_ARCH" ; then
		ARCH="$TARGET_ARCH"
	else
		exit_error "Invalid target arch: $TARGET_ARCH"
	fi
}

generate_initrd() {
	rm -rf ZZ_initrd-expanded
	mkdir -p ZZ_initrd-expanded/bin
	cp -rf 0initrd/* ZZ_initrd-expanded
	cd ZZ_initrd-expanded
	cp -af --remove-destination ../00_${ARCH}/bin/* bin
	
	echo
	if [ ! -f "$DISTRO_SPECS" -a -f ../DISTRO_SPECS ] ; then
		DISTRO_SPECS='../DISTRO_SPECS'
	fi
	if [ ! -f "$DISTRO_SPECS" -a ! -f ../0initrd/DISTRO_SPECS ] ; then
		[ -f /etc/DISTRO_SPECS ] && DISTRO_SPECS='/etc/DISTRO_SPECS'
		[ -f /initrd/DISTRO_SPECS ] && DISTRO_SPECS='/initrd/DISTRO_SPECS'
		. /etc/rc.d/PUPSTATE #PUPMODE
	fi
	[ -f "$DISTRO_SPECS" ] && cp -f ${V} "${DISTRO_SPECS}" .
	[ -x ../init ] && cp -f ../init .

	. ./DISTRO_SPECS

	find . | cpio -o -H newc > ../initrd 2>/dev/null
	cd ..
	gzip -f initrd || exit_error "ERROR"

	echo -e "\n***        INITRD: initrd.gz [${ARCH}]"
	echo -e "*** /DISTRO_SPECS: ${DISTRO_NAME} ${DISTRO_VERSION} ${DISTRO_TARGETARCH}"
}

###############################################
# MAIN
select_target_arch
use_prebuilt_binaries
generate_initrd
### END ###
