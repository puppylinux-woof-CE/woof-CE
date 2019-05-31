#!/bin/bash

. ./build.conf

ARCH_LIST="i686 x86_64 arm aarch64"

SITE=http://01micko.com/wdlkmpx/woof-CE

INITRD_PROGS_STATIC=initrd_progs-20190424-static.tar.xz

PREBUILT_BINARIES="${SITE}/${INITRD_PROGS_STATIC}"

ARCH=`uname -m`
OS_ARCH=$ARCH

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function get_initrd_progs() {
	local var=INITRD_PROGS
	[ "$1" = "-pkg" ] && { var=PACKAGES ; shift ; }
	local arch=$1
	[ "$arch" = "" ] && arch=`uname -m`
	case "$arch" in i?86) arch="x86" ;; esac
	case "$arch" in arm*) arch='arm' ;; esac
	eval echo \$$var \$${var}_${arch} #ex: $PACKAGES $PACKAGES_x86, $INITRD_PROGS $INITRD_PROGS_x86
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function fatal_error() { echo -e "$@" ; exit 1 ; }
function exit_error() { echo -e "$@" ; exit 1 ; }

help_msg() {
	echo "Build static apps in the queue defined in build.conf

Usage:
  $0 <-arch target> [options]

Options:
  -specs file : DISTRO_SPECS file to use
  -help       : show help and exit

  Valid <targets> for -arch:
      ${ARCH_LIST} default
"
}

## command line ##
while [ "$1" ] ; do
	case $1 in
		-prebuilt|-auto|-pkg|-pet) USE_PREBUILT=yes    ; shift ;;
		-a|-arch)  TARGET_ARCH="$2"    ; shift 2
			       [ "$TARGET_ARCH" = "" ] && fatal_error "$0 -arch: Specify a target arch" ;;
		-specs)    DISTRO_SPECS="$2"   ; shift 2
			       [ ! -f "$DISTRO_SPECS" ] && fatal_error "$0 -specs: '${DISTRO_SPECS}' is not a regular file" ;;
	-h|-help|--help) help_msg ; exit ;;
		*)
			echo "Unrecognized option: $1"
			shift
			;;
	esac
done

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function use_prebuilt_binaries() {
	zfile=0sources/${PREBUILT_BINARIES##*/}
	if [ -f "$zfile" ] ; then
		#verify file integrity
		tar -tf "$zfile" &>/dev/null || rm -f "$zfile"
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

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function select_target_arch() {
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
	VALID_TARGET_ARCH=no
	for a in $ARCH_LIST ; do
		if [ "$TARGET_ARCH" = "$a" ] ; then
			VALID_TARGET_ARCH=yes
			ARCH=$a
			break
		fi
	done
	if [ "$VALID_TARGET_ARCH" = "no" ] ; then
		exit_error "Invalid target arch: $TARGET_ARCH"
	fi
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function generate_initrd() {
	INITRD_FILE="initrd.gz"

	rm -rf ZZ_initrd-expanded
	mkdir -p ZZ_initrd-expanded
	cp -rf 0initrd/* ZZ_initrd-expanded
	cd ZZ_initrd-expanded

	for PROG in $(get_initrd_progs ${ARCH}) ; do
		case $PROG in ""|'#'*) continue ;; esac
		if [ -f ../00_${ARCH}/bin/${PROG} ] ; then
			file ../00_${ARCH}/bin/${PROG} | grep -E 'dynamically|shared' && exit 1
			cp -a ${V} --remove-destination ../00_${ARCH}/bin/${PROG} bin
		else
			exit_error "00_${ARCH}/bin/${PROG} not found"
		fi
	done

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
	[ -x ../init ] && cp -f ${V} ../init .

	. ./DISTRO_SPECS

	find . | cpio -o -H newc > ../initrd 2>/dev/null
	cd ..
	gzip -f initrd
	[ $? -eq 0 ] || exit_error "ERROR"

	echo -e "\n***        INITRD: ${INITRD_FILE} [${ARCH}]"
	echo -e "*** /DISTRO_SPECS: ${DISTRO_NAME} ${DISTRO_VERSION} ${DISTRO_TARGETARCH}"

}

###############################################
#                 MAIN
###############################################

select_target_arch
use_prebuilt_binaries
generate_initrd

### END ###
