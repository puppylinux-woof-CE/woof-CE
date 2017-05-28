#!/bin/sh

CWD=`pwd`
echo ${CWD##*/} # prevent running from elsewhere

# see support for these vars
[ -f support/fw.conf ] && fw=support/fw.conf || fw=
[ -f support/rootfs-packages.conf ] && rfsp=support/rootfs-packages.conf || rfsp=
[ -f support/mkwall.conf ] && mkw=support/mkwall.conf || mkw=

_help() {
	xmessage -c \
	"This is a handy utility to store your woof-CE configuration.

Please setup the var 'XTRA_FLG' in '_00build.conf'
A tarball of your config files is made in the current dir.
Be careful when restoring backups as files may have changed!

PLEASE RUN THIS FROM THE COMMAND LINE!

see..
_00build.conf
DISTRO_PKGS_SPECS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}
$fw  $rfsp  $mkw

To restore a backup just extract the generated tarball in place."
	exit 0
}

echo ${CWD##*/} | grep -q '^woof-out' || _help

. ./DISTRO_SPECS 2>/dev/null
. ./_00build.conf

case "$1" in
	*h*)_help;;
esac
[ -z "$XTRA_FLG" ] && _help # make sure the clickers are ok

echo "Press Enter.."
read || _help
echo "Backing up ...
"
tar cvf z${XTRA_FLG}.tar _00build.conf \
		DISTRO_PKGS_SPECS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} \
		$fw $rfsp $mkw
					
