#!/bin/sh
# Slackware puppy specific modifications
#

rm etc/profile.d/lang.*sh # toxic, puppy set the LANG elsewhere.
rm etc/termcap* # toxic

# cp our fonts to slackware's location
for p in ./usr/share/fonts/default/*; do
	pp=$(echo $p | sed 's|default/||';)
	mkdir -p $pp
	[ -d $p ] && mv $p/* $pp
	rmdir $p
done

# compensate for wrong doinst.sh in font packages
rm -f ./fonts.dir ./fonts.scale
for p in ./usr/share/fonts/*; do
	mkfontscale "$p"
	mkfontdir "$p"
done



