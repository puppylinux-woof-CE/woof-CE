#!/bin/bash
# addapted from installpreview.sh
# called by installpreview.sh and pkg_chooser.sh (add_item2, remove_item2)

. /etc/rc.d/functions_x

[ -f /root/.packages/skip_space_check ] && exit 0

# $1 = TREE1|CATEGORY|DESCRIPTION|REPO
#audacity_2.1.2-2|Multimedia-sound|[debian-stretch-main] fast cross-platform audio editor|debian-stretch-main|

IFS="|" read TREE1 CAT DESC REPO <<< "$1"
echo "$REPO" > /tmp/petget_proc/petget/current-repo-triad
[ ! "$TREE1" ] && exit 0

do_grep() { #$1:str $2:file
	[ -z "$1" ] && return
	[ ! -f "$2" ] && return
	grep "$1" "$2"
}

export TEXTDOMAIN=petget___installed_size_preview.sh
export OUTPUT_CHARSET=UTF-8

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

DB_FILE=Packages-${REPO} #triad
tPATTERN='^'"$TREE1"'|'
EXAMDEPSFLAG='yes'
ttPTN='^'"$TREE1"'|.*ALREADY INSTALLED'
if [ "`grep "$ttPTN" /tmp/petget_proc/petget/filterpkgs.results.post`" != "" ];then
 EXAMDEPSFLAG='no'
fi

rm -f /tmp/petget_proc/petget_missing_dbentries-* 2>/dev/null
rm -f /tmp/petget_proc/petget_missingpkgs_patterns 2>/dev/null
rm -f /tmp/petget_proc/petget_installedsizek 2>/dev/null 

DB_ENTRY="`grep "$tPATTERN" /root/.packages/$DB_FILE | head -n 1`"
DB_dependencies="`echo -n "$DB_ENTRY" | cut -f 9 -d '|'`"
DB_size="`echo -n "$DB_ENTRY" | cut -f 6 -d '|'`"

if [ -z "$SIZEFREEM" ] ; then
	SIZEFREEM=$(fx_personal_storage_free_mb)
fi
SIZEFREEK=$(($SIZEFREEM * 1024))

if [ "$DB_dependencies" != "" -a ! -f /tmp/petget_proc/download_only_pet_quietly ]; then
 echo "${TREE1}" > /tmp/petget_proc/petget_installpreview_pkgname
 /usr/local/petget/findmissingpkgs.sh "$DB_dependencies"
fi

MISSINGDEPS_PATTERNS="$(cat /tmp/petget_proc/petget_missingpkgs_patterns)"
if [ "$MISSINGDEPS_PATTERNS" = "" -a "$(do_grep $DB_ENTRY /tmp/petget_proc/overall_dependencies)" = "" ]; then
 SIZEVAL=${DB_size%[A-Z]} #remove suffix: K M B .. etc
 case "$DB_size" in
  *K) echo -n ;;
  *M) SIZEVAL=$(($SIZEVAL * 1024 )) ;;
  *) SIZEVAL=$(($SIZEVAL / 1024 )) ;;
 esac
  if [ "$2" = "RMV" ]; then
   echo -$SIZEVAL >> /tmp/petget_proc/overall_pkg_size_RMV
  else
   echo $SIZEVAL >> /tmp/petget_proc/overall_pkg_size
  fi
 sync
 /usr/local/petget/installmodes.sh check_total_size &
 exit 0
fi

/usr/local/petget/dependencies.sh
[ $? -ne 0 ] &&  kill -9 $(pidof installed_size_preview.sh) \
 && exec /usr/local/petget/installed_size_preview.sh 

FNDMISSINGDBENTRYFILE="`ls -1 /tmp/petget_proc/petget_missing_dbentries-* 2>/dev/null`"
 
 #130511 popup warning if a dep in devx but devx not loaded...
 if ! which gcc; then
  NEEDGCC="$(cat /tmp/petget_proc/petget_missing_dbentries-* | grep -E '\|gcc\||\|gcc_dev_DEV\|' | cut -f 1 -d '|')"
  if [ "$NEEDGCC" ];then
   rm -f /tmp/petget_proc/petget_installed_patterns_system #see pkg_chooser.sh
   #create a separate process for the popup, with delay...
   DEVXNAME="devx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
   /usr/lib/gtkdialog/box_ok "PPM $(gettext 'Warning')" warning "<b>$(gettext 'WARNING: devx not installed')</b>" "$(gettext 'Package:')  <b>${TREE1}</b>" "$(gettext "This package has dependencies that are in the 'devx' SFS file, which is Puppy's C/C++/Vala/Genie/BaCon mega-package, a complete compiling environment.")" "$(gettext 'The devx file is named:') <b>${DEVXNAME}</b>" "$(gettext "Please cancel installation, close the Puppy Package Manager, then click the 'install' icon on the desktop and install the devx SFS file first.")"
  fi
 fi
 
 #compose pkgs into checkboxes...
 MAIN_REPO="`echo "$DB_FILE" | cut -f 2-9 -d '-'`"
 MAINPKG_NAME="`echo "$DB_ENTRY" | cut -f 1 -d '|'`"
 MAINPKG_SIZE="`echo "$DB_ENTRY" | cut -f 6 -d '|'`"
 INSTALLEDSIZEK=0
 if [ "$MAINPKG_SIZE" != "" -a "$(do_grep $MAINPKG_NAME /tmp/petget_proc/overall_dependencies)" = "" ]; then
  if [ "$2" = "RMV" ]; then
   INSTALLEDSIZEKMAIN=-${MAINPKG_SIZE%[A-Z]} #remove suffix: K M B .. etc
   echo "$INSTALLEDSIZEKMAIN" > /tmp/petget_proc/petget_installedsizek # In case all deps are needed
  else
   INSTALLEDSIZEKMAIN=${MAINPKG_SIZE%[A-Z]} #remove suffix: K M B .. etc
  fi
 fi
 echo -n "" > /tmp/petget_proc/petget_moreframes
 echo -n "" > /tmp/petget_proc/petget_tabs
 echo "0" > /tmp/petget_proc/petget_frame_cnt
 DEP_CNT=0
 ONEREPO=""

 for ONEDEPSLIST in `ls -1 /tmp/petget_proc/petget_missing_dbentries-*`
 do
  ONEREPO_PREV="$ONEREPO"
  ONEREPO="`echo "$ONEDEPSLIST" | grep -o 'Packages.*' | sed -e 's%Packages\\-%%'`"
  cat $ONEDEPSLIST |
  while read ONELIST
  do
   DEP_NAME="`echo "$ONELIST" | cut -f 1 -d '|'`"
   DEP_SIZE="`echo "$ONELIST" | cut -f 6 -d '|'`"
   ADDSIZEK=0
   if [ "$(do_grep $DEP_NAME /tmp/petget_proc/overall_dependencies)" != "" ]; then
    if [ "$2" = "ADD" -o "$(do_grep $DEP_NAME /tmp/petget_proc/overall_dependencies | wc -l)" -gt 1 ]; then
     echo done that
    else
     if [ "$DEP_SIZE" != "" ] && [ "$(do_grep $DEP_NAME /tmp/petget_proc/overall_dependencies | wc -l)" -le 1 ] \
     && [ "$(do_grep $DEP_NAME /tmp/petget_proc/pkgs_to_install)" = "" ] ; then
        ADDSIZEK=${DEP_SIZE%[A-Z]} #remove suffix: K M B .. etc
     fi
     INSTALLEDSIZEK=$(($INSTALLEDSIZEK - $ADDSIZEK))
     echo "$INSTALLEDSIZEK" > /tmp/petget_proc/petget_installedsizek_rep
    fi
   else
    if [ "$DEP_SIZE" != "" ] && [ "$(do_grep $DEP_NAME /tmp/petget_proc/pkgs_to_install)" = "" ] ; then
     ADDSIZEK=${DEP_SIZE%[A-Z]} #remove suffix: K M B .. etc
    fi
    INSTALLEDSIZEK=$(($INSTALLEDSIZEK + $ADDSIZEK))
    echo "$INSTALLEDSIZEK" > /tmp/petget_proc/petget_installedsizek_rep
   fi
  done
  if [ "$(cat /tmp/petget_proc/petget_installedsizek_rep)" != "$INSTALLEDSIZEKMAIN" ]; then
   cat /tmp/petget_proc/petget_installedsizek_rep >> /tmp/petget_proc/petget_installedsizek
  fi
 done
rm -f /tmp/petget_proc/petget_installedsizek_rep
INSTALLEDSIZEK=`cat /tmp/petget_proc/petget_installedsizek`
if [ "$2" = "RMV" ]; then
   echo "$INSTALLEDSIZEK" >> /tmp/petget_proc/overall_pkg_size_RMV
   for LINE in $(cat /tmp/petget_proc/petget_missing_dbentries-* 2>/dev/null | sort | uniq | cut -f1 -d '|')
   do
    sed -i "0,/$LINE/{//d;}" /tmp/petget_proc/overall_dependencies
   done
else
   echo "$INSTALLEDSIZEK" >> /tmp/petget_proc/overall_pkg_size
   echo "$INSTALLEDSIZEKMAIN" >> /tmp/petget_proc/overall_pkg_size
   cat /tmp/petget_proc/petget_missing_dbentries-* | cut -f1 -d '|' >> /tmp/petget_proc/dependecies_list
fi

if [ "$2" = "ADD" ]; then
  cat /tmp/petget_proc/dependecies_list | sort | uniq  >> /tmp/petget_proc/overall_dependencies
  rm -f /tmp/petget_proc/dependecies_list
fi
sync
/usr/local/petget/installmodes.sh check_total_size &
