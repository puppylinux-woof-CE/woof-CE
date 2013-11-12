#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/downloadpkgs.sh.
#passed param is the path and name of the downloaded package.
#100116 add support for .tar.bz2 T2 pkgs.
#100616 add support for .txz slackware pkgs.
#101225 bug fix, .pet was converted to .tar.gz, restore to .pet.

export LANG=C
. /etc/rc.d/PUPSTATE  #this has PUPMODE and SAVE_LAYER.
. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
mkdir -p /tmp/petget #101225

DLPKG="$1"
DLPKG_BASE="`basename $DLPKG`" #ex: scite-1.77-i686-2as.tgz
DLPKG_PATH="`dirname $DLPKG`"  #ex: /root

FLAG="ok"
cd $DLPKG_PATH

case $DLPKG_BASE in
 *.pet)
  #101225 bug fix, .pet was converted to .tar.gz, restore to .pet...
  DLPKG_MAIN="`basename $DLPKG_BASE .pet`"
  FULLSIZE=`stat --format=%s "${DLPKG_BASE}"`
  ORIGSIZE=`expr $FULLSIZE - 32`
  dd if="${DLPKG_BASE}" of=/tmp/petget/petmd5sum bs=1 skip=${ORIGSIZE} 2>/dev/null
  sync
  MD5SUM="`cat /tmp/petget/petmd5sum`"
  pet2tgz $DLPKG_BASE
  [ $? -ne 0 ] && FLAG="bad"
  if [ -f ${DLPKG_PATH}/${DLPKG_MAIN}.tar.gz ];then
   mv -f ${DLPKG_PATH}/${DLPKG_MAIN}.tar.gz ${DLPKG_PATH}/${DLPKG_MAIN}.pet
   echo -n "$MD5SUM" >> ${DLPKG_PATH}/${DLPKG_MAIN}.pet
  fi
 ;;
 *.deb)
  DLPKG_MAIN="`basename $DLPKG_BASE .deb`"
  dpkg-deb --contents $DLPKG_BASE
  [ $? -ne 0 ] && FLAG="bad"
 ;;
 *.tgz)
  DLPKG_MAIN="`basename $DLPKG_BASE .tgz`" #ex: scite-1.77-i686-2as
  gzip --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && FLAG="bad"
 ;;
 *.txz)
  DLPKG_MAIN="`basename $DLPKG_BASE .txz`" #ex: scite-1.77-i686-2as
  xz --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && FLAG="bad"
 ;;
 *.tar.gz)
  DLPKG_MAIN="`basename $DLPKG_BASE .tar.gz`" #ex: acl-2.2.47-1-i686.pkg
  gzip --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && FLAG="bad"
 ;;
 *.tar.bz2) #100116
  DLPKG_MAIN="`basename $DLPKG_BASE .tar.bz2`"
  bzip2 --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && FLAG="bad"
 ;;
esac

if [ "$FLAG" = "bad" ];then
 rm -f $DLPKG_BASE > /dev/null 2>&1
 rm -f ${DLPKG_MAIN}.tar.gz > /dev/null 2>&1
 exit 1
fi

###END###
