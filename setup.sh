#!/bin/sh
# (C) James Budiono 2014 
# License: GNU GPL Version 3 or later.

### configuration
WORK_DIR=${WORK_DIR:-./workdir}
HOST_ARCH=${HOST_ARCH:-$(uname -m)}
#TARGET_ARCH= # inherit or ask
#SOURCE=      # source distro - inherit or ask
#VERSION=     # distro version - inherit or ask
#CROSS=       # automatically set - currently cross-build is not supported yet
#DONT_ASK=   # if set to 1, don't ask questions

### helpers 

sanity_check() {
	[ ! -d ./woof-arch ] && echo Missing woof-arch && exit
	[ ! -d ./woof-code ] && echo Missing woof-code && exit
	[ ! -d ./woof-distro ] && echo Missing woof-code && exit
	if [ -e $WORK_DIR ]; then
		echo "$WORK_DIR already exists, running this script again will obliterate it."
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
	local inp p good
	while true; do
		echo "$1"; echo "$3" | awk '{ print "-", $0 }'
		printf "Enter your selection: "; read inp 
		good=; for p in $3; do
			[ $inp = $p ] && good=yes && break
		done
		[ $good ] && echo && break
		printf "$inp is not one of the choices. Please try again.\n\n"
	done
	eval $2=$inp
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

map_target_arch() { # as needed to meet source distro name
	case $SOURCE in
		ubuntu|debian)
			case $TARGET_ARCH in
				x86)    MAPPED_ARCH=i386 ;;
				x86_64) MAPPED_ARCH=amd64 ;;
			esac ;;
		slackware)
			case $TARGET_ARCH in
				x86)    MAPPED_ARCH=slackware ;;
				x86_64) MAPPED_ARCH=slackware64 ;;
			esac ;;
	esac
}

prepare_work_dir() {
	echo "Cleaning out $WORK_DIR ..."
	rm -rf $WORK_DIR; mkdir -p $WORK_DIR
	
	cat > $WORK_DIR/build.conf << EOF
### For SFS builders ###
HOST_ARCH='$HOST_ARCH'
TARGET_ARCH='$TARGET_ARCH'
SOURCE='$SOURCE'
CROSS='$CROSS'
WOOFCE='$(pwd)'

# Edit as needed. Commented section are defaults.
ARCH='$MAPPED_ARCH'
PKGLIST=pkglist
VERSION='$VERSION'
#DISTRO_PREFIX=puppy
#DISTRO_VERSION=700

REPO_DIR=repo-\$VERSION-\$ARCH
CHROOT_DIR=chroot-\$VERSION-\$ARCH
BASE_CODE_PATH="\$WOOFCE/woof-code/rootfs-skeleton"
BASE_ARCH_PATH="\$WOOFCE/woof-arch/\$TARGET_ARCH/target/rootfs-skeleton"
EXTRAPKG_PATH="\$WOOFCE/woof-code/rootfs-packages"

# loads REPO_URL, REPO_PKGDB, REPO_SECTIONS, WITH_APT_DB
. ./repo-url 

# debian/ubuntu only
APT_SOURCES_DIR=\${CHROOT_DIR}/etc/apt/sources.list.d
APT_PKGDB_DIR=\${CHROOT_DIR}/var/lib/apt/lists

# slackware only
INSTALLPKG=./installpkg
REMOVEPKG=./removepkg

### for ISO builders ###
PUPPY_SFS=puppy.sfs   # if you change this, change %makesfs params in pkglist too
OUTPUT_DIR=iso        # if you change this, change %makesfs params in pkglist too
OUTPUT_ISO=puppy.iso
ISO_ROOT=\$OUTPUT_DIR/iso-root

ISOLINUX_BIN="\$WOOFCE/woof-arch/x86/build/boot/isolinux.bin"
ISOLINUX_CFG="\$WOOFCE/woof-code/boot/boot-dialog"
INITRD_ARCH="\$WOOFCE/woof-arch/x86/target/boot/initrd-tree0"
INITRD_CODE="\$WOOFCE/woof-code/boot/initrd-tree0"

# provisional settings
KERNEL_VERSION=3.12.9 # change as needed

EOF

	ln -s $(pwd)/builders/$SOURCE-build.sh $WORK_DIR/build-sfs.sh
	ln -s $(pwd)/builders/build-iso.sh $WORK_DIR/build-iso.sh
	ln -s $(pwd)/builders/runqemu.sh $WORK_DIR/runqemu.sh
	cp woof-distro/${TARGET_ARCH}/${SOURCE}/${VERSION}/pkglist $WORK_DIR
	cp woof-distro/${TARGET_ARCH}/${SOURCE}/${VERSION}/repo-url $WORK_DIR
	
	# distro-specific tools
	case $SOURCE in
		slackware) 
			ln -s $(pwd)/builders/installpkg $WORK_DIR/installpkg
			ln -s $(pwd)/builders/removepkg $WORK_DIR/removepkg ;;
	esac

}

confirmation() {
	cat << EOF
Directory $WORK_DIR has been prepare for your build.
Your configuration is as follows:
---
Host arch:      $HOST_ARCH
Target arch:    $TARGET_ARCH
Source distro:  $SOURCE
Source version: $VERSION
Cross-build:    $([ $CROSS ] && echo yes || echo no)
---
The default pkglist and repo-url has been copied to $WORK_DIR. 
You can use these files as they are, or you can modify them 
as you see fit.

If this doesn't sound right, re-run the script to re-create 
the configuration.
EOF
}

### main ###
sanity_check
get_target_arch
get_source_distro
map_target_arch
prepare_work_dir
confirmation
exit


# === Original code kept for future reference ===

#!/bin/dash
#BK nov. 2011
#111126 do not copy files from woof-distro to woof-out, symlink only.
#111126 fix symlink to compat-distro pkg download directory.
#111127 make sure host linux system has 'printcols' and 'vercmp' utilities.
#111127 also make sure target build will have 'printcols' and 'vercmp'.
#111203 fixes for rerun of this script.
#120503 i left some EMPTYDIRMARKER files inside /dev.
#120512 remove option to create symlinks in working directory.
#120515 build from "gentoo" binary tarballs (refer support/gentoo).
#130306 arch linux: gz now xz.
#130528 change owner:group of symlink instead of what it points to.
#------
#140612 jamesbond - total re-write

CURDIR="`pwd`"

echo
echo 'This script merges woof-arch, woof-code and woof-distro, to ../woof-out_*.

woof-arch:  architecture-dependent (x86, arm) files, mostly binary executables.
woof-code:  the core of Woof. Mostly scripts.
woof-distro: distro-configuration (Debian, Slackware, etc.) files.

Important: the host architecture is distinct from the target architecture.
The host is the machine you are running Woof on, the target is the machine
in which the Puppy that you build is going to run. Typically, you will build
on a x86 machine, and the target may be x86 or arm.'
echo

CNT=1
for ONEARCH in `find woof-arch -mindepth 1 -maxdepth 1 -type d | sed -e 's%^woof-arch/%%' | sort | tr '\n' ' '`
do
 echo "$CNT  $ONEARCH"
 CNT=$(($CNT + 1))
done
echo -n 'Type number of host architecture: '
read nHOSTARCH
HOSTARCH="`find woof-arch -mindepth 1 -maxdepth 1 -type d | sed -e 's%^woof-arch/%%' | sort | head -n $nHOSTARCH | tail -n 1`"
echo "...ok, $HOSTARCH"
echo

CNT=1
for ONEARCH in `find woof-arch -mindepth 1 -maxdepth 1 -type d | sed -e 's%^woof-arch/%%' | sort | tr '\n' ' '`
do
 echo "$CNT  $ONEARCH"
 CNT=$(($CNT + 1))
done
echo -n 'Type number of target architecture: '
read nTARGETARCH
TARGETARCH="`find woof-arch -mindepth 1 -maxdepth 1 -type d | sed -e 's%^woof-arch/%%' | sort | head -n $nTARGETARCH | tail -n 1`"
echo "...ok, $TARGETARCH"
echo

echo 'Woof builds a Puppy based on the binary packages from another distro.
We sometimes refer to this as the "compat-distro".'
echo
CNT=1
taPTN="s%^woof-distro/${TARGETARCH}/%%"
for ONEDISTRO in `find woof-distro/${TARGETARCH} -mindepth 1 -maxdepth 1 -type d | sed -e "${taPTN}" | sort | tr '\n' ' '`
do
 echo "$CNT  $ONEDISTRO"
 CNT=$(($CNT + 1))
done
echo -n 'Type number of compat-distro: '
read nCOMPATDISTRO
COMPATDISTRO="`find woof-distro/${TARGETARCH} -mindepth 1 -maxdepth 1 -type d | sed -e "${taPTN}" | sort | head -n $nCOMPATDISTRO | tail -n 1`"
echo "...ok, $COMPATDISTRO"
echo

echo 'The compat-distro usually has release versions, unless it is a rolling
release system such as Arch Linux. Please choose which release you want to
obtain the binary packages from.'

CNT=1
for ONECOMPAT in `find woof-distro/${TARGETARCH}/${COMPATDISTRO} -maxdepth 1 -mindepth 1 -type d | rev | cut -f 1 -d '/' | rev | sort | tr '\n' ' '`
do
 echo "$CNT  $ONECOMPAT"
 CNT=$(($CNT + 1))
done
if [ $CNT -eq 1 ];then
 echo
 echo "Sorry, there are no release directories inside woof-distro/${COMPATDISTRO}."
 echo "At least one is required. Quiting."
 exit
fi
echo -n 'Type number of release: '
read nCOMPATVERSION
COMPATVERSION="`find woof-distro/${TARGETARCH}/${COMPATDISTRO} -maxdepth 1 -mindepth 1 -type d | rev | cut -f 1 -d '/' | rev | sort | head -n $nCOMPATVERSION | tail -n 1`"
echo "...ok, $COMPATVERSION"

echo
echo 'Choices:'
echo "Host architecture:     $HOSTARCH"
echo "Target architecture:   $TARGETARCH"
echo "Compatible-distro:     $COMPATDISTRO"
echo "Compat-distro version: $COMPATVERSION"
echo
echo -n "If these are ok, press ENTER, other CTRL-C to quit: "
read waitforit

echo
echo "Directory '../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}'
will now be created, if not already, and the contents of 'woof-code' copied
into it. Then, these will also be copied into it:
woof-arch/${HOSTARCH}/build
woof-arch/${TARGETARCH}/target
woof-distro/${TARGETARCH}/${COMPATDISTRO}/${COMPATVERSION} (files all levels)"
echo
echo "Any existing files in '../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}' will be over-ridden."
echo "(Also, if you have any of your own files in folders 'boot', 'kernel-skeleton',
 , 'rootfs-skeleton' or 'support', they will be deleted.)"
echo -n 'Press ENTER to continue: '
read goforit

#111203 as files/dirs could be removed in future woofs, need to wipe entire target dirs first...
rm -r -f ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/boot  2> /dev/null
rm -r -f ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/kernel-skeleton  2> /dev/null
rm -r -f ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/rootfs-skeleton  2> /dev/null
rm -r -f ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/support  2> /dev/null
sync

mkdir -p ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}
echo "Copying woof-code/*..."
cp -a -f --remove-destination woof-code/* ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/
sync
echo "Copying woof-arch/${HOSTARCH}/build/*..."
cp -a -f --remove-destination woof-arch/${HOSTARCH}/build/* ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/
sync
echo "Copying woof-arch/${TARGETARCH}/target/*"
cp -a -f --remove-destination woof-arch/${TARGETARCH}/target/* ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/
sync
echo
echo "Copying woof-distro/${COMPATDISTRO}/${COMPATVERSION}/*..."
#copy any top-level files, going down...

DESTTYPE='file'
choosesymlink=''

PARENTDIR="`echo -n "$CURDIR" | rev | cut -f 1 -d '/' | rev`" #ex: woof2

#lowest level...
#cp -a -f --remove-destination woof-distro/${TARGETARCH}/${COMPATDISTRO}/${COMPATVERSION}/* ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/
for ONETOP in `find woof-distro/${TARGETARCH}/${COMPATDISTRO}/${COMPATVERSION} -mindepth 1 -maxdepth 1 -type f | tr '\n' ' '`
do
 if [ "$choosesymlink" = "" ];then
  cp -f -a --remove-destination $ONETOP ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/
 else
  ONENAME="`basename $ONETOP`"
  ln -snf ../${PARENTDIR}/${ONETOP} ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/${ONENAME}
 fi
done
sync

echo "WOOF_HOSTARCH='$HOSTARCH'
WOOF_TARGETARCH='${TARGETARCH}'
WOOF_COMPATDISTRO='${COMPATDISTRO}'
WOOF_COMPATVERSION='${COMPATVERSION}'" > ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/WOOFMERGEVARS

echo
echo "Now for some housekeeping..."

if [ -f ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/boot/initrd-tree0/bin/bb-create-symlinks ];then
 echo
 echo "Symlinks being created inside here:"
 echo "../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/boot/initrd-tree0/bin"
 cd ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/boot/initrd-tree0/bin
 for ONESYMLINK in `find . -type l | cut -f 2 -d '/' | tr '\n' ' '`
 do
  rm -f ${ONESYMLINK}
 done
 ./bb-create-symlinks
 cd $CURDIR #cd ../../../../
fi

#work around limitations of a version control system...
echo
echo "Some things are modified inside 'woof-code' to cater for most Version
Control Systems. Typically, a VCS cannot handle most of these:
1. Empty directories
2. Special file/directory permissions/ownership
3. Device nodes
4. Symlinks
5. Special characters (such as [, [[) in file/dir names
6. Binary files

BK's Bones VCS can handle all six. Fossil VCS can do no.4 & no.6 only (in fact,
most VCSs such as SVN, GIT and Mercurial, can handle no.4 & no.6). Woof has
lots of symlinks and binary files, and you must use a VCS that supports them.
No.5 is solved by avoiding usage of such special characters, except we have
workarounds for case of files named '[' and '[['."
echo
echo "Directory 'woof-code' has workarounds for no.1-3 (& partial 5):
1. An empty file named 'EMPTYDIRMARKER' inside all empty directories.
2. A file named VCSMETADATA has permissions/ownerships of special files/dirs.
3. 'dev' directories are converted to '*DEVDIR.tar.gz' tarball files.
5. Files named '[' and '[[' renamed 'LEFTSQBRACKETCHAR' 'DBLLEFTSQBRACKETCHAR'."
echo
echo "These workarounds will now be undone in '../woof-out_*'..."
echo -n "Press ENTER to continue: "
read goforit

fossil_fixup_func() { #workarounds for VCS...
 #param passed in is directory to fix.
 #5: '[' and '[[' files renamed...
 for FOSSILFIXFILE in `find ${1} -name LEFTSQBRACKETCHAR | tr '\n' ' '`
 do
  DIRFFF="`dirname "$FOSSILFIXFILE"`"
  mv -f $FOSSILFIXFILE $DIRFFF/[
 done
 for FOSSILFIXFILE in `find ${1} -name DBLLEFTSQBRACKETCHAR | tr '\n' ' '`
 do
  DIRFFF="`dirname "$FOSSILFIXFILE"`"
  mv -f $FOSSILFIXFILE $DIRFFF/[[
 done
 #1: empty dirs have file 'EMPTYDIRMARKER' in them...
 for FOSSILFIXFILE in `find ${1} -type f -name EMPTYDIRMARKER | tr '\n' ' '`
 do
  DIRFFF="`dirname "$FOSSILFIXFILE"`"
  rm -f $DIRFFF/EMPTYDIRMARKER
 done
 #3: 'dev' dir made into a tarball and stored in 'woof-arch'...
 for DEVFILE in `find ${1} -type f -name DEVDIRMARKER | tr '\n' ' '`
 do
  xDEVFILE="${CURDIR}/woof-arch/`cat $DEVFILE`"
  DIRFFF="`dirname "$DEVFILE"`"
  cp -f $xDEVFILE ${DIRFFF}/DEVDIR.tar.gz
  FCURRDIR="`pwd`"
  cd $DIRFFF
  tar -zxf DEVDIR.tar.gz
  rm -f DEVDIR.tar.gz
  rm -f DEVDIRMARKER
  #120503 i left some EMPTYDIRMARKER inside /dev...
  for FOSSILFIXFILE in `find dev -type f -name EMPTYDIRMARKER | tr '\n' ' '`
  do
   DIRFFF="`dirname "$FOSSILFIXFILE"`"
   rm -f $DIRFFF/EMPTYDIRMARKER
  done
  cd $FCURRDIR
 done
}

echo
cd ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}
echo "Fixing ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/rootfs-skeleton..."
fossil_fixup_func rootfs-skeleton
echo "Fixing ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/boot/initrd-tree0..."
fossil_fixup_func boot/initrd-tree0

#2: VCSMETADATA permissions/ownership...
if [ -s VCSMETADATA ];then
 echo "Fixing file/dir permissions/ownership..."
 for ONESPEC in `cat VCSMETADATA | tr '\n' ' '`
 do
  ONEFILE="`echo -n "$ONESPEC" | cut -f 1 -d ':'`"
  [ ! -e $ONEFILE ] && continue
  ONEPERM="`echo -n "$ONESPEC" | cut -f 2 -d ':'`"
  ONEOWNER="`echo -n "$ONESPEC" | cut -f 3 -d ':'`"
  ONEGROUP="`echo -n "$ONESPEC" | cut -f 4 -d ':'`"
  echo -n '.' #echo " $ONEFILE $ONEPERM $ONEOWNER $ONEGROUP"
  chmod $ONEPERM $ONEFILE
  #130528 change owner:group of symlink instead of what it points to...
  [ "$ONEOWNER" != "UNKNOWN" ] && chown -h $ONEOWNER $ONEFILE
  [ "$ONEOWNER" = "UNKNOWN" ] && chown -h root $ONEFILE
  [ "$ONEGROUP" != "UNKNOWN" ] && chgrp -h $ONEGROUP $ONEFILE
  [ "$ONEGROUP" = "UNKNOWN" ] && chgrp -h root $ONEFILE
 done
 echo
fi
cd $CURDIR
sync

#common dir to download pet pkgs to...
mkdir -p ../local-repositories/${TARGETARCH}/packages-pet
[ ! -e ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/packages-pet ] && ln -s ../local-repositories/${TARGETARCH}/packages-pet ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/packages-pet #111203 check exist.

#more links to common download...
if [ -f ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/DISTRO_SPECS ];then

. ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/DISTRO_SPECS

 #111126 code from 2createpackages...
 BINARIES='deb' #get them from packages-deb.
 [ "$DISTRO_BINARY_COMPAT" = "t2" ] && BINARIES="bz2" #get them from packages-bz2-${DISTRO_COMPAT_VERSION}.
 [ "$DISTRO_BINARY_COMPAT" = "slackware" ] && BINARIES="tgz_txz" #download to packages-tgz_txz-${DISTRO_COMPAT_VERSION}.
 [ "$DISTRO_BINARY_COMPAT" = "debian" ] && BINARIES="deb" #download to packages-deb-${DISTRO_COMPAT_VERSION}.
 [ "$DISTRO_BINARY_COMPAT" = "arch" ] && BINARIES="tar_xz" #download to packages-tar_xz-${DISTRO_COMPAT_VERSION}. 130306
 [ "$DISTRO_BINARY_COMPAT" = "puppy" ] && BINARIES="pet" #built entirely from pet pkgs.
 [ "$DISTRO_BINARY_COMPAT" = "scientific" ] && BINARIES="rpm" #Iguleder: download to packages-rpm-${DISTRO_COMPAT_VERSION}.
 [ "$DISTRO_BINARY_COMPAT" = "mageia" ] && BINARIES="rpm"
 [ "$DISTRO_BINARY_COMPAT" = "gentoo" ] && BINARIES="gentoo" #120515 download to packages-gentoo-gap6
[ "$DISTRO_BINARY_COMPAT" = "raspbian" ] && BINARIES="deb_raspbian" #download to packages-deb_raspbian-${DISTRO_COMPAT_VERSION}.
 BINARIES="${BINARIES}-${DISTRO_COMPAT_VERSION}"

 mkdir -p ../local-repositories/${TARGETARCH}/packages-${BINARIES}
 [ ! -e ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/packages-${BINARIES} ] && ln -s ../local-repositories/${TARGETARCH}/packages-${BINARIES} ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/packages-${BINARIES} #111203 check exist.
fi

#record target architecture in DISTRO_SPECS (will end up in /etc/ in Puppy build)...
if [ -f ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/DISTRO_SPECS ];then
 if [ "`grep '^DISTRO_TARGETARCH' ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/DISTRO_SPECS`" = "" ];then
  echo "DISTRO_TARGETARCH='${TARGETARCH}'" >> ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/DISTRO_SPECS
 fi
fi

#until i upgrade the woof scripts... (i was planning to rename Packages-puppy-* to Packages-pet-*, aborted)
for ONEPP in `find ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION} -mindepth 1 -maxdepth 1 -name 'Packages-pet-*' | tr '\n' ' '`
do
 BASEPP="`basename $ONEPP`"
 NEWBASE="`echo -n $BASEPP | sed -e 's%Packages-pet-%Packages-puppy-%'`"
 ln -s $BASEPP ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/${NEWBASE}
done

#111127 make sure host puppy has these...
[ ! -f /usr/sbin/printcols ] && cp -af woof-arch/${HOSTARCH}/build/support/printcols /usr/sbin/ #column manipulator.
[ ! -f /bin/vercmp ] && cp -af woof-arch/${HOSTARCH}/target/boot/initrd-tree0/bin/vercmp /bin/ #dotted-version compare utility, see boot/vercmp.c

#111127 make sure target has these...
cp -af woof-arch/${TARGETARCH}/build/support/printcols ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/${NEWBASE}/rootfs-skeleton/usr/sbin/
cp -af woof-arch/${TARGETARCH}/target/boot/initrd-tree0/bin/vercmp ../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}/${NEWBASE}/rootfs-skeleton/bin/

echo
echo "Directory '../woof-out_${HOSTARCH}_${TARGETARCH}_${COMPATDISTRO}_${COMPATVERSION}'
is now normal, that is, the workarounds have been removed. Note,
../local-repositories has been created (if not already), to be used as a common
binary package download place. 'packages-pet' and 'packages-${BINARIES}'
have been created that link into it, where pkgs will be downloaded to."


###END###
