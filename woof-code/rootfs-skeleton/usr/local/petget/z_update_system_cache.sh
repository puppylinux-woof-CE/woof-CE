#!/bin/bash
#
# PKGFILES="/root/.packages/${DLPKG_NAME}.files"
#

PKGFILES=${1}

if grep -q -m 1 '/usr/share/glib-2.0/schemas' $PKGFILES ; then
	if [ -e /usr/bin/glib-compile-schemas ] ; then
		/usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas
	fi
fi

if grep -q -m 1 '/usr/lib/gio/modules' $PKGFILES ; then
	if [ -e /usr/bin/gio-querymodules ] ; then
		/usr/bin/gio-querymodules /usr/lib/gio/modules
	fi
fi

if grep -q -m 1 '/usr/share/applications/' $PKGFILES ; then
	if [ -e /usr/bin/update-desktop-database ] ; then
		rm -f /usr/share/applications/mimeinfo.cache
		/usr/bin/update-desktop-database /usr/share/applications
	fi
fi

if grep -q -m 1 '/usr/share/mime/' $PKGFILES ; then
	if [ -e /usr/bin/update-mime-database ] ; then
		/usr/bin/update-mime-database /usr/share/mime
	fi
fi

if grep -q -m 1 '/usr/share/icons/hicolor/' $PKGFILES ; then
	if [ -e /usr/bin/gtk-update-icon-cache ] ; then
		/usr/bin/gtk-update-icon-cache /usr/share/icons/hicolor
	fi
fi

if grep -q -m 1 '/usr/lib/gdk-pixbuf' $PKGFILES ; then
	if [ -e /usr/bin/update-gdk-pixbuf-loaders ] ; then
		update-gdk-pixbuf-loaders
	elif [ -e /usr/bin/gdk-pixbuf-query-loaders ] ; then
		gdk-pixbuf-query-loaders --update-cache
	fi
fi

if grep -q -m 1 '/usr/lib/gconv/' $PKGFILES ; then
	iconvconfig
fi

if grep -q -m 1 '/usr/lib/pango/' $PKGFILES; then
	if [ -e /usr/bin/update-pango-querymodules ] ; then
		update-pango-querymodules
	elif [ -e /usr/bin/pango-querymodules ] ; then
		pango-querymodules --update-cache
	fi
fi

if grep -m 1 "/usr/lib/gtk-2.0" $PKGFILES | grep -q "/immodules" ; then
	if [ -e /usr/bin/update-gtk-immodules-2.0 ] ; then
		update-gtk-immodules-2.0
	elif [ -e /usr/bin/gtk-query-immodules-2.0 ] ; then
		gtk-query-immodules-2.0 --update-cache
	fi
fi

if grep -m 1 "/usr/lib/gtk-3.0" $PKGFILES | grep -q "/immodules" ; then
	if [ -e /usr/bin/update-gtk-immodules-3.0 ] ; then
		update-gtk-immodules-3.0
	elif [ -e /usr/bin/gtk-query-immodules-3.0 ] ; then
		gtk-query-immodules-3.0 --update-cache
	fi
fi

if grep -q -m 1 '/usr/share/fonts/' $PKGFILES ; then
	fc-cache -f
fi

if grep -q -m 1 "/lib/modules/$(uname -r)/" $PKGFILES ; then
	depmod -a
fi

