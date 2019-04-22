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

if [ -e /tmp/libfiles.txt ]; then
 rm -f /tmp/libfiles.txt
fi

[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && \
 [ -f /tmp/remove_pets_quietly ] && set -x
 #; mkdir -p /tmp/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget___removepreview.sh
export OUTPUT_CHARSET=UTF-8
[ "$(locale | grep '^LANG=' | cut -d '=' -f 2)" ] && ORIGLANG="$(locale | grep '^LANG=' | cut -d '=' -f 2)"
. /etc/rc.d/PUPSTATE  #111228 this has PUPMODE and SAVE_LAYER.
. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

fix_broken_symlinks(){
LLIB=""

for LIBx in $(cat /tmp/libfiles.txt)
do
	LIBDN="$(dirname $LIBx)"
	BLIB="$(basename $LIBx)"

	ORGLIB="$(echo "$BLIB" | sed -e "s#\.so#\|#g")"
	xORGLIB="$(echo "$ORGLIB" | cut -f 1 -d '|')"

	if [ "$xORGLIB" != "" ]; then
		if [ "$LLIB" == "" ] || [ "$LLIB" != "$xORGLIB" ]; then
		LLIB="$xORGLIB"
		MOTHERFILE=$(find ${LIBDN} -type f -name "${xORGLIB}.so*" -maxdepth 1 | head -n 1)
			if [ "$MOTHERFILE" != "" ]; then
			 SLL=$(find ${LIBDN} -type l -name "${xORGLIB}.so*" -maxdepth 1 | tr '\n' ' ')
				if [ "$SLL" != "" ]; then
				  for SLINK in $SLL
				  do
					  BLINK="$(basename $SLINK)"
					  RL="$(readlink ${LIBDN}/$BLINK)"
					  if [ "$(echo $RL | cut -c 1)" != "/" ]; then
						xRL="$(basename $RL)"
						if [ ! -f ${LIBDN}/$xRL ]; then
						 rm -f $SLINK
						 ln -s ${MOTHERFILE} $SLINK
						fi
					  elif [ "$(echo $RL | cut -c 1)" == "/" ]; then
						if [ ! -f $RL ]; then
						 rm -f $SLINK
						 ln -s ${MOTHERFILE} $SLINK
						fi
					  else
						 rm -f $SLINK
						 ln -s ${MOTHERFILE} $SLINK					    
					  fi
				  done
				fi
			 fi
		fi
	fi
done	
}


DB_pkgname="$TREE2"

#v424 info box, nothing yet installed...
if [ "$DB_pkgname" = "" -a "`cat /root/.packages/user-installed-packages`" = "" ];then #fix for ziggi
 /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy Package Manager')" error "$(gettext 'There are no user-installed packages yet, so nothing to uninstall!')"
 exit 0
fi
#if [ "$DB_pkgname" = "" ];then #fix for ziggi moved here problem is  #2011-12-27 KRG
#exit 0                         #clicking an empty line in the gui would have
#fi                             #thrown the above REM_DIALOG even if pkgs are installed

if [ ! -f /tmp/remove_pets_quietly ] && [ "$DISPLAY" ]; then
 . /usr/lib/gtkdialog/box_yesno "$(gettext 'Puppy Package Manager')" "$(gettext "Do you want to uninstall package")" "<b>${DB_pkgname}</b>"
 [ "$EXIT" != "yes" ] && exit 0
elif [ ! "$DISPLAY" ]; then
 dialog --yesno "$(gettext 'Do you want to uninstall package ')${DB_pkgname}" 0 0
 [ $? -ne 0 ] && exit 0
fi

#111228 if snapmergepuppy running, wait for it to complete (see also /usr/local/petget/installpkg.sh)...
#note, inverse true, /sbin/pup_event_frontend_d will not run snapmergepuppy if removepreview.sh running.
if [ $PUPMODE -eq 13 ];then
  while [ "`pidof snapmergepuppy`" != "" ];do
   sleep 1
  done
fi

if [ -f /root/.packages/${DB_pkgname}.files ];then
 if [ "$PUP_LAYER" = '/pup_ro2' ]; then #120103 shinobar.
  
  #List all library files of a package
  cat /root/.packages/${DB_pkgname}.files | grep -E "*\.so" > /tmp/libfiles.txt
  
  cat /root/.packages/${DB_pkgname}.files |
  while read ONESPEC
  do
   if [ ! -d "$ONESPEC" ];then
    #120103 shinobar: better way of doing this, look all lower layers...
    Sx=$(ls /initrd/pup_{a,y,ro[0-9]*}"$ONESPEC" 2>/dev/null| grep -v '^/initrd/pup_ro1/')
    INAY=$(echo $Sx | grep -E 'pup_a|pup_y')
    if [ "$INAY" != "" ]; then
     S=$(ls /initrd/pup_{a,y}"$ONESPEC" 2>/dev/null| grep -v '^/initrd/pup_ro1/'| tail -n 1)
    else
     S=$(ls /initrd/pup_ro{?,??}"$ONESPEC" 2>/dev/null| grep -v '^/initrd/pup_ro1/'| head -n 1)
    fi # pup_ro2 - pup_ro99
    if [ "$S" ]; then
     #the problem is, deleting the file on the top layer places a ".wh" whiteout file,
     #that hides the original file. what we want is to remove the installed file, and
     #restore the original pristine file...
     cp -a --remove-destination "$S" "$ONESPEC" #120103 shinobar.
     #120103 apparently for odd# PUPMODEs, save layer may have a lurking old file and/or whiteout...
     if [ $PUPMODE -eq 13 ];then
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
 possiblePKGS=`find /root/.packages/ -type f -iname "$firstchar*.files"`
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
 if [ "$DISPLAY" ];then
  /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy package manager')" warning "<b>$(gettext 'No file named') ${DB_pkgname}.files $(gettext 'found in') /root/.packages/ $(gettext 'folder.')</b>" "$0 $(gettext 'refusing cowardly to remove the package.')" " " "<b>$(gettext 'Possible suggestions:')</b> $WARNMSG" "<b>$(gettext 'Possible solution:')</b> $(gettext 'Edit') <i>/root/.packages/user-installed-packages</i> $(gettext 'to match the pkgname') $(gettext 'and start again.')"
  rox /root/.packages
  geany /root/.packages/user-installed-packages
  exit 101
  ###+++2011-12-27 KRG
 else
  dialog --msgbox "$(gettext 'No file named ' ) ${DB_pkgname}.files $(gettext ' found. Refusing cowardly to remove the package. Possible solution: Edit /root/.packages/user-installed-packages and start again.')" 0 0
  mp /root/.packages/user-installed-packages
  exit 101
 fi
fi


if [ "$PUPMODE" = "2" ]; then
#any user-installed deps?...
remPATTERN='^'"$DB_pkgname"'|'
DEP_PKGS="`grep "$remPATTERN" /root/.packages/user-installed-packages | cut -f 9 -d '|' | tr ',' '\n' | grep -v '^\\-' | sed -e 's%^+%%' |cut -f1 -d '&'`" #names-only, one each line. 

#131222 do not uninstall if other-installed depend on it...
echo -n '' > /tmp/petget/other-installed-deps
for ADEP in $DEP_PKGS
do
 if [ "$(grep ${ADEP} /tmp/pkgs_to_remove)" = "" ]; then
  PTN2="|${ADEP}|"
  DEPPKG="$(grep "$PTN2" /root/.packages/user-installed-packages | cut -f 1 -d '|')"
  [ "$DEPPKG" ] && echo "$DEPPKG" >> /tmp/petget/other-installed-deps
 else
  echo "go on"
 fi
done
if [ -s /tmp/petget/other-installed-deps ];then
 OTHERDEPS="$(sort -u /tmp/petget/other-installed-deps | tr '\n' ' ')"
 /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy Package Manager')" error "<b>$(gettext 'Cannot uninstall'): <i>${DB_pkgname}</i></b>" "$(gettext 'Sorry, but these other installed packages depend on the package that you want to uninstall'):" "<i>${OTHERDEPS}</i>" "$(gettext 'Aborting uninstall operation.')"
 exit 1
fi

#131221 131222
#check install history, so know if can safely uninstall...
REMLIST="${DB_pkgname}"
mkdir -p /tmp/petget
echo -n "" > /tmp/petget/FILECLASHES
echo -n "" > /tmp/petget/CLASHPKGS
grep -v '/$' /root/.packages/${DB_pkgname}.files > /tmp/petget/${DB_pkgname}.filesFILESONLY #/ on end, it is a directory entry.
LATERINSTALLED="$(cat /root/.packages/user-installed-packages | cut -f 1 -d '|' | tr '\n' ' ' | grep -o " ${DB_pkgname} .*" | cut -f 3- -d ' ')"
for ALATERPKG in $LATERINSTALLED
do
 if [ -f /audit/${ALATERPKG}DEPOSED.sfs ];then
  mkdir /audit/${ALATERPKG}DEPOSED
  busybox mount -t squashfs -o loop,ro /audit/${ALATERPKG}DEPOSED.sfs /audit/${ALATERPKG}DEPOSED
  FNDFILES="$(cat /tmp/petget/${DB_pkgname}.filesFILESONLY | xargs -I FULLPATHSPEC ls -1 /audit/${ALATERPKG}DEPOSEDFULLPATHSPEC 2>/dev/null | sed -e "s%^/audit/${ALATERPKG}%%")"
  if [ "$FNDFILES" ];then
   #echo "" >> /tmp/petget/FILECLASHES
   #echo "PACKAGE: ${ALATERPKG}" >> /tmp/petget/FILECLASHES
   echo "$FNDFILES" >> /tmp/petget/FILECLASHES
   echo "${ALATERPKG}" >> /tmp/petget/CLASHPKGS
  fi
  busybox umount /audit/${ALATERPKG}DEPOSED
  rmdir /audit/${ALATERPKG}DEPOSED
 fi
done
if [ -s /tmp/petget/CLASHPKGS ];then
 #a later-installed package is going to be compromised if uninstall ${DB_pkgname}.
 #131222 much simpler...
 FILECLASHES="$(sort -u /tmp/petget/FILECLASHES | grep -v '^$')"
 rm -rf /tmp/petget/savedfiles 2>/dev/null
 mkdir /tmp/petget/savedfiles
 echo "$FILECLASHES" |
 while read AFILE
 do
  APATH="$(dirname "$AFILE")"
  mkdir -p /tmp/petget/savedfiles"${APATH}"
  cp -a -f "${AFILE}" /tmp/petget/savedfiles"${APATH}"/
 done
fi
#end 131221 131222

#131230 from here down, use busybox applets only...
export LANG=C
#delete files...
busybox cat /root/.packages/${DB_pkgname}.files | busybox grep -v '/$' | busybox xargs busybox rm -f #/ on end, it is a directory entry.
#do it again, looking for empty directories...
busybox cat /root/.packages/${DB_pkgname}.files |
while read ONESPEC
do
 if [ -d "$ONESPEC" ];then
  [ "`busybox ls -1 "$ONESPEC"`" = "" ] && busybox rmdir "$ONESPEC" 2>/dev/null #120107
 fi
done

#131222 restore files that were deposed when this pkg installed...
if [ -f /audit/${DB_pkgname}DEPOSED.sfs ];then
 busybox mkdir -p /audit/${DB_pkgname}DEPOSED
 busybox mount -t squashfs -o loop,ro /audit/${DB_pkgname}DEPOSED.sfs /audit/${DB_pkgname}DEPOSED
 DIRECTSAVEPATH="/audit/${DB_pkgname}DEPOSED"
 #same code as in installpkg.sh... 131230 cp is compiled statically, need full version...
 cp -a -f --remove-destination ${DIRECTSAVEPATH}/* /  2> /tmp/petget/install-cp-errlog
 busybox sync
 #can have a problem if want to replace a folder with a symlink. for example, got this error:
 # cp: cannot overwrite directory '/usr/share/mplayer/skins' with non-directory
 #3builddistro has this fix... which is a vice-versa situation...
 #firstly, the vice-versa, source is a directory, target is a symlink...
 CNT=0
 while [ -s /tmp/petget/install-cp-errlog ];do
  echo -n "" > /tmp/petget/install-cp-errlog2
  echo -n "" > /tmp/petget/install-cp-errlog3
  busybox cat /tmp/petget/install-cp-errlog | busybox grep 'cannot overwrite non-directory' | busybox tr '[`‘’]' "'" | busybox cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   #adding that extra trailing / does the trick... 131230 full cp...
   cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}"/* "${ONEDIRSYMLINK}"/ 2> /tmp/petget/install-cp-errlog2
  done
  #secondly, which is our mplayer example, source is a symlink, target is a folder...
  busybox cat /tmp/petget/install-cp-errlog | busybox grep 'cannot overwrite directory' | busybox grep 'with non-directory' | busybox tr '[`‘’]' "'" | busybox cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   busybox mv -f "${ONEDIRSYMLINK}" "${ONEDIRSYMLINK}"TEMP
   busybox rm -rf "${ONEDIRSYMLINK}"TEMP
   DIRPATH="$(busybox dirname "${ONEDIRSYMLINK}")"
   cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}" "${DIRPATH}"/ 2> /tmp/petget/install-cp-errlog3
  done
  busybox cat /tmp/petget/install-cp-errlog2 >> /tmp/petget/install-cp-errlog3
  busybox cat /tmp/petget/install-cp-errlog3 > /tmp/petget/install-cp-errlog
  busybox sync
  CNT=$(( $CNT + 1 ))
  [ $CNT -gt 10 ] && break #something wrong, get out.
 done
 busybox umount /audit/${DB_pkgname}DEPOSED
 busybox rm -rf /audit/${DB_pkgname}DEPOSED
 busybox rm -f /audit/${DB_pkgname}DEPOSED.sfs
fi

#131222 restore latest files, needed by later-installed packages...
#note, manner in which old files got saved may result in wrong dirs instead of symlinks, hence need fixes below...
if [ -s /tmp/petget/CLASHPKGS ];then
 DIRECTSAVEPATH="/tmp/petget/savedfiles"
 #same code as in installpkg.sh...
 cp -a -f --remove-destination ${DIRECTSAVEPATH}/* /  2> /tmp/petget/install-cp-errlog
 busybox sync
 #can have a problem if want to replace a folder with a symlink. for example, got this error:
 # cp: cannot overwrite directory '/usr/share/mplayer/skins' with non-directory
 #3builddistro has this fix... which is a vice-versa situation...
 #firstly, the vice-versa, source is a directory, target is a symlink...
 CNT=0
 while [ -s /tmp/petget/install-cp-errlog ];do
  echo -n "" > /tmp/petget/install-cp-errlog2
  echo -n "" > /tmp/petget/install-cp-errlog3
  busybox cat /tmp/petget/install-cp-errlog | busybox grep 'cannot overwrite non-directory' | busybox tr '[`‘’]' "'" | busybox cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   #adding that extra trailing / does the trick...
   cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}"/* "${ONEDIRSYMLINK}"/ 2> /tmp/petget/install-cp-errlog2
  done
  #secondly, which is our mplayer example, source is a symlink, target is a folder...
  busybox cat /tmp/petget/install-cp-errlog | busybox grep 'cannot overwrite directory' | busybox grep 'with non-directory' | busybox tr '[`‘’]' "'" | busybox cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   busybox mv -f "${ONEDIRSYMLINK}" "${ONEDIRSYMLINK}"TEMP
   busybox rm -rf "${ONEDIRSYMLINK}"TEMP
   DIRPATH="$(dirname "${ONEDIRSYMLINK}")"
   cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}" "${DIRPATH}"/ 2> /tmp/petget/install-cp-errlog3
  done
  busybox cat /tmp/petget/install-cp-errlog2 >> /tmp/petget/install-cp-errlog3
  busybox cat /tmp/petget/install-cp-errlog3 > /tmp/petget/install-cp-errlog
  busybox sync
  CNT=$(( $CNT + 1 ))
  [ $CNT -gt 10 ] && break #something wrong, get out.
 done
 busybox rm -rf /tmp/petget/savedfiles
 busybox rm -f /tmp/petget/CLASHPKGS
 busybox rm -f /tmp/petget/FILECLASHES
fi
#end 131220 131222
export LANG="$ORIGLANG"
#131230 ...end need to use busybox applets?

fi

UPDATE_MENUS=''
if [ -f /tmp/remove_pets_quietly ]; then
 LEFT=$(cat /tmp/pkgs_left_to_remove | wc -l)
 [ "$LEFT" -le 1 ] && UPDATE_MENUS=yes
else
  UPDATE_MENUS=yes
fi


if [ "$UPDATE_MENUS" = "yes" ]; then
 #fix menu...
 #master help index has to be updated...
 ##to speed things up, find the help files in the new pkg only...

 #110706 update menu if .desktop file exists...
 if [ -f /root/.packages/${DB_pkgname}.files ];then
  if [ "`grep '\.desktop$' /root/.packages/${DB_pkgname}.files`" != "" ];then
   #Reconstruct configuration files for JWM, Fvwm95, IceWM...
   nohup /usr/sbin/fixmenus
   [ "`pidof jwm`" != "" ] && { jwm -reload || jwm -restart ; }
  fi
 fi
fi

if [ -e /tmp/libfiles.txt ] && [ $PUPMODE -ne 2 ]; then
 fix_broken_symlinks
fi

rm -f /tmp/petget-proc/libfiles.txt > /dev/null

PKGFILES="/root/.packages/${DB_pkgname}.files"

if [ "`grep '/usr/share/glib-2.0/schemas' $PKGFILES`" != "" ];then
 [ -e /usr/bin/glib-compile-schemas ] && /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas
fi

if [ "`grep '/usr/lib/gio/modules' $PKGFILES`" != "" ];then
 [ -e /usr/bin/gio-querymodules ] && /usr/bin/gio-querymodules /usr/lib/gio/modules
fi

if [ "`grep '/usr/share/applications/' $PKGFILES`" != "" ];then
 rm -f /usr/share/applications/mimeinfo.cache
 [ -e /usr/bin/update-desktop-database ] && /usr/bin/update-desktop-database /usr/share/applications
fi

if [ "`grep '/usr/share/mime/' $PKGFILES`" != "" ];then
 [ -e /usr/bin/update-mime-database ] && /usr/bin/update-mime-database /usr/share/mime
fi

if [ "`grep '/usr/share/icons/hicolor/' $PKGFILES`" != "" ];then
 [ -e /usr/bin/gtk-update-icon-cache ] && /usr/bin/gtk-update-icon-cache /usr/share/icons/hicolor
fi

if [ "`grep '/usr/lib/gdk-pixbuf' $PKGFILES`" != "" ];then
 gdk-pixbuf-query-loaders --update-cache
fi

if [ "`grep '/usr/lib/gconv/' $PKGFILES`" != "" ];then
 iconvconfig
fi

if [ "`grep '/usr/lib/pango/' $PKGFILES`" != "" ];then
 pango-querymodules --update-cache
fi

for gtkver in '1.0' '2.0' '3.0'
do
 if [ "`grep '/usr/lib/gtk-$gtkver' $PKGFILES | grep "/immodules"`" != "" ];then
  [ -e /usr/bin/gtk-query-immodules-$gtkver ] && gtk-query-immodules-$gtkver --update-cache
 fi
done

if [ "`grep '/usr/share/fonts/' $PKGFILES`" != "" ];then
 fc-cache -f
fi

KERNVER="$(uname -r)"

if [ "`grep "/lib/modules/$KERNVER/" $PKGFILES`" != "" ];then
 depmod -a
fi

#what about any user-installed deps...
remPATTERN='^'"$DB_pkgname"'|'
#110211 shinobar: was the dependency logic inverted...
DEP_PKGS="`grep "$remPATTERN" /root/.packages/user-installed-packages | cut -f 9 -d '|' | tr ',' '\n' | grep -v '^\\-' | sed -e 's%^+%%' | cut -f1 -d '&'`"
#remove records of pkg...
rm -f /root/.packages/${DB_pkgname}.files
grep -v "$remPATTERN" /root/.packages/user-installed-packages > /tmp/petget-user-installed-pkgs-rem
cp -f /tmp/petget-user-installed-pkgs-rem /root/.packages/user-installed-packages

#v424 .pet pckage may have post-uninstall script, which was originally named puninstall.sh
#but /usr/local/petget/installpkg.sh moved it to /root/.packages/$DB_pkgname.remove
if [ -f /root/.packages/${DB_pkgname}.remove ];then
 nohup /bin/sh /root/.packages/${DB_pkgname}.remove &
 sleep 0.2
 rm -f /root/.packages/${DB_pkgname}.remove
fi

#remove temp file so main gui window will re-filter pkgs display...
FIRSTCHAR="`echo -n "$DB_pkgname" | cut -c 1 | tr '[A-Z]' '[a-z]'`"
rm -f /tmp/petget_fltrd_repo_${FIRSTCHAR}* 2>/dev/null
rm -f /tmp/petget_fltrd_repo_?${FIRSTCHAR}* 2>/dev/null
[ "`echo -n "$FIRSTCHAR" | grep '[0-9]'`" != "" ] && rm -f /tmp/petget_fltrd_repo_0* 2>/dev/null

#announce any deps that might be removable...
echo -n "" > /tmp/petget-deps-maybe-rem
echo -n "" > /tmp/petget-deps-maybe-remove
cut -f 1,2,10 -d '|' /root/.packages/user-installed-packages |
while read ONEDB
do
 ONE_pkgname="`echo -n "$ONEDB" | cut -f 1 -d '|'`"
 ONE_nameonly="`echo -n "$ONEDB" | cut -f 2 -d '|'`"
 ONE_description="`echo -n "$ONEDB" | cut -f 3 -d '|'`"
 opPATTERN='^'"$ONE_nameonly"'$'
 [ "`echo "$DEP_PKGS" | grep "$opPATTERN"`" != "" ] && echo "$ONE_pkgname DESCRIPTION: $ONE_description" >> /tmp/petget-deps-maybe-rem && echo "$ONE_pkgname" >> /tmp/petget-deps-maybe-remove
done
EXTRAMSG=""
if [ -s /tmp/petget-deps-maybe-rem ];then
 #nah, just list the names, not descriptions...
 MAYBEREM="`cat /tmp/petget-deps-maybe-rem | cut -f 1 -d ' ' | tr '\n' ' '` "
 EXTRAMSG="<text><label>$(gettext 'Perhaps you do not need these dependencies that you had also installed:')</label></text> <text use-markup=\"true\"><label>\"<b>${MAYBEREM}</b>\"</label></text><text><label>$(gettext "...if you do want to remove them, you will have to do so back on the main window, after clicking the 'Ok' button below (perhaps make a note of the package names on a scrap of paper right now)")</label></text>"
fi

#announce success...
if [ ! -f /tmp/remove_pets_quietly ]; then
 export REM_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
  <pixmap><input file>/usr/share/pixmaps/puppy/dialog-complete.svg</input></pixmap>
   <text><label>$(gettext 'Package') '$DB_pkgname' $(gettext 'has been removed.')</label></text>
   ${EXTRAMSG}
   <hbox>
    <button ok></button>
   </hbox>
  </vbox>
 </window>
 "
 if [ "$DISPLAY" != "" ];then
  gtkdialog -p REM_DIALOG
 fi
elif [ -s /tmp/petget-deps-maybe-rem ];then
 for MAYBEREM in $(cat /tmp/petget-deps-maybe-remove)
 do
   [ "$(grep $MAYBEREM /tmp/pkgs_to_remove)" = "" ] \
    && echo $MAYBEREM >> /tmp/overall_petget-deps-maybe-rem
 done
fi
###+++2011-12-27 KRG
#emitting exitcode for some windowmanager depending on dbus
#popup a message window saying the program stopped unexpectedly
#ie (old) enlightenment
rm -f $HOME/nohup.out
exit 0
###+++2011-12-27 KRG
###END###
