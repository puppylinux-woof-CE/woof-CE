#!/bin/bash
#
# PKGFILES="/root/.packages/${DLPKG_NAME}.files"
#

PKGFILES=${1}

GTKVERLIST="2.0 3.0 4.0 5.0 6.0"


for usrfld in /usr /usr/local
do

  if grep -q -m 1 "$usrfld/share/glib-2.0/schemas" $PKGFILES ; then
	if [ -e /usr/bin/glib-compile-schemas ] ; then
	  /usr/bin/glib-compile-schemas $usrfld/share/glib-2.0/schemas 2>/dev/null
	fi
  fi

  if grep -q -m 1 "$usrfld/share/applications/" $PKGFILES ; then
	if [ -e /usr/bin/update-desktop-database ] ; then
	 rm -f $usrfld/share/applications/mimeinfo.cache 2>/dev/null
	 /usr/bin/update-desktop-database $usrfld/share/applications 2>/dev/null
	fi
  fi

  if grep -q -m 1 "$usrfld/share/mime/" $PKGFILES ; then
	if [ -e /usr/bin/update-mime-database ] ; then
	  /usr/bin/update-mime-database $usrfld/share/mime 2>/dev/null
	fi
	
	if [ -e "$usrfld/share/mime/packages" ] && [ "$(ls -1 "$usrfld/share/mime/packages" 2>/dev/null)" == "" ]; then
	 rm -rf $usrfld/share/mime/*
	fi
  fi

  if grep -q -m 1 "$usrfld/lib/gio/modules" $PKGFILES ; then
	if [ -e /usr/bin/gio-querymodules ] ; then
	  /usr/bin/gio-querymodules $usrfld/lib/gio/modules 2>/dev/null
	fi
  fi

  if grep -q -m 1 "$usrfld/share/icons/" $PKGFILES ; then
      for gtkcmd in gtk gtk4
      do
	if [ -e /usr/bin/${gtkcmd}-update-icon-cache ] ; then
	  find "$usrfld/share/icons/" -name "icon-theme.cache" -type f -exec rm -f '{}' \;
	  find "$usrfld/share/icons" -maxdepth 1 -name "*" -exec ${gtkcmd}-update-icon-cache -f -i '{}' \; 2>/dev/null
	  break
	fi
      done
  fi

done

if [ "$(grep -q -m 1 '/gconv/' $PKGFILES)" != "" ]; then
  iconvconfig 2>/dev/null
fi

if [ "$(grep -q -m 1 '/usr/lib/gdk-pixbuf' $PKGFILES)" != "" ] || [ "$(grep -q -m 1 '/usr/local/lib/gdk-pixbuf' $PKGFILES)" != "" ]; then
	if [ -e /usr/bin/update-gdk-pixbuf-loaders ] ; then
	 update-gdk-pixbuf-loaders
	elif [ -e /usr/bin/gdk-pixbuf-query-loaders ] ; then
	 gdk-pixbuf-query-loaders --update-cache
	fi
fi

if [ "$(grep -q -m 1 '/usr/lib/pango/' $PKGFILES)" != "" ] || [ "$(grep -q -m 1 '/usr/local/lib/pango/' $PKGFILES)" != "" ]; then
	if [ -e /usr/bin/update-pango-querymodules ] ; then
		update-pango-querymodules
	elif [ -e /usr/bin/pango-querymodules ] ; then
		pango-querymodules --update-cache
	fi
fi

if [ "$(grep -q -m 1 '/usr/share/fonts/' $PKGFILES)" != "" ] || [ "$(grep -q -m 1 '/usr/local/share/fonts/' $PKGFILES)" != "" ]; then
  fc-cache -f
fi

if [ "$(grep -q -m 1 '/etc/ld.so.conf.d/' $PKGFILES)" != "" ]; then
  ldconfig
fi

if [ "$(grep -q -m 1 '/udev/hwdb.d/' $PKGFILES)" != "" ]; then
  [ "$(udevadm --help 2>&1 | grep hwdb)" != "" ] && udevadm hwdb --update
fi

if grep -q -m 1 "/lib/modules/$(uname -r)/" $PKGFILES ; then
  depmod -a
fi

for GTKVER in $GTKVERLIST
do
  if [ "$(grep -m 1 "/usr/lib/gtk-$GTKVER" $PKGFILES | grep -q "/immodules")" != "" ] || [ "$(grep -m 1 "/usr/local/lib/gtk-$GTKVER" $PKGFILES | grep -q "/immodules")" != "" ]; then
	if [ -e /usr/bin/update-gtk-immodules-$GTKVER ] ; then
	  update-gtk-immodules-$GTKVER
	elif [ -e /usr/bin/gtk-query-immodules-$GTKVER ] ; then
	  gtk-query-immodules-$GTKVER --update-cache
	fi
  fi
done
