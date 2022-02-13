#!/bin/bash -e

. ../woof-code/_00func
cd output

TAR=`ls huge-*.tar.bz2`
tar xf $TAR
rm -f $TAR

ZDRV=`ls kernel-modules-*.sfs`
unsquashfs -d zdrv $ZDRV
rm -f $ZDRV
. zdrv/etc/modules/build.conf-*
usrmerge zdrv 0
mksquashfs zdrv $ZDRV $COMP
rm -rf zdrv

FDRV=`ls fdrv-*.sfs`
unsquashfs -d fdrv $FDRV
rm -f $FDRV
usrmerge fdrv 0
mksquashfs fdrv $FDRV $COMP
rm -rf fdrv

tar -cjf $TAR vmlinuz-* $ZDRV $FDRV
md5sum $TAR > $TAR.md5.txt
sha256sum $TAR > $TAR.sha256.txt

rm -f vmlinuz-* $ZDRV $FDRV

KSRC=`ls kernel_sources-*.sfs`
unsquashfs -d ksrc $KSRC
rm -f $KSRC
rm -vf ksrc/lib/modules/*/{build,source}
usrmerge ksrc 0
MODULES=`echo ksrc/usr/lib/modules/*`
ln -sv ../../../src/linux ${MODULES}/build
ln -sv ../../../src/linux ${MODULES}/source
mksquashfs ksrc $KSRC $COMP
rm -rf ksrc

md5sum $KSRC > $KSRC.md5.txt
sha256sum $KSRC > $KSRC.sha256.txt