#!/bin/sh
# addapted from installpreview.sh

[ -f /root/.packages/skip_space_check ] && exit 0

REPO=$(echo $1 | cut -f 4 -d '|') 
[ ! "$REPO" ] && REPO=$(echo $1 | cut -f 2 -d '|')
echo "$REPO" > /tmp/petget/current-repo-triad
TREE1=$(echo $1 | cut -f 1 -d '|')
[ ! "$TREE1" ] && exit 0

export TEXTDOMAIN=petget___installed_size_preview.sh
export OUTPUT_CHARSET=UTF-8

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

DB_FILE=Packages-`cat /tmp/petget/current-repo-triad`
tPATTERN='^'"$TREE1"'|'
EXAMDEPSFLAG='yes'
ttPTN='^'"$TREE1"'|.*ALREADY INSTALLED'
if [ "`grep "$ttPTN" /tmp/petget/filterpkgs.results.post`" != "" ];then
 EXAMDEPSFLAG='no'
fi

rm -f /tmp/petget_missing_dbentries-* 2>/dev/null
rm -f /tmp/petget_missingpkgs_patterns 2>/dev/null
rm -f /tmp/petget_installedsizek 2>/dev/null 

DB_ENTRY="`grep "$tPATTERN" /root/.packages/$DB_FILE | head -n 1`"
DB_dependencies="`echo -n "$DB_ENTRY" | cut -f 9 -d '|'`"
DB_size="`echo -n "$DB_ENTRY" | cut -f 6 -d '|'`"

SIZEFREEM=`cat /tmp/pup_event_sizefreem | head -n 1` 
SIZEFREEK=`expr $SIZEFREEM \* 1024`

if [ "$DB_dependencies" != "" -a ! -f /tmp/download_only_pet_quietly ]; then
 echo "${TREE1}" > /tmp/petget_installpreview_pkgname
 /usr/local/petget/findmissingpkgs.sh "$DB_dependencies"
fi

MISSINGDEPS_PATTERNS="$(cat /tmp/petget_missingpkgs_patterns)"
if [ "$MISSINGDEPS_PATTERNS" = "" -a "$(grep $DB_ENTRY /tmp/overall_dependencies)" = "" ]; then
 SIZEMK="`echo -n "$DB_size" | rev | cut -c 1`"
 SIZEVAL=`echo -n "$DB_size" | rev | cut -c 2-9 | rev`
 case "$SIZEMK" in
  K) echo cool /dev/null ;;
  M) SIZEVAL=$( expr $SIZEVAL \* 1024 ) ;;
  *) SIZEVAL=$( expr $SIZEVAL \/ 1024 ) ;;
 esac
  if [ "$2" = "RMV" ]; then
   echo -$SIZEVAL >> /tmp/overall_pkg_size_RMV
  else
   echo $SIZEVAL >> /tmp/overall_pkg_size
  fi
 sync
 /usr/local/petget/installmodes.sh check_total_size &
 exit 0
fi

/usr/local/petget/dependencies.sh
[ $? -ne 0 ] &&  kill -9 $(pidof installed_size_preview.sh) \
 && exec /usr/local/petget/installed_size_preview.sh 

FNDMISSINGDBENTRYFILE="`ls -1 /tmp/petget_missing_dbentries-* 2>/dev/null`"
 
 #130511 popup warning if a dep in devx but devx not loaded...
 if ! which gcc; then
  NEEDGCC="$(cat /tmp/petget_missing_dbentries-* | grep -E '\|gcc\||\|gcc_dev_DEV\|' | cut -f 1 -d '|')"
  if [ "$NEEDGCC" ];then
   rm -f /tmp/petget_installed_patterns_system #see pkg_chooser.sh
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
 if [ "$MAINPKG_SIZE" != "" -a "$(grep $MAINPKG_NAME /tmp/overall_dependencies)" = "" ]; then
  if [ "$2" = "RMV" ]; then
   INSTALLEDSIZEKMAIN=-$(echo "$MAINPKG_SIZE" | rev | cut -c 2-10 | rev)
   echo "$INSTALLEDSIZEKMAIN" > /tmp/petget_installedsizek # In case all deps are needed
  else
   INSTALLEDSIZEKMAIN=$(echo "$MAINPKG_SIZE" | rev | cut -c 2-10 | rev)
  fi
 fi
 echo -n "" > /tmp/petget_moreframes
 echo -n "" > /tmp/petget_tabs
 echo "0" > /tmp/petget_frame_cnt
 DEP_CNT=0
 ONEREPO=""
 for ONEDEPSLIST in `ls -1 /tmp/petget_missing_dbentries-*`
 do
  ONEREPO_PREV="$ONEREPO"
  ONEREPO="`echo "$ONEDEPSLIST" | grep -o 'Packages.*' | sed -e 's%Packages\\-%%'`"
  cat $ONEDEPSLIST |
  while read ONELIST
  do
   DEP_NAME="`echo "$ONELIST" | cut -f 1 -d '|'`"
   DEP_SIZE="`echo "$ONELIST" | cut -f 6 -d '|'`"
   ADDSIZEK=0
   if [ -f /tmp/overall_dependencies -a \
    "$(grep $DEP_NAME /tmp/overall_dependencies)" != "" ]; then
    if [ "$2" = "ADD" -o "$(grep $DEP_NAME /tmp/overall_dependencies | wc -l)" -gt 1 ]; then
     echo done that
    else
     [ "$DEP_SIZE" != "" ] && [ "$(grep $DEP_NAME /tmp/overall_dependencies | wc -l)" -le 1 ] \
      && [ "$(grep $DEP_NAME /tmp/pkgs_to_install)" = "" ] && ADDSIZEK=`echo "$DEP_SIZE" | rev | cut -c 2-10 | rev`
     INSTALLEDSIZEK=`expr $INSTALLEDSIZEK - $ADDSIZEK`
     echo "$INSTALLEDSIZEK" > /tmp/petget_installedsizek_rep
    fi
   else
    [ "$DEP_SIZE" != "" ] && [ "$(grep $DEP_NAME /tmp/pkgs_to_install)" = "" ]  \
     && ADDSIZEK=`echo "$DEP_SIZE" | rev | cut -c 2-10 | rev`
    INSTALLEDSIZEK=`expr $INSTALLEDSIZEK + $ADDSIZEK`
    echo "$INSTALLEDSIZEK" > /tmp/petget_installedsizek_rep
   fi
  done
  if [ "$(cat /tmp/petget_installedsizek_rep)" != "$INSTALLEDSIZEKMAIN" ]; then
   cat /tmp/petget_installedsizek_rep >> /tmp/petget_installedsizek
  fi
 done
rm -f /tmp/petget_installedsizek_rep
INSTALLEDSIZEK=`cat /tmp/petget_installedsizek`
if [ "$2" = "RMV" ]; then
   echo "$INSTALLEDSIZEK" >> /tmp/overall_pkg_size_RMV
   for LINE in $(cat /tmp/petget_missing_dbentries-* 2>/dev/null | sort | uniq | cut -f1 -d '|')
   do
    sed -i "0,/$LINE/{//d;}" /tmp/overall_dependencies
   done
else
   echo "$INSTALLEDSIZEK" >> /tmp/overall_pkg_size
   echo "$INSTALLEDSIZEKMAIN" >> /tmp/overall_pkg_size
   cat /tmp/petget_missing_dbentries-* | cut -f1 -d '|' >> /tmp/dependecies_list
fi

if [ "$2" = "ADD" ]; then
  cat /tmp/dependecies_list | sort | uniq  >> /tmp/overall_dependencies
  rm -f /tmp/dependecies_list
fi
sync
/usr/local/petget/installmodes.sh check_total_size &
