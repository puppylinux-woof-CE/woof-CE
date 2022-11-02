#!/bin/sh
# Prepare build system.
# Copyright (C) James Budiono 2014 
# License: GNU GPL Version 3 or later.

### configuration
#DONT_ASK=    # if set to 1, don't ask questions
MWD=$(pwd)
WORK_DIR=${WORK_DIR:-workdir}
HOST_ARCH=${HOST_ARCH:-$(uname -m)}
NAME=${NAME:-puppy}
DISTRO_VER=${DISTRO_VER:-899}
#TARGET_ARCH= # inherit or ask
#SOURCE=      # source distro - inherit or ask
#VERSION=     # distro version - inherit or ask
#CROSS=       # automatically set - currently cross-build is not supported yet
KERNEL_URL=${KERNEL_URL:-http://distro.ibiblio.org/puppylinux/huge_kernels}
#KERNEL_TARBALL # inherit or ask

### helpers

sanity_check() {
	case $1 in
		--help|-help|-h) 
			echo "Usage: ${0##*/} [workdir]"
			echo "WORK_DIR environment will be used if [workdir] not specified".
			echo "Otherwise 'workdir' will be used as default."
			exit ;;
		"") ;;
		*)  WORK_DIR=$1 ;;
	esac

	[ ! -d ./woof-code ] && echo Missing woof-code && exit
	[ ! -d ./woof-distro ] && echo Missing woof-code && exit
	if [ -e $WORK_DIR ]; then
		echo "'$WORK_DIR' already exists, running this script again will obliterate it."
		printf "Continue? (yes/no) "; read p
		case $p in
			yes|YES|Yes) ;;
			*) echo "Cancelled. " && exit
		esac
	fi
	if [ $DONT_ASK ]; then
		# make sure we have all the needed parameters
		[ -z "$TARGET_ARCH" ] && echo Please specify TARGET_ARCH. && exit
		[ -z "$SOURCE" ] && echo Please specify SOURCE. && exit
		[ -z "$VERSION" ] && echo Please specify VERSION. && exit
	fi
}

#$1-prompt $2-output var $3 selection
get_selection() {
	[ "$DONT_ASK" ] && return
	local choice p
	while true; do
		echo "$1"; echo "$3" | awk '{ print NR ")", $0 }'
		printf "Enter your selection: "; read choice
		choice=$(echo "$3" | awk -v choice=$choice 'NR==choice {print $0}')
		[ "$choice" ] && echo && break
		printf "Bad selection. Please try again.\n\n"
	done
	eval $2=\"$choice\"
}

get_target_arch() {
	echo "Your host arch: " $HOST_ARCH
	get_selection "Please choose target arch: " TARGET_ARCH "$(ls woof-distro)"
	[ $TARGET_ARCH = x86 -a $HOST_ARCH = x86_64 ] && HOST_ARCH=x86
	[ $TARGET_ARCH != $HOST_ARCH ] && CROSS=1
	# echo $HOST_ARCH $TARGET_ARCH $CROSS
}

get_source_distro() {
	get_selection "Please select source distro: " SOURCE "$(ls woof-distro/$TARGET_ARCH)"
	get_selection "Please select version: " VERSION "$(ls woof-distro/$TARGET_ARCH/$SOURCE)"
	# echo $SOURCE
}

get_kernel() {
	local p
	# handle mirror selection later
	
	# prepare filters
	case $TARGET_ARCH in
		x86) filter="grep -v 64" ;;
		arm*) filter="grep ^kit" ;;
		*)   filter="grep 64" ;;
	esac
	p=${KERNEL_URL##*//}; p=${p%%/*}
	echo Getting list of available kernels from $p ...
	kernels=$(wget -q -O - $KERNEL_URL | 
	          sed '/href/!d; /\.tar\./!d; /md5\.txt/d; /sha256\.txt/d; s/.*href="//; s/".*//; s/%2[bB]/+/;' |
	          $filter)
	get_selection "Please select kernel" KERNEL_TARBALL "$kernels $(printf "\nI will build my own later.")"
	
	case "$KERNEL_TARBALL" in
		*.tar.*) ;;
		*) KERNEL_URL="" KERNEL_TARBALL="" ;; # self-build - clear the variables
	esac
}

choose_prefix() { # DISTRO_FILE_PREFIX
	echo "Choose a distro name or leave blank (no spaces)"
	read name
	[ -n "$name" ] && NAME=$name
}

choose_version() { # DISTRO_VERSION
	echo "Choose a distro version or leave blank (3 or 4 digits)"
	read ver
	[ -n "$ver" ] && DISTRO_VER=$ver
}

map_target_arch() { # as needed to meet source distro name
	case $SOURCE in
		ubuntu|debian|devuan)
			case $TARGET_ARCH in
				x86)    MAPPED_ARCH=i386 ;;
				x86_64) MAPPED_ARCH=amd64 ;;
				arm*) MAPPED_ARCH=armhf ;;
			esac ;;
		*)
			MAPPED_ARCH=$TARGET_ARCH ;;
	esac
}

map_version() { # as needed to meet source distro name
	case $SOURCE in
		slackware) # this is specific for mirrors.slackware.com, others may differ
			case $TARGET_ARCH in
				x86)    MAPPED_VERSION=slackware-$VERSION ;;
				x86_64) MAPPED_VERSION=slackware64-$VERSION ;;
			esac ;;
		*)
			MAPPED_VERSION=$VERSION ;;
	esac
}

prepare_work_dir() {
	mkdir -p $WORK_DIR
	cat > $WORK_DIR/build.conf << EOF
### For SFS builders ###
HOST_ARCH='$HOST_ARCH'
TARGET_ARCH='$MAPPED_ARCH'
SOURCE='$SOURCE'
CROSS='$CROSS'
WOOFCE='$(pwd)'

# Edit as needed. Commented section are defaults.
ARCH='$MAPPED_ARCH'
PKGLIST=basesfs # or devx
VERSION='$MAPPED_VERSION'
DISTRO_PREFIX='$NAME'
DISTRO_VERSION='$DISTRO_VER'

REPO_DIR=repo-\$VERSION-\$ARCH
CHROOT_DIR=chroot-\$VERSION-\$ARCH
DEVX_DIR=devx-holder
NLS_DIR=nls-holder
BASE_CODE_PATH="woof-code/rootfs-skeleton"
BASE_ARCH_PATH="woof-arch/\$TARGET_ARCH/target/rootfs-skeleton"
BOOT_FILES_PATH="woof-arch/\$TARGET_ARCH/build/boot"
EXTRAPKG_PATH="woof-code/rootfs-packages"

# loads DEFAULT_REPOS, WITH_APT_DB and other repository options
. $(pwd)/${WORK_DIR}/repo-url 

### for ISO builder ###
PUPPY_SFS=puppy.sfs   # if you change this, change %makesfs params in basesfs too
OUTPUT_DIR=iso        # if you change this, change %makesfs params in basesfs too
OUTPUT_ISO=puppy.iso
ISO_ROOT=\$OUTPUT_DIR/iso-root

KERNEL_URL="$KERNEL_URL"
KERNEL_TARBALL=$KERNEL_TARBALL

EOF

	ln -snfv $(pwd)/builders/$SOURCE-build.sh $WORK_DIR/build-sfs.sh
	ln -snfv $(pwd)/builders/build-iso.sh $WORK_DIR/build-iso.sh
	ln -snfv $(pwd)/builders/build-tar.sh $WORK_DIR/build-tar.sh
	ln -snfv $(pwd)/builders/runqemu.sh $WORK_DIR/runqemu.sh
	ln -snfv $(pwd)/builders/xlog $WORK_DIR/xlog

	cp woof-distro/${TARGET_ARCH}/${SOURCE}/${VERSION}/* $WORK_DIR

	#============================================
	WOOF_OUT=$WORK_DIR
	
	sdirs='initrd-progs kernel-kit woof-arch woof-code'

	# as files/dirs could be removed in future woofs, need to wipe entire target dirs first...
	for d in $sdirs
	do
		if [ -d ${WOOF_OUT}/${d} ] ; then
			echo "Deleting ${WOOF_OUT}/${d}"
			rm -rf ${WOOF_OUT}/${d} 2> /dev/null
		fi
		if [ -d ../$d ] ; then
			cp -a ../$d ${WOOF_OUT}
		elif [ -d $d ] ; then
			cp -a $d ${WOOF_OUT}
		fi
	done
	sync
	(
	cd ${WOOF_OUT}
	mkdir -p z_doc/usr/share/
	cp -ar woof-code/rootfs-skeleton/usr/share/doc z_doc/usr/share/
	cp -arf woof-arch/${TARGET_ARCH}/target/rootfs-skeleton/* woof-code/rootfs-skeleton
	)
	cat > ${WOOF_OUT}/z_doc/pinstall.sh << _EOF
#!/bin/sh
	. etc/DISTRO_SPECS

echo "Configuring Puppy Help page..."

cutDISTRONAME="\$(echo -n "$DISTRO_NAME" | cut -f 1 -d ' ')"
cPATTERN="s/cutDISTRONAME/\${cutDISTRONAME}/g"
PUPPYDATE="\$(date | tr -s " " | cut -f 2,6 -d " ")"
RELEASE_DATE="\$(date "+%B, %Y")"
dPATTERN="s/PUPPYDATE/\${PUPPYDATE}/g"
rPATTERN="s/RELEASE_DATE/\${RELEASE_DATE}/g"
PATTERN2="s/DISTRO_VERSION/\${DISTRO_VERSION}/g"
nPATTERN="s/DISTRO_NAME/\${DISTRO_NAME}/g"
sed -i -e "\$PATTERN2" -e "\$nPATTERN" -e "\$dPATTERN" -e "\$cPATTERN" usr/share/doc/index.html.top
sed -i -e "\$PATTERN2" -e "\$nPATTERN" -e "\$dPATTERN" usr/share/doc/index.html.bottom

(
	cat usr/share/doc/index.html.top
	cat usr/share/doc/index.html.bottom
) > usr/share/doc/index.html

sed -i -e "\$nPATTERN" usr/share/doc/home.htm

if [ -f usr/share/doc/release-skeleton.top.htm ] ; then
	(
		sed -e "\$PATTERN2" -e "\$nPATTERN" -e "\$rPATTERN" usr/share/doc/release-skeleton.top.htm
		sed -e "\$PATTERN2" -e "\$nPATTERN" -e "\$rPATTERN" usr/share/doc/release-skeleton.bottom.htm
	) > usr/share/doc/release-\${cutDISTRONAME}-\${DISTRO_VERSION}.htm
fi

rm -f usr/share/doc/release-skeleton.*


_EOF
	chmod 755 ${WOOF_OUT}/z_doc/pinstall.sh
	sync
	(
	cd ${WOOF_OUT}
	for d in $sdirs huge_kernel
	do
		[ -d "${d}" ] && find $d -type f -name EMPTYDIRMARKER -delete
	done
	sync
	)

	# delete woof scripts that call -FULL/busybox apps
	for i in bin/df bin/mount bin/ps bin/umount sbin/losetup
	do
		rm -fv ${WOOF_OUT}/woof-code/rootfs-skeleton/${i}
	done

	# distro-specific tools
	case $SOURCE in
		slackware) 
			ln -snfv $(pwd)/builders/installpkg $WORK_DIR/installpkg
			ln -snfv $(pwd)/builders/removepkg $WORK_DIR/removepkg ;;
	esac

}

confirmation() {
	cat << EOF
Directory '$WORK_DIR' has been prepare for your build.
Your configuration is as follows:
---
Host arch:      $HOST_ARCH
Target arch:    $MAPPED_ARCH
Source distro:  $SOURCE
Source version: $VERSION
Distro name:    $NAME
Distro version: $DISTRO_VER
Cross-build:    $([ $CROSS ] && echo yes || echo no)
---
The default pkglist and repo-url has been copied to '$WORK_DIR'. 
You can use these files as they are, or you can modify them 
as you see fit.

If this doesn't sound right, re-run the script to re-create 
the configuration.
EOF
}

### main ###
sanity_check "$@"
get_target_arch
get_source_distro
get_kernel
choose_prefix
choose_version
map_target_arch
map_version
prepare_work_dir
confirmation

### END ###
