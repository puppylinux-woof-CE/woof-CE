echo '#!/bin/sh
exec viewnior "$@"' > usr/local/bin/defaultimageviewer
chmod 755 usr/local/bin/defaultimageviewer

if [ ! -e usr/local/apps/ROX-Filer/AppRun ]; then
	for T in `grep ^MimeType= usr/share/applications/viewnior.desktop | sed -e s/^MimeType=//g -e 's/;/ /g'`; do
		chroot . xdg-mime default viewnior.desktop $T
		chroot . run-as-spot xdg-mime default viewnior.desktop $T
	done
fi