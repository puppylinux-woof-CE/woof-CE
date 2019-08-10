#!/bin/sh
# * called by 3builddistro
# * we're in sandbox3

. ../_00build.conf
. ../DISTRO_SPECS

if [ "$DISTRO_FILE_PREFIX" = "" ]; then
	echo "ERROR: DISTRO_FILE_PREFIX not set."
	exit 1
fi

case $DISTRO_FILE_PREFIX in
	raspup)	REALKERNAME="kernel.img" ;;
esac

mkdir -p build/boot

case $REALKERNAME in
	uImage)     cp -f build/vmlinuz build/boot/uImage ;;
	kernel.img)
		# kernel for pi zero and 1
		[ -f build/vmlinuz ] && cp -f build/vmlinuz build/boot/kernel.img
		# kernel for pi2 and 3
		[ -f build/vmlinuz7 ] && cp -f build/vmlinuz7 build/boot/kernel7.img
		# kernel for pi4
		[ -f build/vmlinuz7l ] && cp -f build/vmlinuz7l build/boot/kernel7l.img
		;;
esac

cp -f build/*.sfs build/boot/
cp -f build/initrd.[gx]z build/boot/
cp -f rootfs-complete/boot/* build/boot/ 2> /dev/null

# merge any boot-kernel_version directories into one boot directory.
for ONEDIR in build/boot-*
do
	mv -f ${ONEDIR}/overlays/* build/boot/overlays/ 2> /dev/null
	rmdir ${ONEDIR}/overlays 2> /dev/null
	mv -f ${ONEDIR}/* build/boot/
	rmdir ${ONEDIR}
done

echo -n "$REALKERNAME" > build/boot/REALKERNAME

cd build/boot
zip -r ../${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}.zip *
cd ../..
