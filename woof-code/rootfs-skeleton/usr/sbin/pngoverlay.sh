#!/bin/ash
# Barry Kauler 2011 GPL3 (/usr/share/doc/legal)
#pngoverlay.sh is an alternative to pngoverlay written by vovchik (in BaCon)
# (vovchik's pngoverlay requires X to be running, which may be a disadvantage)
#requires netpbm svn rev 1543 or later, with pamcomp -mixtransparency
#requires three params, 1st and 2nd must exist:
# bottom-image top-image output-image
#overlays the two images, with common areas of transparency in output image.

[ ! $3 ] && exit 1
[ ! -e "$1" ] && exit 1
[ ! -e "$2" ] && exit 1
[ "`echo -n "$1" | grep 'png$'`" = "" ] && exit 1
[ "`echo -n "$2" | grep 'png$'`" = "" ] && exit 1

pngtopam -alphapam "${1}" > /tmp/pngoverlay_${$}_1.pam
pngtopam -alphapam "${2}" > /tmp/pngoverlay_${$}_2.pam
#1st image on top, 2nd on bottom, 3rd is output...
pamcomp -mixtransparency /tmp/pngoverlay_${$}_2.pam /tmp/pngoverlay_${$}_1.pam > /tmp/pngoverlay_${$}_out.png 2> /dev/null
pamrgbatopng /tmp/pngoverlay_${$}_out.png > "${3}"
rm -f /tmp/pngoverlay_${$}_1.pam
rm -f /tmp/pngoverlay_${$}_2.pam
rm -f /tmp/pngoverlay_${$}_out.pam
