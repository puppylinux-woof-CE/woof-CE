#!/bin/sh

ICONREPO=$1
ICONSET=$2

dld_icns() {
	wget -t 3 -T 10 -q ${1} -P ../local-repositories/icons || return 1
	wget -t 3 -T 10 -q ${1}.sha256.txt -P ../local-repositories/icons || return 1
	return 0
}

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
if [ -e "../local-repositories/icons/${ICO_PKG}" ] && [ -e "../local-repositories/icons/${ICO_PKG}.sha256.txt" ];then
	MTIME=$(date -r "../local-repositories/icons/${ICO_PKG}" "+%s")
	CURTIME=$(date +%s)
	DIFTIME=$(($CURTIME - $MTIME))
	if [ $DIFTIME -gt 345600 ];then # 4 days = 345600 seconds
		echo "deleting ${ICO_PKG} and re-downloading"
		rm -f ../local-repositories/icons/${ICO_PKG}*
		dld_icns $DLD
	else
		echo "${ICO_PKG} is still current"
	fi
else
	dld_icns $DLD
fi
# extract to rootfs-complete
[ -e "../local-repositories/icons/${ICO_PKG}" ] && \
	sha256sum ../local-repositories/icons/${ICO_PKG}.sha256.txt >/dev/null 2>&1 || exit 1 # suppress output
tar xJf "../local-repositories/icons/${ICO_PKG}" -C ./icons-latest/${ICO_DIR} || exit 1
echo -n "${ICO_DIR} " >> /tmp/icon-packages
rm -rf ./packages-${DISTRO_FILE_PREFIX}/${ICO_DIR}
mv -f ./icons-latest/${ICO_DIR} ./packages-${DISTRO_FILE_PREFIX}/
exit 0
