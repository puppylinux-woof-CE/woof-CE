#!/bin/sh

ICONREPO=$1
ICONSET=$2

[ -z "$ICONREPO" ] && exit 1
[ -z "$ICONSET" ] && exit 1

SITE=https://github.com
#GUSER=puppylinux-woof-CE
GUSER=01micko
ICO_PKG=${ICONSET}.tar.xz
ICO_DIR=${ICO_PKG%%\.*}
DLD="${SITE}/${GUSER}/${ICONREPO}/releases/latest/download/$ICO_PKG"

# download
. ./DISTRO_SPECS
mkdir -p ../local-repositories/icons
mkdir -p ./icons-latest/${ICO_DIR}
if ! [ -e "../local-repositories/icons/${ICO_PKG}" ] && ! [ -e "../local-repositories/icons/${ICO_PKG}.sha256.txt" ];then
	wget -t 3 -T 10 -q $DLD -P ../local-repositories/icons
	wget -t 3 -T 10 -q ${DLD}.sha256.txt -P ../local-repositories/icons
fi
# extract to rootfs-complete
[ -e "../local-repositories/icons/${ICO_PKG}" ] && \
	sha256sum ../local-repositories/icons/${ICO_PKG}.sha256.txt || exit 1 
tar xJf "../local-repositories/icons/${ICO_PKG}" -C ./icons-latest/${ICO_DIR} || exit 1
(echo -n ":${ICO_DIR}:|pet|github|"; cat ./icons-latest/${ICO_DIR}/pet.specs) >> ./status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}
echo -n "${ICO_DIR} " >> /tmp/icon-packages
echo >> /tmp/icon-packages # newline
rm -rf ./packages-${DISTRO_FILE_PREFIX}/${ICO_DIR}
mv -f ./icons-latest/${ICO_DIR} ./packages-${DISTRO_FILE_PREFIX}/
exit 0
