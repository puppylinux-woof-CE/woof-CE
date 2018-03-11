#!/bin/bash
# compile musl static apps

. ./build.conf
export MKFLG
export MWD=`pwd`
export TARGET_TRIPLET=

SITE=http://01micko.com/wdlkmpx/woof-CE

#X86_CC=cross-compiler-i486-20170704.tar.xz
X86_CC=cross-compiler-i686-20170828.tar.xz
X86_64_CC=cross-compiler-x86_64-20170705.tar.xz
#ARM_CC=cross-compiler-arm-20170705.tar.xz #armv5
ARM_CC=cross-compiler-arm-20170706.tar.xz #armv6
ARM64_CC=cross-compiler-aarch64-20170705.tar.xz

INITRD_PROGS_STATIC=initrd_progs-20170706-2-static.tar.xz

DEFAULT_x86=$(echo $X86_CC | cut -d '-' -f 3)
DEFAULT_ARM64=aarch64

TARGET_TRIPLET_x86=${DEFAULT_x86}-linux-musl
TARGET_TRIPLET_x86_64="x86_64-linux-musl"
#TARGET_TRIPLET_arm="arm-linux-musleabi"  #arm v5
TARGET_TRIPLET_arm="arm-linux-musleabihf" #arm v6
TARGET_TRIPLET_arm64="aarch64-linux-musl"

ARCH_LIST="default $DEFAULT_x86 x86_64 arm aarch64"

PREBUILT_BINARIES="${SITE}/${INITRD_PROGS_STATIC}"

#aarch64_PREBUILT_BINARIES=
arm_PREBUILT_BINARIES='https://gitlab.com/woodenshoe-wi/initrd-progs-arm/raw/master/initrd_progs-arm-20180227-static.tar.xz'
#i686_PREBUILT_BINARIES=
#x86_64_PREBUILT_BINARIES=


ARCH=`uname -m`
case $ARCH in i*86) ARCH=$DEFAULT_x86 ;; esac
OS_ARCH=$ARCH

function get_initrd_progs() {
	local var=INITRD_PROGS
	[ "$1" = "-pkg" ] && { var=PACKAGES ; shift ; }
	local arch=$1
	[ "$arch" = "" ] && arch=`uname -m`
	case "$arch" in i?86) arch="x86" ;; esac
	case "$arch" in arm*) arch='arm' ;; esac
	eval echo \$$var \$${var}_${arch} #ex: $PACKAGES $PACKAGES_x86, $INITRD_PROGS $INITRD_PROGS_x86
}

case "$1" in release|tarball) #this contains the $PREBUILT_BINARIES
	echo "If you made changes then don't forget to remove all 00_* directories first"
	sleep 4
	if [ -n "$2" ]; then
		$0 -nord -auto -arch $2
		pkgx=initrd_progs-${2}-$(date "+%Y%m%d")-static.tar.xz
	else
		for a in ${ARCH_LIST#default } ; do $0 -nord -auto -arch $a ; done
		pkgx=initrd_progs-$(date "+%Y%m%d")-static.tar.xz
	fi
	echo -e "\n\n\n*** Creating $pkgx"
	while read ARCH ; do
		for PROG in $(get_initrd_progs ${ARCH#00_}) ; do
			case $PROG in ""|'#'*) continue ;; esac
			progs2tar+=" ${ARCH}/bin/${PROG}"
		done
	done <<< "$(ls -d 00_*)"
	tar -Jcf $pkgx ${progs2tar}
	echo "Done."
	exit
esac

case "$1" in w|w_apps|c)
	for a in ${ARCH_LIST#default } ; do $0 -nord -auto -arch $a -pkg w_apps ; done
	exit
esac

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function fatal_error() { echo -e "$@" ; exit 1 ; }

help_msg() {
	echo "Build static apps in the queue defined in build.conf

Usage:
  $0 [options]

Options:
  -pkg pkg    : compile specific pkg only
  -all        : force building all *_static pkgs
  -arch target: compile for target arch
  -sysgcc     : use system gcc
  -cross      : use cross compiler
  -download   : download pkgs only, this overrides other options
  -specs file : DISTRO_SPECS file to use
  -prebuilt   : use prebuilt binaries
  -lang locale: set locale
  -keymap km  : set keyboard layout
  -auto       : don't prompt for input
  -gz|-xz     : compression method for the initrd
  -help       : show help and exit

  Valid <targets> for -arch:
      ${ARCH_LIST#default }
"
}

## defaults (other defaults are in build.conf) ##
USE_SYS_GCC=no
CROSS_COMPILE=no
FORCE_BUILD_ALL=no
export DLD_ONLY=no
INITRD_CREATE=yes
case ${INITRD_COMP} in
	gz|xz) ok=yes ;;
	*) INITRD_COMP="gz" ;;
esac

## command line ##
while [ "$1" ] ; do
	case $1 in
		-fullinstall) FULL_INSTALL=yes ; shift ;;
		-sysgcc)   USE_SYS_GCC=yes     ; USE_PREBUILT=no; shift ;;
		-cross)    CROSS_COMPILE=yes   ; USE_PREBUILT=no; shift ;;
		-all)      FORCE_BUILD_ALL=yes ; shift ;;
	-gz|-xz|gz|xz) INITRD_COMP=${1#-}  ; shift ;;
		-download) DLD_ONLY=yes        ; shift ;;
		-prebuilt) USE_PREBUILT=yes    ; shift ;;
		-nord)     INITRD_CREATE=no    ; shift ;;
		-auto)     PROMPT=no           ; shift ;;
		-v)        V=-v                ; shift ;;
		-lang)     LOCALE="$2"         ; shift 2
			       [ "$LOCALE" = "" ] && fatal_error "$0 -locale: No locale specified" ;;
		-keymap)   KEYMAP="$2"         ; shift 2
			       [ "$KEYMAP" = "" ] && fatal_error "$0 -locale: No keymap specified" ;;
		-pkg)      BUILD_PKG="$2"      ; shift 2
			       [ "$BUILD_PKG" = "" ] && fatal_error "$0 -pkg: Specify a pkg to compile" ;;
		-arch)     TARGET_ARCH="$2"    ; shift 2
			       [ "$TARGET_ARCH" = "" ] && fatal_error "$0 -arch: Specify a target arch" ;;
		-specs)    DISTRO_SPECS="$2"   ; shift 2
			       [ ! -f "$DISTRO_SPECS" ] && fatal_error "$0 -specs: '${DISTRO_SPECS}' is not a regular file" ;;
	-h|-help|--help) help_msg ; exit ;;
		-clean)
			echo -e "Press P and hit enter to proceed, any other combination to cancel.." ; read zz
			case $zz in p|P) echo rm -rf initrd.[gx]z initrd_progs-*.tar.* ZZ_initrd-expanded 00_* 0sources cross-compiler* ;; esac
			exit
			;;
		*)
			echo "Unrecognized option: $1"
			shift
			;;
	esac
done

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function use_prebuilt_binaries() {
	[ ! "$PREBUILT_BINARIES" ] && { echo "ERROR"; exit 1 ; }
	case "$TARGET_ARCH" in
		i686) [ -n "$i686_PREBUILT_BINARIES" ] && PREBUILT_BINARIES=${i686_PREBUILT_BINARIES} ;;
		x86_64) [ -n "$x86_64_PREBUILT_BINARIES" ] && PREBUILT_BINARIES=${x86_64_PREBUILT_BINARIES} ;;
		arm) [ -n "$arm_PREBUILT_BINARIES" ] && PREBUILT_BINARIES=${arm_PREBUILT_BINARIES} ;;
		aarch64) [ -n "$aarch64_PREBUILT_BINARIES" ] && PREBUILT_BINARIES=${aarch64_PREBUILT_BINARIES} ;;
	esac
	zfile=0sources/${PREBUILT_BINARIES##*/}
	if [ -f "$zfile" ] ; then
		#verify file integrity
		tar -taf "$zfile" &>/dev/null || rm -f "$zfile"
	fi
	if [ ! -f "$zfile" ] ; then
		mkdir -p 0sources
		wget -P 0sources --no-check-certificate "$PREBUILT_BINARIES"
		[ $? -eq 0 ] || { rm -f "$zfile"; echo "ERROR"; exit 1 ; }
	fi
	echo "* Extracting ${zfile##*/}..."
	tar -xaf "$zfile" || { rm -f "$zfile"; echo "ERROR"; exit 1 ; }
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function set_compiler() {
	which make &>/dev/null || fatal_error echo "It looks like development tools are not installed.. stopping"
	if [ "$USE_SYS_GCC" = "no" -a "$CROSS_COMPILE" = "no" ] ; then
		# if we're using the script in a non-x86 system
		# it means that the system gcc must be chosen by default
		# perhaps we're running qemu or a native linux os
		case $ARCH in
			i?86|x86_64) CROSS_COMPILE=yes ;;
			*) USE_SYS_GCC=yes ;;
		esac
	fi
	if [ "$USE_SYS_GCC" = "yes" ] ; then
		which gcc &>/dev/null || fatal_error "No gcc, aborting..."
		echo -e "\nBuilding in: $ARCH"
		echo -e "\n* Using system gcc\n"
		sleep 1.5
	else
		CROSS_COMPILE=yes #precaution
		case $ARCH in
			i?86|x86_64) ok=yes ;;
			*)	fatal_error "*** Only use x86 systems to cross-compile\n* Run $0 -sysgcc to use the system gcc ... \n" ;;
		esac
	fi
}

#--

function select_target_arch() {
	[ "$CROSS_COMPILE" = "no" -a "$USE_PREBUILT" = "no" ] && return
	#-- defaults
	case $TARGET_ARCH in
		default) TARGET_ARCH=${ARCH} ;;
		x86) TARGET_ARCH=${DEFAULT_x86} ;;
		arm64) TARGET_ARCH=${DEFAULT_ARM64} ;;
	esac
	VALID_TARGET_ARCH=no
	if [ "$TARGET_ARCH" != "" ] ; then #no -arch specified
		for a in $ARCH_LIST ; do
			[ "$TARGET_ARCH" = "$a" ] && VALID_TARGET_ARCH=yes && break
		done
		if [ "$VALID_TARGET_ARCH" = "no" ] ; then
			echo "Invalid target arch: $TARGET_ARCH"
			exit 1
		fi
		[ "$TARGET_ARCH" != "default" ] && ARCH=${TARGET_ARCH}
	fi
	#--
	if [ "$VALID_TARGET_ARCH" = "no" -a "$PROMPT" = "yes" ] ; then
		echo -e "\nWe're going to compile apps for the init ram disk"
		echo -e "Select the arch you want to compile to\n"
		x=1
		for a in $ARCH_LIST ; do
			case $a in
				default) echo "	${x}) default [${ARCH}]" ;;
				*) echo "	${x}) $a" ;;
			esac
			let x++
		done
		echo "	*) default [${ARCH}]"
		echo -en "\nEnter your choice: " ; read choice
		echo
		x=1
		for a in $ARCH_LIST
		do
			[ "$x" = "$choice" ] && selected_arch=$a && break
			let x++
		done
		case $selected_arch in
			default|"")ok=yes ;;
			*) ARCH=$selected_arch ;;
		esac
	fi
	# using prebuilt binaries: echo $ARCH and return
	[ "$USE_PREBUILT" = "yes" ] && echo "Arch: $ARCH" && return
	# don't check OS_ARCH if only downloading
	if [ "$DLD_ONLY" = "no" ] ; then
		case $OS_ARCH in
			*64) ok=yes ;;
			*) case $ARCH in *64) fatal_error "\n*** Trying to compile for a 64bit arch in a 32bit system?\n*** That's not possible.. exiting.." ;; esac ;;
		esac
	fi
	#--
	case $ARCH in
		i*86)    CC_TARBALL=$X86_CC    ;;
		x86_64)  CC_TARBALL=$X86_64_CC ;;
		arm*)    CC_TARBALL=$ARM_CC    ;;
		arm64|aarch64) CC_TARBALL=$ARM64_CC  ;;
	esac
	if [ -z "$CC_TARBALL" ] ; then
		echo "Cross compiler for $TARGET_ARCH is not available at the moment..."
		exit 1
	fi
	#--
	echo "Arch: $ARCH"
	case $ARCH in
		arm) TARGET_TRIPLET=${TARGET_TRIPLET_arm} ;;
		*)
			TARGET_TRIPLET=$(echo $CC_TARBALL | cut -d '-' -f 3)
			TARGET_TRIPLET=${TARGET_TRIPLET}-linux-musl
			;;
	esac
	sleep 1.5
}

#--

function setup_cross_compiler() {
	[ "$CROSS_COMPILE" = "no" ] && return
	CC_DIR=cross-compiler-${ARCH}
	echo
	## download
	if [ ! -f "0sources/${CC_TARBALL}" ];then
		echo "Download cross compiler"
		[ "$PROMPT" = "yes" ] && echo -n "Press enter to continue, CTRL-C to cancel..." && read zzz
		wget -c -P 0sources ${SITE}/${CC_TARBALL}
		if [ $? -ne 0 ] ; then
			rm -rf ${CC_DIR}
			echo "failed to download ${CC_TARBALL}"
			exit 1
		fi
	else
		[ "$DLD_ONLY" = "yes" ] && echo "Already downloaded ${CC_TARBALL}"
	fi
	[ "$DLD_ONLY" = "yes" ] && return
	## extract
	if [ ! -d "$CC_DIR" ] ; then
		tar --directory=$PWD -xaf 0sources/${CC_TARBALL}
		if [ $? -ne 0 ] ; then
			rm -rf ${CC_DIR}
			rm -fv 0sources/${CC_TARBALL}
			echo "failed to extract ${CC_TARBALL}"
			exit 1
		fi
	fi
	#--
	if [ ! -d "$CC_DIR" ] ; then
		echo "$CC_DIR not found"
		exit 1
	fi
	case $OS_ARCH in i*86)
		_gcc=$(find $CC_DIR/bin -name '*gcc' | head -1)
		if [ ! -z $_gcc ] && file $_gcc | grep '64-bit' ; then
			echo
			echo "ERROR: trying to use a 64-bit (static) cross compiler in a 32-bit system"
			exit
		fi
	esac
	echo -e "\nUsing cross compiler\n"
	export OVERRIDE_ARCH=${ARCH}  # = cross compiling # see ./func
	export XPATH=${PWD}/${CC_DIR} # = cross compiling # see ./func
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function check_bin() {
	case $init_pkg in
		""|'#'*) continue ;;
		coreutils_static) static_bins='cp' ;;
		dosfstools_static) static_bins='fsck.fat' ;;
		e2fsprogs_static) static_bins='e2fsck resize2fs' ;;
		exfat-utils_static) static_bins='exfatfsck' ;;
		fuse-exfat_static) static_bins='mount.exfat-fuse' ;;
		findutils_static) static_bins='find' ;;
		util-linux_static) static_bins='losetup' ;;
		util-linux-222_static) static_bins='losetup-222' ;;
		*) static_bins=${init_pkg%_*} ;;
	esac
	for sbin in ${static_bins} ; do
		[ -f ./00_${ARCH}/bin/${sbin} ] || return 1
	done
}

function build_pkgs() {
	rm -f .fatal
	mkdir -p 00_${ARCH}/bin 00_${ARCH}/log 0sources
	if [ "$DLD_ONLY" = "no" ] ; then
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo -e "\nbuilding packages for the initial ram disk\n"
		sleep 1
	fi
	#--
	[ "$BUILD_PKG" != "" ] && PACKAGES="$BUILD_PKG"
	if [ "$FORCE_BUILD_ALL" = "yes" ] ; then
		PACKAGES=$(find pkg -maxdepth 1 -type d -name '*_static' | sed 's|.*/||' | sort)
	else
		PACKAGES=$(get_initrd_progs -pkg $ARCH)
	fi
	#--
	for init_pkg in ${PACKAGES} ; do
		case $init_pkg in ""|'#'*) continue ;; esac
		[ -f .fatal ] && { echo "Exiting.." ; rm -f .fatal ; exit 1 ; }
		[ -d pkg/"${init_pkg}_static" ] && init_pkg=${init_pkg}_static
		if [ "$DLD_ONLY" = "no" ] ; then
			check_bin $init_pkg
			[ $? -eq 0 ] && { echo "$init_pkg exists ... skipping" ; continue ; }
			echo -e "\n+=============================================================================+"
			echo -e "\nbuilding $init_pkg"
			sleep 1
		fi
		#--
		cd pkg/${init_pkg}
		mkdir -p ${MWD}/00_${ARCH}/log
		sh ${init_pkg}.petbuild 2>&1 | tee ${MWD}/00_${ARCH}/log/${init_pkg}build.log
		cd ${MWD}
		[ "$DLD_ONLY" = "yes" ] && continue
		check_bin $init_pkg
		[ $? -ne 0 ] && { echo "target binary does not exist..."; exit 1; }
	done
	rm -f .fatal
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function set_lang() { #in $MWD
	[ "${LOCALE%_*}" = "en" ] && LOCALE=""
	[ ! "$LOCALE" ] && { echo -e "\n* Using default locale" ; rm -f ZZ_initrd-expanded/PUPPYLANG ; return; }
	echo -e "* LANG set to: $LOCALE\n"
	echo -n "$LOCALE" > ZZ_initrd-expanded/PUPPYLANG
}

function set_keymap() { #in $MWD
	[ ! -f 0initrd/lib/keymaps/${KEYMAP}.gz ] && KEYMAP=""
	case $KEYMAP in default|en|us|"") echo "* Using default keymap"; rm -f ZZ_initrd-expanded/PUPPYKEYMAP ; return ;; esac
	echo -e "* Keymap set to: '${KEYMAP}'"
	echo -n "$KEYMAP" > ZZ_initrd-expanded/PUPPYKEYMAP
}

function generate_initrd() {
	[ "$DLD_ONLY" = "yes" ] && return
	[ "$INITRD_CREATE" = "no" ] && return
	INITRD_FILE="initrd.${INITRD_COMP}"
	[ "$INITRD_GZ" = "yes" ] && INITRD_FILE="initrd.gz"

	if [ "$USE_PREBUILT" = "no" ] ; then
		[ "$PROMPT" = "yes" ] && echo -en "\nPress enter to create ${INITRD_FILE}, CTRL-C to end here.." && read zzz
		echo -e "\n============================================"
		echo "Now creating the initial ramdisk (${INITRD_FILE})"
		echo -e "=============================================\n"
	fi

	rm -rf ZZ_initrd-expanded
	mkdir -p ZZ_initrd-expanded
	cp -rf 0initrd/* ZZ_initrd-expanded
	find ZZ_initrd-expanded -type f -name '*MARKER' -delete

	set_lang    #
	set_keymap  #

	cd ZZ_initrd-expanded

	for PROG in $(get_initrd_progs ${ARCH}) ; do
		case $PROG in ""|'#'*) continue ;; esac
		if [ -f ../00_${ARCH}/bin/${PROG} ] ; then
			file ../00_${ARCH}/bin/${PROG} | grep -E 'dynamically|shared' && exit 1
			cp -a ${V} --remove-destination ../00_${ARCH}/bin/${PROG} bin
		else
			echo "00_${ARCH}/bin/${PROG} not found"
			exit 1
		fi
	done

	[ ! -f bin/nano -a ! -f bin/mp ] && rm -rf usr lib/terminfo

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

	cp -f ${V} ../pkg/busybox_static/bb-*-symlinks bin # essential
	(  cd bin ; sh bb-create-symlinks 2>/dev/null )
	sed -i 's|^PUPDESKFLG=.*|PUPDESKFLG=0|' init

	if [ "$FULL_INSTALL" -o "$PUPMODE" = "2" ] ; then
		rm -fv bin/cryptsetup
		rm -fv bin/ntfs-3g
		rm -fv bin/mount.exfat-fuse
		rm -fv bin/fsck.fat
		rm -fv bin/losetup-222
		rm -fv bin/exfatfsck
		rm -fv bin/resize2fs
		mv init_full_install init
		find -L bin -type l -delete
	fi

	find . | cpio -o -H newc > ../initrd 2>/dev/null
	cd ..
	[ -f initrd.[gx]z ] && rm -f initrd.[gx]z
	case ${INITRD_COMP} in
		gz) gzip -f initrd ;;
		xz) xz --check=crc32 --lzma2 initrd ;;
	esac
	[ $? -eq 0 ] || { echo "ERROR" ; exit 1 ; }
	[ "$INITRD_GZ" = "yes" -a -f initrd.xz ] && mv -f initrd.xz initrd.gz

	echo -e "\n***        INITRD: ${INITRD_FILE} [${ARCH}]"
	echo -e "*** /DISTRO_SPECS: ${DISTRO_NAME} ${DISTRO_VERSION} ${DISTRO_TARGETARCH}"

	[ "$USE_PREBUILT" = "yes" ] && return
	echo -e "\n@@ -- You can inspect ZZ_initrd-expanded to see the final results -- @@"
	echo -e "Finished.\n"
}

###############################################
#                 MAIN
###############################################

if [ "$USE_PREBUILT" = "yes" ] ; then
	select_target_arch
	use_prebuilt_binaries
else
	V="-v"
	set_compiler
	select_target_arch
	setup_cross_compiler
	build_pkgs
	cd ${MWD}
fi

generate_initrd

### END ###
