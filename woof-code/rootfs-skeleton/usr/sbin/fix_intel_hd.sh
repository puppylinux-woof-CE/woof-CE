#!/bin/sh

# this may fix intel crashes on some chips
# see http://www.murga-linux.com/puppy/viewtopic.php?p=955636#955636

echo "fixing intel graphics"
cat > /etc/X11/xorg.conf.d/20-intel.conf <<EOF
Section "Device" 
  Identifier "Card0" 
  Driver "intel" 
  Option "AccelMethod" "uxa" 
EndSection 
EOF

echo "please restart X"
