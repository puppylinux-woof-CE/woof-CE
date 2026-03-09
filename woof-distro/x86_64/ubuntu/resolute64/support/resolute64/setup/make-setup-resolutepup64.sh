#!/bin/sh
# Setup for ResolutePup64

# 260307
# gftp & wireless-tools from noble

./createsfs -r new -f rp64setup gftp-common_2.9.1~beta-2build2_all.deb gftp-gtk_2.9.1~beta-2build2_amd64.deb wireless-tools_30~pre9-16.1ubuntu2_amd64.deb

FINALSFS=rp64setup_new
rm $FINALSFS/pet.specs
mkdir -p $FINALSFS/root/.config/mpv
cp mpv.conf $FINALSFS/root/.config/mpv/

mksquashfs "${FINALSFS}" "${FINALSFS}.sfs" -comp xz -b 1024K
rm -fr "${FINALSFS}"

rm rp64setup.sfs
mv rp64setup_new.sfs rp64setup.sfs
read goon
exit
