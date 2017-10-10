#!/bin/bash
## You can manually add an alternative kernel to the puppy cd.
## Just run this script and add the 'altkernel' dir to the target ISO with ISO Master

## uncomment URL=... and specify a link to the desired huge_kernel tarball
## you can place the tarball in the current dir and the script will not download it

#URL=http://distro.ibiblio.org/puppylinux/huge_kernels/huge-3.4.103-tahr_nopae.tar.bz2

#=====================================================================================

#command line
if [ "$1" != "" ] ; then
	URL=$1
fi

[ -z $URL ] && exit 1

if touch ____aaaaa_____ &>/dev/null ; then
	rm -f ____aaaaa_____
else
	echo "Need write access to $PWD"
	exit 1
fi

file="$(basename "$URL")"

mkdir -p altkernel

DOWNLOAD_TARBALL=1
if [ -f "$file" ] ; then
	echo "* Verifying $file"
	tar -taf "$file" &>/dev/null && DOWNLOAD_TARBALL=0
fi

if [ $DOWNLOAD_TARBALL -eq 1 ] ; then
	wget -c --no-check-certificate "$URL"
	echo "* Verifying $file"
	tar -taf "$file" &>/dev/null || exit 1
fi

echo "* Extracting $file to altkernel"
tar --directory=altkernel -xaf "$file" || exit 1

kernel_ver=$(echo "$file" | cut -f2 -d '-')

mv -f altkernel/kernel-modules.sfs-* altkernel/zdrv.sfs
mv -f altkernel/vmlinuz-* altkernel/vmlinuz
echo "$URL" > altkernel/origin.txt
echo "$kernel_ver" > altkernel/kernel_ver.txt

if [ -z "$BUILDSYS" ] ; then
	isomaster &
	sleep 1
	echo
	echo "Done !"
	echo "Now with 'ISO Master', add the 'altkernel' directory to the target ISO"
fi

### END ###
