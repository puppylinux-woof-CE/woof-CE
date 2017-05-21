#!/bin/sh
# execute one up
. ./_00build.conf
. ./DISTRO_SPECS
# check what version it is
MK_VER=$(mkwallpaper|head -n1|cut -d'-' -f2)
ls /usr/share/fonts/default/TTF|grep -q 'Orbitron' && FONT=Orbitron || FONT=Sans # fancy font
DIMS_X_Y="640 350"
XCWD=`pwd`
IMG=${XCWD}/rootfs-skeleton/usr/share/doc/puppylogo96-trans.png # embedded image for newer mkwallpaper
WCWD=${XCWD}/sandbox3/rootfs-complete
OUT_BG=${WCWD}/usr/share/backgrounds
if [ "$CUSTOM_WALLPAPERS" = "yes" ];then
	mkwallpaper | grep -wq '\-k' && opt='-kyes' || opt=''
	(cd sandbox3/rootfs-complete
	. etc/DISTRO_SPECS
	for e in 1 2 3 4 5 6 7 8; do
		case $e in
			1)color='0.2 0.2 0.2'		;; #dark grey
			2)color='0.70 0.30 0.40'	;; #raspberry
			3)color='0.00 0.75 0.75'	;; #teale
			4)color='0.2 0.7 0.1'		;; #green
			5)color='0.55 0.25	0.60'	;; #purply violet
			6)color='0.1 0.1 0.8'		;; #darkish blue
			7)color='0.73 0.55 0.52'	;; #salmon
			8)color='0.6 0.7 0.8'		;; #light blue
		esac
		if vercmp $MK_VER ge 0.8;then
			echo #do new stuff
			mkwallpaper -n ${DISTRO_FILE_PREFIX}-wall${e} -l "$DISTRO_FILE_PREFIX" \
			-f $FONT -i0 -s 42 -x1280 -y800 -kyes -jbr -z "$color" -e"${IMG} $DIMS_X_Y" -d${OUT_BG} #-ppng hmm.. maybe smaller
		else
			mkwallpaper -n ${DISTRO_FILE_PREFIX}-wall${e} -l "$DISTRO_FILE_PREFIX" -x1024 -y768 -z "$color" ${opt} -w woof
		fi
	done
	)
fi
echo "created custom wallpapers"
