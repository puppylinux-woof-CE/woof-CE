#!/bin/sh
# Slackware puppy specific modifications
#

rm etc/profile.d/lang.*sh # toxic, puppy set the LANG elsewhere.
rm etc/termcap* # toxic

# cp our fonts to slackware's location
for p in ./usr/share/fonts/default/*; do
	pp=$(echo $p | sed 's|default/||';)
	if [ -d $p ]; then
		mkdir -p $pp
		mv $p/* $pp
	fi
done
rm -rf ./usr/share/fonts/default

# compensate for wrong doinst.sh in font packages
rm -f ./fonts.dir ./fonts.scale
for p in ./usr/share/fonts/*; do
	mkfontscale "$p"
	mkfontdir "$p"
done

# sns require busybox ifconfig
mv ./sbin/ifconfig ./sbin/ifconfig-FULL
ln -s ../bin/busybox ./sbin/ifconfig

