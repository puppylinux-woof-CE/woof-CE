echo '#!/bin/sh
exec deadbeef "$@"' > usr/local/bin/defaultaudioplayer
chmod 755 usr/local/bin/defaultaudioplayer

echo '#!/bin/sh
exec deadbeef all.cda' > usr/local/bin/defaultcdplayer
chmod 755 usr/local/bin/defaultcdplayer

if [ ! -e usr/local/apps/ROX-Filer/AppRun ]; then
	for T in `grep ^MimeType= usr/share/applications/deadbeef.desktop | sed -e s/^MimeType=//g -e 's/;/ /g'`; do
		chroot . xdg-mime default deadbeef.desktop $T
	done
fi