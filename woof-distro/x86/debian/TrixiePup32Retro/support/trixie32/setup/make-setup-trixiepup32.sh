#!/bin/sh
# Setup for TrixiePup32

# 250826

./createsfs -r new -f tp32setup abiword.pet BW_rightclick.pet xfe_setup.pet gatotray-3.3-x86.pet samba_simple_setup.pet weechat-shell.pet gftp-gtk_2.9.1~beta-3_i386.deb isomaster_1.3.13-1+b2_i386.deb parcellite_1.2.1-8+b1_i386.deb config-tweaks.sfs

FINALSFS=tp32setup_new
rm $FINALSFS/pet.specs

mksquashfs "${FINALSFS}" "${FINALSFS}.sfs" -comp xz -b 1024K
rm -fr "${FINALSFS}"

rm tp32setup.sfs
mv tp32setup_new.sfs tp32setup.sfs
exit
