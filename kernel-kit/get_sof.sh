#!/bin/sh -xe

[ -d sof-bin ] || git clone https://github.com/thesofproject/sof-bin
cd sof-bin
ver=`git describe --abbrev=0 --tags`
git checkout $ver
mkdir -p "$1/lib/firmware/intel"
verfile=`ls */$ver`
[ -n "$verfile" ] || exit 1
verdir=`dirname $verfile`
cp -r $verdir/sof/ "$1/lib/firmware/intel/sof-$ver"
ln -s sof-$ver "$1/lib/firmware/intel/sof"
cp -r $verdir/sof-tplg/ "$1/lib/firmware/intel/sof-tplg-$ver"
ln -s sof-tplg-$ver "$1/lib/firmware/intel/sof-tplg"
mkdir -p "$1/usr/share/doc/sof-bin"
cp -f LICENCE.* Notice.* "$1/usr/share/doc/sof-bin/"

strings -a `find "$2" -type f -name 'snd-*.ko'` | grep ^sof- | sort | uniq > /tmp/sofstrings
find "$1/lib/firmware/intel/sof-$ver" "$1/lib/firmware/intel/sof-tplg-$ver" -type f -name 'sof-*.*' | while read F; do
	fgrep -qlm1 ${F##*/} /tmp/sofstrings || rm -f $F
done
rm -f /tmp/sofstrings