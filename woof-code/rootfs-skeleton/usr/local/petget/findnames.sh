#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/pkg_chooser.sh
#  ENTRY1 is a string, to search for a package.
#101129 checkboxes for show EXE DEV DOC NLS. fixed some search bugs.
#110223 run message as separate process.
#120203 BK: internationalized.
#120323 replace 'xmessage' with 'pupmessage'.
#120410 Mavrothal: fix "getext" typo.
#120504 Mavrothal: search with multiple keywords, both pkg name and description.
#120504 some files moved into /tmp/petget
#120515 common code from pkg_chooser.sh, findnames.sh, filterpkgs.sh, extracted to /usr/local/petget/postfilterpkgs.sh.
#120529 fix if icon name appended each line.
#120811 category field now supports sub-category |category;subcategory|, use as icon in ppm main window.
#120819 fix for 120811.
#120827 search may find pkgs that are already installed, mark with mini-tick icon.
#120908 need version field. (used in show_installed_version_diffs.sh). 120909 bug fix.

#puppy package database format:
#pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|compileddistro|compiledrelease|repo|
#...'compileddistro|compiledrelease' (fields 11,12) identify where the package was compiled.

export TEXTDOMAIN=petget___findnames.sh
export OUTPUT_CHARSET=UTF-8

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS #has PKGS_SPECS_TABLE.
. /root/.packages/DISTRO_PET_REPOS #has PET_REPOS, PACKAGELISTS_PET_ORDER

#120504 Mavrothal:
if [ "$ENTRY1" = "" ] ; then
 exit 0
fi
entryPATTERN1="`echo -n "$ENTRY1" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g' -e 's%\\*%.*%g' | awk '{print $1}'`"
entryPATTERN2="`echo -n "$ENTRY1" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g' -e 's%\\*%.*%g' | awk '{print $2}'`"
entryPATTERN3="`echo -n "$ENTRY1" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g' -e 's%\\*%.*%g' | awk '{print $3}'`"
entryPATTERN4="`echo -n "$ENTRY1" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g' -e 's%\\*%.*%g' | awk '{print $4}'`"

CURRENTREPO="`cat /tmp/petget/current-repo-triad`" #search here first.
ALLACTIVEREPOS="`cat /tmp/petget_active_repo_list`"
SEARCH_REPOS_FLAG=$1

if [ "$(cat /var/local/petget/ui_choice 2>/dev/null)" = "Classic" ]; then
 #120504 ask which repos...
 export ASKREPO_DIALOG="<window title=\"$(gettext 'PPM: search')\" icon-name=\"gtk-about\">
 <vbox>
 <frame $(gettext 'Search only current repository')>
  <hbox>
   <text><label>\"${CURRENTREPO}\"</label></text>
   <vbox>
    <button><label>$(gettext 'Search')</label><action type=\"exit\">BUTTON_SEARCH_CURRENT</action></button>
   </vbox>
  </hbox>
 </frame>
 <frame $(gettext 'Search all repositories')>
  <hbox>
   <text><label>\"${ALLACTIVEREPOS}\"</label></text>
   <vbox>
    <button><label>$(gettext 'Search')</label><action type=\"exit\">BUTTON_SEARCH_ALL</action></button>
   </vbox>
  </hbox>
 </frame>
 </vbox>
 </window>
"
 RETPARAMS="`gtkdialog --center --program=ASKREPO_DIALOG`"
 eval "$RETPARAMS"
 [ "$EXIT" != "BUTTON_SEARCH_CURRENT" -a "$EXIT" != "BUTTON_SEARCH_ALL" ] && exit
 SEARCH_REPOS_FLAG="current"
 [ "$EXIT" = "BUTTON_SEARCH_ALL" ] && SEARCH_REPOS_FLAG="all"
fi

if [ "$SEARCH_REPOS_FLAG" = "current" ];then #120504
 REPOLIST="$CURRENTREPO"
else
 REPOLIST="`echo "$ALLACTIVEREPOS"  | tr '\n' ' '`"
fi

FNDIT=no
echo -n "" > /tmp/petget/filterpkgs.results
for ONEREPO in $REPOLIST
do
 #120908 need version field (#3)...
 #120827 need nameonly field (#2)...
 #120811 need category field (#5), and subcategory part of it...
 #120504 Mavrothal:
 if [ "$entryPATTERN4" != "" ]; then
  FNDENTRIES="`cat /root/.packages/Packages-${ONEREPO} | cut -f1,2,3,5,10 -d \| | grep -i "$entryPATTERN1" | grep -i "$entryPATTERN2" | grep -i "$entryPATTERN3" | grep -i "$entryPATTERN4"`" #120827
 elif [ "$entryPATTERN3" != "" ]; then
  FNDENTRIES="`cat /root/.packages/Packages-${ONEREPO} | cut -f1,2,3,5,10 -d \| | grep -i "$entryPATTERN1" | grep -i "$entryPATTERN2" | grep -i "$entryPATTERN3"`" #120827
 elif [ "$entryPATTERN2" != "" ]; then
  FNDENTRIES="`cat /root/.packages/Packages-${ONEREPO} | cut -f1,2,3,5,10 -d \| | grep -i "$entryPATTERN1" | grep -i "$entryPATTERN2"`" #120827
 else
  FNDENTRIES="`cat /root/.packages/Packages-${ONEREPO} | cut -f1,2,3,5,10 -d \| | grep -i "$entryPATTERN1"`" #120827
 fi

 if [ "$FNDENTRIES" ];then
  repoPTN="s%$%|${ONEREPO}|%"
  FPR="`echo "$FNDENTRIES" | sed "$repoPTN"`"
  if  [ "$FPR" = "|${ONEREPO}" ];then
   echo -n "" > /tmp/petget/filterpkgs.results #nothing.
  else
   echo "$FPR" >> /tmp/petget/filterpkgs.results #120504 append repo-triad each line.
  fi
  FNDIT=yes
 fi
done

if [ "$FNDIT" = "no" ];then
 #120909 these files may have been created at previous search, it will upset show_installed_version_diffs.sh if still exist...
 [ -f /tmp/petget/filterpkgs.results.installed ] && rm -f /tmp/petget/filterpkgs.results.installed
 [ -f /tmp/petget/filterpkgs.results.notinstalled ] && rm -f /tmp/petget/filterpkgs.results.notinstalled
 /usr/lib/gtkdialog/box_ok "$(gettext 'PPM package search')" error "$(gettext 'Sorry, no matching package name')"
else
 
 #120827 search may find pkgs that are already installed...
 if [ -f /tmp/petget_installed_patterns_all ];then #precaution.
  grep -f /tmp/petget_installed_patterns_all -v /tmp/petget/filterpkgs.results > /tmp/petget/filterpkgs.results.notinstalled
  grep -f /tmp/petget_installed_patterns_all /tmp/petget/filterpkgs.results > /tmp/petget/filterpkgs.results.installed
  cp -f /tmp/petget/filterpkgs.results.notinstalled /tmp/petget/filterpkgs.results
  if [ -s /tmp/petget/filterpkgs.results.installed ];then
   #change category field to "complete" (display /usr/share/icons/hicolor/scalable/status/complete.svg)...
   #120908 now have version field (in field #3), ex: xserver-xorg-video-radeon_6.14.99|xserver-xorg-video-radeon|6.14.99|BuildingBlock|X.Org X server -- AMD/ATI Radeon display driver|puppy-noarch-official|
    sed -e 's%|%ONEPIPECHAR%' -e 's%|%ONEPIPECHAR%' -e 's%|[^|]*%|complete%' -e 's%|complete|%|complete|(ALREADY INSTALLED) %' -e 's%ONEPIPECHAR%|%g' /tmp/petget/filterpkgs.results.installed >> /tmp/petget/filterpkgs.results
   #ex: xserver-xorg-video-radeon_6.14.99|xserver-xorg-video-radeon|6.14.99|complete|(ALREADY INSTALLED) X.Org X server -- AMD/ATI Radeon display driver|puppy-noarch-official|
  fi
 fi
 #remove field #2, so file is same as generated by filterpkgs.sh, and as expected by postfilterpkgs.sh... 120908 remove #3...
 cut -f 1,4,5,6,7 -d '|' /tmp/petget/filterpkgs.results > /tmp/petget/filterpkgs.results1 #note, retain | on end.
 mv -f /tmp/petget/filterpkgs.results1 /tmp/petget/filterpkgs.results
 
 #120515 post-filter /tmp/petget/filterpkgs.results.post according to EXE,DEV,DOC,NLS checkboxes...
 /usr/local/petget/postfilterpkgs.sh
 #...main gui will read /tmp/petget/filterpkgs.results.post (actually that happens in ui_Classic or ui_Ziggy, which is included in pkg_chooser.sh).

 #120529 hiccup, filterpkgs.results.post may now have icon name appended each line, but filterpkgs.results.post-noicons is backup (created by postfilterpkgs.sh)
 #120504 post-process presentation to show which repo...
 #filterpkgs.results.post each line has package-name|description|repo-triad
 #when we have searched multiple repos, move repo-triad into description field, so that it will show up on main window...
 if [ "$SEARCH_REPOS_FLAG" = "all" ];then
  #creates descript field like: "[puppy-4-official] Abiword word processor"
  #120811 format in /tmp/petget/filterpkgs.results.post now: pkgname|subcategory|description|dbfile, 
  # ex: htop-0.9-i486|System|View Running Processes|puppy-wary5-official (previously was: pkgname|description|dbfile)
  #cut -f 1,2,3,4 -d '|' /tmp/petget/filterpkgs.results.post > /tmp/petget/filterpkgs.results.post2
  (
    while IFS="|" read F1 F2 F3 F4 ETC
    do
      echo "${F1}|${F2}|[${F4}] ${F3}|${F4}|"
    done < /tmp/petget/filterpkgs.results.post
  ) > /tmp/petget/filterpkgs.results.post2
  mv -f /tmp/petget/filterpkgs.results.post2 /tmp/petget/filterpkgs.results.post
  ## ex line: abiword-1.2.3|[puppy-4-official] Abiword word processor|puppy-4-official|
 fi
 
fi

