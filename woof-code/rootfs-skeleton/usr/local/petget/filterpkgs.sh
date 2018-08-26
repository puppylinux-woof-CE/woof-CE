#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from pkg_chooser.sh, provides filtered formatted list of uninstalled pkgs.
# ...this has written to /tmp/petget_pkg_first_char, ex: 'mn'
#filter category may be passed param to this script, ex: 'Document'
# or, /tmp/petget_filtercategory was written by pkg_chooser.sh.
#repo may be written to /tmp/petget/current-repo-triad by pkg_chooser.sh, ex: slackware-12.2-official
#/tmp/petget_pkg_name_aliases_patterns setup in pkg_chooser.sh, name aliases.
#written for Woof, standardised package database format.
#v425 'ALL' may take awhile, put up please wait msg.
#100716 PKGS_MANAGEMENT file has new variable PKG_PET_THEN_BLACKLIST_COMPAT_KIDS.
#101129 checkboxes for show EXE DEV DOC NLS.
#101221 yaf-splash fix.
#120203 BK: internationalized.
#120504 some files moved into /tmp/petget
#120504b improved dev,doc,nls,exe pkg selection.
#120515 dev,doc,exe selection for Mageia .rpm pkgs, fix for 120504b.
#120515 common code from pkg_chooser.sh, findnames.sh, filterpkgs.sh, extracted to /usr/local/petget/postfilterpkgs.sh.
#120719 support raspbian.
#120811 category field now supports sub-category |category;subcategory|, use as icon in ppm main window.
#120813 fix search pattern for optional subcategory. 120813 fix.
#120817 modification of category field now done in postfilterpkgs.sh.
#130330 GUI filtering. see pkg_chooser.sh, ui_Classic, ui_Ziggy. 130331 ignore case. need backslashes.
#130331 more GUI filter options.
#130507 fix GUI filter.
#130511 pkg_chooser.sh has created layers-installed-packages (use instead of woof-installed-packages).

export TEXTDOMAIN=petget___filterpkgs.sh
export OUTPUT_CHARSET=UTF-8

#export LANG=C

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS
. /root/.packages/PKGS_MANAGEMENT #has PKG_ALIASES_INSTALLED, PKG_NAME_ALIASES

#130330 GUI filtering...
DEFGUIFILTER="$(cat /var/local/petget/gui_filter 2>/dev/null)"
#$GUIONLYSTR $ANYTYPESTR are exported from pkg_chooser.sh ... 130331 need backslashes...
guigtk2PTN='\+libgtk2|\+libgtk\+2|\+libgtkmm-2|\+gtk\+2|\+gtk\+,|\+gtkdialog|\+xdialog|\+python-gtk2'
guigtk3PTN='\+libgtk-3|\+libgtk\+3|\+libgtkmm-3|\+gtk\+3'
guiqt4PTN='\+libqtgui4|\+qt,'
guiqt5PTN='\+libqt5gui|\+libqtgui5'
exclguiPTN=''
EXCPARAM=''
case $DEFGUIFILTER in
 $GUIONLYSTR) guiPTN='\+libx11'"|$guigtk2PTN|$guigtk3PTN|$guiqt4PTN|$guiqt5PTN" ;;
 GTK+2*)      guiPTN="$guigtk2PTN" ;;
 GTK+3*)      guiPTN="$guigtk3PTN" ;;
 Qt4*KDE)     guiPTN="$guiqt4PTN" ; exclguiPTN='kde' ;; #130331
 Qt4*)        guiPTN="$guiqt4PTN" ;;
 Qt5*KDE)     guiPTN="$guiqt5PTN" ; exclguiPTN='kde' ;; #130331
 Qt5*)        guiPTN="$guiqt5PTN" ;;
 $NONGUISTR)  guiPTN='\+libx11'"|$guigtk2PTN|$guigtk3PTN|$guiqt4PTN|$guiqt5PTN" ; EXCPARAM='-v' ;; #130331
 *)           guiPTN="|" ;; #$ANYTYPESTR, let everything through.
esac

#130507
xDEFGUIFILTER="$(echo -n "$DEFGUIFILTER" | tr -d ' ' | tr -d '-' | tr -d '+' | tr -d ',')" #ex, translate 'Qt4 GUI apps only' to 'Qt4GUIappsonly'

PKG_FIRST_CHAR='a-z0-9'
. /usr/lib/gtkdialog/box_splash -close never -text "$(gettext 'Please wait, processing all entries may take awhile...')" &
X1PID=$!

#which repo...
FIRST_DB="`ls -1 /root/.packages/Packages-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}* | head -n 1 | rev | cut -f 1 -d '/' | rev | cut -f 2-4 -d '-'`"
fltrREPO_TRIAD="$FIRST_DB" #ex: slackware-12.2-official
#or, a selection was made in the main gui (pkg_chooser.sh)...
[ -f /tmp/petget/current-repo-triad ] && fltrREPO_TRIAD="`cat /tmp/petget/current-repo-triad`"

REPO_FILE="`find /root/.packages/ -type f -name "Packages-${fltrREPO_TRIAD}*" | head -n 1`"

#choose a category in the repo...
if [ $1 ];then #$1 exs: Document, Internet, Graphic, Setup, Desktop
 fltrCATEGORY="$1"
 echo "$1" > /tmp/petget_filtercategory
elif [ -f /tmp/petget_filtercategory ]; then #or, a selection was made in the main gui (pkg_chooser.sh)...
 fltrCATEGORY="`cat /tmp/petget_filtercategory`"
else
 fltrCATEGORY="Desktop" #show Desktop category pkgs.
fi
#120813 there may be optional subcategory, put ; into pattern...
categoryPATTERN="|${fltrCATEGORY}[;|]"
[ "$fltrCATEGORY" = "ALL" ] && categoryPATTERN="|" #let everything through.

#find pkgs in db starting with $PKG_FIRST_CHAR and by distro and category...
#each line: pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|
#optionally on the end: compileddistro|compiledrelease|repo| (fields 11,12,13)
#filter the repo pkgs by first char and category, also extract certain fields...
#w017 filter out all 'lib' pkgs, too many for gtkdialog (ubuntu/debian only)...
#w460 filter out all 'language-' pkgs, too many (ubuntu/debian)...
if [ ! -f /tmp/petget_fltrd_repo_${PKG_FIRST_CHAR}_${fltrCATEGORY}_${xDEFGUIFILTER}_Packages-${fltrREPO_TRIAD} ];then
 case $DISTRO_BINARY_COMPAT in
  ubuntu|debian|devuan|raspbian)
   FLTRD_REPO="`printcols $REPO_FILE 1 2 3 5 10 6 9 | grep -v -E '^lib|^language\\-' | grep -i "^[${PKG_FIRST_CHAR}]" | grep "$categoryPATTERN" | grep -i ${EXCPARAM} -E "$guiPTN" | sed -e 's%||$%|unknown|%'`" #130330  130331 ignore case.
  ;;
  *)
   FLTRD_REPO="`printcols $REPO_FILE 1 2 3 5 10 6 9 | grep -i "^[${PKG_FIRST_CHAR}]" | grep "$categoryPATTERN" | grep -i ${EXCPARAM} -E "$guiPTN" | sed -e 's%||$%|unknown|%'`" #130330  130331 ignore case.
  ;;
 esac
 #...extracted fields, reordered: pkgname|nameonly|version|category|description|size|dependencies
 if [ "$exclguiPTN" ];then #130331
  #well well, news to me, this has to be done in two steps...
  FLTRD_REPO1="$(echo "$FLTRD_REPO" | grep -i -v "$exclguiPTN")"
  FLTRD_REPO="$FLTRD_REPO1"
 fi
 echo "$FLTRD_REPO" > /tmp/petget_fltrd_repo_${PKG_FIRST_CHAR}_${fltrCATEGORY}_${xDEFGUIFILTER}_Packages-${fltrREPO_TRIAD}
 #...file ex: /tmp/petget_fltrd_repo_a_Document_Packages-slackware-12.2-official
fi

#w480 extract names of packages that are already installed...
shortPATTERN="`cut -f 2 -d '|' /tmp/petget_fltrd_repo_${PKG_FIRST_CHAR}_${fltrCATEGORY}_${xDEFGUIFILTER}_Packages-${fltrREPO_TRIAD} | sed -e 's%^%|%' -e 's%$%|%'`"
echo "$shortPATTERN" > /tmp/petget_shortlist_patterns
INSTALLED_CHAR_CAT="`cat /root/.packages/layers-installed-packages /root/.packages/user-installed-packages | grep --file=/tmp/petget_shortlist_patterns`" #130511
#make up a list of filter patterns, so will be able to filter pkg db...
if [ "$INSTALLED_CHAR_CAT" ];then #100711
 INSTALLED_PATTERNS="`echo "$INSTALLED_CHAR_CAT" | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%'`"
 echo "$INSTALLED_PATTERNS" > /tmp/petget_installed_patterns
else
 echo -n "" > /tmp/petget_installed_patterns
fi

#packages may have different names, add them to installed list (refer pkg_chooser.sh)...
INSTALLEDALIASES="`grep --file=/tmp/petget_installed_patterns /tmp/petget_pkg_name_aliases_patterns | tr ',' '\n'`"
[ "$INSTALLEDALIASES" ] && echo "$INSTALLEDALIASES" >> /tmp/petget_installed_patterns

#w480 pkg_chooser has created this, pkg names that need to be ignored (for whatever reason)...
cat /tmp/petget_pkg_name_ignore_patterns >> /tmp/petget_installed_patterns

#100716 PKGS_MANAGEMENT file has new variable PKG_PET_THEN_BLACKLIST_COMPAT_KIDS...
xDBC="`echo -n "${fltrREPO_TRIAD}" | cut -f 1 -d '-'`" #ex: slackware-12.2-official 1st-param is $DISTRO_BINARY_COMPAT
if [ "$xDBC" != "puppy" ];then #not PET pkgs.
 for ONEPTBCK in $PKG_PET_THEN_BLACKLIST_COMPAT_KIDS
 do
  pONEPTBCK='|'"$ONEPTBCK"'|' #ex: |ffmpeg|
  fONEPTBCK="`grep "$pONEPTBCK" /root/.packages/layers-installed-packages /root/.packages/user-installed-packages | grep '\.pet|'`" #130511
  #if it is a PET, then filter-out any compat-distro pkgs that depend on it...
  [ "fONEPTBCK" != "" ] && echo '+'"$ONEPTBCK"'[,|]' >> /tmp/petget_installed_patterns
 done
fi

#clean it up...
grep -v '^$' /tmp/petget_installed_patterns > /tmp/petget_installed_patterns-tmp
mv -f /tmp/petget_installed_patterns-tmp /tmp/petget_installed_patterns

#filter out installed pkgs from the repo pkg list...
fprPTN="s%$%|${fltrREPO_TRIAD}%" #120504 append repo-triad on end of each line.
#120811 keep subcategory for icon (if no subcategory, will use category)... 120813 fix...
#120813 pick subcategory if it exists...
#120817 no, modify category field in postfilterpkgs.sh...
FPR="`grep --file=/tmp/petget_installed_patterns -v /tmp/petget_fltrd_repo_${PKG_FIRST_CHAR}_${fltrCATEGORY}_${xDEFGUIFILTER}_Packages-${fltrREPO_TRIAD} | cut -f 1,4,5 -d '|' | sed -e "$fprPTN"`"
if  [ "$FPR" = "|${fltrREPO_TRIAD}" ];then
 echo -n "" > /tmp/petget/filterpkgs.results #nothing.
else
 echo "$FPR" > /tmp/petget/filterpkgs.results
fi
#...'pkgname|category|description|repo-triad' has been written to /tmp/petget/filterpkgs.results for main gui.

#120515 post-filter /tmp/petget/filterpkgs.results.post according to EXE,DEV,DOC,NLS checkboxes...
/usr/local/petget/postfilterpkgs.sh
#...main gui will read /tmp/petget/filterpkgs.results.post (actually that happens in ui_Classic or ui_Ziggy, which is included in pkg_chooser.sh).

[ $X1PID -ne 0 ] && kill $X1PID

###END###

