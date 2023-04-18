echo '#!/bin/sh
exec l3afpad "$@"' > usr/local/bin/defaulttextviewer
chmod 755 usr/local/bin/defaulttextviewer

[ -e usr/local/apps/ROX-Filer/AppRun ] || chroot . xdg-mime default l3afpad.desktop text/plain
