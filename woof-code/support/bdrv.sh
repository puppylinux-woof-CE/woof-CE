#!/bin/sh -e

. ../DISTRO_SPECS
. ../_00build.conf
[ ! -e ../_00build_2.conf ] || . ../_00build_2.conf

debootstrap=`command -v debootstrap || :`
if [ -z "$debootstrap" ]; then
	echo "WARNING: debootstrap is missing"
	[ -z "$GITHUB_ACTIONS" ] || exit 1
	exit 0
fi

case "$DISTRO_TARGETARCH" in
x86_64) ARCH=amd64 ;;
x86) ARCH=i386  ;;
arm) ARCH=armhf ;;
arm64) ARCH=aarch64 ;;
*) exit 1 ;;
esac

case "$DISTRO_BINARY_COMPAT" in
debian) MIRROR=http://deb.debian.org/debian ;;
devuan) MIRROR=http://deb.devuan.org/merged ;;
ubuntu) MIRROR=http://archive.ubuntu.com/ubuntu ;;
*) exit 1 ;;
esac

export LD_LIBRARY_PATH=
export DEBIAN_FRONTEND=noninteractive

CACHE_DIR=`pwd`/../../local-repositories/bdrv/${DISTRO_TARGETARCH}
mkdir -p "$CACHE_DIR"
TARBALL="${CACHE_DIR}/debootstrap-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}.tar.gz"
[ "$USR_SYMLINKS" != "yes" ] || TARBALL="${CACHE_DIR}/debootstrap-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}-usrmerge.tar.gz"

if [ "$USR_SYMLINKS" = "yes" -a ! -e ${TARBALL} ]; then
	$debootstrap --arch=$ARCH --variant=minbase --make-tarball=${TARBALL} ${DISTRO_COMPAT_VERSION} bdrv ${MIRROR}
elif [ ! -e ${TARBALL} ]; then
	$debootstrap --no-merged-usr --arch=$ARCH --variant=minbase --make-tarball=${TARBALL} ${DISTRO_COMPAT_VERSION} bdrv ${MIRROR}
fi

# create a tiny installation of the compatible distro
if [ "$USR_SYMLINKS" = "yes" ]; then
	$debootstrap --arch=$ARCH --variant=minbase --unpack-tarball=${TARBALL} ${DISTRO_COMPAT_VERSION} bdrv ${MIRROR}
else
	$debootstrap --no-merged-usr --arch=$ARCH --variant=minbase --unpack-tarball=${TARBALL} ${DISTRO_COMPAT_VERSION} bdrv ${MIRROR}
fi

# make sure UIDs and GIDs are consistent with Puppy
cat rootfs-complete/etc/group > bdrv/etc/group
cat rootfs-complete/etc/passwd > bdrv/etc/passwd
cat rootfs-complete/etc/shadow > bdrv/etc/shadow

rm -f bdrv/etc/resolv.conf
cat /etc/resolv.conf > bdrv/etc/resolv.conf

[ ! -e ${CACHE_DIR}/archives-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}.tar.gz ] || tar -C bdrv -xzf ${CACHE_DIR}/archives-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}.tar.gz

# configure the package manager
case "$DISTRO_BINARY_COMPAT" in
debian)
	echo "deb ${MIRROR} ${DISTRO_COMPAT_VERSION} main contrib non-free" > bdrv/etc/apt/sources.list

	if [ "$DISTRO_COMPAT_VERSION" != "sid" ]; then
		cat << EOF >> bdrv/etc/apt/sources.list
deb ${MIRROR} ${DISTRO_COMPAT_VERSION}-updates main contrib non-free
deb ${MIRROR}-security ${DISTRO_COMPAT_VERSION}-security main contrib non-free
EOF
	fi
	;;

devuan)
	echo "deb ${MIRROR} ${DISTRO_COMPAT_VERSION} main contrib non-free" > bdrv/etc/apt/sources.list

	if [ "$DISTRO_COMPAT_VERSION" != "ceres" ]; then
		cat << EOF >> bdrv/etc/apt/sources.list
deb ${MIRROR} ${DISTRO_COMPAT_VERSION}-updates main contrib non-free
deb ${MIRROR} ${DISTRO_COMPAT_VERSION}-security main contrib non-free
EOF
	fi
	;;

ubuntu)
	echo "deb ${MIRROR} ${DISTRO_COMPAT_VERSION} main universe multiverse restricted" > bdrv/etc/apt/sources.list

	if [ "$DISTRO_COMPAT_VERSION" != "devel" ]; then
		cat << EOF >> bdrv/etc/apt/sources.list
deb ${MIRROR} ${DISTRO_COMPAT_VERSION}-updates main universe multiverse restricted
deb ${MIRROR} ${DISTRO_COMPAT_VERSION}-security main universe multiverse restricted
EOF
	fi

	# the x86 repo is small, contains popular packages like Steam and won't make apt update 2x slower
	[ "$ARCH" != "amd64" ] || chroot bdrv dpkg --add-architecture i386
	;;
esac
cat << EOF > bdrv/etc/apt/apt.conf.d/00puppy
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
chroot bdrv apt-get update
chroot bdrv apt-get upgrade -y

# blacklist packages that may conflict with packages in the main SFS
chroot bdrv apt-mark hold busybox
chroot bdrv apt-mark hold busybox-static

# snap is broken without systemd
[ "$DISTRO_BINARY_COMPAT" = "devuan" ] || chroot bdrv apt-mark hold snapd

# install all packages that didn't get fully redirected to devx
PKGS=`cat ../status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} | cut -f 1,2,5 -d \| |
while IFS=\| read GENERICNAME TYPE NAME; do
	[ "$TYPE" = "compat" ] || continue

	case "$NAME" in
	*-dev|*-dev-bin|*-devtools|*-headers) continue ;;
	esac

	[ -d ../packages-${DISTRO_FILE_PREFIX}/${GENERICNAME//:}_DEV -a ! -e ../packages-${DISTRO_FILE_PREFIX}/${GENERICNAME//:} ] || echo "$NAME"
done`
chroot bdrv apt-get install -y $PKGS

# add missing package recommendations, Synaptic and gdebi
chroot bdrv apt-get install -y command-not-found synaptic gdebi
sed -e 's/^Categories=.*/Categories=X-Setup-puppy/' -i bdrv/usr/share/applications/synaptic.desktop
echo "NoDisplay=true" >> bdrv/usr/share/applications/gdebi.desktop

rm -f bdrv/etc/resolv.conf

cat << EOF >> bdrv/etc/apt/apt.conf.d/00puppy
# https://github.com/debuerreotype/debuerreotype/blob/6952be0a084e834bd25aa623c94f6ad342899b55/scripts/debuerreotype-minimizing-config#L88
DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb || true"; };
APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb || true"; };
EOF
tar -C bdrv -c var/cache/apt/archives | gzip -1 > ${CACHE_DIR}/archives-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}.tar.gz

# remove any unneeded packages
chroot bdrv apt-get autoremove -y --purge

# prevent updates
chroot bdrv apt-mark hold `chroot bdrv dpkg-query -f '${binary:Package}\n' -W | tr '\n' ' '`

# remove unneeded files
chroot bdrv apt-get clean
rm -f bdrv/var/lib/apt/lists/* 2>/dev/null || :
rm -rf bdrv/home bdrv/root bdrv/dev bdrv/run bdrv/var/log bdrv/var/cache/man bdrv/var/cache/fontconfig bdrv/var/cache/ldconfig bdrv/etc/ssl bdrv/lib/udev bdrv/lib/modprobe.d bdrv/lib/firmware bdrv/usr/share/mime bdrv/etc/ld.so.cache bdrv/usr/bin/systemctl bdrv/usr/bin/systemd-analyze bdrv/usr/bin/systemctl bdrv/usr/lib/systemd/systemd-networkd bdrv/usr/lib/systemd/systemd bdrv/usr/lib/systemd/systemd-journald bdrv/usr/share/fonts bdrv/etc/fonts bdrv/etc/init.d bdrv/etc/rc*.d
rm -rf `find bdrv -name __pycache__`
for ICONDIR in bdrv/usr/share/icons/*; do
	[ "$ICONDIR" != "bdrv/usr/share/icons/hicolor" ] || continue
	rm -rf "$ICONDIR"
done

# remove all duplicates and files that may conflict with the main SFS
find bdrv | tac | while read FILE; do
	RELPATH=${FILE#bdrv/}
	[ -e "rootfs-complete/$RELPATH" ] || continue

	case "$RELPATH" in
	etc/group|etc/passwd|etc/shadow) continue ;;
	esac

	if [ -L "bdrv/$RELPATH" -o -f "bdrv/$RELPATH" ]; then
		rm -f "bdrv/$RELPATH"
	elif [ -d "bdrv/$RELPATH" ]; then
		rmdir "bdrv/$RELPATH" 2>/dev/null || :
	fi
done

# delete files and directories present in the main SFS
cat ../status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} | cut -f 2,5 -d \| | while IFS=\| read TYPE NAME; do
	[ "$TYPE" = "compat" ] || continue

	LIST=bdrv/var/lib/dpkg/info/$NAME:$ARCH.list
	[ -f "$LIST" ] || LIST=bdrv/var/lib/dpkg/info/$NAME.list
	[ -f "$LIST" ] || continue

	sort -r $LIST > /tmp/$NAME-sorted.list

	while read FILE; do
		[ -d "bdrv/$FILE" ] || rm -f "bdrv/$FILE" 2>/dev/null
	done < /tmp/$NAME-sorted.list

	while read FILE; do
		[ ! -d "bdrv/$FILE" ] || rmdir "bdrv/$FILE" 2>/dev/null || :
	done < /tmp/$NAME-sorted.list

	rm -f /tmp/$NAME-sorted.list
done

# impersonate the distro we're compatible with, so tools like software-properties-gtk work
mkdir -p bdrv/usr/lib
sed "s/^ID=.*/ID=${DISTRO_BINARY_COMPAT}/" rootfs-complete/usr/lib/os-release > bdrv/usr/lib/os-release
echo "VERSION_CODENAME=${DISTRO_COMPAT_VERSION}" >> bdrv/usr/lib/os-release
chmod 644 bdrv/usr/lib/os-release

# open .deb files with gdebi
if [ -e rootfs-complete/usr/local/bin/rox ]; then
	mkdir -p bdrv/etc/xdg/rox.sourceforge.net/MIME-types
	for MIMETYPE in application_x-deb application_vnd.debian.binary-package; do
		cat << EOF > bdrv/etc/xdg/rox.sourceforge.net/MIME-types/$MIMETYPE
#!/bin/sh
exec gdebi-gtk "\$1"
EOF
		chmod 755 bdrv/etc/xdg/rox.sourceforge.net/MIME-types/$MIMETYPE
	done
fi
for DESKTOP in gpkgdialog.desktop Xpkgdialog.desktop pkgdialog.desktop petget.desktop; do
	[ -e rootfs-complete/usr/share/applications/$DESKTOP ] || continue
	(
		while read LINE; do
			case "$LINE" in
			MimeType=*) echo "MimeType=`echo "$LINE" | cut -f 2 -d = | tr ';' '\n' | grep -v deb | grep -v -E '^$' | tr '\n' ';'`" ;;
			*) echo "$LINE" ;;
			esac
		done < rootfs-complete/usr/share/applications/$DESKTOP
	) > bdrv/usr/share/applications/$DESKTOP
done
if [ -e rootfs-complete/usr/share/applications/mimeapps.list ]; then
	(
		while read LINE; do
			case "$LINE" in
			*deb*=*) echo "${LINE%=*}=gdebi.desktop" ;;
			*) echo "$LINE" ;;
			esac
		done < rootfs-complete/usr/share/applications/mimeapps.list
	) > bdrv/usr/share/applications/mimeapps.list
fi

# move large directories to docx and nlsx
mkdir -p bdrv_NLS/usr/share bdrv_DOC/usr/share
mv bdrv/usr/share/locale bdrv_NLS/usr/share/
mv bdrv/usr/share/doc bdrv/usr/share/info bdrv/usr/share/man bdrv_DOC/usr/share/
if [ -d bdrv/usr/share/gnome/help ]; then
	mkdir -p bdrv_DOC/usr/share/gnome
	mv bdrv/usr/share/gnome/help bdrv_DOC/usr/share/gnome/
	rmdir bdrv/usr/share/gnome 2>/dev/null
fi
