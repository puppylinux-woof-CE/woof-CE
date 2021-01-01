#!/bin/bash

CWD=`pwd`
ARCH=`uname -m`

make || exit 1
make install_min DESTDIR=${CWD}-${ARCH} || exit 1
