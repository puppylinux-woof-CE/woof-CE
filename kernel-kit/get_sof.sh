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
[ -n "$GITHUB_ACTIONS" ] && rm -f "$BASE"
cd "$DIR"
mkdir -p "$1/lib/firmware/intel"
for DIR in sof sof-tplg sof-ipc4 sof-ace-tplg; do
	cp -r $DIR "$1/lib/firmware/intel/"
	ln -s $DIR "$1/lib/firmware/intel/$DIR-$TAG"
done
mkdir -p "$1/usr/share/doc/sof-bin"
cp -f LICENCE.* Notice.* "$1/usr/share/doc/sof-bin/"
cd ..
[ -n "$GITHUB_ACTIONS" ] && rm -rf "$DIR"
