#!/bin/sh -e

debootstrap=`command -v debootstrap || :`
if [ -z "$debootstrap" ]; then
	echo "WARNING: debootstrap is missing"
	[ -z "$GITHUB_ACTIONS" ] || exit 1
	exit 0
fi

. ../DISTRO_SPECS
. ../_00build.conf
[ ! -e ../_00build_2.conf ] || . ../_00build_2.conf

case "$DISTRO_TARGETARCH" in
x86_64) ARCH=amd64 ;;
x86) ARCH=i386  ;;
arm) ARCH=armhf ;;
arm64) ARCH=aarch64 ;;
esac

export LD_LIBRARY_PATH=
export DEBIAN_FRONTEND=noninteractive

# create a tiny Debian installation
if [ "$USR_SYMLINKS" = "yes" ]; then
	$debootstrap --arch=$ARCH --variant=minbase ${DISTRO_COMPAT_VERSION} bdrv http://deb.debian.org/debian
else
	$debootstrap --no-merged-usr --arch=$ARCH --variant=minbase ${DISTRO_COMPAT_VERSION} bdrv http://deb.debian.org/debian
fi

# make sure UIDs and GIDs are consistent with Puppy
cat rootfs-complete/etc/group > bdrv/etc/group
cat rootfs-complete/etc/passwd > bdrv/etc/passwd
cat rootfs-complete/etc/shadow > bdrv/etc/shadow

# blacklist packages that may conflict with packages in the main SFS
chroot bdrv apt-mark hold busybox
chroot bdrv apt-mark hold busybox-static

mount --bind /etc/resolv.conf bdrv/etc/resolv.conf
trap "umount -l bdrv/etc/resolv.conf" INT ERR

# configure the package manager
echo "deb http://deb.debian.org/debian ${DISTRO_COMPAT_VERSION} main contrib non-free" > bdrv/etc/apt/sources.list
if [ "$DISTRO_COMPAT_VERSION" != "sid" ]; then
	cat << EOF >> bdrv/etc/apt/sources.list
deb http://deb.debian.org/debian ${DISTRO_COMPAT_VERSION}-updates main contrib non-free
deb http://deb.debian.org/debian-security ${DISTRO_COMPAT_VERSION}-security main contrib non-free
EOF
fi
cat << EOF > bdrv/etc/apt/apt.conf.d/00puppy
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
chroot bdrv apt-get update

# install all packages included in the woof-CE build
chroot bdrv apt-get install -y `cat ../status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} | cut -f 5 -d \| | tr '\n' ' '`

# add Synaptic
chroot bdrv apt-get install -y synaptic
sed -e 's/^Categories=.*/Categories=X-Setup-puppy/' -i bdrv/usr/share/applications/synaptic.desktop

umount -l bdrv/etc/resolv.conf

# remove any unneeded packages
chroot bdrv apt-get autoremove -y --purge

# prevent updates
chroot bdrv apt-mark hold `chroot bdrv dpkg-query -f '${binary:Package}\n' -W | tr '\n' ' '`

# remove unneeded files
chroot bdrv apt-get clean
rm -f bdrv/var/lib/apt/lists/* 2>/dev/null || :
rm -rf bdrv/home bdrv/root bdrv/dev bdrv/run bdrv/var/log bdrv/var/cache/man bdrv/var/cache/fontconfig bdrv/var/cache/ldconfig bdrv/etc/ssl bdrv/lib/udev bdrv/lib/modprobe.d bdrv/lib/firmware bdrv/usr/share/mime bdrv/etc/ld.so.cache bdrv/usr/bin/systemctl bdrv/usr/bin/systemd-analyze bdrv/usr/bin/systemctl bdrv/usr/lib/systemd/systemd-networkd bdrv/usr/lib/systemd/systemd bdrv/usr/lib/systemd/systemd-journald bdrv/usr/share/fonts
rm -rf `find bdrv -name __pycache__`
for ICONDIR in bdrv/usr/share/icons/*; do
	[ "$ICONDIR" != "bdrv/usr/share/icons/hicolor" ] || continue
	rm -rf "$ICONDIR"
done

# remove all duplicates and files that may conflict with the main SFS
find bdrv | tac | while read FILE; do
	RELPATH=${FILE#bdrv/}
	[ -e "rootfs-complete/$RELPATH" ] || continue

	if [ -L "bdrv/$RELPATH" -o -f "bdrv/$RELPATH" ]; then
		rm -f "bdrv/$RELPATH"
	elif [ -d "bdrv/$RELPATH" ]; then
		rmdir "bdrv/$RELPATH" 2>/dev/null || :
	fi
done

# delete files and directories present in the main SFS
cat ../status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} | cut -f 5 -d \| | while read NAME; do
	LIST=bdrv/var/lib/dpkg/info/$NAME:$ARCH.list
	[ -f "$LIST" ] || LIST=bdrv/var/lib/dpkg/info/$NAME.list

	while read FILE; do
		[ -d "bdrv/$FILE" ] || rm -f "bdrv/$FILE" 2>/dev/null
	done < $LIST

	while read FILE; do
		[ ! -d "bdrv/$FILE" ] || rmdir "bdrv/$FILE" 2>/dev/null || :
	done < $LIST
done