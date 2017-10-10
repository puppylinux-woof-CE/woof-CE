#!/bin/sh
# woof pinstall.sh for ca-certificates compat pkg
CWD="`pwd`"
cd ./usr/share/ca-certificates
find -type f | cut -c 3- > ../../../etc/ca-certificates.conf
cd "$CWD"
chroot . /usr/sbin/update-ca-certificates --fresh
