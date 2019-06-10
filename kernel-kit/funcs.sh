#!/bin/bash

function git_aufs_util_branch() {
	# aufs-util branch - must keep this updated - git://git.code.sf.net/p/aufs/aufs-util.git
	for i in 4.14 4.9 4.4 4.1 4.0 3.18 3.14 3.9 3.2
	do
		if vercmp ${kernel_version} ge ${i} ; then
			aufs_util_branch=${i}
			break
		fi
	done
}

# sets $aufsv
function git_aufs_branch() {
 #  aufs_git_4="git://github.com/sfjro/aufs4-standalone.git"
 #  aufs_git_5="git://github.com/sfjro/aufs5-standalone.git"
 #---
 # $kernel_version       is set by build.sh
 # $kernel_major_version is set by build.sh
 case ${kernel_major_version} in
	3.*) aufsv=${kernel_major_version} ;; # 3.14, 3.18      etc
	4.*) aufsv=${kernel_major_version} ;; # 4.1,  4.4, 4.14 etc
 esac

 case ${kernel_major_version} in
	#### k3.0 #####
	3.2)  aufsv=3.2                #unknown actual value
		vercmp ${kernel_version} ge 3.2.30 && aufsv='3.2.x'
		;;
	3.10) aufsv=3.10
		vercmp ${kernel_version} ge 3.10.26 && aufsv='3.10.x'
		;;
	3.12) aufsv=3.12
		vercmp ${kernel_version} ge 3.12.7 && aufsv='3.12.x'
		vercmp ${kernel_version} ge 3.12.31 && aufsv='3.12.31+'
		;;
	3.14) aufsv=3.14
		vercmp ${kernel_version} ge 3.14.21 && aufsv='3.14.21+'
		vercmp ${kernel_version} ge 3.14.40 && aufsv='3.14.40+'
		;;
	3.18) aufsv=3.18
		vercmp ${kernel_version} ge 3.18.1 && aufsv='3.18.1+'
		vercmp ${kernel_version} ge 3.18.25 && aufsv='3.18.25+'
		;;

	#### k4.0 #####
	4.1)  aufsv=4.1
		vercmp ${kernel_version} ge 4.1.13 && aufsv='4.1.13+'
		;;
	4.9)  aufsv=4.9
		vercmp ${kernel_version} ge 4.9.9 && aufsv='4.9.9+'
		vercmp ${kernel_version} ge 4.9.94 && aufsv='4.9.94+'
		;;
	4.11) aufsv=4.11.0-untested
		vercmp ${kernel_version} ge 4.11.7 && aufsv='4.11.7+'
		;;
	4.14) aufsv=4.14
		vercmp ${kernel_version} ge 4.14.56 && aufsv='4.14.56+'
		vercmp ${kernel_version} ge 4.14.73 && aufsv='4.14.73+'
		;;
	4.18) aufsv=4.18
		vercmp ${kernel_version} ge 4.18.11 && aufsv='4.18.11+'
		;;
	4.19) aufsv=4.19
		vercmp ${kernel_version} ge 4.19.17 && aufsv='4.19.17+'
		;;
	4.20) aufsv=4.20
		vercmp ${kernel_version} ge 4.20.4 && aufsv='4.20.4+'
		;;

	#### k5.0 #####
	5.0)  aufsv=5.0 ;;
	5.1)  aufsv=5.1 ;;
 esac
}
#======================================================================

function log_ver() {
	touch ${BUILD_LOG}
	(
	if [ -f /etc/DISTRO_SPECS ] ; then
		. /etc/DISTRO_SPECS
		echo "$DISTRO_NAME $DISTRO_VERSION [$(uname -m)]"
	fi
	gcc --version | head -1
	git --version | head -1
	mksquashfs -version | head -1
	echo
	) | tee -a ${BUILD_LOG}
}

#======================================================================

#y = builtin
#m = module

function config_is_set() {
	[ ! "$1" -o ! "$2" ] && return
	local opt=$1 file=$2
	if grep -q -E "^${opt}=y|^${opt}=m" "$file" ; then
		return 0
	else
		return 1
	fi
}

# $1 = type
# $2 = config_opt
# $3 = config_file
function config_set() {
	[ ! "$1" -o ! "$2" -o ! "$3" ] && return 1
	local type=$1 opt=$2 file=$3 t
	case $type in
		builtin) t='y' ;;
		custom) t='c' ;; #for special purposes (further processing)
		*) t='m' ;; #module = default
	esac
	sed -i -e "s|# $opt .*|${opt}=${t}|" \
		-e "s|^$opt=.*|${opt}=${t}|" "$file"
}

function config_unset() {
	[ ! "$1" -o ! "$2" ] && return
	local opt=$1 file=$2
	sed -i -e "s|^${opt}=y|# $opt is not set|" \
		-e "s|^${opt}=m|# $opt is not set|" "$file"
}

function config_toggle() {
	[ ! "$1" -o ! "$2" ] && return
	local opt=$1 file=$2
	if config_is_set $opt "$file" ; then
		config_unset $opt "$file"
	else
		config_set module $opt "$file"
	fi
}

function config_delete() {
	[ ! "$1" -o ! "$2" ] && return
	local opt=$1 file=$2
	sed -i -e "/^${opt}=y/d" -e "/ ${opt} /d" "$file"
}

# $1 = config file
function config_get_builtin()   { grep '=y'  "$1" | cut -f1 -d '=' ; }
function config_get_module()   {  grep '=m'  "$1" | cut -f1 -d '=' ; }
function config_get_set() { grep -E '=m|=y'  "$1" | cut -f1 -d '=' ; }
function config_get_unset() { grep 'not set' "$1" | cut -f2 -d ' ' ; }

# $1 = config_file
# $2 = file with fixed config options
function fix_config() {
	[ ! "$1" -o ! "$2" ] && return
	local file=$1 fixed_opts=$2
	(
	cat $fixed_opts | sed -e 's| is not set||' -e '/^$/d' -e '/##/d' | \
	while read line ; do
		case $line in
			*'=m') C_OPT=${line%=*} ; echo "s%.*${C_OPT}.*%${C_OPT}=m%" ;;
			*'=y') C_OPT=${line%=*} ; echo "s%.*${C_OPT}.*%${C_OPT}=y%" ;;
			*) C_OPT=${line:2}      ; echo "s%.*${C_OPT}.*%# ${C_OPT} is not set%" ;;
		esac
	done
	) > /tmp/ksed.file
	cp "$1" "$1".orig
	sed -i -f /tmp/ksed.file "$1"
}


##############
## EXAMPLES ##
##############

# $1: kernel config file
function set_pae() {
	#http://askubuntu.com/questions/395771/in-32-bit-ubuntu-12-04-how-can-i-find-out-if-pae-has-been-enabled
	config_set builtin CONFIG_X86_PAE $1
	config_set builtin CONFIG_HIGHMEM64G $1
	config_unset CONFIG_HIGHMEM4G $1
}

# $1: kernel config file
function unset_pae() {
	config_delete CONFIG_X86_PAE $1
	config_unset CONFIG_HIGHMEM64G $1
	config_set builtin CONFIG_HIGHMEM4G $1
}

# $1: kernel config file
function set_i486() {
	config_set builtin CONFIG_M486 $1
	for i in CONFIG_M386 CONFIG_M686 CONFIG_M586 CONFIG_M586TSC CONFIG_M586MMX CONFIG_MPENTIUMII CONFIG_MPENTIUMIII CONFIG_MPENTIUMM CONFIG_MPENTIUM4 CONFIG_MK6 CONFIG_MK7 CONFIG_MK8 CONFIG_MCRUSOE CONFIG_MEFFICEON CONFIG_MWINCHIPC6 CONFIG_MWINCHIP3D CONFIG_MELAN CONFIG_MGEODEGX1 CONFIG_MGEODE_LX CONFIG_MCYRIXIII CONFIG_MVIAC3_2 CONFIG_MVIAC7 CONFIG_MCORE2 CONFIG_MATOM
	do
		config_unset $i $1
	done
}

# $1: kernel config file
function set_i686() {
	config_set builtin CONFIG_M686 $1
	for i in CONFIG_M386 CONFIG_M486 CONFIG_M586 CONFIG_M586TSC CONFIG_M586MMX CONFIG_MPENTIUMII CONFIG_MPENTIUMIII CONFIG_MPENTIUMM CONFIG_MPENTIUM4 CONFIG_MK6 CONFIG_MK7 CONFIG_MK8 CONFIG_MCRUSOE CONFIG_MEFFICEON CONFIG_MWINCHIPC6 CONFIG_MWINCHIP3D CONFIG_MELAN CONFIG_MGEODEGX1 CONFIG_MGEODE_LX CONFIG_MCYRIXIII CONFIG_MVIAC3_2 CONFIG_MVIAC7 CONFIG_MCORE2 CONFIG_MATOM
	do
		config_unset $i $1
	done
}

# $HOST_ARCH and $x86_* are set in build.conf and/or build.sh
# edits .config in current dir
# part of build.sh ...
function i386_specific_stuff() {
	if [ "$HOST_ARCH" = "x86" ] ; then
		if [ "$x86_disable_pae" = "yes" ] ; then
			if grep 'CONFIG_X86_PAE=y' .config ; then #CONFIG_HIGHMEM64G=y
				log_msg "Disabling PAE..."
				MAKEOLDCONFIG=1
				unset_pae .config
			fi
		fi
		if [ "$x86_enable_pae" = "yes" ] ; then
			if ! grep 'CONFIG_X86_PAE=y' .config ; then
				log_msg "Enabling PAE..."
				MAKEOLDCONFIG=1
				set_pae .config
			fi
		fi
		if [ "$x86_set_i486" = "yes" ] ; then
			if grep -q 'CONFIG_OUTPUT_FORMAT="elf32-i386"' .config ; then
				if ! grep -q 'CONFIG_M486=y' .config ; then
					log_msg "Forcing i486..."
					MAKEOLDCONFIG=1
					set_i486 .config
				fi
			fi
		fi
		if [ "$x86_set_i686" = "yes" ] ; then
			if grep -q 'CONFIG_OUTPUT_FORMAT="elf32-i386"' .config ; then
				if ! grep -q 'CONFIG_M686=y' .config ; then
					log_msg "Forcing i686..."
					MAKEOLDCONFIG=1
					set_i686 .config
				fi
			fi
		fi
		[ "$MAKEOLDCONFIG" != "" ] && make silentoldconfig
	fi
}

#$@



#########################
### GIT KERNEL SOURCE ###
#########################

function get_git_kernel() {
# uses exit_error() func from build.sh

	[ "$USE_GIT_KERNEL" == '' ] && exit_error "Error: USE_GIT_KERNEL must be specified before calling get_git_kernel()"

	if [ ! -f /tmp/${kernel_git_dir}_done -o ! -d sources/${kernel_git_dir}/.git ] ; then
		mkdir -p sources/kernels
		cd sources
		if [ ! -d ${kernel_git_dir}/.git ] ; then
			git clone --depth=1 ${USE_GIT_KERNEL} ${kernel_git_dir}
			[ $? -ne 0 ] && exit_error "Error: failed to download the kernel sources."
			touch /tmp/${kernel_git_dir}_done
		else
			cd ${kernel_git_dir}
			echo "Updating ${kernel_git_dir}"
			git fetch --depth=1 origin
			if [ $? -ne 0 ] ; then
				log_msg "WARNING: 'git fetch --depth=1 origin' command failed" && sleep 5
			else
				git checkout origin &>/dev/null
				[ $? -ne 0 ] && exit_error "Error: unable to checkout ${kernel_git_dir}"

				touch /tmp/${kernel_git_dir}_done
			fi
		fi
		cd $MWD
	fi

}

function print_git_kernel_version() {

	cd sources/${kernel_git_dir}

	makefile_version="`grep '^VERSION = ' Makefile`"
	makefile_patchlevel="`grep '^PATCHLEVEL = ' Makefile`"
	makefile_sublevel="`grep '^SUBLEVEL = ' Makefile`"

	echo "`expr match "$makefile_version" '[^[:digit:]]*\([[:digit:]]*\)'`.`expr match "$makefile_patchlevel" '[^[:digit:]]*\([[:digit:]]*\)'`.`expr match "$makefile_sublevel" '[^[:digit:]]*\([[:digit:]]*\)'`"

	cd $MWD

}

function configure_git_kernel() {
# uses exit_error() func from build.sh

# use for ARM kernels only please,
# should work with https://github.com/raspberrypi/linux
# arch/arm/configs/bcmrpi_defconfig and
# arch/arm/configs/bcm2709_defconfig

	[ "$USE_GIT_KERNEL_CONFIG" == '' ] && exit_error "Error: USE_GIT_KERNEL_CONFIG must be specified before calling configure_git_kernel()"

	echo "Using USE_GIT_KERNEL_CONFIG"
	[ -f "sources/${kernel_git_dir}/${USE_GIT_KERNEL_CONFIG}" ] && cp "sources/${kernel_git_dir}/${USE_GIT_KERNEL_CONFIG}" DOTconfig
	config_set builtin CONFIG_INPUT_EVDEV DOTconfig
	config_set builtin CONFIG_NLS_CODEPAGE_850 DOTconfig
	config_set builtin CONFIG_NLS_CODEPAGE_852 DOTconfig
	config_set builtin CONFIG_SQUASHFS DOTconfig
	config_set builtin CONFIG_TMPFS_XATTR DOTconfig
	echo 'CONFIG_AUFS_FS=y' >> DOTconfig
	echo 'CONFIG_ARM=y' >> DOTconfig

}



###########################
### GIT CROSS COMPILERS ###
###########################

function get_git_cross_compiler() {
# uses exit_error() func from build.sh

	[ "$1" == '' ] && exit_error "Error: URL of git repo must be passed to get_git_cross_compiler()"

	if [ ! -f /tmp/${tools_git_dir}_done -o ! -d tools/${tools_git_dir}/.git ] ; then
		cd tools
		if [ ! -d ${tools_git_dir}/.git ] ; then
			git clone --depth=1 "$1" ${tools_git_dir}
			[ $? -ne 0 ] && exit_error "Error: failed to download the cross compiler."
			touch /tmp/${tools_git_dir}_done
		else
			cd ${tools_git_dir}
			echo "Updating ${tools_git_dir}"
			git fetch --depth=1 origin
			if [ $? -ne 0 ] ; then
				log_msg "WARNING: 'git fetch --depth=1 origin' command failed" && sleep 5
			else
				git checkout origin &>/dev/null
				[ $? -ne 0 ] && exit_error "Error: unable to checkout ${tools_git_dir}"

				touch /tmp/${tools_git_dir}_done
			fi
		fi
		cd $MWD
	fi
}



##################################
### MAINLINE KERNEL PLUS PATCH ###
##################################

function get_sha256sums() {
	# get the latest version of sha256sums.asc
	for kernel_mirror in $kernel_mirrors ; do
		kernel_mirror=${kernel_mirror}/${ksubdir}
		wget ${WGET_OPT} -c -P sources/kernels ${kernel_mirror}${testing}/sha256sums.asc
		if [ $? -ne 0 ] ; then
			echo "Error downloading sha256sums.asc from $kernel_mirror"
		else
			break
		fi
	done

	KERNEL_SHA256SUM="`grep -F "linux-${kernel_major_version}.tar.xz" sources/kernels/sha256sums.asc`"
	[ "$KERNEL_SHA256SUM" != '' ] && echo "$KERNEL_SHA256SUM" > sources/kernels/linux-${kernel_major_version}.tar.xz.sha256.txt
	PATCH_SHA256SUM="`grep -F "patch-${kernel_tarball_version}.xz" sources/kernels/sha256sums.asc`"
	[ "$PATCH_SHA256SUM" != '' ] && echo "$PATCH_SHA256SUM" > sources/kernels/patch-${kernel_tarball_version}.xz.sha256.txt
}

function download_mainline_kernel_plus_patch() {
# uses log_msg() func from build.sh

	DOWNLOAD_KERNEL=1
	DOWNLOAD_PATCH=1

	# do not download if we already have an existing exact match version
	if [ -f sources/kernels/linux-${kernel_tarball_version}.tar.xz ]; then
		DOWNLOAD_KERNEL=0
		DOWNLOAD_PATCH=0
	fi

	# unless it is corrupt...
	if [ -f sources/kernels/linux-${kernel_tarball_version}.tar.xz.md5.txt ] ; then
		cd sources/kernels
		md5sum -c linux-${kernel_tarball_version}.tar.xz.md5.txt
		if [ $? -ne 0 ] ; then
			log_msg "md5sum FAILED: will resume kernel download..."
			DOWNLOAD_KERNEL=1
			DOWNLOAD_PATCH=1
		fi
		cd $MWD
	fi


	# check if we already have a mainline kernel
	[ -f sources/kernels/linux-${kernel_major_version}.tar.xz ] && DOWNLOAD_KERNEL=0
	# check if we already have a kernel patch
	[ -f sources/kernels/patch-${kernel_tarball_version}.xz ] && DOWNLOAD_PATCH=0

	# if sha256sum is installed...
	if [ "`which sha256sum`" != '' ]; then
		[ ! -f sources/kernels/linux-${kernel_major_version}.tar.xz.sha256.txt ] && get_sha256sums
		# and a checksum was successfully created
		if [ -f sources/kernels/linux-${kernel_major_version}.tar.xz.sha256.txt ]; then
			cd sources/kernels
			# check kernel tarball
			sha256sum -c linux-${kernel_major_version}.tar.xz.sha256.txt
			if [ $? -ne 0 ] ; then
				log_msg "sha256sum FAILED: will re-download mainline kernel..."
				DOWNLOAD_KERNEL=1
			fi
			cd $MWD
		fi

		[ ! -f sources/kernels/patch-${kernel_tarball_version}.xz.sha256.txt ] && get_sha256sums
		# if a checksum was successfully created
		if [ -f sources/kernels/patch-${kernel_tarball_version}.xz.sha256.txt ]; then
			cd sources/kernels
			# check patch file
			sha256sum -c patch-${kernel_tarball_version}.xz.sha256.txt
			if [ $? -ne 0 ] ; then
				log_msg "sha256sum FAILED: will re-download kernel patch..."
				DOWNLOAD_PATCH=1
			fi
			cd $MWD
		fi
	fi

	if [ $DOWNLOAD_KERNEL -eq 1 ] ; then
		KERROR=1
		for kernel_mirror in $kernel_mirrors ; do
			kernel_mirror=${kernel_mirror}/${ksubdir}
			log_msg "Downloading: ${kernel_mirror}${testing}/linux-${kernel_major_version}.tar.xz"
			wget ${WGET_OPT} -c -P sources/kernels ${kernel_mirror}${testing}/linux-${kernel_major_version}.tar.xz >> ${BUILD_LOG}
			if [ $? -ne 0 ] ; then
				echo "Error"
			else
				KERROR=
				break
			fi
		done
		[ $KERROR ] && exit 1
	fi
	if [ $DOWNLOAD_PATCH -eq 1 ] ; then
		KERROR=1
		for kernel_mirror in $kernel_mirrors ; do
			kernel_mirror=${kernel_mirror}/${ksubdir}
			log_msg "Downloading: ${kernel_mirror}${testing}/patch-${kernel_tarball_version}.xz"
			wget ${WGET_OPT} -c -P sources/kernels ${kernel_mirror}${testing}/patch-${kernel_tarball_version}.xz >> ${BUILD_LOG}
			if [ $? -ne 0 ] ; then
				echo "Error"
			else
				KERROR=
				break
			fi
		done
		[ $KERROR ] && exit 1
	fi

}


### END ###
