#!/bin/sh
# /etc/init.d/javaif.sh
# Derived from /etc/init.d/java.sfs.sh in java-sfs.sh by Uten
#set -x #DEBUG

[ "$1" ] || exit
ARGUMENT="$1"

function update_configuration () {
    JAVAHOME="$(javaiffind)"
    local UPDATECONFIG=false
    if [ "$JAVAHOME" ]; then
     if [ -d "$JAVAHOME/jre" ]; then #JDK
      JREHOME="$JAVAHOME/jre"
     else
      JREHOME="$JAVAHOME"
     fi
     JAVAVERSION="$($JAVAHOME/bin/java -version 2>&1 | grep 'version' | cut -f3 -d ' ' | tr -d '\"')"
     if [ "$JREHOME $JAVAVERSION" != "$PREVJREHOME $PREVVERSION" ]; then
      local UPDATECONFIG=true
     fi
    else
     JREHOME=''
     JAVAVERSION=''
     if [ "$PREVJAVAHOME" -o "$PREVJREHOME" -o "$PREVVERSION" ]; then
      local UPDATECONFIG=true
     fi
    fi
    if [ $UPDATECONFIG = true ]; then
     SEDSCRIPT1="/JAVAHOME=/ s%=.*%=${JAVAHOME}%"
     SEDSCRIPT2="/JREHOME=/ s%=.*%=${JREHOME}%"
     SEDSCRIPT3="/JAVAVERSION=/ s%=.*%=${JAVAVERSION}%"
     sed -i -e "$SEDSCRIPT1" -e "$SEDSCRIPT2" -e "$SEDSCRIPT3" /etc/javaif.conf
    fi
}

function add_plugin_links() {
    for ONEBROWSER in $BROWSERS; do
     if [ -d /usr/lib/$ONEBROWSER ]; then
      for ONEPLUGIN in $BROWSERPLUGINS; do
       mkdir -p /usr/lib/$ONEBROWSER/plugins
       if [ -f $JREHOME/lib/i386/$ONEPLUGIN ]; then
        ln -sf $JREHOME/lib/i386/$ONEPLUGIN /usr/lib/$ONEBROWSER/plugins/$(basename $ONEPLUGIN)
       fi
      done
     fi
    done
}

function remove_plugin_links() {
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

function add_icon_links() {
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
     if [ "$ROXMIMEPATH" -a -f $JREHOME/lib/desktop/icons/hicolor/48x48/mimetypes/gnome-mime-$ONEMIMEICON ]; then
      ln -sf $JREHOME/lib/desktop/icons/hicolor/48x48/mimetypes/gnome-mime-$ONEMIMEICON $ROXMIMEPATH/$ONEMIMEICON
     fi
    done
    for ONEGROUP in hicolor HighContrast HighContrastInverse LowContrast; do
     if [ -d $JREHOME/lib/desktop/icons/$ONEGROUP ]; then
      mkdir -p /usr/share/icons/$ONEGROUP/16x16/apps
      mkdir -p /usr/share/icons/$ONEGROUP/48x48/apps
      for ONEMAINICON in $MAINICONS; do
       if [ -f $JREHOME/lib/desktop/icons/$ONEGROUP/16x16/apps/$ONEMAINICON ]; then
        ln -sf $JREHOME/lib/desktop/icons/$ONEGROUP/16x16/apps/$ONEMAINICON /usr/share/icons/$ONEGROUP/16x16/apps/
       fi
       if [ -f $JREHOME/lib/desktop/icons/$ONEGROUP/48x48/apps/$ONEMAINICON ]; then
        ln -sf $JREHOME/lib/desktop/icons/$ONEGROUP/48x48/apps/$ONEMAINICON /usr/share/icons/$ONEGROUP/48x48/apps/
       fi
      done
      mkdir -p /usr/share/icons/$ONEGROUP/16x16/mimetypes
      mkdir -p /usr/share/icons/$ONEGROUP/48x48/mimetypes
      for ONEMIMEICON in $MIMEICONS; do
       if [ -f $JREHOME/lib/desktop/icons/$ONEGROUP/16x16/mimetypes/gnome-mime-$ONEMIMEICON ]; then
        ln -sf $JREHOME/lib/desktop/icons/$ONEGROUP/16x16/mimetypes/gnome-mime-$ONEMIMEICON /usr/share/icons/$ONEGROUP/16x16/mimetypes/
       fi
       if [ -f $JREHOME/lib/desktop/icons/$ONEGROUP/48x48/mimetypes/gnome-mime-$ONEMIMEICON ]; then
        ln -sf $JREHOME/lib/desktop/icons/$ONEGROUP/48x48/mimetypes/gnome-mime-$ONEMIMEICON /usr/share/icons/$ONEGROUP/48x48/mimetypes/
       fi
      done
     fi
    done
}

function remove_icon_links() {
    for ONEIMAGE in $IMAGES; do
     rm -f /usr/share/pixmaps/$ONEIMAGE
    done
    for ONEMAINICON in $MAINICONS; do
     rm -f /usr/local/lib/X11/mini-icons/$ONEMAINICON
    done
    for ONEMIMEICON in $MIMEICONS; do
     [ "$ROXMIMEPATH" ] && rm -f $ROXMIMEPATH/$ONEMIMEICON
    done
    for ONEGROUP in hicolor HighContrast HighContrastInverse LowContrast; do
     for ONEMAINICON in $MAINICONS; do
      rm -f /usr/share/icons/$ONEGROUP/16x16/apps/$ONEMAINICON
      rm -f /usr/share/icons/$ONEGROUP/48x48/apps/$ONEMAINICON
     done
     for ONEMIMEICON in $MIMEICONS; do
      rm -f /usr/share/icons/$ONEGROUP/16x16/mimetypes/gnome-mime-$ONEMIMEICON
      rm -f /usr/share/icons/$ONEGROUP/48x48/mimetypes/gnome-mime-$ONEMIMEICON
     done
    done
}

case "$ARGUMENT" in
 start|change)
  BROWSERS=''; BROWSERPLUGINS=''
  IMAGES=''; MAINICONS=''; MIMEICONS=''
  . /etc/javaif.conf
  PREVJAVAHOME="$JAVAHOME"
  PREVJREHOME="$JREHOME"
  PREVVERSION="$JAVAVERSION"
  FORCEEXECPATH=false
  ROXMIMEPATH=$(find /usr -maxdepth 5 -name "MIME" | grep -m 1 'ROX-Filer')
  update_configuration
  if [ "$JAVAHOME" ]; then
   if [ "$PREVJREHOME" ]; then
    remove_plugin_links
    remove_icon_links
   fi
   add_plugin_links
   add_icon_links
   # Remove possible conflicting override links & script from PET/SFS package
   for ONEEXEC in java javac javaws jcontrol jjs; do
    rm -f /usr/bin/$ONEEXEC
   done
   rm -f /etc/init.d/java.sfs.sh # possible conflicting init scripts
   rm -f etc/init.d/java
  else
   remove_plugin_links
   remove_icon_links
  fi
  ;;
esac

