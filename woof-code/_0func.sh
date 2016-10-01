#!/bin/sh
# common functions

function source_compat_repos() {
	if [ -f ./DISTRO_COMPAT_REPOS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} ];then
		. ./DISTRO_COMPAT_REPOS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}
	else
		. ./DISTRO_COMPAT_REPOS-${DISTRO_BINARY_COMPAT}
	fi
}

function source_pkgs_specs() {
	if [ -f ./DISTRO_PKGS_SPECS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} ];then #w478
		. ./DISTRO_PKGS_SPECS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} #has FALLBACKS_COMPAT_VERSIONS
	else
		. ./DISTRO_PKGS_SPECS-${DISTRO_BINARY_COMPAT} #has FALLBACKS_COMPAT_VERSIONS
	fi
}

function source_woofmergevars() {
	if [ -f WOOFMERGEVARS ];then
		. ./WOOFMERGEVARS #has variables WOOF_HOSTARCH, WOOF_TARGETARCH, WOOF_COMPATDISTRO, WOOF_COMPATVERSION
	else
		echo 'File WOOFMERGEVARS does not exist. This is created by script
	merge2out. Your setup is wrong, quiting.'
		exit 1
	fi
}

function set_binaries_var() {
	BINARIES='deb' #download to packages-deb.
	[ "$DISTRO_BINARY_COMPAT" = "slackware" ] && BINARIES="tgz_txz" #100617 download to packages-tgz_txz-${DISTRO_COMPAT_VERSION}.
	[ "$DISTRO_BINARY_COMPAT" = "slackware64" ] && BINARIES="tgz_txz" #140716 download to packages-tgz_txz-${DISTRO_COMPAT_VERSION}.
	[ "$DISTRO_BINARY_COMPAT" = "debian" ] && BINARIES="deb" #download to packages-deb-${DISTRO_COMPAT_VERSION}.
	[ "$DISTRO_BINARY_COMPAT" = "devuan" ] && BINARIES="deb" #download to packages-deb-${DISTRO_COMPAT_VERSION}.
	[ "$DISTRO_BINARY_COMPAT" = "gentoo" ] && BINARIES="gentoo" #120515 download to packages-gentoo-gap6
	[ "$DISTRO_BINARY_COMPAT" = "raspbian" ] && BINARIES="deb_raspbian" #download to packages-deb_raspbian-${DISTRO_COMPAT_VERSION}.
	BINARIES="${BINARIES}-${DISTRO_COMPAT_VERSION}" #w478
}

function set_archdir_var() {
	#debian and derivatives: wheezy and later
	#ubuntu and derivatives: precise and later
	ARCHDIR=''
	case $WOOF_COMPATDISTRO in raspbian|debian|devuan|ubuntu|trisquel)
		case $WOOF_TARGETARCH in #see file WOOFMERGEVARS
			x86) ARCHDIR='i386-linux-gnu' ;;
			x86_64) ARCHDIR='x86_64-linux-gnu' ;;
			arm) ARCHDIR='arm-linux-gnueabihf' ;;
		esac
	esac
}

function run_findpkgs() {
	#new script to find all pkgs for build...
	./support/findpkgs
	#...returns file status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}
	# each line is full db entry for pkg, prefixed with :generic-name:, pet/compat and repo-filename.
	# ex: :a52dec:|compat|Packages-puppy-wary5-official|a52dec-0.7.4-w5|a52dec|0.7.4-w5||BuildingBlock|68K||a52dec-0.7.4-w5.pet||A free ATSC A52 stream decoder|puppy|wary5||
	if [ $? -ne 0 ];then
		echo
		echo "ERROR: Script support/findpkgs aborted with an error, exiting."
		exit 1
	fi
	if [ ! -f status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} ];then
		echo
		echo "ERROR: Something went wrong with support/findpkgs, exiting."
		exit 1
	fi
}

### END ###
