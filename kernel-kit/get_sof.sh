#!/bin/sh -xe

[ -d sof-bin ] || git clone https://github.com/thesofproject/sof-bin
cd sof-bin
ver=`git describe --abbrev=0 --tags`
mkdir -p "$1/lib/firmware/intel"
cp -r $ver*/sof-$ver "$1/lib/firmware/intel/"
ln -s sof-$ver "$1/lib/firmware/intel/sof"
cp -r $ver*/sof-tplg-$ver "$1/lib/firmware/intel/"
ln -s sof-tplg-$ver "$1/lib/firmware/intel/sof-tplg"
mkdir -p "$1/usr/share/doc/sof-bin"
cp -f LICENCE.* Notice.* "$1/usr/share/doc/sof-bin/"

strings -a `find "$2" -type f -name 'snd-*.ko'` | grep ^sof- | sort | uniq > /tmp/sofstrings
find "$1/lib/firmware/intel/sof-$ver" "$1/lib/firmware/intel/sof-tplg-$ver" -type f -name 'sof-*.*' | while read F; do
	fgrep -qlm1 ${F##*/} /tmp/sofstrings || rm -f $F
done
rm -f /tmp/sofstrings