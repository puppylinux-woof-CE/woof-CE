#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from pkg_chooser.sh
#package to be previewed prior to installation is TREE1 -- inherited from parent.
#/tmp/petget/current-repo-triad has the repository that installing from.
#100821 bug in Lucid 5.1, /tmp/pup_event_sizefreem had two identical lines.
#101221 yaf-splash fix.
#120101 01micko: jwm >=547 has -reload, no screen flicker.
#120116 rev. 514 introduced icon rendering method which broke -reload at 547. fixed at rev. 574.
#120203 BK: internationalized.
#120504 if no pkgs in category, then when click in window in main dlg, comes here with TREE1="".
#120504 select correct repo when have chosen a pkg from multiple-repo list.
#120604 fix for prepended icons field.
#120811 category field now supports sub-category |category;subcategory|, use as icon in ppm main window.
#120827 if pkg already installed, do not examine dependencies (doesn't work).
#120903 ubuntu, have lots pkgs installed, check_deps.sh takes ages, remove for now, need to rewrite in C.
#120904 "examine dependencies" button did not create any /tmp/petget_missing_dbentries-*, workaround.
#120905 better advice if too many deps. 120907 revert.
#120907 max frames increase 5 to 10. Note, precise puppy gave 72 deps for vlc, which would require 10 frames.
#130511 popup warning if a dep in devx but devx not loaded.

[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && \
 [ -f /tmp/install_quietly ] && set -x
 #; mkdir -p /tmp/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget___installpreview.sh
export OUTPUT_CHARSET=UTF-8

[ "$TREE1" = "" ] && exit #120504 nothing to install.

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

if [ ! -f /tmp/install_quietly ]; then
 . /usr/lib/gtkdialog/box_splash -close never -text "$(gettext 'Please wait, processing package database files...')" &
 X1PID=$!
fi

#ex: TREE1=abiword-1.2.4 (first field in database entry).
DB_FILE=Packages-`cat /tmp/petget/current-repo-triad` #ex: Packages-slackware-12.2-official
tPATTERN='^'"$TREE1"'|'

#120827 'examine dependencies' button does not work if pkg already installed...
EXAMDEPSFLAG='yes'
ttPTN='^'"$TREE1"'|.*ALREADY INSTALLED'
if [ "`grep "$ttPTN" /tmp/petget/filterpkgs.results.post`" != "" ];then #created by postfilterpkgs.sh
 EXAMDEPSFLAG='no'

fi

#120504 if findnames.sh searched multiple repos, /tmp/petget/current-repo-triad (set in pkg_chooser.sh) might be wrong...
[ -f /tmp/petget/current-repo-triad.previous ] && rm -f /tmp/petget/current-repo-triad.previous
if [ -f /tmp/petget/filterpkgs.results.post ];then
  ALTSEARCHREPO="$(grep "$tPATTERN" /tmp/petget/filterpkgs.results.post | grep '|\[' | cut -f 2 -d '[' | cut -f 1 -d ']')"
 [ "$ALTSEARCHREPO" ] && DB_FILE="Packages-${ALTSEARCHREPO}"
 #hmmm, other scripts, ex dependencies.sh, will need to have this correct...
 if [ "$ALTSEARCHREPO" ];then
  mv -f /tmp/petget/current-repo-triad /tmp/petget/current-repo-triad.previous #need to restore old one before exit this script.
  echo -n "$ALTSEARCHREPO" > /tmp/petget/current-repo-triad
 fi
fi

rm -f /tmp/petget_missing_dbentries-* 2>/dev/null

DB_ENTRY="`grep "$tPATTERN" /root/.packages/$DB_FILE | head -n 1`"
#line format: pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|
#optionally on the end: compileddistro|compiledrelease|repo| (fields 11,12,13)

DB_pkgname="`echo -n "$DB_ENTRY" | cut -f 1 -d '|'`"
DB_nameonly="`echo -n "$DB_ENTRY" | cut -f 2 -d '|'`"
DB_version="`echo -n "$DB_ENTRY" | cut -f 3 -d '|'`"
DB_pkgrelease="`echo -n "$DB_ENTRY" | cut -f 4 -d '|'`"
DB_category="`echo -n "$DB_ENTRY" | cut -f 5 -d '|'`"
DB_size="`echo -n "$DB_ENTRY" | cut -f 6 -d '|'`"
DB_path="`echo -n "$DB_ENTRY" | cut -f 7 -d '|'`"
DB_fullfilename="`echo -n "$DB_ENTRY" | cut -f 8 -d '|'`"
DB_dependencies="`echo -n "$DB_ENTRY" | cut -f 9 -d '|'`"
DB_description="`echo -n "$DB_ENTRY" | cut -f 10 -d '|'`"

[ "$DB_description" = "" ] && DB_description="$(gettext 'no description available')"

SIZEFREEM=`cat /tmp/pup_event_sizefreem | head -n 1` #100821 bug in Lucid 5.1, file had two identical lines.
SIZEFREEK=`expr $SIZEFREEM \* 1024`

if [ $DB_size ];then
 SIZEMK="`echo -n "$DB_size" | rev | cut -c 1`"
 SIZEVAL=`echo -n "$DB_size" | rev | cut -c 2-9 | rev`
 SIZEINFO="<text><label>$(gettext 'After installation, this package will occupy') ${SIZEVAL}${SIZEMK}B. $(gettext 'The amount of free space that you have for installation is') ${SIZEFREEM}MB (${SIZEFREEK}KB).</label></text>"
 SIZEVALz=`expr $SIZEVAL \/ 3`
 SIZEVALz=`expr $SIZEVAL + $SIZEVALz`
 SIZEVALx2=`expr $SIZEVALz + 10000`
 if [ $SIZEVALx2 -ge $SIZEFREEK ];then
  MSGWARN1="${SIZEINFO}<text use-markup=\"true\"><label>\"<b>$(gettext "A general rule-of-thumb is that the free space should be at least the original-package-size plus installed-package-size plus 10MB to allow for sufficient working space during and after installation. It does not look to good, so you had better click the 'Cancel' button")</b> -- $(gettext "note, if you are running Puppy in a mode that has a 'pupsave' file, then the Utility menu has an entry 'Resize personal storage file' that should solve the problem.")\"</label></text>"
 else
  MSGWARN1="${SIZEINFO}<text use-markup=\"true\"><label>\"<b>$(gettext "...free space looks ok, so click 'Install' button:")</b>\"</label></text>"
 fi
else
 MSGWARN1="<text use-markup=\"true\"><label>\"<b>$(gettext 'Unfortunately the provider of the package database has not supplied the size of this package when installed. If you are able to see the size of the compressed package, multiple that by 3 to get the approximate installed size. The free available space, which is') ${SIZEFREEM}MB (${SIZEFREEK}KB), $(gettext 'should be at least 4 times greater.')</b>\"</label></text>"
fi


#find missing dependencies...
if [ "$DB_dependencies" = "" ];then
 DEPINFO="<text><label>$(gettext 'It seems that all dependencies are already installed. Sometimes though, the dependency information in the database is incomplete, however a check for presence of needed shared libraries will be done after installation.')</label></text>"
else

 #find all missing pkgs...
 /usr/local/petget/findmissingpkgs.sh "$DB_dependencies"
 #...returns /tmp/petget_installed_patterns_all, /tmp/petget_pkg_deps_patterns, /tmp/petget_missingpkgs_patterns
 MISSINGDEPS_PATTERNS="`cat /tmp/petget_missingpkgs_patterns`"
 #/tmp/petget_missingpkgs_patterns has a list of missing dependencies, format ex:
 #|kdebase|
 #|kdelibs|
 #|mesa|
 #|qt|

 DEPBUTTON=""
 ONLYMSG=""
 if [ "$MISSINGDEPS_PATTERNS" = "" ];then
  DEPINFO="<text><label>$(gettext 'It seems that all dependencies are already installed. Sometimes though, the dependency information in the database is incomplete, however a check for presence of needed shared libraries will be done after installation.')</label></text>"
 else
  ONLYMSG=" $(gettext 'ONLY')"
  xMISSINGDEPS="`echo "$MISSINGDEPS_PATTERNS" | sed -e 's%|%%g' | tr '\n' ' '`"
  if [ "$EXAMDEPSFLAG" != "no" ];then #120828
   DEPBUTTON="<button>
   <label>$(gettext 'Examine dependencies')</label>
   <action>echo \"${TREE1}\" > /tmp/petget_installpreview_pkgname</action>
   <action type=\"exit\">BUTTON_EXAMINE_DEPS</action>
   </button>"
   DEPINFO="<text><label>$(gettext 'Warning, the following dependent packages are missing:')</label></text>
   <text use-markup=\"true\"><label>\"<b>${xMISSINGDEPS}</b>\"</label></text>
   <text><label>$(gettext "A warning, these dependencies may have other dependencies not necessarily listed here. It is recommended that you click the 'Examine dependencies' button to find all dependencies before installing.")</label></text>
   <text use-markup=\"true\"><label>\"<b>$(gettext "Please click 'Examine dependencies' to install") ${TREE1} $(gettext "as well as its dependencies")</b>\"</label></text>"
  else
   DEPINFO="<text><label>$(gettext 'Warning, the following dependent packages are missing:')</label></text>
   <text use-markup=\"true\"><label>\"<b>${xMISSINGDEPS}</b>\"</label></text>"
  fi
  if [ $DB_size ];then
   MSGWARN1="<text><label>$(gettext 'After installation, this package will occupy') ${SIZEVAL}${SIZEMK}B, $(gettext 'however the dependencies will need more space so you really need to find what they will need first.')</label></text>"
  else
   MSGWARN1="<text><label>$(gettext 'Also, the package database provider has not supplied the installed size of this package, so you will have to try and estimate whether you have enough free space for it (and the dependencies)')</label></text>"
  fi
 fi 
fi

[ ! -f /tmp/install_quietly ] && kill $X1PID || echo
if [ ! -f /tmp/install_quietly ]; then
export PREVIEW_DIALOG="<window title=\"$(gettext 'Puppy Package Manager: preinstall')\" icon-name=\"gtk-about\">
<vbox>
 <text><label>$(gettext 'You have chosen to install package') '${TREE1}'. $(gettext 'A short description of this package is:')</label></text>
 <text use-markup=\"true\"><label>\"<b>${DB_description}</b>\"</label></text>
 ${DEPINFO}
 
 ${MSGWARN1}
 
 <frame>
  <hbox>
   <text><label>$(gettext 'If you would like more information about') '${TREE1}', $(gettext 'such as what it is for and the dependencies, this button will download and display detailed information:')</label></text>
   <button><label>$(gettext 'More info')</label><action>/usr/local/petget/fetchinfo.sh ${TREE1} & </action></button>
  </hbox>
 </frame>
 
 <hbox>
  ${DEPBUTTON}
  <button>
   <label>$(gettext 'Install') ${TREE1}${ONLYMSG}</label>
   <action>echo \"${TREE1}\" > /tmp/petget_installpreview_pkgname</action>
   <action type=\"exit\">BUTTON_INSTALL</action>
  </button>
  <button>
   <label>$(gettext 'Download-only')</label>
   <action type=\"exit\">BUTTON_PKGS_DOWNLOADONLY</action>
  </button>
  <button cancel></button>
 </hbox>
</vbox>
</window>
"

RETPARAMS="`gtkdialog3 --center --program=PREVIEW_DIALOG`"
else
 if [ -f /tmp/download_only_pet_quietly ]; then
  RETPARAMS='EXIT="BUTTON_PKGS_DOWNLOADONLY"'
 elif [ "$MISSINGDEPS_PATTERNS" != "" ];then
  RETPARAMS='EXIT="BUTTON_EXAMINE_DEPS"'
 elif [ -f /tmp/download_pets_quietly ]; then
  RETPARAMS='EXIT="BUTTON_PKGS_DOWNLOADONLY"'
 else
  RETPARAMS='EXIT="BUTTON_INSTALL"'
 fi
fi

eval "$RETPARAMS"
if [ "$EXIT" != "BUTTON_INSTALL" -a "$EXIT" != "BUTTON_EXAMINE_DEPS" -a "$EXIT" != "BUTTON_PKGS_DOWNLOADONLY" ];then
 [ -f /tmp/petget/current-repo-triad.previous ] && mv -f /tmp/petget/current-repo-triad.previous /tmp/petget/current-repo-triad
 exit
fi

#DB_ENTRY has the database entry of the main package that we want to install.
#DB_FILE has the name of the database file that has the main entry, ex: Packages-slackware-12.2-slacky

if [ "$EXIT" = "BUTTON_EXAMINE_DEPS" ];then
 /usr/local/petget/dependencies.sh
 [ $? -ne 0 ] && exec /usr/local/petget/installpreview.sh #reenter.
 #returns with /tmp/petget_missing_dbentries-* has the database entries of missing deps.
 #the '*' on the end is the repo-file name, ex: Packages-slackware-12.2-slacky
 
 #120904
 FNDMISSINGDBENTRYFILE="`ls -1 /tmp/petget_missing_dbentries-* 2>/dev/null`"
 if [ "$FNDMISSINGDBENTRYFILE" = "" -a ! -f /tmp/install_quietly ];then
  . pupdialog --title "$(gettext 'PPM: examine dependencies')" --background LightYellow --msgbox "$(gettext 'There seem to be no missing dependencies.')

$(gettext 'Note: if the previous window indicated that there are missing dependencies, they were not found. Sometimes, a package database lists a dependency that does not actually exist anymore and is not required.')" 0 0
  exec /usr/local/petget/installpreview.sh #reenter.
 fi
 
 #130511 popup warning if a dep in devx but devx not loaded...
 if ! which gcc; then
  NEEDGCC="$(cat /tmp/petget_missing_dbentries-* | grep -E '\|gcc\||\|gcc_dev_DEV\|' | cut -f 1 -d '|')"
  if [ "$NEEDGCC" ];then
   rm -f /tmp/petget_installed_patterns_system #see pkg_chooser.sh
   #create a separate process for the popup, with delay...
   DEVXNAME="devx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
   echo "#!/bin/sh
sleep 3
. pupdialog --background pink --colors --ok-label \"$(gettext 'OK')\" --backtitle \"$(gettext 'WARNING: devx not installed')\" --msgbox \"$(gettext 'Package:')  \Zb${TREE1}\ZB
$(gettext "This package has dependencies that are in the 'devx' SFS file, which is Puppy's C/C++/Vala/Genie/BaCon mega-package, a complete compiling environment.")

$(gettext 'The devx file is named:') \Zb${DEVXNAME}\ZB

$(gettext "Please cancel installation, close the Puppy Package Manager, then click the \Zbinstall\ZB icon on the desktop and install the devx SFS file first.")\" 0 0" > /tmp/petget_devx_popup.sh #'geany
   chmod 755 /tmp/petget_devx_popup.sh
   /tmp/petget_devx_popup.sh &
  fi
 fi
 
 #compose pkgs into checkboxes...
 MAIN_REPO="`echo "$DB_FILE" | cut -f 2-9 -d '-'`"
 MAINPKG_NAME="`echo "$DB_ENTRY" | cut -f 1 -d '|'`"
 MAINPKG_SIZE="`echo "$DB_ENTRY" | cut -f 6 -d '|'`"
 MAINPKG_DESCR="`echo "$DB_ENTRY" | cut -f 10 -d '|'`"
 MAIN_CHK="<checkbox><default>true</default><label>${MAINPKG_NAME} SIZE: ${MAINPKG_SIZE}B DESCRIPTION: ${MAINPKG_DESCR}</label><variable>CHECK_PKG_${MAIN_REPO}_${MAINPKG_NAME}</variable></checkbox>"
 INSTALLEDSIZEK=0
 [ "$MAINPKG_SIZE" != "" ] && INSTALLEDSIZEK=`echo "$MAINPKG_SIZE" | rev | cut -c 2-10 | rev`
 
 #making up the dependencies into tabs, need limit of 8 per tab...
 #also limit to 6 tabs (gedit is way beyond this!)...
 echo -n "" > /tmp/petget_moreframes
 echo -n "" > /tmp/petget_tabs
 echo "0" > /tmp/petget_frame_cnt
 DEP_CNT=0
 ONEREPO=""
 for ONEDEPSLIST in `ls -1 /tmp/petget_missing_dbentries-*`
 do
  ONEREPO_PREV="$ONEREPO"
  ONEREPO="`echo "$ONEDEPSLIST" | grep -o 'Packages.*' | sed -e 's%Packages\\-%%'`"
  FRAME_CNT=`cat /tmp/petget_frame_cnt`
  if [ "$ONEREPO_PREV" != "" ];then #next repo, so start a new tab.
   DEP_CNT=0
   FRAME_CNT=`expr $FRAME_CNT + 1`
   echo "$FRAME_CNT" > /tmp/petget_frame_cnt
   #w017 bugfix, prevent double frame closure...
   [ "`cat /tmp/petget_moreframes | tail -n 1 | grep '</frame>$'`" = "" ] && echo "</frame>" >> /tmp/petget_moreframes
  fi
  cat $ONEDEPSLIST |
  while read ONELIST
  do
   DEP_NAME="`echo "$ONELIST" | cut -f 1 -d '|'`"
   DEP_SIZE="`echo "$ONELIST" | cut -f 6 -d '|'`"
   DEP_DESCR="`echo "$ONELIST" | cut -f 10 -d '|'`"
   DEP_CNT=`expr $DEP_CNT + 1`
   case $DEP_CNT in
    1)
     echo -n "<frame REPOSITORY: ${ONEREPO}>" >> /tmp/petget_moreframes
     echo -n "Dependencies|" >> /tmp/petget_tabs
     echo -n "<checkbox><default>true</default><label>${DEP_NAME} SIZE: ${DEP_SIZE}B DESCRIPTION: ${DEP_DESCR}</label><variable>CHECK_PKG_${ONEREPO}_${DEP_NAME}</variable></checkbox>" >> /tmp/petget_moreframes
    ;;
    8)
     FRAME_CNT=`cat /tmp/petget_frame_cnt`
     FRAME_CNT=`expr $FRAME_CNT + 1`
     if [ $FRAME_CNT -gt 10 ];then #120907
      echo -n "<text use-markup=\"true\"><label>\"<b>$(gettext 'SORRY! Too many dependencies, list truncated. Suggest click Cancel button and install some deps first.')</b>\"</label></text>" >> /tmp/petget_moreframes #120907
     else
      echo -n "<checkbox><default>true</default><label>${DEP_NAME} SIZE: ${DEP_SIZE}B DESCRIPTION: ${DEP_DESCR}</label><variable>CHECK_PKG_${ONEREPO}_${DEP_NAME}</variable></checkbox>" >> /tmp/petget_moreframes
     fi
     echo "</frame>" >> /tmp/petget_moreframes
     DEP_CNT=0
     echo "$FRAME_CNT" > /tmp/petget_frame_cnt
    ;;
    *)
     echo -n "<checkbox><default>true</default><label>${DEP_NAME} SIZE: ${DEP_SIZE}B DESCRIPTION: ${DEP_DESCR}</label><variable>CHECK_PKG_${ONEREPO}_${DEP_NAME}</variable></checkbox>" >> /tmp/petget_moreframes
    ;;
   esac
   [ $FRAME_CNT -gt 10 ] && break #too wide! 120907
   ADDSIZEK=0
   [ "$DEP_SIZE" != "" ] && ADDSIZEK=`echo "$DEP_SIZE" | rev | cut -c 2-10 | rev`
   INSTALLEDSIZEK=`expr $INSTALLEDSIZEK + $ADDSIZEK`
   echo "$INSTALLEDSIZEK" > /tmp/petget_installedsizek
  done
  INSTALLEDSIZEK=`cat /tmp/petget_installedsizek`
  FRAME_CNT=`cat /tmp/petget_frame_cnt`
  [ $FRAME_CNT -gt 10 ] && break #too wide! 120907
 done
 TABS="`cat /tmp/petget_tabs`"
 MOREFRAMES="`cat /tmp/petget_moreframes`"
 #make sure last frame has closed...
 [ "`echo "$MOREFRAMES" | tail -n 1 | grep '</frame>$'`" = "" ] && MOREFRAMES="${MOREFRAMES}</frame>"
 
 INSTALLEDSIZEM=`expr $INSTALLEDSIZEK \/ 1024`
 MSGWARN2="$(gettext "If that looks like enough free space, go ahead and click the 'Install' button...")"
 testSIZEK=`expr $INSTALLEDSIZEK \/ 3`
 testSIZEK=`expr $INSTALLEDSIZEK + $testSIZEK`
 testSIZEK=`expr $testSIZEK + 8000`
 [ $testSIZEK -gt $SIZEFREEK ] && MSGWARN2="$(gettext "Not too good! recommend that you make more space before installing -- see 'Resize personal storage file' in the 'Utility' menu.")"
if [ ! -f /tmp/install_quietly ]; then
 export DEPS_DIALOG="<window title=\"$(gettext 'Puppy Package Manager: dependencies')\" icon-name=\"gtk-about\">
<vbox>
 
 <frame REPOSITORY: ${MAIN_REPO}>
  ${MAIN_CHK}
 </frame>

 <notebook labels=\"${TABS}\">
 ${MOREFRAMES}
 </notebook>
 
 <hbox>
 <text><label>$(gettext "Sometimes Puppy's automatic dependency checking comes up with a list that may include packages that don't really need to be installed, or are already installed under a different name. If uncertain, just accept them all, but if you spot one that does not need to be installed, then un-tick it.")</label></text>
 
 <text><label>$(gettext 'Puppy usually avoids listing the same package more than once if it exists in two or more repositories. However, if the same package is listed twice, choose the one that seems to be most appropriate.')</label></text>
 </hbox>
 
 <hbox>
  <vbox>
   <text><label>$(gettext 'Click to see the hierarchy of the dependencies:')</label></text>
   <hbox>
    <button>
     <label>$(gettext 'View hierarchy')</label>
     <action>/usr/local/bin/defaulttextviewer /tmp/petget_deps_visualtreelog & </action>
    </button>
   </hbox>
  </vbox>
  <text><label>\"   \"</label></text>
  <text use-markup=\"true\"><label>\"<b>$(gettext 'If all of the above packages are selected, the total installed size will be') ${INSTALLEDSIZEK}KB (${INSTALLEDSIZEM}MB). $(gettext 'The free space available for installation is') ${SIZEFREEK}KB (${SIZEFREEM}MB). ${MSGWARN2}</b>\"</label></text>
 </hbox>
 
 <hbox>
  <button>
   <label>$(gettext 'Download-only selected packages')</label>
   <action type=\"exit\">BUTTON_PKGS_DOWNLOADONLY</action>
  </button>
  <button>
   <label>$(gettext 'Download-and-install selected packages')</label>
   <action type=\"exit\">BUTTON_PKGS_INSTALL</action>
  </button>
  <button cancel></button>
 </hbox>
</vbox>
</window>
"

RETPARAMS="`gtkdialog3 --center --program=DEPS_DIALOG`"
else
 if [ ! -f /tmp/download_pets_quietly ]; then
 xEXIT="BUTTON_PKGS_INSTALL"
 else
 xEXIT="BUTTON_PKGS_DOWNLOADONLY"
 fi
  DEPS_TOINSTALL=$(sed 's/<variable>/\n/g' /tmp/petget_moreframes \
   |grep ^CHECK_PKG_ | cut -f1 -d '<' | sed 's/$/=\"true\"/')
  PKG_TOINSTALL=CHECK_PKG_${MAIN_REPO}_${MAINPKG_NAME}="true"
  RETPARAMS="$DEPS_TOINSTALL
$PKG_TOINSTALL
EXIT=$xEXIT"
  [ "$DEPS_TOINSTALL" != "" ] && echo "$DEPS_TOINSTALL"  | cut -f 1 -d '=' \
   | cut -f 4-10 -d '_'  >> /tmp/pkgs_to_install_done
  rm -f /tmp/petget_moreframes
fi

 #example if 'Install' button clicked:
 #CHECK_PKG_slackware-12.2-official_libtermcap-1.2.3="true"
 #CHECK_PKG_slackware-12.2-official_pygtk-2.12.1="true"
 #CHECK_PKG_slackware-12.2-slacky_beagle-0.3.9="true"
 #CHECK_PKG_slackware-12.2-slacky_libgdiplus-2.0="true"
 #CHECK_PKG_slackware-12.2-slacky_libgdiplus-2.2="true"
 #CHECK_PKG_slackware-12.2-slacky_mono-2.2="true"
 #CHECK_PKG_slackware-12.2-slacky_monodoc-2.0="true"
 #EXIT="BUTTON_PKGS_INSTALL"

 if [ "`echo "$RETPARAMS" | grep '^EXIT' | grep -E 'BUTTON_PKGS_INSTALL|BUTTON_PKGS_DOWNLOADONLY'`" != "" ];then
  #remove any unticked pkgs from the list...
  for ONECHK in `echo "$RETPARAMS" | grep '^CHECK_PKG_' | grep '"false"' | tr '\n' ' '`
  do
   ONEREPO="`echo -n "$ONECHK" | cut -f 1 -d '=' | cut -f 3 -d '_'`" #ex: slackware-12.2-slacky
   ONEPKG="`echo -n "$ONECHK" | cut -f 1 -d '=' | cut -f 4-9 -d '_'`"  #ex: libtermcap-1.2.3
   opPATTERN='^'"$ONEPKG"'|'
   grep -v "$opPATTERN" /tmp/petget_missing_dbentries-Packages-${ONEREPO} > /tmp/petget_tmp
   mv -f /tmp/petget_tmp /tmp/petget_missing_dbentries-Packages-${ONEREPO}
  done
 else
  [ -f /tmp/petget/current-repo-triad.previous ] && mv -f /tmp/petget/current-repo-triad.previous /tmp/petget/current-repo-triad #120504
  exit
 fi
fi
#come here, want to install pkg(s)...

#DB_ENTRY has the database entry of the main package that we want to install.
#DB_FILE has the name of the database file that has the main entry, ex: Packages-slackware-12.2-slacky
#TREE1 is name of main pkg, ex: abiword-1.2.3

#check to see if main pkg entry already in install-lists...
touch /tmp/petget_missing_dbentries-${DB_FILE} #create if doesn't exist.
mPATTERN='^'"$TREE1"'|'
if [ "`grep "$mPATTERN" /tmp/petget_missing_dbentries-${DB_FILE}`" = "" ];then
 echo "$DB_ENTRY" >> /tmp/petget_missing_dbentries-${DB_FILE}
fi

#now do the actual install...
PASSEDPRM=""
[ "`echo "$RETPARAMS" | grep '^EXIT' | grep 'BUTTON_PKGS_DOWNLOADONLY'`" != "" ] && PASSEDPRM="DOWNLOADONLY" && touch /tmp/manual_pkg_download
/usr/local/petget/downloadpkgs.sh $PASSEDPRM
if [ $? -ne 0 ];then
 [ -f /tmp/petget/current-repo-triad.previous ] && mv -f /tmp/petget/current-repo-triad.previous /tmp/petget/current-repo-triad #120504
 exit 1
fi
[ "$PASSEDPRM" = "DOWNLOADONLY" ] && exit

if [ -f /tmp/install_pets_quietly ]; then
 LEFT=$(cat /tmp/pkgs_left_to_install | wc -l)
 [ "$LEFT" -le 1 ] && UPDATE_MENUS=yes
else
  UPDATE_MENUS=yes
fi

if [ "$UPDATE_MENUS" = "yes" ]; then
INSTALLEDCAT="menu" #any string.
[ "`cat /tmp/petget-installed-pkgs-log | grep -o 'CATEGORY' | grep -v 'none'`" = "" ] && INSTALLEDCAT="none"
RESTARTMSG="$(gettext 'Please wait, updating help page and menu...')"
[ "$INSTALLEDCAT" = "none" ] &&  RESTARTMSG="$(gettext 'Please wait, updating help page...')"
 if [ ! -f /tmp/install_quietly ]; then
  /usr/lib/gtkdialog/box_splash -text "${RESTARTMSG}" &
  X3PID=$!
 fi
fi

#w091019 update image cache...
iUPDATE='no'
for iONE in `cat /tmp/petget_missing_dbentries-* | cut -f 1 -d '|' | tr '\n' ' '`
do
 if [ -f /root/.packages/${iONE}.files ]; then
  [ "`grep 'usr/share/icons/hicolor' /root/.packages/${iONE}.files`" != "" ] \
   && echo yes >> /tmp/iUPDATE
 fi
done
if [ "$UPDATE_MENUS" = "yes" ]; then
 if [ "$(grep yes /tmp/iUPDATE)" != "" ]; then \
  gtk-update-icon-cache -f /usr/share/icons/hicolor/
  rm -f /tmp/iUPDATE
 fi
fi

#Reconstruct configuration files for JWM, Fvwm95, IceWM...
if [ "$UPDATE_MENUS" = "yes" -a "$INSTALLEDCAT" != "none" ];then
 nohup /usr/sbin/fixmenus
 [ "`pidof jwm`" != "" ] && { jwm -reload || jwm -restart ; }
fi
[ ! -f /tmp/install_quietly ] && kill $X3PID || echo

#120905 restore...
#120903 ubuntu, have lots pkgs installed, this takes ages. remove for now, need to rewrite in C...
#check any missing shared libraries...
PKGS="`cat /tmp/petget_missing_dbentries-* | cut -f 1 -d '|' | tr '\n' '|'`"
/usr/local/petget/check_deps.sh $PKGS

[ -f /tmp/petget/current-repo-triad.previous ] && mv -f /tmp/petget/current-repo-triad.previous /tmp/petget/current-repo-triad #120504

rm -f nohup.out 2>/dev/null
###END###
