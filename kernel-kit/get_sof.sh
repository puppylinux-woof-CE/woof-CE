#!/bin/bash -xe

read TAG URL < <(curl -H "Accept: application/vnd.github+json" https://api.github.com/repos/thesofproject/sof-bin/releases | jq -r '[.[] | select(.prerelease == false and .draft == false)] | .[0].tag_name + " " + .[0].assets[0].browser_download_url')
test -n "$TAG"
test "$TAG" != null
test -n "$URL"
test "$URL" != null
BASE=${URL##*/}
[ -e "$BASE" ] || curl -fLo "$BASE" "$URL"
DIR=${BASE%*.tar.*}
rm -rf "$DIR"
tar -xf "$BASE"
cd "$DIR"
mkdir -p "$1/lib/firmware/intel"
cp -r sof "$1/lib/firmware/intel/sof-$TAG"
ln -s sof-$TAG "$1/lib/firmware/intel/sof"
cp -r sof-tplg "$1/lib/firmware/intel/sof-tplg-$TAG"
ln -s sof-tplg-$TAG "$1/lib/firmware/intel/sof-tplg"
mkdir -p "$1/usr/share/doc/sof-bin"
cp -f LICENCE.* Notice.* "$1/usr/share/doc/sof-bin/"
