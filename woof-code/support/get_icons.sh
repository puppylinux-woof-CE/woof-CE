#!/bin/sh

ICONREPO=$1

[ -z "$ICONREPO" ] && exit 1

SITE=https://github.com
#GUSER=puppylinux-woof-CE
GUSER=01micko
RLSE=$(curl -s ${SITE}/${GUSER}/${ICONREPO}/releases | grep -o "\/${GUSER}.*\.tar\.xz" | head -n1) # gets latest
ICO_PKG=${RLSE##*/}
[ -z "$RLSE" ] && exit 1 
DLD="${SITE}${RLSE}"

# download
mkdir -p ../local-repositories/icons
wget -t 1 -T 10 -q $DLD -P ../local-repositories/icons
wget -t 1 -T 10 -q ${DLD}.sha256.txt -P ../local-repositories/icons
# extract to rootfs-complete
[ -e "../local-repositories/icons/${ICO_PKG}" ] && \
	sha256sum ../local-repositories/icons/${ICO_PKG}.sha256.txt || exit 1 
tar xJf "../local-repositories/icons/${ICO_PKG}" -C $MWD/sandbox3/rootfs-complete || exit 1
[ -e "$MWD/sandbox3/rootfs-complete/pet.specs" ] && \
	cat $MWD/sandbox3/rootfs-complete/pet.specs >> /tmp/rootfs-packages.specs
rm -f ../local-repositories/icons/${ICO_PKG} # delete
exit 0
