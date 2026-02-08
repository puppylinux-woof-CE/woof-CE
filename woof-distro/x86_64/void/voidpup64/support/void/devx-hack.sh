echo "For void64 devx: merge the /usr/lib64 directory into /usr/lib; delete the empty /usr/lib64 then link lib64 to lib"
cd ./sandbox3/devx
cp -r usr/lib64/* usr/lib/
rm -rf usr/lib64
ln -s lib usr/lib64

echo "Fix libtoolize"
mkdir -p bin
ln -s /usr/bin/sed bin/sed
sed -i 's%#! /usr/bin/env sh%#!/bin/sh%' usr/bin/libtoolize
cd ../../
