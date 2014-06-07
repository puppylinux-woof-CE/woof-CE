#!/bin/sh

[ ! -e ./usr/bin/xterm ] && ln -s urxvt ./usr/bin/xterm
[ ! -e ./usr/bin/rxvt ] && ln -s urxvt ./usr/bin/rxvt

if [ -f ./root/Choices/ROX-Filer/PuppyPin ];then
 sed -e 's%/rxvt%/urxvt%' ./root/Choices/ROX-Filer/PuppyPin >/tmp/puppypin.urxvt
 mv -f /tmp/puppypin.urxvt ./root/Choices/ROX-Filer/PuppyPin
fi
