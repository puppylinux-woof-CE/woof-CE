#!/bin/sh

# this may fix intel crashes on some chips
# see http://www.murga-linux.com/puppy/viewtopic.php?p=955636#955636

echo "Xorg intel UXA acceleration enabled"
echo "Xorg intel UXA acceleration enabled" >/dev/console

cat > /etc/X11/xorg.conf.d/20-intel.conf <<EOF
Section "Device" 
  Identifier "Card0" 
  Driver "intel" 
  Option "AccelMethod" "uxa" 
EndSection 
EOF

if [ "$DISPLAY" ] ; then
	echo "please restart X"
fi
