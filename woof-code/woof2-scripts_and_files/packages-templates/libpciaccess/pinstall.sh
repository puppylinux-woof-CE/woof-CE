#!/bin/sh

#get rid of this as in xorg 7.5 it no longer works properly...
#(use lspci instead)
if [ -f ./usr/share/pci.ids -o -f ./usr/share/pci.ids.gz ];then
 rm -f ./usr/bin/scanpci
fi
