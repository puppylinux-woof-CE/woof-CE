#!/bin/sh
# DEB chroot installer for making Woof-based puppy
# Copyright (C) James Budiono 2014
# License: GNU GPL Version 3 or later.
#
# Note: Assumes you have working dpkg-deb in the parent OS.
#
# env vars: DRY_RUN=1     - don't install, just print output of flattened pkglist
#           WITH_APT_DB=1 - include apt database (5MB compressed)
#           WITHOUT_DPKG=1 - don't use system dpkg

### end-user configuration
PKGLIST=${PKGLIST:-pkglist}
ARCH=${ARCH:-i386} # or amd64
VERSION=${VERSION:-trusty}
DISTRO_PREFIX=${DISTRO_PREFIX:-puppy}
DISTRO_VERSION=${DISTRO_VERSION:-700} # informative only

DEFAULT_REPOS=${REPO_URLS:-http://archive.ubuntu.com/ubuntu|$VERSION|main:universe|Packages.bz2}
#KEEP_DUPLICATES=1 # keep multiple versions of package in pkgdb
#WITH_APT_DB= # default is don't include apt-db

# dirs
REPO_DIR=${REPO_DIR:-repo-$VERSION-$ARCH}
CHROOT_DIR=${CHROOT_DIR:-chroot-$VERSION-$ARCH}
DEVX_DIR=${DEVX_DIR:-devx-holder}
NLS_DIR=${NLS_DIR:-nls-holder}
BASE_CODE_PATH=${ROOTFS_BASE:-rootfs-skeleton}
# BASE_ARCH_PATH= # inherit - arch-specific base files, can be empty
EXTRAPKG_PATH=${EXTRAPKG_PATH:-rootfs-packages}

APT_SOURCES_DIR=/etc/apt/sources.list.d
APT_PKGDB_DIR=/var/lib/apt/lists

### system-configuration, don't change
LANG=C
REPO_PKGDB_URL="%repo_url%/dists/%version%/%repo%/binary-%arch/%repo_pkgdb%"
LOCAL_PKGDB=pkgdb
ADMIN_DIR=/var/lib/dpkg
TRACKER=/tmp/tracker.$$
FLATTEN=/tmp/flatten.$$

###
BUILD_CONFIG=${BUILD_CONFIG:-./build.conf}
[ -e $BUILD_CONFIG ] && . $BUILD_CONFIG

### helpers ###

trap 'cleanup; exit' INT HUP TERM 0
cleanup() {
	rm -f $TRACKER $FLATTEN
}

### prepare critical dirs
prepare_dirs() {
	rm -rf $CHROOT_DIR
	mkdir -p $REPO_DIR $CHROOT_DIR $CHROOT_DIR/$APT_SOURCES_DIR $CHROOT_DIR/$APT_PKGDB_DIR
	for p in info parts alternatives methods updates; do
		mkdir -p $CHROOT_DIR/$ADMIN_DIR/$p
	done
	! [ -e $CHROOT_DIR/$ADMIN_DIR/status ]    && echo > $CHROOT_DIR/$ADMIN_DIR/status
	! [ -e $CHROOT_DIR/$ADMIN_DIR/available ] && echo > $CHROOT_DIR/$ADMIN_DIR/available
	
	if ! [ -e helpers ]; then
		mkdir -p helpers
		(cd helpers; ln -sf $(which true) update-rc.d)
	fi
	PATH=$(pwd)/helpers:$PATH
	> $TRACKER
}

###
# $REPO_DIR, $LOCAL_PKGDB, $1-url, $2-version, $3-repos-to-use, $4-pkgdb
add_repo() {
	local MARKER localdb pkgdb_url apt_pkgdb apt_source
	for p in $(echo $3|tr ':' ' '); do
		MARKER="### $2-$p-$1 ###" 
		localdb=$2-$p-$4
		pkgdb_url="$(echo $REPO_PKGDB_URL | sed "s|%repo_url%|$1|; s|%version%|$2|; s|%repo%|$p|; s|%repo_pkgdb%|$4|; s|%arch|$ARCH|")"
		apt_pkgdb="$(echo "$pkgdb_url" | sed 's|^http.*://||; s|^file:///||; s|/|_|g; s|\..z$||; s|\.bz2$||;')"
		apt_source="$2-$p.list"

		# download
		if ! [ -e $REPO_DIR/$localdb ] && echo Downloading database for "$p $1" ...; then
			if ! case "$1" in
				file://*) cp "${pkgdb_url#file://}" $REPO_DIR/$localdb ;;
				*) wget -q --no-check-certificate -c -O "$REPO_DIR/$localdb" "$pkgdb_url" ;;
			esac; then
				echo Bad database download for "$p $1", skipping ... 
				rm -f $REPO_DIR/$localdb # bad download, don't proceed
				continue
			fi
		fi

		# add apt sources and database
		echo "deb $1 $2 $p" > $CHROOT_DIR/$APT_SOURCES_DIR/"$apt_source"
		[ $WITH_APT_DB ] && echo Copying "$p $1" database for apt ...
		case $4 in
			*gz)  gunzip -c  $REPO_DIR/$localdb ;;
			*bz2) bunzip2 -c $REPO_DIR/$localdb ;;
			*xz)  unxz -c    $REPO_DIR/$localdb ;;
			*)    cat        $REPO_DIR/$localdb ;;
		esac > $CHROOT_DIR/$APT_PKGDB_DIR/"$apt_pkgdb"

		if ! grep -F -m1 -q "$MARKER" $REPO_DIR/$LOCAL_PKGDB 2>/dev/null; then	
			echo Processing database for "$2 $p" ...
			echo "$MARKER" >> $REPO_DIR/$LOCAL_PKGDB
			# awk version is 10x faster than bash/ash/dash version, even with LANG=C
			# format: pkg|pkgver|pkgfile|pkgpath|pkgprio|pkgsection|pkgmd5|pkgdep			
			< $CHROOT_DIR/$APT_PKGDB_DIR/"$apt_pkgdb" >> $REPO_DIR/$LOCAL_PKGDB \
			awk -v repo_url="$1" '
function fixdepends(s) {
	split(s,a,","); s="";
	for (p in a) {
		gsub(/[ \t]*\(.*\)|[ \t]\|.*|:any/,"",a[p]); s=s "," a[p]
	}
	sub(/^,/,"",s); return s;
}
/^Package:/     { sub(/^Package: /,"");  PKG=$0; }
/^Version:/     { sub(/^Version: /,"");  PKGVER=$0; }
/^Filename:/    { sub(/^Filename: /,""); PKGPATH=$0; sub(/.*\//,""); PKGFILE=$0; }
/^Priority:/    { sub(/^Priority: /,""); PKGPRIO=$0; }
/^Section:/     { sub(/^Section: /,"");  PKGSECTION=$0; }
/^MD5sum:/      { sub(/^MD5sum: /,"");   PKGMD5=$0; }
/^Depends:/     { sub(/^Depends: /,"");     PKGDEP=fixdepends($0) "," PKGDEP; }
/^Pre-Depends:/ { sub(/^Pre-Depends: /,""); PKGDEP=fixdepends($0) "," PKGDEP; }
/^$/            { print PKG "|" PKGVER "|" PKGFILE "|" repo_url "/" PKGPATH "|" PKGPRIO "|" PKGSECTION "|" PKGMD5 "|" PKGDEP ;
                  PKG=""; PKGVER=""; PKGFILE=""; PKGPATH=""; PKGPRIO=""; PKGSECTION=""; PKGMD5="";  PKGDEP=""; }
'
			# remove duplicates, use the "later" version if duplicate packages are found
			< $REPO_DIR/$LOCAL_PKGDB > /tmp/t.$$ \
			awk -F"|" '{if (!a[$1]) b[n++]=$1; a[$1]=$0} END {for (i=0;i<n;i++) {print a[b[i]]}}'
			mv /tmp/t.$$ $REPO_DIR/$LOCAL_PKGDB
		fi
		if [ -z "$WITH_APT_DB" ] || [ $DRY_RUN ]; then rm -f $CHROOT_DIR/APT_PKGDB_DIR/"$apt_pkgdb"; fi
	done
}

# $*-repos, format: url|version|sections|pkgdb
add_multiple_repos() {
	while [ "$1" ]; do
		add_repo $(echo "$1" | tr '|' ' ')
		shift
	done
}

###
# $1-pkg returns PKG PKGVER PKGFILE PKGPATH PKGPRIO PKGMD5 PKGSECTION PKGDEP
# format: pkg|pkgver|pkgfile|pkgpath|pkgprio|pkgsection|pkgmd5|pkgdep
get_pkg_info() {
	local pkg="$1"	
	OIFS="$IFS"; IFS="|"
	set -- $(grep -m1 "^$pkg|" $REPO_DIR/$LOCAL_PKGDB)
    [ -z "$1" ] && set --  $(grep -m1 "|${pkg}.t.z|" $REPO_DIR/$LOCAL_PKGDB)
	IFS="$OIFS"
	PKG="$1" PKGVER="$2" PKGFILE="$3" PKGPATH="$4" PKGPRIO="$5" PKGSECTION="$6" PKGMD5="$7" PKGDEP="$8"
	#echo $PKG $PKGVER $PKGFILE $PKGPATH $PKGPRIO $PKGSECTION $PKGMD5 $PKGDEP
}

###
# $1-priority $2-inclusion list $3-exclusion list
get_pkgs_by_priority() {
	local include=".*" exclude="^everything"
	[ "$2" ] && include="$2"
	[ "$3" ] && exclude="$3"
	# format: pkg|pkgver|pkgfile|pkgpath|pkgprio|pkgsection|pkgmd5|pkgdep
	< $REPO_DIR/$LOCAL_PKGDB awk -F"|" -v prio=$1 '$5==prio { print $1 }' |
	grep -E "$include" | grep -vE "$exclude"
}

###
# $1-pkg
is_already_installed() {
	test -e $CHROOT_DIR/$ADMIN_DIR/info/"${1}".list
}

###
# $1-retry, $PKGFILE, $PKGPATH, $PKGMD5
download_pkg() {
	local retval=0 local
	[ "$1" ] && echo "Bad md5sum $PKGFILE, attempting to re-download ..."
	if ! [ -e "$REPO_DIR/$PKGFILE" ] && echo Downloading "$PKGFILE" ...; then
		case "$PKGPATH" in
			file://*) cp "${PKGPATH#file://}" $REPO_DIR/$PKGFILE ;;
			*) wget -q --no-check-certificate -O $REPO_DIR/$PKGFILE "$PKGPATH" ;;
		esac
	fi
	
	# check md5sum
	echo "$PKGMD5  $REPO_DIR/$PKGFILE" > /tmp/md5.$$
	md5sum -c /tmp/md5.$$ >/dev/null; retval=$? 
	rm -f /tmp/md5.$$
	[ $retval -ne 0 -a -z "$1" ] && rm -f "$REPO_DIR/$PKGFILE" && download_pkg retry && retval=0
	return $retval
}

# $@-all, doc, gtkdoc, locales, cache
cutdown() {
	local options="$*" LIBDIR=lib
	[ "$1" = "all" ] && options="doc gtkdoc locales cache man"
	for p in $options; do
		case $p in
			doc)
				rm -rf $CHROOT_DIR/usr/share/doc $CHROOT_DIR/usr/doc
				mkdir $CHROOT_DIR/usr/share/doc $CHROOT_DIR/usr/doc ;;
			gtkdoc)
				rm -rf $CHROOT_DIR/usr/share/gtk-doc
				mkdir $CHROOT_DIR/usr/share/gtk-doc ;;
			cache)
				find $CHROOT_DIR -name icon-theme.cache -delete ;;
			man)
				rm -rf $CHROOT_DIR/usr/share/man $CHROOT_DIR/usr/share/info
				mkdir $CHROOT_DIR/usr/share/info
				for p in $(seq 1 8); do
					mkdir -p $CHROOT_DIR/usr/share/man/man${p}
				done ;;
			nls)
				[ -d $CHROOT_DIR/usr/lib64/locale ] && LIBDIR=lib64
				rm -rf $NLS_DIR; mkdir -p $NLS_DIR/usr/share/locale $NLS_DIR/usr/$LIBDIR/locale
				[ -d $CHROOT_DIR/usr/share/locale ] &&
				for p in $(ls $CHROOT_DIR/usr/share/locale); do
					case "$p" in
						en|"") ;; # do nothing
						*) mv $CHROOT_DIR/usr/share/locale/$p $NLS_DIR/usr/share/locale ;;
					esac
				done
				[ -d $CHROOT_DIR/usr/$LIBDIR/locale ] &&
				for p in $(ls $CHROOT_DIR/usr/$LIBDIR/locale); do
					case "$p" in
						en_US|en_AU|en_US.*|en_AU.*|C|C.*|"") ;; # skip
						*) mv $CHROOT_DIR/usr/$LIBDIR/locale/$p $NLS_DIR/usr/$LIBDIR/locale
					esac
				done ;;
			dev)
				# recreates dir structure, move headers and static libs to devx dir
				rm -rf $DEVX_DIR
				find $CHROOT_DIR -type d | sed "s|$CHROOT_DIR|$DEVX_DIR|" | xargs -I '{}' mkdir -p '{}'
				rm -rf $DEVX_DIR/usr/include; mv $CHROOT_DIR/usr/include $DEVX_DIR/usr
				find $CHROOT_DIR -name "*.a" -type f | while read -r pp; do
					mv "$pp" $DEVX_DIR/"${pp#$CHROOT_DIR/}"
				done

				# clean up empty dirs
				find $DEVX_DIR -type d | sort -r | xargs rmdir 2>/dev/null ;;
		esac
	done
}


######## commands handler ########

###
# $1-force PKGFILE PKG PKGVER PKGPRIO ARCH
do_install() { bootstrap_install; } # enable bootstrap installer by default
install_pkg() {
	if ! is_already_installed $PKG || [ "$1" = force ]; then
		echo Installing "$PKGFILE" ... 
		do_install 
	fi
}
### choice of bootstrap or dpkg 
dpkg_install() {
	dpkg --root=$CHROOT_DIR --admindir=$CHROOT_DIR/$ADMIN_DIR --force-all --unpack "$REPO_DIR/$PKGFILE";
	return 0
}
### choice of bootstrap or dpkg 
dpkgchroot_install() {
	! [ -d $CHROOT_DIR/tmp ] && mkdir -p $CHROOT_DIR/tmp
	cp "$REPO_DIR/$PKGFILE" $CHROOT_DIR/tmp
	chroot $CHROOT_DIR /usr/bin/dpkg --force-all --unpack /tmp/"$PKGFILE"
	rm -f $CHROOT_DIR/tmp/"$PKGFILE"
	return 0
}
bootstrap_install() {
	local data decompressor
	if [ -z "$WITHOUT_DPKG" ]; then
		dpkg-deb -X "$REPO_DIR/$PKGFILE" $CHROOT_DIR
	else
		data=$(ar t "$REPO_DIR/$PKGFILE" | grep data)
		case $data in
			*xz) decompressor="unxz -c" ;;
			*gz) decompressor="gunzip -c" ;;
			*bz2) decompressor="bunzip2 -c" ;;
			*lzma) decompressor="unlzma -c" ;;
		esac
		ar p "$REPO_DIR/$PKGFILE" $data | $decompressor | tar -xv -C $CHROOT_DIR
	fi |
	sed '1 s|^.*$|/.|; s|^\.||' > "$CHROOT_DIR/$ADMIN_DIR/info/${PKG}.list" &&
	update_pkg_status "$PKG" "$PKGPRIO" "$PKGSECTION" "$PKGVER" "$PKGDEP"
}
# $1-PKG $2-PKGPRIO $3-PKGSECTION $4-PKGVER $5-PKGDEP
update_pkg_status() {
	{
echo \
"Package: $1
Status: install ok installed
Priority: $2
Section:  $3
Maintainer: unspecified
Architecture: $ARCH
Version: $4"
[ "${5%,}" ] && echo "Depends: ${5%,}" 
echo "Description: $1 installed by deb-build.sh
"
	} >> "$CHROOT_DIR/$ADMIN_DIR/status"

}

# $1-dir to install $2-name $3-category
install_from_dir() {
	local pkgname=${DISTRO_PREFIX}-$2
	! [ -d ${1} ] && echo $2 not found ... && return 1 # dir doesn't exist
	is_already_installed $pkgname && return 1

	echo "/." > "$CHROOT_DIR/$ADMIN_DIR/info/${pkgname}.list"
	cp -av --remove-destination "${1}"/* $CHROOT_DIR | sed "s|.*${CHROOT_DIR}||; s|'\$||" \
	>> "$CHROOT_DIR/$ADMIN_DIR/info/${pkgname}.list"
	[ -f "$CHROOT_DIR"/pinstall.sh ] && ( cd "$CHROOT_DIR"; sh pinstall.sh )
	rm -f $CHROOT_DIR/pinstall.sh
	update_pkg_status "$pkgname" "required" "$3" "1.0" ""
	return 0
}

# $@ dirs to import
import_dir() {
	while [ "$1" ]; do
		[ -d "$1" ] && echo "Importing $1 ..." && cp -a "$1"/* $CHROOT_DIR
		shift
	done
}

###
# $@-pkg to remove
remove_pkg() {
	while [ "$1" ]; do
		if [ -z "$WITHOUT_DPKG" ]; then
			dpkg --root=$CHROOT_DIR --admindir=$CHROOT_DIR/$ADMIN_DIR --force-all -P "$1"
		else
			# manual removal - first remove entries from status
			sed -i -e "/^Package: ${1}\$/,/^$/d" "$CHROOT_DIR/$ADMIN_DIR/status"

			# then delete installed files
			if [ -e "$CHROOT_DIR/$ADMIN_DIR/info/${1}.list" ]; then
				< "$CHROOT_DIR/$ADMIN_DIR/info/${1}.list" sort -r |
				> /tmp/removepkg.$$ awk -v chroot="$CHROOT_DIR" '$0=="/." {next} { printf("%s%s\0",chroot,$0)}'
				< /tmp/removepkg.$$ xargs -0 rm -f 2>/dev/null
				< /tmp/removepkg.$$ xargs -0 rmdir 2>/dev/null
				rm -f /tmp/removepkg.$$
			fi

			# then remove all database files
			rm -f "$CHROOT_DIR/$ADMIN_DIR/info/${1}".* 2>/dev/null
		fi
		shift
	done
}

###
# $@-pkg to lock
lock_pkg() {
	if [ $WITHOUT_DPKG ]; then
		# dpkg-less lock method
		while [ "$1" ]; do
			sed -i -e "/^Package: ${1}\$/,/^$/ {/^Status:/ s/install/hold/}" "$CHROOT_DIR/$ADMIN_DIR/status"	
			shift
		done
	else
		# use dpkg to lock it
		while [ "$1" ]; do
			echo "$1" hold
			shift
		done | dpkg --root=$CHROOT_DIR --admindir=$CHROOT_DIR/$ADMIN_DIR --set-selections
	fi
}

### so that apt-get is happy
# $1 dummy pkgname. Note dependencies of dummy packages are not pulled.
install_dummy() {
	while [ "$1" ]; do
		get_pkg_info "$1"; shift
		[ -z $PKG ] && continue
		is_already_installed $PKG && continue
		echo Installing dummy for $PKG ...
		echo "/." > "$CHROOT_DIR/$ADMIN_DIR/info/${PKG}.list"
		update_pkg_status "$PKG" "$PKGPRIO" "$PKGSECTION" "$PKGVER" ""
	done
}

###
# $1-if "nousr", then don't use /usr
# note: busybox must be static and compiled with applet list
install_bb_links() {
	is_already_installed bblink && return
	local nousr=""
	case $1 in
		nousr|nouser) nousr=usr/ ;;
	esac
	
	echo "/." > "$CHROOT_DIR/$ADMIN_DIR/info/bblinks.list"
	if [ -e $CHROOT_DIR/bin/busybox ] && $CHROOT_DIR/bin/busybox > /dev/null; then
		$CHROOT_DIR/bin/busybox --list-full | while read -r p; do
			pp=${p#$nousr}
			[ -e $CHROOT_DIR/$pp ] && continue # don't override existing binaries
			echo /$pp >> "$CHROOT_DIR/$ADMIN_DIR/info/bblinks.list"
			case $pp in 
				usr*) ln -s ../../bin/busybox $CHROOT_DIR/$pp 2>/dev/null ;; 
				*)    ln -s ../bin/busybox $CHROOT_DIR/$pp 2>/dev/null ;; 
			esac
		done
	fi
	update_pkg_status "bblinks" "required" "core" "1.0" ""	
}

###
# $1-output $2 onwards - squashfs_param
make_sfs() {
	local output="$1" dir=${1%/*}
	shift
	[ "$dir" ] && [ "$dir" != "$output" ] && mkdir -p $dir
	echo $DISTRO_VERSION > $CHROOT_DIR/etc/${DISTRO_PREFIX}-version
	mksquashfs $CHROOT_DIR "$output" -noappend "$@"
	padsfs "$output"
}
padsfs() {
	ORIGSIZE=$(stat -c %s "$1")
	BLOCKS256K=$(( ((ORIGSIZE/1024/256)+1) ))
	dd if=/dev/zero of="$1" bs=256K seek=$BLOCKS256K count=0
}


######## pkglist parser ########

###
# $1-pkglist, output std
flatten_pkglist() {
	local pkglist="$1"
	while read -r pp; do
		p=${pp%%#*}; eval set -- $p; p="$1"
		[ -z $p ] && continue
		
		# commands
		case $p in
			%exit) break ;;
			%include)
				[ "$2" ] && flatten_pkglist "$2" ;;
			%dpkg|%dpkgchroot|%bootstrap|%bblinks|%makesfs|%remove|%addbase|%addpkg|%dummy|%dpkg_configure|%lock|%cutdown|%import)
				echo "$pp" ;;
			%symlink|%rm|%mkdir|%touch|%chroot)
				echo "$pp" ;;
			%depend)
				track_dependency() { list_dependency; } ;;
			%nodepend)
				track_dependency() { :; } ;;
			%pkgs_by_priority)
				shift # $1-priority $2-inclusion list $3-exclusion list
				get_pkgs_by_priority "$@" > /tmp/prio.$1.$$
				flatten_pkglist /tmp/prio.$1.$$
				rm -f /tmp/prio.$1.$$ ;;
			%repo)
				shift # $1-url $2-version $3-repos to use $4-pkgdb
				add_repo "$@" 1>&2 ;;
			%reinstall)
				shift # $1-pkgname ...
				while [ "$1" ]; do echo "$1" force; shift; done ;;
			*) # anything else
				if ! grep -m1 -q "^${p}$" $TRACKER; then
					get_pkg_info "$p"
					echo $p >> $TRACKER
					track_dependency
					echo $p
				fi ;;			
		esac
	done < $pkglist
	return 0
}
# dependency tracker
track_dependency() { :; } # default is no dependency tracking
list_dependency() {
	[ -z "$PKGDEP" ] && return
	local depfile=$(mktemp -p /tmp dep.XXXXXXXX)
	echo $PKGDEP | tr ',' '\n' | while read -r p; do
		[ -z "$p" ] && continue
		! grep -m1 -q "^${p}$" $TRACKER && echo $p
	done > $depfile
	[ -s $depfile ] && ( flatten_pkglist $depfile; )
	rm -f $depfile 
}

###
# $1-pkglist
process_pkglist() {
	# count
	local pkglist="$1" COUNT=$(wc -l < "$1") COUNTER=0
	
	# process
	while read -r p; do
		p=${p%%#*}; eval set -- $p; p="$1"
		[ -z $p ] && continue
		
		# commands
		COUNTER=$((COUNTER+1))		
		echo $COUNTER of $COUNT "$@"		
		case $p in
			%exit) break ;;
			%dpkg)
				echo Switching to dpkg
				[ -z "$WITHOUT_DPKG" ] && do_install() { dpkg_install; } ||
				do_install() { dpkgchroot_install; } ;;
			%dpkgchroot)
				echo Switching to dpkgchroot
				do_install() { dpkgchroot_install; } ;;
			%bootstrap)
				echo Switching to bootstrap
				do_install() { bootstrap_install; } ;;
			%bblinks)
				shift # $1-nousr
				echo Installing busybox symlinks ...
				install_bb_links "$@" ;;
			%makesfs)
				shift # $1-output $@-squashfs params
				echo Creating $1 ...
				make_sfs "$@" ;;
			%remove)
				shift # $1-pkgname, pkgname, ...
				remove_pkg "$@" ;;
			%addbase)
				echo Installing base rootfs ...
				[ "$BASE_ARCH_PATH" ] && install_from_dir $BASE_ARCH_PATH base-arch core				
				install_from_dir $BASE_CODE_PATH base core ;;
			%addpkg)
				shift # $1-pkgname, pkgname ...
				while [ "$1" ]; do
					! [ -d $EXTRAPKG_PATH/$1 ] && shift && continue
					echo Installing extra package "$1"  ...
					install_from_dir $EXTRAPKG_PATH/$1 $1 optional
					shift
				done ;;
			%dummy)
				shift # $1-pkgname, pkgname ...
				install_dummy "$@" ;;
			%dpkg_configure)
				shift # $@-configure flags
				DEBIAN_FRONTEND=noninteractive chroot $CHROOT_DIR /usr/bin/dpkg --configure "$@" ;;
			%lock)
				shift # $1-pkgname, pkgname ...
				lock_pkg "$@" ;;
			%cutdown)
				shift # $@ various cutdown options
				cutdown "$@" ;;
			%import)
				shift # $@ dirs to import
				import_dir "$@" ;;
				
			### filesystem operations
			%symlink)
				shift # $1 source $2 target
				rm -f $CHROOT_DIR/$2
				ln -s $1 $CHROOT_DIR/$2
				;;
			%rm)
				shift # $@ files to remove
				while [ "$1" ]; do
					rm -rf $CHROOT_DIR/$1
					shift
				done
				;;
			%mkdir)
				shift # $@ dirs to make
				while [ "$1" ]; do
					mkdir -p $CHROOT_DIR/$1
					shift
				done
				;;
			%touch)
				shift # $@ files to create
				while [ "$1" ]; do
					> $CHROOT_DIR/$1
					shift
				done
				;;
			%chroot)
				shift # $@ commands
				chroot $CHROOT_DIR "$@"
				;;

			# anything else - install package
			*)
				get_pkg_info $p
				[ -z "$PKG" ] && echo Cannot find ${p}. && continue
				download_pkg || { echo Download $p failed. && exit 1; }
				install_pkg "$2" || { echo Installation of $p failed. && exit 1; }			
				;;
		esac		
	done < $pkglist
	return 0
}

sanity_check() {
	if [ -z "$WITHOUT_DPKG" ]; then
		! dpkg-deb --help 2>&1 | grep -q -- -X && WITHOUT_DPKG=1
		! dpkg --help 2>&1 | grep -q root && WITHOUT_DPKG=1
		[ "$WITHOUT_DPKG" ] && echo "Bad dpkg/dpkg-deb found, will attempt to build without one."
	fi
	if [ -z "$WITHOUT_DPKG" ]; then
		! type ar > /dev/null && echo "Missing ar, please install first (may be from devx?)." && exit	
	fi
}

params() {
	case "$1" in
		--help|-h) echo "Usage: ${0##*/} [--help|-h|pkglist]" && exit ;;
		"") ;;
		*) PKGLIST="$1"
	esac
}

### main
params "$@"
sanity_check
prepare_dirs
add_multiple_repos $DEFAULT_REPOS
echo Flattening $PKGLIST ...
flatten_pkglist $PKGLIST > $FLATTEN
if [ -z "$DRY_RUN" ]; then
	process_pkglist $FLATTEN
else
	cat $FLATTEN
fi
