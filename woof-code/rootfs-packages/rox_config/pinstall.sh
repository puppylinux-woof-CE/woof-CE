#!/bin/sh
#post-install script for rox_config.
#Woof: current directory is rootfs-complete, which has the final filesystem.

echo "Configuring ROX Filer..."

if [ "`pwd`" != "/" ];then


#120521 better way to create OpenWith entries (will have icons in menu)...
#120601 filter out mtPaint-snapshot-screen-capture.desktop ...
for ONEOPEN in Abiword Bcrypt ePDFView Firefox Geany gedit evince gpicview mtpaint Ghasher Ghostview gnome-mplayer Gnumeric Gxine HomeBank InkLite Inkscape Pburn ISOMaster Leafpad Mozilla-Firefox mhWaveEdit Notecase Opera Planner Pmusic PupZip SeaMonkey-Composer SeaMonkey-web-browser Viewnior XArchive
do
 FNDOPEN="`find usr/share/applications -mindepth 1 -maxdepth 1 -type f -iname "${ONEOPEN}*.desktop" | head -n 1`"
 [ "$FNDOPEN" ] && ln -snf /${FNDOPEN} root/.config/rox.sourceforge.net/OpenWith/${ONEOPEN}
done
echo

fi

