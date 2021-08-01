#!/bin/sh

ICONREPO=$1

[ -z "$ICONREPO" ] && exit 1

SITE=https://github.com
#GUSER=puppylinux-woof-CE
GUSER=01micko
RLSE=$(curl -s ${SITE}/${GUSER}/${ICONREPO}/releases | grep -o "\/${GUSER}.*\.tar\.xz" | head -n1) # gets latest
ICO_PKG=${RLSE##*/}
ICO_DIR=${ICO_PKG%%\.*}
[ -z "$RLSE" ] && exit 1 
DLD="${SITE}${RLSE}"

# download
. ./DISTRO_SPECS
mkdir -p ../local-repositories/icons
mkdir -p $MWD/icons-latest/${ICO_DIR}
wget -t 1 -T 10 -q $DLD -P ../local-repositories/icons
wget -t 1 -T 10 -q ${DLD}.sha256.txt -P ../local-repositories/icons
# extract to rootfs-complete
[ -e "../local-repositories/icons/${ICO_PKG}" ] && \
	sha256sum ../local-repositories/icons/${ICO_PKG}.sha256.txt || exit 1 
tar xJf "../local-repositories/icons/${ICO_PKG}" -C ./icons-latest/${ICO_DIR} || exit 1
(echo -n ":${ICO_DIR}:|pet|github|"; cat ./icons-latest/${ICO_DIR}/pet.specs) >> ./status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}
echo -n "${ICO_DIR} " >> /tmp/icon-packages
echo >> /tmp/icon-packages # newline
rm -rf ./packages-${DISTRO_FILE_PREFIX}/${ICO_DIR}
mv -f ./icons-latest/${ICO_DIR} ./packages-${DISTRO_FILE_PREFIX}/
rm -f ../local-repositories/icons/${ICO_PKG}* # delete
exit 0
