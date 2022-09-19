#!/bin/sh

echo "Setting up SIP profile"
mkdir -p /root/.config/jami
cp /etc/ccs/dring.yml  /root/.config/jami/
echo "Overwriting jwm tray"
cp /etc/ccs/jwm* /root/.jwm/
#echo "Setting wallpaper"
#set_wallpaper /usr/share/bliss.svg
