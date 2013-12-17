#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from pkg_chooser.sh and petget.
#package to be removed is TREE2, ex TREE2=abiword-1.2.3 (corrresponds to 'pkgname' field in db).
#installed pkgs are recorded in /root/.packages/user-installed-packages, each
#line a standardised database entry:
#pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|
#optionally on the end: compileddistro|compiledrelease|repo| (fields 11,12,13)
#If X not running, no GUI windows displayed, removes without question.
#v424 support post-uninstall script for .pet pkgs.
#v424 need info box if user has clicked when no pkgs installed.
#110211 shinobar: was the dependency logic inverted.
#110706 update menu if .desktop file exists.
#111228 if snapmergepuppy running, wait for it to complete.
#120101 01micko: jwm >=547 has -reload, no screen flicker.
#120103 shinobar, bk: improve file deletion when older file in lower layer.
#120107 rerwin: need quotes around some paths in case of space chars.
#120116 rev. 514 introduced icon rendering method which broke -reload at 547. fixed at rev. 574.
#120203 BK: internationalized.
#120323 replace 'xmessage' with 'pupmessage'.

export TEXTDOMAIN=petget___removepreview.sh
export OUTPUT_CHARSET=UTF-8

. /etc/rc.d/PUPSTATE  #111228 this has PUPMODE and SAVE_LAYER.
. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

DB_pkgname="$TREE2"

#v424 info box, nothing yet installed...
if [ "$DB_pkgname" = "" -a "`cat /root/.packages/user-installed-packages`" = "" ];then #fix for ziggi
 export REM_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
   <pixmap><input file>/usr/local/lib/X11/pixmaps/error.xpm</input></pixmap>
   <text><label>$(gettext 'There are no user-installed packages yet, so nothing to uninstall!')</label></text>
   <hbox>
    <button ok></button>
   </hbox>
  </vbox>
 </window>
"
 [ "$DISPLAY" != "" ] && gtkdialog3 --program=REM_DIALOG
 exit 0
fi
if [ "$DB_pkgname" = "" ];then #fix for ziggi moved here problem is  #2011-12-27 KRG
exit 0                         #clicking an empty line in the gui would have
fi                             #thrown the above REM_DIALOG even if pkgs are installed

export REM_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
   <pixmap><input file>/usr/local/lib/X11/pixmaps/question.xpm</input></pixmap>
   <text><label>$(gettext "Click 'OK' button to confirm that you wish to uninstall package") '$DB_pkgname'</label></text>
   <hbox>
    <button ok></button>
    <button cancel></button>
   </hbox>
  </vbox>
 </window>
" 
if [ "$DISPLAY" != "" ];then
 RETPARAMS="`gtkdialog3 --program=REM_DIALOG`"
 eval "$RETPARAMS"
 [ "$EXIT" != "OK" ] && exit 0
fi

#111228 if snapmergepuppy running, wait for it to complete (see also /usr/local/petget/installpkg.sh)...
#note, inverse true, /sbin/pup_event_frontend_d will not run snapmergepuppy if removepreview.sh running.
if [ $PUPMODE -eq 3 -o $PUPMODE -eq 7 -o $PUPMODE -eq 13 ];then
  while [ "`pidof snapmergepuppy`" != "" ];do
   sleep 1
  done
fi

if [ -f /root/.packages/${DB_pkgname}.files ];then
 if [ "$PUP_LAYER" = '/pup_ro2' ]; then #120103 shinobar.
  cat /root/.packages/${DB_pkgname}.files |
  while read ONESPEC
  do
   if [ ! -d "$ONESPEC" ];then
    #120103 shinobar: better way of doing this, look all lower layers...
    S=$(ls /initrd/pup_ro{?,??}"$ONESPEC" 2>/dev/null| grep -v '^/initrd/pup_ro1/'| head -n 1)	# pup_ro2 - pup_ro99
    if [ "$S" ]; then
     #the problem is, deleting the file on the top layer places a ".wh" whiteout file,
     #that hides the original file. what we want is to remove the installed file, and
     #restore the original pristine file...
     cp -a --remove-destination "$S" "$ONESPEC" #120103 shinobar.
     #120103 apparently for odd# PUPMODEs, save layer may have a lurking old file and/or whiteout...
     if [ $PUPMODE -eq 3 -o $PUPMODE -eq 7 -o $PUPMODE -eq 13 ];then
      [ -f "/initrd${SAVE_LAYER}${ONESPEC}" ] && rm -f "/initrd${SAVE_LAYER}${ONESPEC}" #normally /pup_ro1
      BN="`basename "$ONESPEC"`"
      DN="`dirname "$ONESPEC"`"
      [ -f "/initrd${SAVE_LAYER}${DN}/.wh.${BN}" ] && rm -f "/initrd${SAVE_LAYER}${DN}/.wh.${BN}"
     fi
    else
     rm -f "$ONESPEC"
    fi
   fi
  done
 else #120103 shinobar: PUPMODE=2
  cat /root/.packages/${DB_pkgname}.files | grep -v '/$' | xargs rm -f #/ on end, it is a directory entry.
 fi
 #do it again, looking for empty directories...
 cat /root/.packages/${DB_pkgname}.files |
 while read ONESPEC
 do
  if [ -d "$ONESPEC" ];then
   [ "`ls -1 "$ONESPEC"`" = "" ] && rmdir "$ONESPEC" 2>/dev/null #120107
  fi
 done
 ###+++2011-12-27 KRG
else
 firstchar=`echo ${DB_pkgname} | cut -c 1`
 possiblePKGS=`find /root/.packages -type f -iname "$firstchar*.files"`
 possible5=`echo "$possiblePKGS" | head -n5`
 count=`echo "$possiblePKGS" | wc -l`
 [ ! "$count" ] && count=0
 [ ! "$possiblePKGS" ] && possiblePKGS="$(gettext 'No pkgs beginning with') ${firstchar} $(gettext 'found')"
 if [ "$count" -le '5' ];then
  WARNMSG="$possiblePKGS"
 else
  WARNMSG="$(gettext 'Found more than 5 pkgs starting with') ${firstchar}.
$(gettext 'The first 5 are')
$possible5"
 fi
 pupmessage -bg red "$(gettext 'WARNING:')
$(gettext 'No file named') ${DB_pkgname}.files $(gettext 'found in')
/root/.packages/ $(gettext 'folder.')
 
$0
$(gettext 'refusing cowardly to remove the package.')

$(gettext 'Possible suggestions are')
$WARNMSG

$(gettext 'Possible solution:')
$(gettext 'Edit') /root/.packages/user-installed-packages $(gettext 'to match the pkgname')
$(gettext 'and start again.')
"
 rox /root/.packages
 geany /root/.packages/user-installed-packages
 exit 101
 ###+++2011-12-27 KRG
fi

#fix menu...
#master help index has to be updated...
##to speed things up, find the help files in the new pkg only...
/usr/sbin/indexgen.sh #${WKGDIR}/${APKGNAME}

#110706 update menu if .desktop file exists...
if [ -f /root/.packages/${DB_pkgname}.files ];then
 if [ "`grep '\.desktop$' /root/.packages/${DB_pkgname}.files`" != "" ];then
  #Reconstruct configuration files for JWM, Fvwm95, IceWM...
  /usr/sbin/fixmenus
  if [ "`pidof jwm`" != "" ];then #120101
   JWMVER=`jwm -v|head -n1|cut -d ' ' -f2|cut -d - -f2`
   if vercmp $JWMVER lt 574;then #120116 547 to 574.
    jwm -restart #screen will flicker.
   else
    jwm -reload
   fi
  fi
 fi
fi

#what about any user-installed deps...
remPATTERN='^'"$DB_pkgname"'|'
#110211 shinobar: was the dependency logic inverted...
DEP_PKGS="`grep "$remPATTERN" /root/.packages/user-installed-packages | cut -f 9 -d '|' | tr ',' '\n' | grep -v '^\\-' | sed -e 's%^+%%'`"

#remove records of pkg...
rm -f /root/.packages/${DB_pkgname}.files
grep -v "$remPATTERN" /root/.packages/user-installed-packages > /tmp/petget-user-installed-pkgs-rem
cp -f /tmp/petget-user-installed-pkgs-rem /root/.packages/user-installed-packages

#v424 .pet pckage may have post-uninstall script, which was originally named puninstall.sh
#but /usr/local/petget/installpkg.sh moved it to /root/.packages/$DB_pkgname.remove
if [ -f /root/.packages/${DB_pkgname}.remove ];then
 /bin/sh /root/.packages/${DB_pkgname}.remove
 rm -f /root/.packages/${DB_pkgname}.remove
fi

#remove temp file so main gui window will re-filter pkgs display...
FIRSTCHAR="`echo -n "$DB_pkgname" | cut -c 1 | tr '[A-Z]' '[a-z]'`"
rm -f /tmp/petget_fltrd_repo_${FIRSTCHAR}* 2>/dev/null
rm -f /tmp/petget_fltrd_repo_?${FIRSTCHAR}* 2>/dev/null
[ "`echo -n "$FIRSTCHAR" | grep '[0-9]'`" != "" ] && rm -f /tmp/petget_fltrd_repo_0* 2>/dev/null

#announce any deps that might be removable...
echo -n "" > /tmp/petget-deps-maybe-rem
cut -f 1,2,10 -d '|' /root/.packages/user-installed-packages |
while read ONEDB
do
 ONE_pkgname="`echo -n "$ONEDB" | cut -f 1 -d '|'`"
 ONE_nameonly="`echo -n "$ONEDB" | cut -f 2 -d '|'`"
 ONE_description="`echo -n "$ONEDB" | cut -f 3 -d '|'`"
 opPATTERN='^'"$ONE_nameonly"'$'
 [ "`echo "$DEP_PKGS" | grep "$opPATTERN"`" != "" ] && echo "$ONE_pkgname DESCRIPTION: $ONE_description" >> /tmp/petget-deps-maybe-rem
done
EXTRAMSG=""
if [ -s /tmp/petget-deps-maybe-rem ];then
 #nah, just list the names, not descriptions...
 MAYBEREM="`cat /tmp/petget-deps-maybe-rem | cut -f 1 -d ' ' | tr '\n' ' '`"
 EXTRAMSG="<text><label>$(gettext 'Perhaps you do not need these dependencies that you had also installed:')</label></text> <text use-markup=\"true\"><label>\"<b>${MAYBEREM}</b>\"</label></text><text><label>$(gettext "...if you do want to remove them, you will have to do so back on the main window, after clicking the 'Ok' button below (perhaps make a note of the package names on a scrap of paper right now)")</label></text>"
fi

#announce success...
export REM_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
  <pixmap><input file>/usr/local/lib/X11/pixmaps/ok.xpm</input></pixmap>
   <text><label>$(gettext 'Package') '$DB_pkgname' $(gettext 'has been removed.')</label></text>
   ${EXTRAMSG}
   <hbox>
    <button ok></button>
   </hbox>
  </vbox>
 </window>
" 
if [ "$DISPLAY" != "" ];then
 gtkdialog3 --program=REM_DIALOG
fi
###+++2011-12-27 KRG
#emitting exitcode for some windowmanager depending on dbus
#popup a message window saying the program stopped unexpectedly
#ie (old) enlightenment
exit 0
###+++2011-12-27 KRG
###END###
