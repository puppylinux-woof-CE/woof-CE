#!/bin/sh
# Setup for TrixiePup64

# 250327

./createsfs -r new -f tp64setup abiword.pet BW_rightclick.pet xfe_setup.pet gatotray-3.3_bw64.pet samba_simple_setup.pet weechat-shell.pet gftp-gtk_2.9.1~beta-3_amd64.deb isomaster_1.3.13-1+b2_amd64.deb parcellite_1.2.1-8+b1_amd64.deb config-tweaks.sfs

FINALSFS=tp64setup_new
rm $FINALSFS/pet.specs

mksquashfs "${FINALSFS}" "${FINALSFS}.sfs" -comp xz -b 1024K
rm -fr "${FINALSFS}"

rm tp64setup.sfs
mv tp64setup_new.sfs tp64setup.sfs
read goon
exit
