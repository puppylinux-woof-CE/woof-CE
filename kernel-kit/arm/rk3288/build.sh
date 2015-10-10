#!/bin/sh -x

. ./build.conf

TODAY=`date +%d%m%y`
MAKE="make $JOBS"

build() {
	if [ -f dist/sources/vanilla/chromiumos_kernel-chromeos-3.14-git$TODAY.tar.gz ]
	then
		tar -xzvf dist/sources/vanilla/chromiumos_kernel-chromeos-3.14-git$TODAY.tar.gz
	else
		git clone --depth 1 -b chromeos-3.14 https://chromium.googlesource.com/chromiumos/third_party/kernel chromiumos_kernel-chromeos-3.14-git$TODAY
		tar -c chromiumos_kernel-chromeos-3.14-git$TODAY | gzip -1 > dist/sources/vanilla/chromiumos_kernel-chromeos-3.14-git$TODAY.tar.gz
	fi

	if [ -f dist/sources/vanilla/aufs3-standalone-aufs3.14-git$TODAY ]
	then
		tar -xzvf dist/sources/vanilla/aufs3-standalone-aufs3.14-git$TODAY.tar.gz
	else
		git clone --depth 1 -b aufs3.14 git://git.code.sf.net/p/aufs/aufs3-standalone aufs3-standalone-aufs3.14-git$TODAY
		tar -c aufs3-standalone-aufs3.14-git$TODAY | gzip -1 > dist/sources/vanilla/aufs3-standalone-aufs3.14-git$TODAY.tar.gz
	fi

	[ ! -f dist/sources/vanilla/deblob-3.14 ] && wget -O dist/sources/vanilla/deblob-3.14 http://linux-libre.fsfla.org/pub/linux-libre/releases/LATEST-3.14.N/deblob-3.14
	[ ! -f dist/sources/vanilla/deblob-check ] && wget -O dist/sources/vanilla/deblob-check http://linux-libre.fsfla.org/pub/linux-libre/releases/LATEST-3.14.N/deblob-check

	export WIFIVERSION=-3.8
	if [ "`uname -m`" != "armv7l" ]
	then
		export ARCH=arm
		export CROSS_COMPILE=arm-linux-gnueabihf-
	fi

	cd chromiumos_kernel-chromeos-3.14-git$TODAY

	# clean the sources tree
	$MAKE clean
	$MAKE mrproper

	# deblob the kernel
	chmod 755 ../dist/sources/vanilla/deblob-3.14
	../dist/sources/vanilla/deblob-3.14 --force

	# reset the minor version, remove the -gnu version suffix and append the
	# custom suffix
	cp -f Makefile Makefile-orig
	sed -i "s/^SUBLEVEL =.*/SUBLEVEL =/" Makefile
	sed -i "s/^EXTRAVERSION =.*/EXTRAVERSION = $custom_suffix/" Makefile
	diff -up Makefile-orig Makefile > ../dist/sources/patches/version.patch
	rm -f Makefile-orig

	# add Aufs
	for i in kbuild base standalone mmap
	do
		patch -N -p1 < ../aufs3-standalone-aufs3.14-git$TODAY/aufs3-$i.patch
	done
	cp -rf ../aufs3-standalone-aufs3.14-git$TODAY/fs .
	cp -f ../aufs3-standalone-aufs3.14-git101015/include/uapi/linux/aufs_type.h include/uapi/linux/

	# build the kernel
	cp ../DOTconfig .config
	$MAKE zImage modules dtbs

	# install the kernel modules
	make INSTALL_MOD_PATH=../dist/packages/linux_kernel-3.14-git$TODAY$package_name_suffix
	mkdir ../dist/packages/linux_kernel-3.14-git$TODAY$package_name_suffix/boot

	# pack the kernel image
	export PATH="`pwd`:$PATH"
	mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg
	dd if=/dev/zero of=bootloader.bin bs=512 count=1
	vbutil_kernel --pack ../dist/packages/linux_kernel-3.14-git$TODAY$package_name_suffix/boot/vmlinux.kpart --version 1 --vmlinuz vmlinux.uimg --arch arm --config ../cmdline --bootloader bootloader.bin --keyblock /usr/share/vboot/devkeys/kernel.keyblock --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk
}

cleanup() {
	rm -rf aufs3-standalone-aufs3.14-git* chromiumos_kernel-chromeos-3.14-git*
}

trap cleanup EXIT
trap cleanup TERM
trap cleanup INT

if [ "$1" = "clean" ]
then
	rm -rf dist/sources/*/* dist/packages/* dist/sources/build.log
else
	build 2>&1 | tee dist/sources/build.log
fi
