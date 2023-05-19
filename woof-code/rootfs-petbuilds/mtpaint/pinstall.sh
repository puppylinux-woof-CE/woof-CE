echo '#!/bin/sh
exec mtpaint "$@"' > usr/local/bin/defaultimageeditor
chmod 755 usr/local/bin/defaultimageeditor

echo '#!/bin/sh
exec mtpaint-screenshot "$@"' > usr/local/bin/defaultscreenshot
chmod 755 usr/local/bin/defaultscreenshot

if [ ! -e usr/local/apps/ROX-Filer/AppRun ]; then
	chroot . xdg-mime default mtpaint.desktop image/bmp
	chroot . run-as-spot xdg-mime default mtpaint.desktop image/bmp
fi