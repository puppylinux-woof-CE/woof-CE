#!/bin/ash
# /etc/init.d/javaif.sh
# Derived from /etc/init.d/java.sfs.sh in java-sfs.sh by Uten

[ "$1" ] || exit
ARGUMENT="$1"

#==============================================================
#                      FUNCTIONS
#==============================================================

update_configuration () {
    JAVAHOME=''; JREHOME=''; JAVAVERSION=''; ICEDTEAHOME=''; ICEDTEAVERSION=''
    if [ -f /root/.javaifrc ]; then
     . /root/.javaifrc #dynamic info
    fi
    PREVJAVAHOME="$JAVAHOME"
    PREVVERSION="$JAVAVERSION"
    PREVICEDTEAHOME="$ICEDTEAHOME"
    PREVICEDTEAVERSION="$ICEDTEAVERSION"
    JAVAHOME="$(javaiffind)" #Latest installed java version & icedtea-web
    ICEDTEAHOME="$(echo -n "$JAVAHOME " | cut -f 2 -d ' ')"
    JAVAHOME="$(echo -n $JAVAHOME | cut -f 1 -d ' ')"
    if [ "$JAVAHOME" ]; then
     JAVAVERSION="$($JAVAHOME/bin/java -version 2>&1 | grep 'version' | cut -f3 -d ' ' | tr -d '\"')"
     if [ -d "$JAVAHOME/jre" ]; then #JDK
      JREHOME="$JAVAHOME/jre"
     else
      JREHOME="$JAVAHOME"
     fi
     if [ -n "$ICEDTEAHOME" ]; then
      ICEDTEAVERSION="$(grep -osm 1 '"icedtea-web .*"' \
       $ICEDTEAHOME/man/man1/icedtea-web.1 \
       $ICEDTEAHOME/share/man/man1/icedtea-web.1 | \
       sed 's/.*"icedtea-web (*\([0-9.]*\).*/\1/')"
      for ONEEXEC in itweb-settings javaws policyeditor; do
       if [ -x /usr/bin/$ONEEXEC ]; then
        if [ -h /usr/bin/$ONEEXEC ]; then
         rm -f /usr/bin/$ONEEXEC
        else
         chmod a-x /usr/bin/$ONEEXEC
        fi
       fi
      done
     else
      ICEDTEAVERSION=''
      for ONEEXEC in itweb-settings javaws policyeditor; do
       if [ -f /usr/bin/$ONEEXEC ]; then
        chmod a+x /usr/bin/$ONEEXEC
       elif [ -f $JAVAHOME/bin/$ONEEXEC ]; then
         ln -snf $JAVAHOME/bin/$ONEEXEC /usr/bin/$ONEEXEC
       fi
      done
     fi
     JAVAIFRC="JAVAHOME=$JAVAHOME
JAVAVERSION=$JAVAVERSION
ICEDTEAHOME=$ICEDTEAHOME
ICEDTEAVERSION=$ICEDTEAVERSION"
     if [ ! -f /root/.javaifrc ] || [ "$JAVAIFRC" != "$(cat /root/.javaifrc)" ]; then
      echo -n "$JAVAIFRC" > /root/.javaifrc
     fi
    else
     rm -f /root/.javaifrc
    fi
}

add_plugin_links() {
    for ONEBROWSER in $BROWSERS; do
     if [ -d /usr/lib/$ONEBROWSER ]; then
      for ONEPLUGIN in $BROWSERPLUGINS; do
       if [ -f $JREHOME/lib/i386/$ONEPLUGIN ]; then
        mkdir -p /usr/lib/$ONEBROWSER/plugins
        ln -sf $JREHOME/lib/i386/$ONEPLUGIN /usr/lib/$ONEBROWSER/plugins/$(basename $ONEPLUGIN)
       fi
      done
     fi
    done
}

remove_plugin_links() {
    for ONEBROWSER in $BROWSERS; do
     if [ -d /usr/lib/$ONEBROWSER ]; then
      for ONEPLUGIN in $BROWSERPLUGINS; do
       if [ -d /usr/lib/$ONEBROWSER/plugins ]; then
        rm -f /usr/lib/$ONEBROWSER/plugins/$(basename $ONEPLUGIN)
       fi
      done
     fi
    done
}

add_icon_links() {
    for ONEIMAGE in $IMAGES; do
     if [ -f $JREHOME/lib/images/icons/$ONEIMAGE ]; then
      ln -sf $JREHOME/lib/images/icons/$ONEIMAGE /usr/share/pixmaps/
     fi
    done
    for ONEMAINICON in $MAINICONS; do
     if [ -f $JREHOME/lib/desktop/icons/hicolor/16x16/apps/$ONEMAINICON ]; then
      ln -sf $JREHOME/lib/desktop/icons/hicolor/16x16/apps/$ONEMAINICON /usr/local/lib/X11/mini-icons/
     fi
    done
    for ONEMIMEICON in $MIMEICONS; do
     if [ "$ROXMIMEICONPATH" -a -f $JREHOME/lib/desktop/icons/hicolor/48x48/mimetypes/gnome-mime-$ONEMIMEICON ]; then
      ln -sf $JREHOME/lib/desktop/icons/hicolor/48x48/mimetypes/gnome-mime-$ONEMIMEICON $ROXMIMEICONPATH/$ONEMIMEICON
     fi
    done
    for ONEGROUP in hicolor HighContrast HighContrastInverse LowContrast; do
     if [ -d $JREHOME/lib/desktop/icons/$ONEGROUP ]; then
      for ONEMAINICON in $MAINICONS; do
       if [ -f $JREHOME/lib/desktop/icons/$ONEGROUP/16x16/apps/$ONEMAINICON ]; then
        mkdir -p /usr/share/icons/$ONEGROUP/16x16/apps
        ln -sf $JREHOME/lib/desktop/icons/$ONEGROUP/16x16/apps/$ONEMAINICON /usr/share/icons/$ONEGROUP/16x16/apps/
       fi
       if [ -f $JREHOME/lib/desktop/icons/$ONEGROUP/48x48/apps/$ONEMAINICON ]; then
        mkdir -p /usr/share/icons/$ONEGROUP/48x48/apps
        ln -sf $JREHOME/lib/desktop/icons/$ONEGROUP/48x48/apps/$ONEMAINICON /usr/share/icons/$ONEGROUP/48x48/apps/
       fi
      done
      for ONEMIMEICON in $MIMEICONS; do
       if [ -f $JREHOME/lib/desktop/icons/$ONEGROUP/16x16/mimetypes/gnome-mime-$ONEMIMEICON ]; then
        mkdir -p /usr/share/icons/$ONEGROUP/16x16/mimetypes
        ln -sf $JREHOME/lib/desktop/icons/$ONEGROUP/16x16/mimetypes/gnome-mime-$ONEMIMEICON /usr/share/icons/$ONEGROUP/16x16/mimetypes/
       fi
       if [ -f $JREHOME/lib/desktop/icons/$ONEGROUP/48x48/mimetypes/gnome-mime-$ONEMIMEICON ]; then
        mkdir -p /usr/share/icons/$ONEGROUP/48x48/mimetypes
        ln -sf $JREHOME/lib/desktop/icons/$ONEGROUP/48x48/mimetypes/gnome-mime-$ONEMIMEICON /usr/share/icons/$ONEGROUP/48x48/mimetypes/
       fi
      done
     fi
    done
}

remove_icon_links() {
    for ONEIMAGE in $IMAGES; do
      [ -f /usr/share/pixmaps/$ONEIMAGE ] && rm -f /usr/share/pixmaps/$ONEIMAGE
    done
    for ONEMAINICON in $MAINICONS; do
      [ -f /usr/local/lib/X11/mini-icons/$ONEMAINICON ] && rm -f /usr/local/lib/X11/mini-icons/$ONEMAINICON
    done
    for ONEMIMEICON in $MIMEICONS; do
     [ "$ROXMIMEICONPATH" ] && rm -f $ROXMIMEICONPATH/$ONEMIMEICON
    done
    for ONEGROUP in hicolor HighContrast HighContrastInverse LowContrast; do
     for ONEMAINICON in $MAINICONS; do
       if [ -f /usr/share/icons/$ONEGROUP/16x16/apps/$ONEMAINICON ] ; then
         rm -f /usr/share/icons/$ONEGROUP/16x16/apps/$ONEMAINICON
       fi
       if [ -f /usr/share/icons/$ONEGROUP/48x48/apps/$ONEMAINICON ] ; then
         rm -f /usr/share/icons/$ONEGROUP/48x48/apps/$ONEMAINICON
       fi
     done
     for ONEMIMEICON in $MIMEICONS; do
       if [ -f /usr/share/icons/$ONEGROUP/16x16/mimetypes/gnome-mime-$ONEMIMEICON ] ; then
         rm -f /usr/share/icons/$ONEGROUP/16x16/mimetypes/gnome-mime-$ONEMIMEICON
       fi
       if [ -f /usr/share/icons/$ONEGROUP/48x48/mimetypes/gnome-mime-$ONEMIMEICON ] ; then
         rm -f /usr/share/icons/$ONEGROUP/48x48/mimetypes/gnome-mime-$ONEMIMEICON
       fi
     done
    done
}

#==============================================================
#                      MAIN
#==============================================================

case "$ARGUMENT" in
 start|change)
  [ "$ARGUMENT" = 'start' ] && sleep 1 #Wait for other java service scripts before overriding them, then do change
  BROWSERS=''; BROWSERPLUGINS=''
  IMAGES=''; MAINICONS=''; MIMEICONS=''
  FORCEEXECPATH=false
  ROXMIMEICONPATH=/usr/local/apps/ROX-Filer/ROX/MIME
  ROXMIMETYPESPATH=/etc/xdg/rox.sourceforge.net/MIME-types
  update_configuration
  . /etc/javaif.conf #static info
  if [ "$JAVAHOME" ]; then
   if [ "$PREVJAVAHOME" ]; then
    remove_plugin_links
    remove_icon_links
   fi
   add_plugin_links
   add_icon_links
  else
   remove_plugin_links
   remove_icon_links
  fi
  ;;
esac

