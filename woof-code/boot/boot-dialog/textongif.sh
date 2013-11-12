#!/bin/sh

RIGHTVER="$2"
Y1=315
X1=330
X2=331
X3=332

# | pnmsmooth

cat $1 | giftopnm | ppmlabel -background transparent -color "dark orange" -size 22 -x $X1 -y $Y1 -text "$RIGHTVER" -background transparent -color "dark orange" -size 22 -x $X2 -y $Y1 -text "$RIGHTVER" -background transparent -color "dark orange" -size 22 -x $X3 -y $Y1 -text "$RIGHTVER" | ppmquant 256 | ppmtogif #> logo.gif
sync

