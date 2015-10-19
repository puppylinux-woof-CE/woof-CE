#!/bin/sh
CWD="`pwd`"
if [ "$CWD" != "/" ]; then #woof
 cd ./usr/share/ca-certificates
 find -type f | cut -c 3- > ../../../etc/ca-certificates.conf
 cd "$CWD"
 chroot . /usr/sbin/update-ca-certificates --fresh
else
 /usr/sbin/update-ca-certificates --fresh
fi
