#!/bin/sh
#Force update cache files
#written by mistfire

GTKVERLIST='1.0 2.0 3.0'
ARCH=`uname -m`

SKIPDEPMOD="$1"

case $ARCH in
i?86)
 uLIBs="lib lib32 lib/i386-linux-gnu"
;;
x86_64|amd64)
 uLIBs="lib lib64 lib/x86_64-linux-gnu amd64-linux-gnu"
;;
esac

for uLIB in $uLIBs
do
 [ -e /$uLIB/gio/modules ] && gio-querymodules /$uLIB/gio/modules	
done

gdk-pixbuf-query-loaders --update-cache
pango-querymodules --update-cache
iconvconfig
fc-cache -f

for gtkver in $GTKVERLIST
do
 if [ "$(which gtk-query-immodules-$gtkver)" != "" ]; then 
  gtk-query-immodules-$gtkver --update-cache
 fi
done

for usrdata in /usr /usr/local
do
 
 [ -e $usrdata/share/glib-2.0/schemas ] && glib-compile-schemas $usrdata/share/glib-2.0/schemas 2>/dev/null
 [ -e $usrdata/share/mime ] && update-mime-database $usrdata/share/mime 2>/dev/null
 [ -e $usrdata/share/icons/hicolor ] && gtk-update-icon-cache $usrdata/share/icons/hicolor 2>/dev/null
 
 if [ -e $usrdata/share/applications ]; then
  rm -f $usrdata/share/applications/mimeinfo.cache 2>/dev/null
  update-desktop-database $usrdata/share/applications 2>/dev/null
 fi
 
 for uLIB in $uLIBs
 do
  [ -e $usrdata/$uLIB/gio/modules ] && gio-querymodules $usrdata/$uLIB/gio/modules	
 done
 
done

[ "$SKIPDEPMOD" == "" ] && depmod -a
