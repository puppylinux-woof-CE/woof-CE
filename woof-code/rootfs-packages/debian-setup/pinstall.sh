#!/bin/sh
# Debian/Ubuntu specific modifications
#

rm -f etc/init.d/udev                   # puppy already starts udev in rc.sysinit
rm usr/bin/X; ln -sf Xorg usr/bin/X     # delete useless xorg wrapper
ln -s xterm usr/bin/x-terminal-emulator # some programs look for this symlink
