echo '#!/bin/sh
exec geany "$@"' > usr/local/bin/defaulttexteditor
chmod 755 usr/local/bin/defaulttexteditor

echo '#!/bin/sh
exec geany "$@"' > usr/local/bin/defaulthtmleditor
chmod 755 usr/local/bin/defaulthtmleditor

if [ ! -e usr/local/apps/ROX-Filer/AppRun ]; then
	for T in `grep ^MimeType= usr/share/applications/geany.desktop | sed -e s/^MimeType=//g -e 's/;/ /g'`; do
		[ "$T" = "text/plain" ] && continue
		chroot . xdg-mime default geany.desktop $T
		chroot . run-as-spot xdg-mime default geany.desktop $T
	done
	chroot . xdg-mime default geany.desktop "application/xhtml+xml"
	chroot . run-as-spot xdg-mime default geany.desktop "application/xhtml+xml"
fi
