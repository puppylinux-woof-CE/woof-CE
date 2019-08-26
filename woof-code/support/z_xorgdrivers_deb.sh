#!/bin/bash
# get all xorg input/video drivers from Packages-distro-*
# .. and paste the result in yes|xserver_xorg|...|exe,dev,doc,nls
# specially for ubuntu as it has many drivers in the Universe repo
#
# Usage:
# run
#    ./0setup
# then run this script"
#    ./support/z_xorgdrivers_deb.sh
#

distros='debian ubuntu raspbian devuan trisquel'

for i in $distros ; do
	if [ -f Packages-${i}-*-main ] ; then #ex: Packages-debian-stretch-main
		distro=${i}
		break
	fi
done

if [ "$distro" ] ; then
	grep -E 'xserver-xorg-input-|xserver-xorg-video-' Packages-${distro}-* | \
		grep -v '.*-lts-.*' | \
		grep ':xserver-xorg-' | \
		cut -f 2 -d ':' | \
		cut -f 1 -d '_' | \
		sort | \
		tr '\n' ','
	echo
fi

