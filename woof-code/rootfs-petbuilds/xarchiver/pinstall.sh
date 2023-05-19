echo '#!/bin/sh
exec xarchiver "$@"' > usr/local/bin/defaultarchiver
chmod 755 usr/local/bin/defaultarchiver

if [ ! -e usr/local/apps/ROX-Filer/AppRun ]; then
	for T in `grep ^MimeType= usr/share/applications/xarchiver.desktop | sed -e s/^MimeType=//g -e 's/;/ /g'`; do
		chroot . xdg-mime default xarchiver.desktop $T
		chroot . run-as-spot xdg-mime default xarchiver.desktop $T
	done
fi
