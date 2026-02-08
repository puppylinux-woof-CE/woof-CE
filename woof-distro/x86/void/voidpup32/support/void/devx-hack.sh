cd ./sandbox3/devx
echo "Fix libtoolize"
mkdir -p bin
ln -s /usr/bin/sed bin/sed
sed -i 's%#! /usr/bin/env sh%#!/bin/sh%' usr/bin/libtoolize
cd ../../
