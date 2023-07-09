echo '#!/bin/sh
exec epdfview "$@"' > usr/local/bin/defaultpdfviewer
chmod 755 usr/local/bin/defaultpdfviewer

if [ ! -e usr/local/apps/ROX-Filer/AppRun ]; then
	chroot . xdg-mime default epdfview.desktop application/pdf
	chroot . run-as-spot xdg-mime default epdfview.desktop application/pdf
fi
