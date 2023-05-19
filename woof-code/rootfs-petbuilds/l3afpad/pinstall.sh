echo '#!/bin/sh
exec l3afpad "$@"' > usr/local/bin/defaulttextviewer
chmod 755 usr/local/bin/defaulttextviewer

if [ ! -e usr/local/apps/ROX-Filer/AppRun ]; then
	chroot . xdg-mime default l3afpad.desktop text/plain
	chroot . run-as-spot xdg-mime default l3afpad.desktop text/plain
fi
