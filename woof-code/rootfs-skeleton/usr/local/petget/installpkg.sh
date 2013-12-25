#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/downloadpkgs.sh and petget.
#passed param is the path and name of the downloaded package.
#/tmp/petget_missing_dbentries-Packages-* has database entries for the set of pkgs being downloaded.
#w456 warning: petget may write to /tmp/petget_missing_dbentries-Packages-alien with missing fields.
#w478, w482 fix for pkg menu categories.
#w482 detect zero-byte pet.specs, fix typo.
#100110 add support for T2 .tar.bz2 binary packages.
#100426 aufs can now write direct to save layer.
#100616 add support for .txz slackware pkgs.
# 20aug10 shinobar: excute pinstall.sh under original LANG environment
#  6sep10 shinobar: warning to install on /mnt/home # 16sep10 remove test code
# 17sep10 shinobar; fix typo was double '|' at reading DESCRIPTION
# 22sep10 shinobar clean up probable old files for precaution
# 22sep10 shinobar: bugfix was not working clean out whiteout files
#110503 change ownership of some files if non-root.
#110523 support for rpm pkgs.
#110705 fix rpm install.
#110817 rcrsn51: fix find syntax, looking for icons. 110821 improve.
#111013 shinobar: aufs direct-write to layer not working, bypass for now.
#111013 revert above. it works for me, except if file already on top -- that is another problem, needs to be addressed.
#111207 improve search for menu icon.
#111229 /usr/local/petget/removepreview.sh when uninstalling a pkg, may have copied a file from sfs-layer to top, check.
#120102 install may have overwritten a symlink-to-dir.
#120107 rerwin: need quotes around some paths in case of space chars. remove '--unlink-first' from tar (was introduced 120102, don't think necessary).
#120126 noryb009: fix typo.
#120219 was not properly internationalized (there was no TEXTDOMAIN).
#120523 may need to run gio-query-modules and/or glib-compile-schemas. (refer also rc.update and 3builddistro)
#120628 fix Categories= assignment in .desktop files. see also 2createpackages in woof.
#120818 Categories management improved. pkg db now has category[;subcategory] (see 0setup), xdg enhanced (see /etc/xdg and /usr/share/desktop-directories), and generic icons for all subcategories (see /usr/local/lib/X11/mini-icons).
#120901 .desktop files, get rid of param on end of Exec, ex: Exec=gimp-2.8 %U
#120907 post-install hacks.
#120926 apply translation for .desktop file if langpack installed.
#121015 01micko: alternative code to delete %-param off end of Exec line in .desktop file.
#121109 fixing Categories field in .desktop may fail, as DB_category field may not match that in .desktop file, so leave out that $tPATTERN match in $PUPHIERARCHY.
#121109 menu category was not reported correctly in post-install window.
#121119 change in layout of /etc/xdg/menus/hierarchy caused regex pattern bug.
#121119 if only one .desktop file, first check if a match in /usr/local/petget/categories.dat.
#121120 bugfix of 121119.
#121123 having a problem with multiarch symlinks in full-installation, getting replaced by a directory.
#121206 default icon needs .xpm extension. note puppy uses older xdg-utilities, Icon field needs image ext.
#121217 still getting reports multiarch symlinks getting overwritten.
#130112 some deb's have a post-install script (ex: some python debs).
#130112 multiarch symlinks now optional. see also 2createpackages, 3builddistro.
#130114 revert 130112 "multiarch symlinks now optional".
#130126 'categories.dat' format changed.
#130219 grep, ignore case.
#130305 rerwin: ensure tmp directory has all permissions after package expansion.
#130314 install arch linux pkgs. run arch linux pkg post-install script.
#131122 support xz compressed pets (see dir2pet, pet2tgz), changed file test

export TEXTDOMAIN=petget___installpkg.sh
export OUTPUT_CHARSET=UTF-8

APPDIR=$(dirname $0)
[ -f "$APPDIR/i18n_head" ] && source "$APPDIR/i18n_head"
LANG_USER=$LANG
export LANG=C
. /etc/rc.d/PUPSTATE  #this has PUPMODE and SAVE_LAYER.
. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION

. /etc/xdg/menus/hierarchy #w478 has PUPHIERARCHY variable.

DLPKG="$1"
DLPKG_BASE="`basename $DLPKG`" #ex: scite-1.77-i686-2as.tgz
DLPKG_PATH="`dirname $DLPKG`"  #ex: /root

# 6sep10 shinobar: installing files under /mnt is danger
install_path_check() {
  FILELIST="/root/.packages/${DLPKG_NAME}.files"
  [ -s "$FILELIST" ] || return 0 #120126 noryb009: typo
  grep -q '^/mnt' "$FILELIST" || return 0
  MNTDIRS=$(cat "$FILELIST" | grep '^/mnt/.*/$' | cut -d'/' -f1-3  | tail -n 1)
  LANG=$LANG_USER
  MSG1=$(gettext "This package will install files under")
  MSG2=$(gettext "It can be dangerous to install files under '/mnt' because it depends on the profile of installation.")
  MSG3=""
  if grep -q '^/mnt/home' "$FILELIST"; then
    if [ $PUPMODE -eq 5 ]; then
      MSG3=$(gettext "You are running Puppy without 'pupsave', and '/mnt/home' does not exist. In this case, you can use the RAM for this space, but strongly recommended to shutdown now to create 'pupsave' BEFORE installing these packages.")
      MSG3="$MSG3\\n$(gettext "NOTE: You can install this package for a tentative use, then do NOT make 'pupsave' with this package installed.")"
    fi
    DIRECTSAVEPATH=""
  fi
  # dialog
  export DIALOG="<window title=\"$T_title\" icon-name=\"gtk-dialog-warning\">
  <vbox>
  <text use-markup=\"true\"><label>\"$MSG1: <b>$MNTDIRS</b>\"</label></text>
  <text><input>echo -en \"$MSG2 $MSG3\"</input></text>
  <text><label>$(gettext "Click 'Cancel' not to install(recommended). Or click 'Install' if you like to proceed.")</label></text>
  <hbox>
  <button cancel></button>
  <button><input file stock=\"gtk-apply\"></input><label>$(gettext 'Install')</label><action type=\"exit\">INSTALL</action></button>
  </hbox>
  </vbox>
  </window>"
  RETPARAMS=`gtkdialog3 --program=DIALOG` || echo "$DIALOG" >&2
  eval "$RETPARAMS"
  LANG=C
  [ "$EXIT" = "INSTALL" ]  && return 0
  rm -f "$FILELIST" 
  exit 1
}

# 22sep10 shinobar clean up probable old files for precaution
 rm -f /pet.specs /pinstall.sh /puninstall.sh /install/doinst.sh

#get the pkg name ex: scite-1.77 ...
dbPATTERN='|'"$DLPKG_BASE"'|'
DLPKG_NAME="`cat /tmp/petget_missing_dbentries-Packages-* | grep "$dbPATTERN" | head -n 1 | cut -f 1 -d '|'`"

#boot from flash: bypass tmpfs top layer, install direct to pup_save file...
DIRECTSAVEPATH=""
#111013 shinobar: this currently not working, bypass for now... 111013 revert...
#if [ "ABC" = "DEF" ];then #111013
if [ $PUPMODE -eq 3 -o $PUPMODE -eq 7 -o $PUPMODE -eq 13 ];then
 FLAGNODIRECT=1
 [ "`lsmod | grep '^unionfs' `" != "" ] && FLAGNODIRECT=0
 #100426 aufs can now write direct to save layer...
 if [ "`lsmod | grep '^aufs' `" != "" ];then
  #note: fsnotify now preferred not inotify, udba=notify uses whichever is enabled in module...
  busybox mount -t aufs -o remount,udba=notify unionfs / #remount aufs with best evaluation mode.
  FLAGNODIRECT=$?
  [ $FLAGNODIRECT -ne 0 ] && logger -s -t "installpkg.sh" "Failed to remount aufs / with udba=notify"
 fi
 if [ $FLAGNODIRECT -eq 0 ];then
  #note that /sbin/pup_event_frontend_d will not run snapmergepuppy if installpkg.sh or downloadpkgs.sh are running.
  while [ "`pidof snapmergepuppy`" != "" ];do
   sleep 1
  done
  DIRECTSAVEPATH="/initrd${SAVE_LAYER}" #SAVE_LAYER is in /etc/rc.d/PUPSTATE.
  rm -f $DIRECTSAVEPATH/pet.specs $DIRECTSAVEPATH/pinstall.sh $DIRECTSAVEPATH/puninstall.sh $DIRECTSAVEPATH/install/doinst.sh
 fi
fi

cd $DLPKG_PATH

case $DLPKG_BASE in
 *.pet)
  # determine compression
  file -b "$DLPKG_BASE" | grep -q "^xz" && EXT=xz || EXT=gz #131122
  case $EXT in
  xz)OPT=-J ;;
  gz)OPT=-z ;;
  esac
  DLPKG_MAIN="`basename $DLPKG_BASE .pet`"
  pet2tgz $DLPKG_BASE
  [ $? -ne 0 ] && exit 1
  PETFILES="`tar --list ${OPT} -f ${DLPKG_MAIN}.tar.${EXT}`"
  #slackware pkg, got a case where passed the above test but failed here...
  [ $? -ne 0 ] && exit 1
  if [ "`echo "$PETFILES" | grep '^\\./'`" != "" ];then
   #ttuuxx has created some pets with './' prefix...
   pPATTERN="s%^\\./${DLPKG_NAME}%%"
   echo "$PETFILES" | sed -e "$pPATTERN" > /root/.packages/${DLPKG_NAME}.files
   install_path_check
   tar ${OPT} -x --strip=2 --directory=${DIRECTSAVEPATH}/ -f ${DLPKG_MAIN}.tar.${EXT} #120102. 120107 remove --unlink-first
  else
   #new2dir and tgz2pet creates them this way...
   pPATTERN="s%^${DLPKG_NAME}%%"
   echo "$PETFILES" | sed -e "$pPATTERN" > /root/.packages/${DLPKG_NAME}.files
   install_path_check
   tar ${OPT} -x --strip=1 --directory=${DIRECTSAVEPATH}/ -f ${DLPKG_MAIN}.tar.${EXT} #120102. 120107. 131122
  fi
 ;;
 *.deb)
  DLPKG_MAIN="`basename $DLPKG_BASE .deb`"
  PFILES="`dpkg-deb --contents $DLPKG_BASE | tr -s ' ' | cut -f 6 -d ' '`"
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/${DLPKG_NAME}.files
  install_path_check
  dpkg-deb -x $DLPKG_BASE ${DIRECTSAVEPATH}/
  if [ $? -ne 0 ];then
   rm -f /root/.packages/${DLPKG_NAME}.files
   exit 1
  fi
  [ -d /DEBIAN ] && rm -rf /DEBIAN #130112 precaution.
  dpkg-deb -e $DLPKG_BASE /DEBIAN #130112 extracts deb control files to dir /DEBIAN. may have a post-install script, see below.
 ;;
 *.tgz)
  DLPKG_MAIN="`basename $DLPKG_BASE .tgz`" #ex: scite-1.77-i686-2as
  gzip --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -z -f $DLPKG_BASE`"
  #hmmm, got a case where passed the above test but failed here...
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/${DLPKG_NAME}.files
  install_path_check
  tar -z -x --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE #120102. 120107
 ;;
 *.txz) #100616
  DLPKG_MAIN="`basename $DLPKG_BASE .txz`" #ex: scite-1.77-i686-2as
  xz --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -J -f $DLPKG_BASE`"
  #hmmm, got a case where passed the above test but failed here...
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/${DLPKG_NAME}.files
  install_path_check
  tar -J -x --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE #120102. 120107
 ;;
 *.tar.gz)
  DLPKG_MAIN="`basename $DLPKG_BASE .tar.gz`" #ex: acl-2.2.47-1-i686.pkg
  gzip --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -z -f $DLPKG_BASE`"
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/${DLPKG_NAME}.files
  install_path_check
  tar -z -x --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE #120102. 120107
 ;;
 *.tar.bz2) #100110
  DLPKG_MAIN="`basename $DLPKG_BASE .tar.bz2`"
  bzip2 --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -j -f $DLPKG_BASE`"
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/${DLPKG_NAME}.files
  install_path_check
  tar -j -x --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE #120102. 120107
 ;;
 *.pkg.tar.zx) #130314 arch pkgs.
  DLPKG_MAIN="`basename $DLPKG_BASE .pkg.tar.xz`" #ex: acl-2.2.51-3-i686
  xz --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -J -f $DLPKG_BASE`"
  #hmmm, got a case where passed the above test but failed here...
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/${DLPKG_NAME}.files
  install_path_check
  tar -J -x --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE
 ;;
 *.rpm) #110523
  DLPKG_MAIN="`basename $DLPKG_BASE .rpm`"
  busybox rpm -qp $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`busybox rpm -qpl $DLPKG_BASE`"
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/${DLPKG_NAME}.files
  install_path_check
  #110705 rpm -i does not work for mageia pkgs...
  exploderpm -i $DLPKG_BASE
 ;;
esac

rm -f $DLPKG_BASE 2>/dev/null
rm -f $DLPKG_MAIN.tar.${EXT} 2>/dev/null #131122

#pkgname.files may need to be fixed...
FIXEDFILES="`cat /root/.packages/${DLPKG_NAME}.files | grep -v '^\\./$'| grep -v '^/$' | sed -e 's%^\\.%%' -e 's%^%/%' -e 's%^//%/%'`"
echo "$FIXEDFILES" > /root/.packages/${DLPKG_NAME}.files

#120102 install may have overwritten a symlink-to-dir...
#tar defaults to not following symlinks, for both dirs and files, but i want to follow symlinks
#for dirs but not for files. so, fix here... (note, dir entries in .files have / on end)
cat /root/.packages/${DLPKG_NAME}.files | grep '[a-zA-Z0-9]/$' | sed -e 's%/$%%' | grep -v '^/mnt' |
while read ONESPEC
do
 if [ -d "${DIRECTSAVEPATH}${ONESPEC}" ];then
  if [ ! -h "${DIRECTSAVEPATH}${ONESPEC}" ];then
   DIRLINK=""
   if [ -h "/initrd${PUP_LAYER}${ONESPEC}" ];then #120107
    DIRLINK="`readlink -m "/initrd${PUP_LAYER}${ONESPEC}" | sed -e "s%/initrd${PUP_LAYER}%%"`" #PUP_LAYER: see /etc/rc.d/PUPSTATE. 120107
    xDIRLINK="`readlink "/initrd${PUP_LAYER}${ONESPEC}"`" #120107
   fi
   if [ ! "$DIRLINK" ];then
    if [ -h "/initrd${SAVE_LAYER}${ONESPEC}" ];then #120107
     DIRLINK="`readlink -m "/initrd${SAVE_LAYER}${ONESPEC}" | sed -e "s%/initrd${SAVE_LAYER}%%"`" #SAVE_LAYER: see /etc/rc.d/PUPSTATE. 120107
     xDIRLINK="`readlink "/initrd${SAVE_LAYER}${ONESPEC}"`" #120107
    fi
   fi
   if [ "$DIRLINK" ];then
    if [ -d "$DIRLINK"  ];then
     if [ "$DIRLINK" != "${ONESPEC}" ];then #precaution.
      mkdir -p "${DIRECTSAVEPATH}${DIRLINK}" #120107
      cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONESPEC}"/* "${DIRECTSAVEPATH}${DIRLINK}/" #ha! fails if put double-quotes around entire expression.
      rm -rf "${DIRECTSAVEPATH}${ONESPEC}"
      if [ "$DIRECTSAVEPATH" = "" ];then
       ln -s "$xDIRLINK" "${ONESPEC}"
      else
       DSOPATH="`dirname "${DIRECTSAVEPATH}${ONESPEC}"`"
       DSOBASE="`basename "${DIRECTSAVEPATH}${ONESPEC}"`"
       rm -f "${DSOPATH}/.wh.${DSOBASE}" #allow underlying symlink to become visible on top.
      fi
     fi
    fi
   fi
  fi
 fi
done

#121217 it seems that this problem is occurring in other modes (13 reported)...
#121123 having a problem with multiarch symlinks in full-installation...
#it seems that the symlink is getting replaced by a directory.
if [ "$DISTRO_ARCHDIR" ];then #in /etc/rc.d/DISTRO_SPECS. 130112 change test from DISTRO_ARCHDIR. 130114 revert DISTRO_ARCHDIR_SYMLINKS==yes.
  if [ -d /usr/lib/${DISTRO_ARCHDIR} ];then
   if [ ! -h /usr/lib/${DISTRO_ARCHDIR} ];then
    cp -a -f --remove-destination /usr/lib/${DISTRO_ARCHDIR}/* /usr/lib/
    sync
    rm -r -f /usr/lib/${DISTRO_ARCHDIR}
    ln -s ./ /usr/lib/${DISTRO_ARCHDIR}
   fi
  fi
  if [ -d /lib/${DISTRO_ARCHDIR} ];then
   if [ ! -h /lib/${DISTRO_ARCHDIR} ];then
    cp -a -f --remove-destination /lib/${DISTRO_ARCHDIR}/* /lib/
    sync
    rm -r -f /lib/${DISTRO_ARCHDIR}
    ln -s ./ /lib/${DISTRO_ARCHDIR}
   fi
  fi
  if [ -d /usr/bin/${DISTRO_ARCHDIR} ];then
   if [ ! -h /usr/bin/${DISTRO_ARCHDIR} ];then
    cp -a -f --remove-destination /usr/bin/${DISTRO_ARCHDIR}/* /usr/bin/
    sync
    rm -r -f /usr/bin/${DISTRO_ARCHDIR}
    ln -s ./ /usr/bin/${DISTRO_ARCHDIR}
   fi
  fi
fi

#flush unionfs cache, so files in pup_save layer will appear "on top"...
if [ "$DIRECTSAVEPATH" != "" ];then
 #but first, clean out any bad whiteout files...
 # 22sep10 shinobar: bugfix was not working clean out whiteout files
 find /initrd/pup_rw -mount -type f -name .wh.\*  -printf '/%P\n'|
 while read ONEWHITEOUT
 do
  ONEWHITEOUTFILE="`basename "$ONEWHITEOUT"`"
  ONEWHITEOUTPATH="`dirname "$ONEWHITEOUT"`"
  if [ "$ONEWHITEOUTFILE" = ".wh.__dir_opaque" ];then
   [ "`grep "$ONEWHITEOUTPATH" /root/.packages/${DLPKG_NAME}.files`" != "" ] && rm -f "/initrd/pup_rw/$ONEWHITEOUT"
   continue
  fi
  ONEPATTERN="`echo -n "$ONEWHITEOUT" | sed -e 's%/\\.wh\\.%/%'`"'/*'	;#echo "$ONEPATTERN" >&2
  [ "`grep -x "$ONEPATTERN" /root/.packages/${DLPKG_NAME}.files`" != "" ] && rm -f "/initrd/pup_rw/$ONEWHITEOUT"
 done
 #111229 /usr/local/petget/removepreview.sh when uninstalling a pkg, may have copied a file from sfs-layer to top, check...
 cat /root/.packages/${DLPKG_NAME}.files |
 while read ONESPEC
 do
  [ "$ONESPEC" = "" ] && continue #precaution.
  if [ ! -d "$ONESPEC" ];then
   [ -e "/initrd/pup_rw${ONESPEC}" ] && rm -f "/initrd/pup_rw${ONESPEC}"
  fi
 done
 #now re-evaluate all the layers...
 if [ "`lsmod | grep '^aufs' `" != "" ];then #100426
  busybox mount -t aufs -o remount,udba=reval unionfs / #remount with faster evaluation mode.
  [ $? -ne 0 ] && logger -s -t "installpkg.sh" "Failed to remount aufs / with udba=reval"
 else
  mount -t unionfs -o remount,incgen unionfs /
 fi
 sync
fi

#some .pet pkgs have images at '/'...
mv /*24.xpm /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*32.xpm /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*32.png /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*48.xpm /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*48.png /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*.xpm /usr/local/lib/X11/mini-icons/ 2>/dev/null
mv /*.png /usr/local/lib/X11/mini-icons/ 2>/dev/null

ls -dl /tmp | grep -q '^drwxrwxrwt' || chmod 1777 /tmp #130305 rerwin.

#post-install script?...
if [ -f /pinstall.sh ];then #pet pkgs.
 chmod +x /pinstall.sh
 cd /
  LANG=$LANG_USER sh /pinstall.sh
 rm -f /pinstall.sh
fi
if [ -f /install/doinst.sh ];then #slackware pkgs.
 chmod +x /install/doinst.sh
 cd /
 LANG=$LANG_USER sh /install/doinst.sh
 rm -rf /install
fi
if [ -e /DEBIAN/postinst ];then #130112 deb post-install script.
 cd /
 LANG=$LANG_USER sh DEBIAN/postinst
 rm -rf /DEBIAN
fi
#130314 run arch linux pkg post-install script...
if [ -f /.INSTALL ];then #arch post-install script.
 if [ -f /usr/local/petget/ArchRunDotInstalls ];then #precaution. see 3builddistro, script created by noryb009.
  #this code is taken from below...
  dlPATTERN='|'"`echo -n "$DLPKG_BASE" | sed -e 's%\\-%\\\\-%'`"'|'
  archVER="`cat /tmp/petget_missing_dbentries-Packages-* | grep "$dlPATTERN" | head -n 1 | cut -f 3 -d '|'`"
  if [ "$archVER" ];then #precaution.
   cd /
   mv -f .INSTALL .INSTALL1-${archVER}
   cp -a /usr/local/petget/ArchRunDotInstalls /ArchRunDotInstalls
   LANG=$LANG_USER /ArchRunDotInstalls
   rm -f ArchRunDotInstalls
   rm -f .INSTALL*
  fi
 fi
fi

#v424 .pet pkgs may have a post-uninstall script...
if [ -f /puninstall.sh ];then
 mv -f /puninstall.sh /root/.packages/${DLPKG_NAME}.remove
fi

#w465 <pkgname>.pet.specs is in older pet pkgs, just dump it...
#maybe a '$APKGNAME.pet.specs' file created by dir2pet script...
rm -f /*.pet.specs 2>/dev/null
#...note, this has a setting to prevent .files and entry in user-installed-packages, so install not registered.

#add entry to /root/.packages/user-installed-packages...
#w465 a pet pkg may have /pet.specs which has a db entry...
if [ -f /pet.specs -a -s /pet.specs ];then #w482 ignore zero-byte file.
 DB_ENTRY="`cat /pet.specs | head -n 1`"
 rm -f /pet.specs
else
 [ -f /pet.specs ] && rm -f /pet.specs #w482 remove zero-byte file.
 dlPATTERN='|'"`echo -n "$DLPKG_BASE" | sed -e 's%\\-%\\\\-%'`"'|'
 DB_ENTRY="`cat /tmp/petget_missing_dbentries-Packages-* | grep "$dlPATTERN" | head -n 1`"
fi
echo DLPKG_BASE=$DLPKG_BASE
echo DLPKG_NAME=$DLPKG_NAME
echo DB_ENTRY=$DB_ENTRY
##+++2011-12-27 KRG check if $DLPKG_BASE matches DB_ENTRY 1 so uninstallation works :Ooops:
db_pkg_name=`echo "$DB_ENTRY" |cut -f 1 -d '|'`
echo db_pkg_name=$db_pkg_name
if [ "$db_pkg_name" != "$DLPKG_NAME" ];then
 echo not equal sed ing now
 DB_ENTRY=`echo "$DB_ENTRY" |sed "s#$db_pkg_name#$DLPKG_NAME#"`
fi
##+++2011-12-27 KRG

#see if a .desktop file was installed, fix category... 120628 improve...
#120818 overhauled. Pkg db now has category[;subcategory] (see 0setup), xdg enhanced (see /etc/xdg and /usr/share/desktop-directories), and generic icons for all subcategories (see /usr/local/lib/X11/mini-icons).
#note, similar code also in Woof 2createpackages.
ONEDOT=""
CATEGORY="`echo -n "$DB_ENTRY" | cut -f 5 -d '|'`" #exs: Document, Document;edit
[ "$CATEGORY" = "" ] && CATEGORY='BuildingBlock' #paranoid precaution.
#xCATEGORY and DEFICON will be the fallbacks if Categories entry in .desktop is invalid...
xCATEGORY="`echo -n "$CATEGORY" | sed -e 's%^%X-%' -e 's%;%-%'`" #ex: X-Document-edit (refer /etc/xdg/menu/*.menu)
DEFICON="`echo -n "$CATEGORY" | sed -e 's%^%mini-%' -e 's%;%-%'`"'.xpm' #ex: mini-Document-edit (refer /usr/local/lib/X11/mini-icons -- these are in jwm search path) 121206 need .xpm extention.
case $CATEGORY in
 Calculate)     CATEGORY='Business'             ; xCATEGORY='X-Business'            ; DEFICON='mini-Business.xpm'            ;; #Calculate is old name, now Business.
 Develop)       CATEGORY='Utility;development'  ; xCATEGORY='X-Utility-development' ; DEFICON='mini-Utility-development.xpm' ;; #maybe an old pkg has this.
 Help)          CATEGORY='Utility;help'         ; xCATEGORY='X-Utility-help'        ; DEFICON='mini-Help.xpm'                ;; #maybe an old pkg has this.
 BuildingBlock) CATEGORY='Utility'              ; xCATEGORY='Utility'               ; DEFICON='mini-BuildingBlock.xpm'       ;; #unlikely to have a .desktop file.
esac
topCATEGORY="`echo -n "$CATEGORY" | cut -f 1 -d ';'`"
tPATTERN="^${topCATEGORY} "
cPATTERN="s%^Categories=.*%Categories=${xCATEGORY}%"
iPATTERN="s%^Icon=.*%Icon=${DEFICON}%"

#121119 if only one .desktop file, first check if a match in /usr/local/petget/categories.dat...
CATDONE='no'
if [ -f /usr/local/petget/categories.dat ];then #precaution, but it will be there.
 NUMDESKFILE="$(grep 'share/applications/.*\.desktop$' /root/.packages/${DLPKG_NAME}.files | wc -l)"
 if [ "$NUMDESKFILE" = "1" ];then
  #to lookup categories.dat, we need to know the generic name of the package, which may be different from pkg name...
  #db entry format: pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|compileddistro|compiledrelease|repo|
  DBNAMEONLY="$(echo -n "$DB_ENTRY" | cut -f 2 -d '|')"
  DBPATH="$(echo -n "$DB_ENTRY" | cut -f 7 -d '|')"
  DBCOMPILEDDISTRO="$(echo -n "$DB_ENTRY" | cut -f 11 -d '|')"
  [ ! "$DBCOMPILEDDISTRO" ] && DBCOMPILEDDISTRO='puppy' #any name will do here.
  case $DBCOMPILEDDISTRO in
   debian|ubuntu|raspbian)
    if [ "$DBPATH" ];then #precaution
     xNAMEONLY="$(basename ${DBPATH})"
    else
     xNAMEONLY="$DBNAMEONLY"
    fi
   ;;
   *) xNAMEONLY="$DBNAMEONLY" ;;
  esac
  xnPTN=" ${xNAMEONLY} "
  #130126 categories.dat format changed slightly... 130219 ignore case...
  CATVARIABLE="$(grep -i "$xnPTN" /usr/local/petget/categories.dat | grep '^PKGCAT' | head -n 1 | cut -f 1 -d '=' | cut -f 2,3 -d '_' | tr '_' '-')" #ex: PKGCAT_Graphic_camera=" gphoto2 gtkam "
  if [ "$CATVARIABLE" ];then #ex: Graphic-camera
   xCATEGORY="X-${CATVARIABLE}"
   cPATTERN="s%^Categories=.*%Categories=${xCATEGORY}%" #121120
   CATFOUND="yes"
   CATDONE='yes'
  fi
 fi
fi

for ONEDOT in `grep 'share/applications/.*\.desktop$' /root/.packages/${DLPKG_NAME}.files | tr '\n' ' '` #121119 exclude other strange .desktop files.
do
 #120901 get rid of param on end of Exec, ex: Exec=gimp-2.8 %U
 #sed -i -e 's/\(^Exec=[^%]*\).*/\1/' -e 's/ *$//' $ONEDOT #'s/\(^Exec=[^ ]*\).*/\1/'
 #121015 01micko: alternative that may work better...
 for PARMATER in u U f F #refer:  http://standards.freedesktop.org/desktop-entry-spec/latest/ar01s06.html
 do
  sed -i "s/ %${PARMATER}//" $ONEDOT
 done
 
 #w478 find if category is already valid (see also 2createpackages)..
 if [ "$CATDONE" = "no" ];then #121119
  CATFOUND="no"
  for ONEORIGCAT in `cat $ONEDOT | grep '^Categories=' | head -n 1 | cut -f 2 -d '=' | tr ';' ' ' | rev` #search in reverse order.
  do
   ONEORIGCAT="`echo -n "$ONEORIGCAT" | rev`" #restore rev of one word.
   oocPATTERN=' '"$ONEORIGCAT"' '
   [ "`echo "$PUPHIERARCHY" | tr -s ' ' | grep "$tPATTERN" | cut -f 3 -d ' ' | tr ',' ' ' | sed -e 's%^% %' -e 's%$% %' | grep "$oocPATTERN"`" != "" ] && CATFOUND="yes"
   #got a problem with sylpheed, "Categories=GTK;Network;Email;News;" this displays in both Network and Internet menus...
   if [ "$CATFOUND" = "yes" ];then
    cPATTERN="s%^Categories=.*%Categories=${ONEORIGCAT}%"
    break
   fi
  done
  #121109 above may fail, as DB_category field may not match that in .desktop file, so leave out that $tPATTERN match in $PUPHIERARCHY...
  if [ "$CATFOUND" = "no" ];then
   for ONEORIGCAT in `cat $ONEDOT | grep '^Categories=' | head -n 1 | cut -f 2 -d '=' | tr ';' ' ' | rev` #search in reverse order.
   do
    ONEORIGCAT="`echo -n "$ONEORIGCAT" | rev`" #restore rev of one word.
    oocPATTERN=' '"$ONEORIGCAT"' '
    [ "`echo "$PUPHIERARCHY" | tr -s ' ' | cut -f 3 -d ' ' | tr ',' ' ' | sed -e 's%^% %' -e 's%$% %' | grep "$oocPATTERN"`" != "" ] && CATFOUND="yes"
    #got a problem with sylpheed, "Categories=GTK;Network;Email;News;" this displays in both Network and Internet menus...
    if [ "$CATFOUND" = "yes" ];then
     cPATTERN="s%^Categories=.*%Categories=${ONEORIGCAT}%"
     break
    fi
   done
  fi
 fi
 sed -i -e "$cPATTERN" $ONEDOT #fix Categories= entry.

 #w019 does the icon exist?...
 ICON="`grep '^Icon=' $ONEDOT | cut -f 2 -d '='`"
 if [ "$ICON" != "" ];then
  [ -e "$ICON" ] && continue #it may have a hardcoded path.
  ICONBASE="`basename "$ICON"`"
  #110706 fix icon entry in .desktop... 110821 improve...
  #first search where jwm looks for icons... 111207...
  FNDICON="`find /usr/local/lib/X11/mini-icons /usr/share/pixmaps -maxdepth 1 -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
  if [ "$FNDICON" ];then
   ICONNAMEONLY="`basename $FNDICON`"
   iPTN="s%^Icon=.*%Icon=${ICONNAMEONLY}%"
   sed -i -e "$iPTN" $ONEDOT
   continue
  else
   #look elsewhere... 111207...
   FNDICON="`find /usr/share/icons /usr/local/share/pixmaps -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
   #111207 look further afield, ex parole pkg has /usr/share/parole/pixmaps/parole.png...
   [ ! "$FNDICON" ] && [ -d /usr/share/$ICONBASE ] && FNDICON="`find /usr/share/${ICONBASE} -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
   #111207 getting desperate...
   [ ! "$FNDICON" ] && FNDICON="`find /usr/share -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
   if [ "$FNDICON" ];then
    ICONNAMEONLY="`basename "$FNDICON"`"
    ln -snf "$FNDICON" /usr/share/pixmaps/${ICONNAMEONLY}
    iPTN="s%^Icon=.*%Icon=${ICONNAMEONLY}%"
    sed -i -e "$iPTN" $ONEDOT
    continue
   fi
  fi
  #substitute a default icon...
  sed -i -e "$iPATTERN" $ONEDOT #note, ONEDOT is name of .desktop file.
 fi
 
 #120926 if a langpack installed, it will have /usr/share/applications.in (see /usr/sbin/momanager, /usr/share/doc/langpack-template/pinstall.sh).
 ABASEDESKTOP="`basename $ONEDOT`"
 ADIRDESKTOP="`dirname $ONEDOT`"
 if [ -f /usr/share/applications.in/${ABASEDESKTOP} ];then
  TARGETLANG="`echo -n $LANG_USER | cut -f 1 -d '_'`" #ex: de
  tlPTN="^Name\[${TARGETLANG}\]"
  if [ "$(grep "$tlPTN" ${ADIRDESKTOP}/${ABASEDESKTOP})" = "" ];then
   if [ "$(grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP})" != "" ];then
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Name=%${INSERTALINE}\\nName=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
  fi
  #do same for Comment field...
  tlPTN="^Comment\[${TARGETLANG}\]"
  if [ "$(grep "$tlPTN" ${ADIRDESKTOP}/${ABASEDESKTOP})" = "" ];then
   if [ "$(grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP})" != "" ];then
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Comment=%${INSERTALINE}\\nComment=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
  fi
  #well, i suppose need this too...
  TARGETLANG="`echo -n $LANG_USER | cut -f 1 -d '.'`" #ex: de_DE
  tlPTN="^Name\[${TARGETLANG}\]"
  if [ "$(grep "$tlPTN" ${ADIRDESKTOP}/${ABASEDESKTOP})" = "" ];then
   if [ "$(grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP})" != "" ];then
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Name=%${INSERTALINE}\\nName=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
  fi
  #do same for Comment field...
  tlPTN="^Comment\[${TARGETLANG}\]"
  if [ "$(grep "$tlPTN" ${ADIRDESKTOP}/${ABASEDESKTOP})" = "" ];then
   if [ "$(grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP})" != "" ];then
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Comment=%${INSERTALINE}\\nComment=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
  fi
 fi
 
done

#due to images at / in .pet and post-install script, .files may have some invalid entries...
INSTFILES="`cat /root/.packages/${DLPKG_NAME}.files`"
echo "$INSTFILES" |
while read ONEFILE
do
 if [ ! -e "$ONEFILE" ];then
  ofPATTERN='^'"$ONEFILE"'$'
  grep -v "$ofPATTERN" /root/.packages/${DLPKG_NAME}.files > /tmp/petget_instfiles
  mv -f /tmp/petget_instfiles /root/.packages/${DLPKG_NAME}.files
 fi
done

#w482 DB_ENTRY may be missing DB_category and DB_description fields...
#pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|
#optionally on the end: compileddistro|compiledrelease|repo| (fields 11,12,13)
DESKTOPFILE="`grep '\.desktop$' /root/.packages/${DLPKG_NAME}.files | head -n 1`"
if [ "$DESKTOPFILE" != "" ];then
 DB_category="`echo -n "$DB_ENTRY" | cut -f 5 -d '|'`"
 DB_description="`echo -n "$DB_ENTRY" | cut -f 10 -d '|'`"
 CATEGORY="$DB_category"
 DESCRIPTION="$DB_description"
 zCATEGORY="`cat $DESKTOPFILE | grep '^Categories=' | sed -e 's%;$%%' | cut -f 2 -d '=' | rev | cut -f 1 -d ';' | rev`" #121109
 if [ "$zCATEGORY" != "" ];then #121109
  #v424 but want the top-level menu category...
  catPATTERN="[ ,]${zCATEGORY},|[ ,]${zCATEGORY} |[ ,]${zCATEGORY}"'$' #121119 fix bug in pattern.
  CATEGORY="`echo "$PUPHIERARCHY" | cut -f 1 -d '#' | grep -E "$catPATTERN" | grep ':' | cut -f 1 -d ' ' | head -n 1`" #121119 /etc/xdg/menus/hierarchy 
 fi
 if [ "$DB_description" = "" ];then
  DESCRIPTION="`cat $DESKTOPFILE | grep '^Comment=' | cut -f 2 -d '='`"
  [ "$DESCRIPTION" = "" ] && DESCRIPTION="`cat $DESKTOPFILE | grep '^Name=' | cut -f 2 -d '='`"	# shinobar
 fi
 if [ "$DB_category" = "" -o "$DB_description" = "" ];then
  newDB_ENTRY="`echo -n "$DB_ENTRY" | cut -f 1-4 -d '|'`"
  newDB_ENTRY="$newDB_ENTRY"'|'"$CATEGORY"'|'
  newDB_ENTRY="$newDB_ENTRY""`echo -n "$DB_ENTRY" | cut -f 6-9 -d '|'`"
  newDB_ENTRY="$newDB_ENTRY"'|'"$DESCRIPTION"'|'
  newDB_ENTRY="$newDB_ENTRY""`echo -n "$DB_ENTRY" | cut -f 11-14 -d '|'`"
  DB_ENTRY="$newDB_ENTRY"
 fi
fi

echo "$DB_ENTRY" >> /root/.packages/user-installed-packages

#110706 fix 'Exec filename %u' line...
DESKTOPFILES="`grep '\.desktop$' /root/.packages/${DLPKG_NAME}.files | tr '\n' ' '`"
for ONEDESKTOP in $DESKTOPFILES
do
 sed -i -e 's/ %u$//' $ONEDESKTOP
done

#120907 post-install hacks...
/usr/local/petget/hacks-postinstall.sh $DLPKG_MAIN

#announcement of successful install...
#announcement is done after all downloads, in downloadpkgs.sh...
CATEGORY="`echo -n "$CATEGORY" | cut -f 1 -d ';'`"
[ "$CATEGORY" = "" ] && CATEGORY="none"
[ "$CATEGORY" = "BuildingBlock" ] && CATEGORY="none"
echo "PACKAGE: $DLPKG_NAME CATEGORY: $CATEGORY" >> /tmp/petget-installed-pkgs-log

#110503 change ownership of some files if non-root...
#hmmm, i think this will only work if running this script as root...
# (the entry script pkg_chooser.sh has sudo to switch to root)
HOMEUSER="`grep '^tty1' /etc/inittab | tr -s ' ' | cut -f 3 -d ' '`" #root or fido.
if [ "$HOMEUSER" != "root" ];then
 grep -E '^/var|^/root|^/etc' /root/.packages/${DLPKG_NAME}.files |
 while read FILELINE
 do
  busybox chown ${HOMEUSER}:users "${FILELINE}"
 done
fi

#120523 precise puppy needs this... (refer also rc.update and 3builddistro)
if [ "`grep '/usr/share/glib-2.0/schemas' /root/.packages/${DLPKG_NAME}.files`" != "" ];then
 [ -e /usr/bin/glib-compile-schemas ] && /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas
fi
if [ "`grep '/usr/lib/gio/modules' /root/.packages/${DLPKG_NAME}.files`" != "" ];then
 [ -e /usr/bin/gio-querymodules ] && /usr/bin/gio-querymodules /usr/lib/gio/modules
fi

###END###
