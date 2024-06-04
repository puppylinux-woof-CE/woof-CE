#!/bin/bash
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from pkg_chooser.sh and petget.
#package to be removed is TREE2, ex TREE2=abiword-1.2.3 (corrresponds to 'pkgname' field in db).
#installed pkgs are recorded in /var/packages/user-installed-packages, each
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
#240114 v2.5 Fix cut delimiter argument; restore original files for overlay file system.  In an overlay file system, deleted files are represented in the top layer by zero-length files with no permissions.
#240528 v2.5 Suppress gtkdialog log output.

[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && \
 [ -f /tmp/petget_proc/remove_pets_quietly ] && set -x
 #; mkdir -p /tmp/petget_proc/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/petget_proc/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget___removepreview.sh
export OUTPUT_CHARSET=UTF-8
[ "$(locale | grep '^LANG=' | cut -d '=' -f 2)" ] && ORIGLANG="$(locale | grep '^LANG=' | cut -d '=' -f 2)"
[ -e /etc/rc.d/PUPSTATE ] && . /etc/rc.d/PUPSTATE  #111228 this has PUPMODE and SAVE_LAYER.
. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /var/packages/DISTRO_PKGS_SPECS

[ "$PUPMODE" == "" ] && PUPMODE=2

#Check if the / is layered fs
ISLAYEREDFS="$(mount | grep "on / type" | grep "unionfs")"
[ "$ISLAYEREDFS" == "" ] && ISLAYEREDFS="$(mount | grep "on / type" | grep -E "aufs|overlay")"

DB_pkgname="$TREE2"

#v424 info box, nothing yet installed...
if [ "$DB_pkgname" = "" ] && [ "`cat /var/packages/user-installed-packages`" = "" ];then #fix for ziggi
 /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy Package Manager')" error "$(gettext 'There are no user-installed packages yet, so nothing to uninstall!')"
 exit 0
fi
#if [ "$DB_pkgname" = "" ];then #fix for ziggi moved here problem is  #2011-12-27 KRG
#exit 0                         #clicking an empty line in the gui would have
#fi                             #thrown the above REM_DIALOG even if pkgs are installed

if [ ! -f /tmp/petget_proc/remove_pets_quietly ] \
  && ( [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] ); then
 . /usr/lib/gtkdialog/box_yesno "$(gettext 'Puppy Package Manager')" "$(gettext "Do you want to uninstall package")" "<b>${DB_pkgname}</b>"
 [ "$EXIT" != "yes" ] && exit 0
elif [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
 dialog --yesno "$(gettext 'Do you want to uninstall package ')${DB_pkgname}" 0 0
 [ $? -ne 0 ] && exit 0
fi

if [ "$ISLAYEREDFS" != "" ] && [ "$PUNIONFS" != "overlay" ];then
 busybox mount -t aufs -o remount,udba=notify unionfs /
fi

#111228 if snapmergepuppy running, wait for it to complete (see also /usr/local/petget/installpkg.sh)...
#note, inverse true, /sbin/pup_event_frontend_d will not run snapmergepuppy if removepreview.sh running.
if [ $PUPMODE -eq 13 ]; then
  while [ "`pidof snapmergepuppy`" != "" ];do
   sleep 1
  done
fi

if [ -f /var/packages/${DB_pkgname}.files ];then

  cat /var/packages/${DB_pkgname}.files | sort -r |
  while read ONESPEC
  do
    if [ -f "$ONESPEC" ] || [ -L "$ONESPEC" ]; then
      #Check if is layered fs.
      #if [ "$ISLAYEREDFS" != "" -a "$PUNIONFS" != "overlay" ];then
      if [ "$ISLAYEREDFS" != "" ];then #240114...
        if [ "$PUNIONFS" = "overlay" ];then
          if [ -L "/initrd/pup_rw${ONESPEC}" ] \
           || [ -e "/initrd/pup_rw${ONESPEC}" ]; then
            if [ -L "/initrd/pup_ro2${ONESPEC}" ] \
             || [ -e "/initrd/pup_ro2${ONESPEC}" ]; then
              cp -a -f --remove-destination "/initrd/pup_ro2${ONESPEC}" "${ONESPEC}"
            else
              rm -f "${ONESPEC}"
            fi
          fi

        else #aufs #240114 end
         #Delete at pup_rw layer
         [ -e "/initrd/pup_rw${ONESPEC}" ] && rm -f "/initrd/pup_rw${ONESPEC}"
         [ -L "/initrd/pup_rw${ONESPEC}" ] && rm -f "/initrd/pup_rw${ONESPEC}"
  
         #Delete file at save layer 
         [ -e "/initrd${SAVE_LAYER}${ONESPEC}" ] && rm -f "/initrd${SAVE_LAYER}${ONESPEC}" #normally /pup_ro1
         [ -L "/initrd${SAVE_LAYER}${ONESPEC}" ] && rm -f "/initrd${SAVE_LAYER}${ONESPEC}" #normally /pup_ro1
         
         BN="`basename "$ONESPEC"`"
         DN="`dirname "$ONESPEC"`"
         
         #The file might be builtin just show the builtin files on top layer
         [ -f "/initrd${SAVE_LAYER}${DN}/.wh.${BN}" ] && rm -f "/initrd${SAVE_LAYER}${DN}/.wh.${BN}"
        fi
        
      else
         #Not layered fs. delete the file anyway
         if [ -f "$ONESPEC" ] || [ -L "$ONESPEC" ]; then
          rm -f "$ONESPEC"
         fi
      fi
    fi
  done
  
 #Restore any builtin files that were deleted
 PKGNAMEONLY="$(grep -m 1 "^${DB_pkgname}|" /var/packages/user-installed-packages | cut -f 2 -d '|')" #240114...
 if [ "$PKGNAMEONLY" != "" ] \
  && [ -f "/var/packages/builtin_files/${PKGNAMEONLY}" ] \
  && [ "$ISLAYEREDFS" != "" ];then
   if [ "$PUNIONFS" = "overlay" ];then
     while IFS= read -r line
     do 
       if [ -L "/initrd/pup_ro2${line%/}" ] \
        || [ -e "/initrd/pup_ro2${line%/}" ]; then
         if [ ! -e "${line%/}" ]; then
           if [ -d "/initrd/pup_ro2${line%/}" ]; then
             cp -a -f --remove-destination "/initrd/pup_ro2${line%/}" "$(dirname ${line})/" 2>/dev/null
           else
             cp -a -f --remove-destination "/initrd/pup_ro2${line}" "${line}" 2>/dev/null
           fi
         fi
       fi
     done < "/var/packages/builtin_files/${PKGNAMEONLY}"

   else #aufs #240114 end
     while IFS= read -r line
     do 
       bname="$(basename $line)"
       dname="$(dirname $line)"
       [ -e "/initrd/pup_rw${dname}/.wh.${bname}" ] && rm -f "/initrd/pup_rw${dname}/.wh.${bname}" 2>/dev/null
       [ -e "/initrd${SAVE_LAYER}${dname}/.wh.${bname}" ] && rm -f "/initrd${SAVE_LAYER}${dname}/.wh.${bname}" 2>/dev/null        
     done < "/var/packages/builtin_files/${PKGNAMEONLY}"
   fi #240114
 
 fi
 
 # do it again, looking for empty directories...
  cat /var/packages/${DB_pkgname}.files 2>/dev/null | xargs -i dirname '{}' | sort -r | uniq | while read LINE
  do
    DELLEVELS=$(echo -n "$LINE" | sed -e 's/[^/]//g' | wc -c | sed -e 's/ //g')
    if [ $DELLEVELS -gt 2 ]; then      
      if [ "$(ls -1 "$LINE")" == "" ]; then
        if [ "$ISLAYEREDFS" = "" ] || [ "$PUNIONFS" = "overlay" ]; then #240114
          [ -d "$LINE" ] && rmdir "$LINE" 2>/dev/null
        else
          [ -d "/initrd/pup_rw$LINE" ] && rmdir "/initrd/pup_rw$LINE" 2>/dev/null
          [ -d "/initrd${SAVE_LAYER}$LINE" ] && rmdir "/initrd${SAVE_LAYER}$LINE" 2>/dev/null
        fi
      fi
    fi
  done
  
 ###+++2011-12-27 KRG
else
 firstchar=`echo ${DB_pkgname} | cut -c 1`
 possiblePKGS=`find /var/packages/ -type f -iname "$firstchar*.files"`
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
 if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ];then
  /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy package manager')" warning "<b>$(gettext 'No file named') ${DB_pkgname}.files $(gettext 'found in') /var/packages/ $(gettext 'folder.')</b>" "$0 $(gettext 'refusing cowardly to remove the package.')" " " "<b>$(gettext 'Possible suggestions:')</b> $WARNMSG" "<b>$(gettext 'Possible solution:')</b> $(gettext 'Edit') <i>/var/packages/user-installed-packages</i> $(gettext 'to match the pkgname') $(gettext 'and start again.')"
  rox /var/packages
  geany /var/packages/user-installed-packages
  exit 101
  ###+++2011-12-27 KRG
 else
  dialog --msgbox "$(gettext 'No file named ' ) ${DB_pkgname}.files $(gettext ' found. Refusing cowardly to remove the package. Possible solution: Edit /var/packages/user-installed-packages and start again.')" 0 0
  mp /var/packages/user-installed-packages
  exit 101
 fi
fi


if [ "$PUPMODE" = "2" ]; then
#any user-installed deps?...
remPATTERN='^'"$DB_pkgname"'|'
DEP_PKGS="`grep "$remPATTERN" /var/packages/user-installed-packages | cut -f 9 -d '|' | tr ',' '\n' | grep -v '^\\-' | sed -e 's%^+%%' |cut -f1 -d '&'`" #names-only, one each line. 

#131222 do not uninstall if other-installed depend on it...
echo -n '' > /tmp/petget_proc/petget/other-installed-deps
for ADEP in $DEP_PKGS
do
 if [ "$(grep ${ADEP} /tmp/petget_proc/pkgs_to_remove)" = "" ]; then
  PTN2="|${ADEP}|"
  DEPPKG="$(grep "$PTN2" /var/packages/user-installed-packages | cut -f 1 -d '|')"
  [ "$DEPPKG" ] && echo "$DEPPKG" >> /tmp/petget_proc/petget/other-installed-deps
 else
  echo "go on"
 fi
done
if [ -s /tmp/petget_proc/petget/other-installed-deps ];then
 OTHERDEPS="$(sort -u /tmp/petget_proc/petget/other-installed-deps | tr '\n' ' ')"
 /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy Package Manager')" error "<b>$(gettext 'Cannot uninstall'): <i>${DB_pkgname}</i></b>" "$(gettext 'Sorry, but these other installed packages depend on the package that you want to uninstall'):" "<i>${OTHERDEPS}</i>" "$(gettext 'Aborting uninstall operation.')"
 exit 1
fi

#131221 131222
#check install history, so know if can safely uninstall...
REMLIST="${DB_pkgname}"
mkdir -p /tmp/petget_proc/petget
echo -n "" > /tmp/petget_proc/petget/FILECLASHES
echo -n "" > /tmp/petget_proc/petget/CLASHPKGS
grep -v '/$' /var/packages/${DB_pkgname}.files > /tmp/petget_proc/petget/${DB_pkgname}.filesFILESONLY #/ on end, it is a directory entry.
LATERINSTALLED="$(cat /var/packages/user-installed-packages | cut -f 1 -d '|' | tr '\n' ' ' | grep -o " ${DB_pkgname} .*" | cut -f 3- -d ' ')"
for ALATERPKG in $LATERINSTALLED
do
 if [ -f /audit/${ALATERPKG}DEPOSED.sfs ];then
  mkdir /audit/${ALATERPKG}DEPOSED
  busybox mount -t squashfs -o loop,ro /audit/${ALATERPKG}DEPOSED.sfs /audit/${ALATERPKG}DEPOSED
  FNDFILES="$(cat /tmp/petget_proc/petget/${DB_pkgname}.filesFILESONLY | xargs -I FULLPATHSPEC ls -1 /audit/${ALATERPKG}DEPOSEDFULLPATHSPEC 2>/dev/null | sed -e "s%^/audit/${ALATERPKG}%%")"
  if [ "$FNDFILES" ];then
   #echo "" >> /tmp/petget_proc/petget/FILECLASHES
   #echo "PACKAGE: ${ALATERPKG}" >> /tmp/petget_proc/petget/FILECLASHES
   echo "$FNDFILES" >> /tmp/petget_proc/petget/FILECLASHES
   echo "${ALATERPKG}" >> /tmp/petget_proc/petget/CLASHPKGS
  fi
  busybox umount /audit/${ALATERPKG}DEPOSED
  rmdir /audit/${ALATERPKG}DEPOSED
 fi
done
if [ -s /tmp/petget_proc/petget/CLASHPKGS ];then
 #a later-installed package is going to be compromised if uninstall ${DB_pkgname}.
 #131222 much simpler...
 FILECLASHES="$(sort -u /tmp/petget_proc/petget/FILECLASHES | grep -v '^$')"
 rm -rf /tmp/petget_proc/petget/savedfiles 2>/dev/null
 mkdir /tmp/petget_proc/petget/savedfiles
 echo "$FILECLASHES" |
 while read AFILE
 do
  APATH="$(dirname "$AFILE")"
  mkdir -p /tmp/petget_proc/petget/savedfiles"${APATH}"
  cp -a -f "${AFILE}" /tmp/petget_proc/petget/savedfiles"${APATH}"/
 done
fi
#end 131221 131222

#131230 from here down, use busybox applets only...
export LANG=C
#delete files...
busybox cat /var/packages/${DB_pkgname}.files | busybox grep -v '/$' | busybox xargs busybox rm -f #/ on end, it is a directory entry.
#do it again, looking for empty directories...
busybox cat /var/packages/${DB_pkgname}.files |
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
 cp -a -f --remove-destination ${DIRECTSAVEPATH}/* /  2> /tmp/petget_proc/petget/install-cp-errlog
 busybox sync
 #can have a problem if want to replace a folder with a symlink. for example, got this error:
 # cp: cannot overwrite directory '/usr/share/mplayer/skins' with non-directory
 #3builddistro has this fix... which is a vice-versa situation...
 #firstly, the vice-versa, source is a directory, target is a symlink...
 CNT=0
 while [ -s /tmp/petget_proc/petget/install-cp-errlog ];do
  echo -n "" > /tmp/petget_proc/petget/install-cp-errlog2
  echo -n "" > /tmp/petget_proc/petget/install-cp-errlog3
  busybox cat /tmp/petget_proc/petget/install-cp-errlog | busybox grep 'cannot overwrite non-directory' | busybox tr '`‘’' "'" | busybox cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   #adding that extra trailing / does the trick... 131230 full cp...
   cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}"/* "${ONEDIRSYMLINK}"/ 2> /tmp/petget_proc/petget/install-cp-errlog2
  done
  #secondly, which is our mplayer example, source is a symlink, target is a folder...
  busybox cat /tmp/petget_proc/petget/install-cp-errlog | busybox grep 'cannot overwrite directory' | busybox grep 'with non-directory' | busybox tr '`‘’' "'" | busybox cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   busybox mv -f "${ONEDIRSYMLINK}" "${ONEDIRSYMLINK}"TEMP
   busybox rm -rf "${ONEDIRSYMLINK}"TEMP
   DIRPATH="$(busybox dirname "${ONEDIRSYMLINK}")"
   cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}" "${DIRPATH}"/ 2> /tmp/petget_proc/petget/install-cp-errlog3
  done
  busybox cat /tmp/petget_proc/petget/install-cp-errlog2 >> /tmp/petget_proc/petget/install-cp-errlog3
  busybox cat /tmp/petget_proc/petget/install-cp-errlog3 > /tmp/petget_proc/petget/install-cp-errlog
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
if [ -s /tmp/petget_proc/petget/CLASHPKGS ];then
 DIRECTSAVEPATH="/tmp/petget_proc/petget/savedfiles"
 #same code as in installpkg.sh...
 cp -a -f --remove-destination ${DIRECTSAVEPATH}/* /  2> /tmp/petget_proc/petget/install-cp-errlog
 busybox sync
 #can have a problem if want to replace a folder with a symlink. for example, got this error:
 # cp: cannot overwrite directory '/usr/share/mplayer/skins' with non-directory
 #3builddistro has this fix... which is a vice-versa situation...
 #firstly, the vice-versa, source is a directory, target is a symlink...
 CNT=0
 while [ -s /tmp/petget_proc/petget/install-cp-errlog ];do
  echo -n "" > /tmp/petget_proc/petget/install-cp-errlog2
  echo -n "" > /tmp/petget_proc/petget/install-cp-errlog3
  busybox cat /tmp/petget_proc/petget/install-cp-errlog | busybox grep 'cannot overwrite non-directory' | busybox tr '`‘’' "'" | busybox cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   #adding that extra trailing / does the trick...
   cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}"/* "${ONEDIRSYMLINK}"/ 2> /tmp/petget_proc/petget/install-cp-errlog2
  done
  #secondly, which is our mplayer example, source is a symlink, target is a folder...
  busybox cat /tmp/petget_proc/petget/install-cp-errlog | busybox grep 'cannot overwrite directory' | busybox grep 'with non-directory' | busybox tr '`‘’' "'" | busybox cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   busybox mv -f "${ONEDIRSYMLINK}" "${ONEDIRSYMLINK}"TEMP
   busybox rm -rf "${ONEDIRSYMLINK}"TEMP
   DIRPATH="$(dirname "${ONEDIRSYMLINK}")"
   cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}" "${DIRPATH}"/ 2> /tmp/petget_proc/petget/install-cp-errlog3
  done
  busybox cat /tmp/petget_proc/petget/install-cp-errlog2 >> /tmp/petget_proc/petget/install-cp-errlog3
  busybox cat /tmp/petget_proc/petget/install-cp-errlog3 > /tmp/petget_proc/petget/install-cp-errlog
  busybox sync
  CNT=$(( $CNT + 1 ))
  [ $CNT -gt 10 ] && break #something wrong, get out.
 done
 busybox rm -rf /tmp/petget_proc/petget/savedfiles
 busybox rm -f /tmp/petget_proc/petget/CLASHPKGS
 busybox rm -f /tmp/petget_proc/petget/FILECLASHES
fi
#end 131220 131222
export LANG="$ORIGLANG"
#131230 ...end need to use busybox applets?

fi

if [ "$ISLAYEREDFS" != "" ] && [ "$PUNIONFS" != "overlay" ];then
 #now re-evaluate all the layers...
	busybox mount -t aufs -o remount,udba=reval unionfs / #remount with faster evaluation mode.
fi

UPDATE_MENUS=''
if [ -f /tmp/petget_proc/remove_pets_quietly ]; then
 LEFT=$(cat /tmp/petget_proc/pkgs_left_to_remove | wc -l)
 [ "$LEFT" -le 1 ] && UPDATE_MENUS=yes
else
  UPDATE_MENUS=yes
fi

if [ "$UPDATE_MENUS" = "yes" ]; then
 #fix menu...
 #master help index has to be updated...
 ##to speed things up, find the help files in the new pkg only...

 #110706 update menu if .desktop file exists...
 if [ -f /var/packages/${DB_pkgname}.files ];then
  if [ "`grep '\.desktop$' /var/packages/${DB_pkgname}.files`" != "" ];then
   #Reconstruct configuration files for JWM, Fvwm95, IceWM...
   nohup /usr/sbin/fixmenus
   [ "`pidof jwm`" != "" ] && { jwm -reload || jwm -restart ; }
  fi
 fi
fi

PKGFILES=/var/packages/${DB_pkgname}.files
# update system cache
/usr/local/petget/z_update_system_cache.sh "$PKGFILES"

#what about any user-installed deps...
remPATTERN='^'"$DB_pkgname"'|'
#110211 shinobar: was the dependency logic inverted...
DEP_PKGS="`grep "$remPATTERN" /var/packages/user-installed-packages | cut -f 9 -d '|' | tr ',' '\n' | grep -v '^\\-' | sed -e 's%^+%%' | cut -f1 -d '&'`"
#remove records of pkg...
rm -f /var/packages/${DB_pkgname}.files
grep -v "$remPATTERN" /var/packages/user-installed-packages > /tmp/petget_proc/petget-user-installed-pkgs-rem
cp -f /tmp/petget_proc/petget-user-installed-pkgs-rem /var/packages/user-installed-packages

#v424 .pet pckage may have post-uninstall script, which was originally named puninstall.sh
#but /usr/local/petget/installpkg.sh moved it to /var/packages/$DB_pkgname.remove
if [ -f /var/packages/${DB_pkgname}.remove ];then
 nohup /bin/sh /var/packages/${DB_pkgname}.remove &
 sleep 0.2
 rm -f /var/packages/${DB_pkgname}.remove
fi

#remove temp file so main gui window will re-filter pkgs display...
FIRSTCHAR="`echo -n "$DB_pkgname" | cut -c 1 | tr '[A-Z]' '[a-z]'`"
rm -f /tmp/petget_proc/petget_fltrd_repo_${FIRSTCHAR}* 2>/dev/null
rm -f /tmp/petget_proc/petget_fltrd_repo_?${FIRSTCHAR}* 2>/dev/null
[ "`echo -n "$FIRSTCHAR" | grep '[0-9]'`" != "" ] && rm -f /tmp/petget_proc/petget_fltrd_repo_0* 2>/dev/null

#announce any deps that might be removable...
echo -n "" > /tmp/petget_proc/petget-deps-maybe-rem
echo -n "" > /tmp/petget_proc/petget-deps-maybe-remove
cut -f 1,2,10 -d '|' /var/packages/user-installed-packages |
while read ONEDB
do
 ONE_pkgname="`echo -n "$ONEDB" | cut -f 1 -d '|'`"
 ONE_nameonly="`echo -n "$ONEDB" | cut -f 2 -d '|'`"
 ONE_description="`echo -n "$ONEDB" | cut -f 3 -d '|'`"
 opPATTERN='^'"$ONE_nameonly"'$'
 [ "`echo "$DEP_PKGS" | grep "$opPATTERN"`" != "" ] && echo "$ONE_pkgname DESCRIPTION: $ONE_description" >> /tmp/petget_proc/petget-deps-maybe-rem && echo "$ONE_pkgname" >> /tmp/petget_proc/petget-deps-maybe-remove
done
EXTRAMSG=""
if [ -s /tmp/petget_proc/petget-deps-maybe-rem ];then
 #nah, just list the names, not descriptions...
 MAYBEREM="`cat /tmp/petget_proc/petget-deps-maybe-rem | cut -f 1 -d ' ' | tr '\n' ' '` "
 EXTRAMSG="<text><label>$(gettext 'Perhaps you do not need these dependencies that you had also installed:')</label></text> <text use-markup=\"true\"><label>\"<b>${MAYBEREM}</b>\"</label></text><text><label>$(gettext "...if you do want to remove them, you will have to do so back on the main window, after clicking the 'Ok' button below (perhaps make a note of the package names on a scrap of paper right now)")</label></text>"
fi

#announce success...
if [ ! -f /tmp/petget_proc/remove_pets_quietly ]; then
 REM_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
  <pixmap>
  <width>48</width>
  <height>48</height>
  <input file>/usr/share/pixmaps/puppy/dialog-complete.svg</input></pixmap>
   <text><label>$(gettext 'Package') '$DB_pkgname' $(gettext 'has been removed.')</label></text>
   ${EXTRAMSG}
   <hbox>
    <button ok></button>
   </hbox>
  </vbox>
 </window>
 "
 export REM_DIALOG
 if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ];then
  if [ "$EXTRAMSG" != "" ]; then
#   gtkdialog -p REM_DIALOG #Debug
   gtkdialog -p REM_DIALOG >/dev/null #240528
  else
   /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy Package Manager')" info "$(gettext 'Package') $(gettext 'has been removed.')" "$DB_pkgname"
  fi
 fi
elif [ -s /tmp/petget_proc/petget-deps-maybe-rem ];then
 for MAYBEREM in $(cat /tmp/petget_proc/petget-deps-maybe-remove)
 do
   [ "$(grep $MAYBEREM /tmp/petget_proc/pkgs_to_remove)" = "" ] \
    && echo $MAYBEREM >> /tmp/petget_proc/overall_petget-deps-maybe-rem
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
