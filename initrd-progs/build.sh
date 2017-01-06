#!/bin/bash
#also see:
#  http://autobuild.buildroot.org/toolchains/tarballs/

. ./build.conf
export MKFLG
export MWD=`pwd`

ARCH_LIST="default i686 x86_64 arm" #arm64
ARCH_LIST_EX="i486 i586 i686 x86_64 armv4l armv4tl armv5l armv6l m68k mips mips64 mipsel powerpc powerpc-440fp sh2eb sh2elf sh4 sparc"

DEFAULT_x86=i686
DEFAULT_ARM=armv6l
#DEFAULT_ARM64=aarch64

PREBUILT_BINARIES="http://01micko.com/wdlkmpx/woof-CE/initrd_progs-20170106-static.tar.xz"

ARCH=`uname -m`
OS_ARCH=$ARCH

case "$1" in release|tarball) #this contains the $PREBUILT_BINARIES
	echo "If you made changes then don't forget to remove all 00_* directories first"
	sleep 4
	for a in ${ARCH_LIST#default } ; do $0 -nord -auto -arch $a ; done
	pkgx=initrd_progs-$(date "+%Y%m%d")-static.tar.xz
	echo -e "\n\n\n*** Creating $pkgx"
	while read ARCH ; do
		for PROG in ${INITRD_PROGS} ; do
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
  -cross      : use the cross compilers from Aboriginal Linux
  -download   : download pkgs only, this overrides other options
  -specs file : DISTRO_SPECS file to use
  -prebuilt   : use prebuilt binaries
  -lang locale: set locale
  -keymap km  : set keyboard layout
  -auto       : don't prompt for input
  -gz|-xz     : compression method for the initrd
  -help       : show help and exit

  Valid <targets> for -arch:
      $ARCH_LIST_EX

  The most relevant <targets> for Puppy are:
      ${ARCH_LIST#default }

  Note that one target not yet supported by musl is aarch64 (arm64)
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
		# the cross compilers from landley.net were compiled on x86
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
		#   aboriginal linux   #
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
		arm) TARGET_ARCH=${DEFAULT_ARM} ;;
		#arm64) TARGET_ARCH=${DEFAULT_ARM64} ;;
	esac
	VALID_TARGET_ARCH=no
	if [ "$TARGET_ARCH" != "" ] ; then #no -arch specified
		for a in $ARCH_LIST_EX ; do
			[ "$TARGET_ARCH" = "$a" ] && VALID_TARGET_ARCH=yes && break
		done
		if [ "$VALID_TARGET_ARCH" = "no" ] ; then
			echo "Invalid target arch: $TARGET_ARCH"
			exit 1
		else
			[ "$TARGET_ARCH" != "default" ] && ARCH=${TARGET_ARCH}
		fi
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
		for a in $ARCH_LIST ; do [ "$x" = "$choice" ] && selected_arch=$a && break ; let x++ ; done
		for a in $ARCH_LIST_EX ; do [ "$a" = "$choice" ] && selected_arch=$a ; done
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
	echo "Arch: $ARCH"
	sleep 1.5
}

#--

function setup_cross_compiler() {
	# Aboriginal Linux #
	[ "$CROSS_COMPILE" = "no" ] && return
	CCOMP_DIR=cross-compiler-${ARCH}
	URL=http://landley.net/aboriginal/downloads/binaries
	PACKAGE=${CCOMP_DIR}.tar.gz
	echo
	## download
	if [ ! -f "0sources/${PACKAGE}" ];then
		echo "Download cross compiler from Aboriginal Linux"
		[ "$PROMPT" = "yes" ] && echo -n "Press enter to continue, CTRL-C to cancel..." && read zzz
		wget -c -P 0sources ${URL}/${PACKAGE}
		if [ $? -ne 0 ] ; then
			rm -rf ${CCOMP_DIR}
			echo "failed to download ${PACKAGE}"
			exit 1
		fi
	else
		[ "$DLD_ONLY" = "yes" ] && echo "Already downloaded ${PACKAGE}"
	fi
	[ "$DLD_ONLY" = "yes" ] && return
	## extract
	if [ ! -d "$CCOMP_DIR" ] ; then
		tar --directory=$PWD -xaf 0sources/${PACKAGE}
		if [ $? -ne 0 ] ; then
			rm -rf ${CCOMP_DIR}
			rm -fv 0sources/${PACKAGE}
			echo "failed to extract ${PACKAGE}"
			exit 1
		fi
	fi
	#--
	[ ! -d "$CCOMP_DIR" ] && { echo "$CCOMP_DIR not found"; exit 1; }
	if [ -d cross-compiler-${ARCH}/cc/lib ] ; then
		cp cross-compiler-${ARCH}/cc/lib/* cross-compiler-${ARCH}/lib
	fi
	echo -e "\nUsing cross compiler from Aboriginal Linux\n"
	export OVERRIDE_ARCH=${ARCH}     # = cross compiling # see ./func
	export XPATH=${PWD}/${CCOMP_DIR} # = cross compiling # see ./func
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function check_bin() {
	case $init_pkg in
		""|'#'*) continue ;;
		coreutils_static) static_bins='cp' ;;
		dosfstools_static) static_bins='fsck.fat' ;;
		e2fsprogs_static) static_bins='e2fsck resize2fs' ;;
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
	fi
	PACKAGES=$(echo "$PACKAGES" | grep -Ev '^#|^$')
	#--
	for init_pkg in ${PACKAGES} ; do
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

	for PROG in ${INITRD_PROGS} ; do
		case $PROG in ""|'#'*) continue ;; esac
		if [ -f ../00_${ARCH}/bin/${PROG} ] ; then
			file ../00_${ARCH}/bin/${PROG} | grep -E 'dynamically|shared' && exit 1
			cp -a ${V} --remove-destination ../00_${ARCH}/bin/${PROG} bin
		else
			echo "00_${ARCH}/bin/${PROG} not found"
			exit 1
		fi
	done

	[ ! -f bin/nano ] && rm -rf usr lib/terminfo

	echo
	if [ ! -f "$DISTRO_SPECS" -a -f ../DISTRO_SPECS ] ; then
		DISTRO_SPECS='../DISTRO_SPECS'
	fi
	if [ ! -f "$DISTRO_SPECS" -a ! -f ../0initrd/DISTRO_SPECS ] ; then
		[ -f /etc/DISTRO_SPECS ] && DISTRO_SPECS='/etc/DISTRO_SPECS'
		[ -f /initrd/DISTRO_SPECS ] && DISTRO_SPECS='/initrd/DISTRO_SPECS'
	fi
	[ -f "$DISTRO_SPECS" ] && cp -f ${V} "${DISTRO_SPECS}" .
	[ -x ../init ] && cp -f ${V} ../init .

	. ./DISTRO_SPECS

	cp -f ${V} ../pkg/busybox_static/bb-*-symlinks bin # essential
	(  cd bin ; sh bb-create-symlinks 2>/dev/null )
	sed -i 's|^PUPDESKFLG=.*|PUPDESKFLG=0|' init

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
	use_prebuilt_binaries
	select_target_arch
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
