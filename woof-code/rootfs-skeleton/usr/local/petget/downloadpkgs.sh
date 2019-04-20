#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (see /usr/share/doc/legal).
#called from /usr/local/petget/installpreview.sh
#The database entries for the packages to be installed are in /tmp/petget_proc/petget_missing_dbentries-*
#ex: /tmp/petget_proc/petget_missing_dbentries-Packages-slackware-12.2-official
#v424 fix msg, x does not need restart to update menu.
#100117 fix for downloading pets from quirky repo.
#100903 fix if subdirectory field 7 in pkg db entry is empty.
#100921 bypass if file list empty.
#100926 fix hack, one puppy repo does not have "puppylinux" in url.
#101013 improvement suggested by L18L, list current locales in 'trim the fat'.
#101014 another hack, wary5 pets are now in the ibiblio quirky site.
#101016 do not offer to trim-the-fat if install pet pkg(s).
#101116 call download_file to download pkg, instead of direct run of wget.
#101118 improve test fail and exit number.
#110812 hack for pets that are in quirky site at ibiblio.
#120203 BK: internationalized.
#120313 'noarch' repo is on quirky ibiblio site.
#120515 support download from arm gentoo compat-distro binary pkgs on ibiblio quirky site.
#120904 vertical scrollbar for successful-install window. 120907 another.
#120908 fixes for composing repo-list.
#120927 want to translate "CATEGORY:" and "PACKAGE:" that are in /tmp/petget_proc/petget-installed-pkgs-log (see installpkg.sh).
#121011 L18L reported problem, category names also need translating.
#121019 flag to download_file when called from ppm.
#121105 hack for RetroPrecise.
#121123 first test that all pkgs exist online before downloading any.
#121130 fix 121123.

[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && \
 [ -f /tmp/petget_proc/install_quietly ] && set -x
 #; mkdir -p /tmp/petget_proc/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/petget_proc/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget___downloadpkgs.sh
export OUTPUT_CHARSET=UTF-8

#export LANG=C
PASSEDPARAM=""
[ $1 ] && PASSEDPARAM="$1" #DOWNLOADONLY
FLAGPET="" #101016

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS #
. /root/.packages/DISTRO_PET_REPOS #has PET_REPOS, PACKAGELISTS_PET_ORDER
. /root/.packages/DISTRO_COMPAT_REPOS #v431 has REPOS_DISTRO_COMPAT

if [ -f /root/.packages/download_path ]; then
 . /root/.packages/download_path
 [ -d "$DL_PATH" -a -w "$DL_PATH" ] && DL_PATH="$DL_PATH" || DL_PATH=/root
else
 DL_PATH=/root
fi

DL_SAVE_FLAG=$(cat /var/local/petget/nd_category 2>/dev/null)

echo -n "" > /tmp/petget_proc/petget-installed-pkgs-log

PKGCNT=0 ; FAILCNT=0 ; EXITVAL=0 #101118
for ONELIST in `ls -1 /tmp/petget_proc/petget_missing_dbentries-Packages-*` #ex: petget_missing_dbentries-Packages-puppy-quirky-official
do
 #ex of entry in file $ONELIST: rox-menu-0.5.0|rox-menu|0.5.0||Desktop|128K|pet_packages-quirky|rox-menu-0.5.0.pet|+rox-clib,+rox_filer|menu for a rox panel|t2|8.0rc|official|
 echo -n "" > /tmp/petget_proc/petget_repos
 LISTNAME="`echo -n "$ONELIST" | grep -o 'Packages.*'`" #ex: Packages-puppy-quirky-official
 
 #note: puppy4, had 4xx, which should resolve to 4 i think...
 REPO_DEFAULT_SUBSUBDIR="`echo -n "$LISTNAME" | cut -f 3 -d '-' | sed -e 's%xx$%%'`" #100903 ex: quirky
 #110812 hack for pets that are in quirky site at ibiblio...
 OFFICIAL_REPO='puppylinux'
 #Remove BK's quirky hacks 131206
 
 case $LISTNAME in
  Packages-puppy-*) #a .pet pkg.
   for ONEPETREPO in $PET_REPOS #ex: z|http://distro.ibiblio.org//quirky|Packages-puppy-quirky-official
   do
    ONEPETREPO_3_PATTERN="`echo -n "$ONEPETREPO" | cut -f 3 -d '|' | sed -e 's%\\-%\\\\-%g' -e 's%\\*%.*%g'`"
    ONEPETREPO_2="`echo -n "$ONEPETREPO" | cut -f 2 -d '|'`" #full URL
    ONEPETREPO_1="$(echo "$ONEPETREPO_2" | cut -f 3 -d '/')" #ex: distro.ibiblio.org
    [ "`echo -n "$LISTNAME" | grep "$ONEPETREPO_3_PATTERN"`" != "" ] && echo "${ONEPETREPO_1}|${ONEPETREPO_2}|${LISTNAME}" >> /tmp/petget_proc/petget_repos
    #...ex: ibiblio.org|http://distro.ibiblio.org//puppylinux|Packages-puppy-4-official
   done
  ;;
  *) #a compat pkg.
   #have the compat-distro repo urls in /root/.packages/DISTRO_PKGS_SPECS,
   #variable REPOS_DISTRO_COMPAT ...
   #REPOS_DISTRO_COMPAT has the associated Packages-* local database file...
   for ONEURLENTRY in $REPOS_DISTRO_COMPAT #ex: z|http://mirror.aarnet.edu.au/pub/slackware/slackware-14.2|Packages-slackware-ponce-official
   do
    PARTPKGDB="`echo -n "$ONEURLENTRY" | cut -f 3 -d '|'`"
    #PARTPKGDB may have a glob * wildcard, convert to reg.expr., also backslash '-'...
    PARTPKGDB="`echo -n "$PARTPKGDB" | sed -e 's%\\-%\\\\-%g' -e 's%\\*%.*%g'`"
    ONEURLENTRY_2="`echo -n "$ONEURLENTRY" | cut -f 2 -d '|'`" #full URL
    ONEURLENTRY_1="$(echo "$ONEURLENTRY_2" | cut -f 3 -d '/')" #ex: mirror.aarnet.edu.au
    [ "`echo "$LISTNAME" | grep "$PARTPKGDB"`" != "" ] && echo "${ONEURLENTRY_1}|${ONEURLENTRY_2}|${LISTNAME}" >> /tmp/petget_proc/petget_repos
    #...ex: mirror.aarnet.edu.au|http://mirror.aarnet.edu.au/pub/slackware/slackware-14.2|Packages-slackware-ponce-official
   done
  ;;
 esac

 sort --key=1 --field-separator="|" --unique /tmp/petget_proc/petget_repos > /tmp/petget_proc/petget_repos-tmp
 mv -f /tmp/petget_proc/petget_repos-tmp /tmp/petget_proc/petget_repos
 
 #/tmp/petget_proc/petget_repos has a list of repos for downloading these packages.
 #now put up a window, request which url to use...
 
 LISTNAMECUT="`echo -n "$LISTNAME" | cut -f 2-9 -d '-'`" #take Packages- off.
 
 REPOBUTTONS=""
 for ONEREPOSPEC in `cat /tmp/petget_proc/petget_repos`
 do
  URL_TEST="`echo -n "$ONEREPOSPEC" | cut -f 1 -d '|'`"
  URL_FULL="`echo -n "$ONEREPOSPEC" | cut -f 2 -d '|'`"
  REPOBUTTONS="${REPOBUTTONS}<radiobutton><label>${URL_TEST}</label><variable>RADIO_URL_${URL_TEST}</variable></radiobutton>"
 done
 
 PKGNAMES="`cat $ONELIST | cut -f 1 -d '|' | tr '\n' ' '`"

 [ "$PKGNAMES" = "" -o "$PKGNAMES" = " " ] && continue #100921
  
 #120907 scrollbar...
 if [ ! -f /tmp/petget_proc/install_quietly ]; then
  export PPM_DEPS_DIALOG="<window title=\"$(gettext 'Puppy Package Manager: download')\" icon-name=\"gtk-about\">
<vbox>
 <text><label>$(gettext 'You have chosen to download these packages:')</label></text>
 <vbox scrollable=\"true\" height=\"100\">
  <text use-markup=\"true\"><label>\"<b>${PKGNAMES}</b>\"</label></text>
 </vbox>
 <text><label>$(gettext "Please choose which URL you would like to download them from. Choose 'LOCAL FOLDER' if you have already have them on this computer (on hard drive, USB drive or CD):")</label></text>

 <frame ${LISTNAMECUT}>
  ${REPOBUTTONS}
  <radiobutton><label>$(gettext 'LOCAL FOLDER')</label><variable>RADIO_URL_LOCAL</variable></radiobutton>
 </frame>
 
 <hbox>
  <button>
   <label>$(gettext 'Test URLs')</label>
   <action>/usr/local/petget/testurls.sh</action>
  </button>
  <button>
   <label>$(gettext 'Download packages')</label>
   <action type=\"exit\">BUTTON_PKGS_DOWNLOAD</action>
  </button>
  <button cancel></button>
 </hbox>
</vbox>
</window>
" 

  RETPARAMS="`gtkdialog -p PPM_DEPS_DIALOG`"
 else
  RETPARAMS='EXIT="BUTTON_PKGS_DOWNLOAD"'
 fi
 #RETPARAMS ex:
 #RADIO_URL_LOCAL="false"
 #RADIO_URL_repository.slacky.eu="true"
 #EXIT="BUTTON_PKGS_DOWNLOAD"
 
 [ "`echo "$RETPARAMS" | grep 'BUTTON_PKGS_DOWNLOAD'`" = "" ] && exit 1

 #determine the url to download from....
 #if [ "$RADIO_URL_LOCAL" = "true" ];then
 if [ "`echo "$RETPARAMS" | grep 'RADIO_URL_LOCAL' | grep 'true'`" != "" ];then
  #put up a dlg box asking for folder with pkgs...
  LOCALDIR="/root"
  if [ -s /var/log/petlocaldir ];then
   OLDLOCALDIR="`cat /var/log/petlocaldir`"
   [ -d $OLDLOCALDIR ] && LOCALDIR="$OLDLOCALDIR"
  fi
  LOCALDIR="`Xdialog --backtitle "Note: Files not displayed, only directories" --title "Choose local directory" --stdout --no-buttons --dselect "$LOCALDIR" 0 0`"
  [ $? -ne 0 ] && exit 1
  if [ "$LOCALDIR" != "" ];then #121130
   LOCALDIR="$(echo -n "$LOCALDIR" | sed -e 's%/$%%')" #drop / off the end.
   echo "$LOCALDIR" > /var/log/petlocaldir
  else
   exit 1
  fi
  DOWNLOADFROM="file://${LOCALDIR}"
 else
  if [ ! -f /tmp/petget_proc/install_quietly ]; then
   URL_BASIC="`echo "$RETPARAMS" | grep 'RADIO_URL_' | grep '"true"' | cut -f 1 -d '=' | cut -f 3 -d '_'`"
   DOWNLOADFROM="`cat /tmp/petget_proc/petget_repos | grep "$URL_BASIC" | head -n 1 | cut -f 2 -d '|'`"
  else
   DOWNLOADFROM="`awk '{ if (NR==1) print $0 }' /tmp/petget_proc/petget_repos | cut -f 2 -d '|'`"
   DOWNLOADFROM_ALT="`awk '{ if (NR==2) print $0 }' /tmp/petget_proc/petget_repos | cut -f 2 -d '|'`"
  fi
 fi
 
 #now download and install them...
 cd "$DL_PATH"
 
 #121123 first test that they all exist online...
 if [ ! -f /tmp/petget_proc/install_quietly ];then
  . yaf-splash -bg '#FFD600' -close never -fontsize large -text "$(gettext 'Please wait, testing that packages exist in repository...')" &
  testPID=$!
 else
  echo "$(gettext 'Testing that packages exist in repository')" > /tmp/petget_proc/petget/install_status
 fi
 DL_BAD_LIST=''
 for ONEFILE in `cat $ONELIST | cut -f 7,8,13 -d '|'` #path|fullfilename|repo-id
 do
  ONEREPOID="`echo -n "$ONEFILE" | cut -f 3 -d '|'`" #ex: official (...|puppy|wary5|official|)
  ONEPATH="`echo -n "$ONEFILE" | cut -f 1 -d '|'`"
  ONEPKGNAME="`echo -n "$ONEFILE" | cut -f 2 -d '|'`"
  ONEFILE="`echo -n "$ONEFILE" | cut -f 1,2 -d '|' | tr '|' '/'`" #path/fullfilename
  [ "`echo -n "$ONEFILE" | rev | cut -c 1-3 | rev`" = "pet" ] && FLAGPET='yes'
  if [ "`echo "$RETPARAMS" | grep 'RADIO_URL_LOCAL' | grep 'true'`" != "" ];then
   if [ ! -f ${LOCALDIR}/${ONEPKGNAME} ];then #121130 fix.
    [ ! -f ./${ONEPKGNAME} ] && DL_BAD_LIST="${DL_BAD_LIST} ${ONEPKGNAME}"
   fi
  else
   if [ "$ONEPATH" == "" ];then
    if [ "$FLAGPET" != "yes" ];then
     ONEFILE="compat_packages-${REPO_DEFAULT_SUBSUBDIR}${ONEFILE}"
    else
     ONEFILE="pet_packages-${REPO_DEFAULT_SUBSUBDIR}${ONEFILE}"
    fi
   fi
   if [ ! -f /tmp/petget_proc/install_quietly ]; then
    LANG=C wget -4 -t 2 -T 20 --waitretry=20 --spider -S "${DOWNLOADFROM}/${ONEFILE}" > /tmp/petget_proc/download_file_spider.log0 2>&1 #
    if [ $? -ne 0 ];then
     DL_BAD_LIST="${DL_BAD_LIST} ${ONEPKGNAME}"
    fi
   else
    LANG=C wget -4 -t 2 -T 20 --waitretry=20 --spider -S "${DOWNLOADFROM}/${ONEFILE}" > /tmp/petget_proc/download_file_spider.log0 2>&1 #
    if [ $? -ne 0 ];then
     DOWNLOADFROM="${DOWNLOADFROM_ALT}"
     LANG=C wget -4 -t 2 -T 20 --waitretry=20 --spider -S "${DOWNLOADFROM}/${ONEFILE}" > /tmp/petget_proc/download_file_spider.log0 2>&1 
     if [ $? -ne 0 ];then
      DL_BAD_LIST="${DL_BAD_LIST} ${ONEPKGNAME}"
     fi
    fi
   fi
  fi 
 done
 [ ! -f /tmp/petget_proc/install_quietly ] && pupkill $testPID || echo
 if [ "$DL_BAD_LIST" ];then
  BADMSG1="$(gettext 'Unfortunately, these packages are not available:')"
  BADMSG2="$(gettext "It may be that the local package database needs to be updated. In some cases, the packages in the online package repository change, so you may be trying to download a package that no longer exists.")"
  BADMSG3="$(gettext "SOLUTION: From the main PPM window, click the 'Configure' BUTTON and click the 'Update' button to update the local package database.")"
  BADMSG4="$(gettext 'The installation has been aborted!')"
  
  /usr/lib/gtkdialog/box_ok "$(gettext 'Packages not available')" error "${BADMSG1}" "<b>${DL_BAD_LIST}</b>" "${BADMSG4}" "${BADMSG2} ${BADMSG3}"
  echo ${DL_BAD_LIST} >> /tmp/petget_proc/pkgs_DL_BAD_LIST
  exit 1
 fi
 
 for ONEFILE in `cat $ONELIST | cut -f 7,8,13 -d '|'` #100527 path|fullfilename|repo-id
 do
  PKGCNT=$(($PKGCNT + 1)) #101118
  #100903 reorder...
  ONEREPOID="`echo -n "$ONEFILE" | cut -f 3 -d '|'`" #100527 ex: official (...|puppy|wary5|official|)
  ONEPATH="`echo -n "$ONEFILE" | cut -f 1 -d '|'`" #100527
  ONEFILE="`echo -n "$ONEFILE" | cut -f 1,2 -d '|' | tr '|' '/'`" #100527 path/fullfilename
  [ "`echo -n "$ONEFILE" | rev | cut -c 1-3 | rev`" = "pet" ] && FLAGPET='yes' #101016
  #if [ "$RADIO_URL_LOCAL" = "true" ];then
  if [ "`echo "$RETPARAMS" | grep 'RADIO_URL_LOCAL' | grep 'true'`" != "" ];then
   [ ! -f ${LOCALDIR}/${ONEFILE} ] && ONEFILE="`basename $ONEFILE`"
   cp -f ${LOCALDIR}/${ONEFILE} ./
  else
   #100527 need fix if |path| field of pkg database was empty... 100903 improve...
   if [ "$ONEPATH" == "" ];then #120515
    if [ "$FLAGPET" != "yes" ];then
     ONEFILE="compat_packages-${REPO_DEFAULT_SUBSUBDIR}${ONEFILE}"
    else
     ONEFILE="pet_packages-${REPO_DEFAULT_SUBSUBDIR}${ONEFILE}"
    fi
   fi
   #101116 now have a download utility...
   echo "$(gettext 'downloading'): ${ONEFILE}" > /tmp/petget_proc/petget/install_status
   export DL_F_CALLED_FROM='ppm' #121019
   download_file ${DOWNLOADFROM}/${ONEFILE}
   if [ $? -ne 0 ];then #101116
    DLPKG="`basename $ONEFILE`"
    [ -f "${DL_PATH}"/$DLPKG ] && rm -f "${DL_PATH}"/$DLPKG
   fi
   unset DL_F_CALLED_FROM
  fi
  sync
  DLPKG="`basename $ONEFILE`"
  if [ -f "${DL_PATH}"/$DLPKG -a "$DLPKG" != "" ];then
   if [ "$PASSEDPARAM" = "DOWNLOADONLY" ];then
    echo "$(gettext 'Verifying'): ${ONEFILE}" > /tmp/petget_proc/petget/install_status
    /usr/local/petget/verifypkg.sh $DLPKG
   else
    echo "$(gettext 'Installing'): ${ONEFILE}" > /tmp/petget_proc/petget/install_status
    /usr/local/petget/installpkg.sh $DLPKG
    #...appends pkgname and category to /tmp/petget_proc/petget-installed-pkgs-log if successful.
   fi
   if [ $? -ne 0 ];then
    LASTPKG=$(tail -n 1 /tmp/petget_proc/pgks_failed_to_install_forced)
    if [ $(echo ${DLPKG} | grep ${LASTPKG}) = "" ]; then
     /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy Package Manager')" error "<b>$(gettext 'Faulty download of') ${DLPKG}</b>"
     FAILCNT=$(($FAILCNT + 1)) #101118
    fi
   fi
   #already removed, but take precautions...
  [ "$PASSEDPARAM" != "DOWNLOADONLY" -a "$DL_SAVE_FLAG" != "true" \
   -a "$(grep ${DLPKG} /tmp/petget_proc/pkg_preexists)" = "" ] && rm -f $DLPKG 2>/dev/null
   rm -f /tmp/petget_proc/pkg_preexists 2>/dev/null
  else
   /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy Package Manager')" error "<b>$(gettext 'Failed to download') ${DLPKG}</b>"
   FAILCNT=$(($FAILCNT + 1)) #101118
  fi
 done

done

#101118 exit 1 if all pkgs failed to download...
[ $FAILCNT -ne 0 ] && [ $FAILCNT -eq $PKGCNT ] && EXITVAL=1

if [ "$PASSEDPARAM" = "DOWNLOADONLY" -a ! -f /tmp/petget_proc/download_pets_quietly \
 -a ! -f /tmp/petget_proc/download_only_pet_quietly ];then
 /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy Package Manager')" complete "$(gettext 'Finished. The packages have been downloaded to') $PWD $(gettext 'directory.')"
 exit $EXITVAL
fi

exit $EXITVAL #101118
###END###
