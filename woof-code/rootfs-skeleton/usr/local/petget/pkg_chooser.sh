#!/bin/bash
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (/usr/share/doc/legal/lgpl-2.1.txt).
#The Puppy Package Manager main GUI window.
#v424 reintroduce the 'ALL' category, for ppup build only.
#v425 enable ENTER key for find box.
#100116 add quirky repo at ibiblio. 100126: bugfixes.
#100513 reintroduce the 'ALL' category for quirky (t2).
#100903 handle puppy-wary5 repo.
#100911 handle puppy-lucid repo.
#101126 prevent 'puppy-quirky' radiobutton first for quirky 1.4 (based on wary5 pkgs).
#101129 checkboxes for show EXE DEV DOC NLS.
#101205 bugfix for: make sure first radiobutton matches list of pkgs.
#110118 alternate User Interfaces. see also configure.sh.
#110505 support sudo for non-root user.
#110706 fix for deps checking.
#120203 BK: internationalized.
#120327 sometimes the selected repo radiobutton did not match listed packages at startup.
#120504 /tmp/petget_filterversion renamed to /tmp/petget/current-repo-triad
#120504 some files moved into /tmp/petget
#120504b improved separation of dev,doc,nls,exe, enhanced ubuntu,debian pkg support.
#120515 common code from pkg_chooser.sh, findnames.sh, filterpkgs.sh, extracted to /usr/local/petget/postfilterpkgs.sh.
#120527 change gtkdialog3 to gtkdialog4. icon patterns for postfilterpkgs.sh.
#120529 ui may show app thumbnail icons.
#120603 /root/.packages/user-installed-packages missing at first boot.
#120515 gentoo build.
#120811 category field now supports sub-category |category;subcategory|, use as icon in ppm main window.
#120822 in precise puppy have a pet 'cups' instead of the ubuntu debs. the latter are various pkgs, including 'libcups2'. we don't want libcups2 showing up as a missing dependency, so have to screen these alternative names out. see also findmissingpkgs.sh.
#120831 simplify repos radiobuttons. fixes a bug, when make selection in setup wasn't same in main window.
#120903 bugfix for 120831. 120905 fix window too wide.
#121125 offer to download a Service Pack, if available.
#130330 GUI filter. see also ui_Classic, ui_Ziggy, filterpkgs.sh.
#130331 more GUI filter options. See also filterpkgs.sh.
#130511 need to include devx-only-installed-packages, if loaded.

/usr/local/petget/service_pack.sh & #121125 offer download Service Pack.

export TEXTDOMAIN=petget___pkg_chooser.sh
export OUTPUT_CHARSET=UTF-8

[ "`whoami`" != "root" ] && exec sudo -A ${0} ${@} #110505

mkdir -p /tmp/petget #120504
mkdir -p /var/local/petget

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS
. /root/.packages/PKGS_MANAGEMENT #has PKG_REPOS_ENABLED, PKG_NAME_ALIASES

#120529 app icons
touch /root/.packages/user-installed-packages #120603 missing at first boot.
#101129 choose to display EXE, DEV, DOC, NLS pkgs... note, this code-block is also in findnames.sh and filterpkgs.sh...
DEF_CHK_EXE='true'
DEF_CHK_DEV='false'
DEF_CHK_DOC='false'
DEF_CHK_NLS='false'
[ -e /var/local/petget/postfilter_EXE ] && DEF_CHK_EXE="`cat /var/local/petget/postfilter_EXE`"
[ -e /var/local/petget/postfilter_DEV ] && DEF_CHK_DEV="`cat /var/local/petget/postfilter_DEV`"
[ -e /var/local/petget/postfilter_DOC ] && DEF_CHK_DOC="`cat /var/local/petget/postfilter_DOC`"
[ -e /var/local/petget/postfilter_NLS ] && DEF_CHK_NLS="`cat /var/local/petget/postfilter_NLS`"
#120515 the script /usr/local/petget/postfilterpkgs.sh handles checkbox actions, is called from ui_Ziggy and ui_Classic.

#finds all user-installed pkgs and formats ready for display...
/usr/local/petget/finduserinstalledpkgs.sh #writes to /tmp/installedpkgs.results

#130511 need to include devx-only-installed-packages, if loaded...
#note, this code block also in check_deps.sh.
if which gcc;then
 cp -f /root/.packages/woof-installed-packages /tmp/ppm-layers-installed-packages
 cat /root/.packages/devx-only-installed-packages >> /tmp/ppm-layers-installed-packages
 sort -u /tmp/ppm-layers-installed-packages > /root/.packages/layers-installed-packages
else
 cp -f /root/.packages/woof-installed-packages /root/.packages/layers-installed-packages
fi

#100711 moved from findmissingpkgs.sh... 130511 rename woof-installed-packages to layers-installed-packages...
if [ ! -f /tmp/petget_installed_patterns_system ];then
 INSTALLED_PATTERNS_SYS="`cat /root/.packages/layers-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_SYS" > /tmp/petget_installed_patterns_system
 #PKGS_SPECS_TABLE also has system-installed names, some of them are generic combinations of pkgs...
 INSTALLED_PATTERNS_GEN="`echo "$PKGS_SPECS_TABLE" | grep '^yes' | cut -f 2 -d '|' |  sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_GEN" >> /tmp/petget_installed_patterns_system
 
 #120822 in precise puppy have a pet 'cups' instead of the ubuntu debs. the latter are various pkgs, including 'libcups2'.
 #we don't want libcups2 showing up as a missing dependency, so have to screen these alternative names out...
 case $DISTRO_BINARY_COMPAT in
  ubuntu|debian|raspbian)
   #for 'cups' pet, we want to create a pattern '/cups|' so can locate all debs with that DB_path entry '.../cups'
    INSTALLED_PTNS_PET="$(grep '\.pet|' /root/.packages/layers-installed-packages | cut -f 2 -d '|' | sed -e 's%^%/%' -e 's%$%|%' -e 's%\-%\\-%g')"
   if [ "$INSTALLED_PTNS_PET" != "/|" ];then
    echo "$INSTALLED_PTNS_PET" > /tmp/petget/installed_ptns_pet
    INSTALLED_ALT_NAMES="$(grep --no-filename -f /tmp/petget/installed_ptns_pet /root/.packages/Packages-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}-* | cut -f 2 -d '|')"
    if [ "$INSTALLED_ALT_NAMES" ];then
     INSTALLED_ALT_PTNS="$(echo "$INSTALLED_ALT_NAMES" | sed -e 's%^%|%' -e 's%$%|%' -e 's%\-%\\-%g')"
     echo "$INSTALLED_ALT_PTNS" >> /tmp/petget_installed_patterns_system
    fi
   fi
  ;;
 esac
 sort -u /tmp/petget_installed_patterns_system > /tmp/petget_installed_patterns_systemx
 mv -f /tmp/petget_installed_patterns_systemx /tmp/petget_installed_patterns_system
fi
#100711 this code repeated in findmissingpkgs.sh...
cp -f /tmp/petget_installed_patterns_system /tmp/petget_installed_patterns_all
if [ -s /root/.packages/user-installed-packages ];then
 INSTALLED_PATTERNS_USER="`cat /root/.packages/user-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_USER" >> /tmp/petget_installed_patterns_all
 #120822 find alt names in compat-distro pkgs, for user-installed pets...
 case $DISTRO_BINARY_COMPAT in
  ubuntu|debian|raspbian)
   #120904 bugfix, was very slow...
   MODIF1=`stat --format=%Y /root/.packages/user-installed-packages` #seconds since epoch.
   MODIF2=0
   [ -f /var/local/petget/installed_alt_ptns_pet_user ] && MODIF2=`stat --format=%Y /var/local/petget/installed_alt_ptns_pet_user`
   if [ $MODIF1 -gt $MODIF2 ];then
    INSTALLED_PTNS_PET="$(grep '\.pet|' /root/.packages/user-installed-packages | cut -f 2 -d '|')"
    if [ "$INSTALLED_PTNS_PET" != "" ];then
     xINSTALLED_PTNS_PET="$(echo "$INSTALLED_PTNS_PET" | sed -e 's%^%/%' -e 's%$%|%' -e 's%\-%\\-%g')"
     echo "$xINSTALLED_PTNS_PET" > /tmp/petget/fmp_xipp1
     INSTALLED_ALT_NAMES="$(grep --no-filename -f /tmp/petget/fmp_xipp1 /root/.packages/Packages-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}-* | cut -f 2 -d '|')"
     if [ "$INSTALLED_ALT_NAMES" ];then
      INSTALLED_ALT_PTNS="$(echo "$INSTALLED_ALT_NAMES" | sed -e 's%^%|%' -e 's%$%|%' -e 's%\-%\\-%g')"
      echo "$INSTALLED_ALT_PTNS" > /var/local/petget/installed_alt_ptns_pet_user
      echo "$INSTALLED_ALT_PTNS" >> /tmp/petget_installed_patterns_all
     fi
    fi
    touch /var/local/petget/installed_alt_ptns_pet_user
   else
    cat /var/local/petget/installed_alt_ptns_pet_user >> /tmp/petget_installed_patterns_all
   fi
  ;;
 esac
fi

#process name aliases into patterns (used in filterpkgs.sh, findmissingpkgs.sh) ... 100126...
xPKG_NAME_ALIASES="`echo "$PKG_NAME_ALIASES" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g'`"
echo "$xPKG_NAME_ALIASES" > /tmp/petget_pkg_name_aliases_patterns_raw #110706
cp -f /tmp/petget_pkg_name_aliases_patterns_raw /tmp/petget_pkg_name_aliases_patterns #110706 _raw see findmissingpkgs.sh.

#100711 above has a problem as it has wildcards. need to expand...
#ex: PKG_NAME_ALIASES has an entry 'cxxlibs,glibc*,libc-*', the above creates '|cxxlibs|,|glibc.*|,|libc\-.*|',
#    after expansion: '|cxxlibs|,|glibc|,|libc-|,|glibc|,|glibc_dev|,|glibc_locales|,|glibc-solibs|,|glibc-zoneinfo|'
echo -n "" > /tmp/petget_pkg_name_aliases_patterns_expanded
for ONEALIASLINE in `cat /tmp/petget_pkg_name_aliases_patterns | tr '\n' ' '` #ex: |cxxlibs|,|glibc.*|,|libc\-.*|
do
 echo -n "" > /tmp/petget_temp1
 for PARTONELINE in `echo -n "$ONEALIASLINE" | tr ',' ' '`
 do
  grep "$PARTONELINE" /tmp/petget_installed_patterns_all >> /tmp/petget_temp1
 done
 ZZZ="`echo "$ONEALIASLINE" | sed -e 's%\.\*%%g' | tr -d '\\'`"
 [ -s /tmp/petget_temp1 ] && ZZZ="${ZZZ},`cat /tmp/petget_temp1 | tr '\n' ',' | tr -s ',' | tr -d '\\'`"
 ZZZ="`echo -n "$ZZZ" | sed -e 's%,$%%'`"
 echo "$ZZZ" >> /tmp/petget_pkg_name_aliases_patterns_expanded
done
cp -f /tmp/petget_pkg_name_aliases_patterns_expanded /tmp/petget_pkg_name_aliases_patterns

#w480 PKG_NAME_IGNORE is definedin PKGS_MANAGEMENT file... 100126...
xPKG_NAME_IGNORE="`echo "$PKG_NAME_IGNORE" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g' -e 's%\-%\\-%g'`"
echo "$xPKG_NAME_IGNORE" > /tmp/petget_pkg_name_ignore_patterns

repocnt=0
COMPAT_REPO=""
COMPAT_DBS=""
echo -n "" > /tmp/petget_active_repo_list

#120831 simplify...
REPOS_RADIO=""
repocnt=0
#sort with -puppy-* repos last...
if [ "$DISTRO_BINARY_COMPAT" = "puppy" ];then
 aPRE="`echo -n "$PKG_REPOS_ENABLED" | tr ' ' '\n' | grep '\-puppy\-' | tr -s '\n' | tr '\n' ' '`"
 bPRE="`echo -n "$PKG_REPOS_ENABLED" | tr ' ' '\n' | grep -v '\-puppy\-' | tr -s '\n' | tr '\n' ' '`"
else
 aPRE="`echo -n "$PKG_REPOS_ENABLED" | tr ' ' '\n' | grep -v '\-puppy\-' | tr -s '\n' | tr '\n' ' '`"
 bPRE="`echo -n "$PKG_REPOS_ENABLED" | tr ' ' '\n' | grep '\-puppy\-' | tr -s '\n' | tr '\n' ' '`"
fi
for ONEREPO in $aPRE $bPRE #ex: ' Packages-puppy-precise-official Packages-puppy-noarch-official Packages-ubuntu-precise-main Packages-ubuntu-precise-multiverse '
do
 [ ! -f /root/.packages/$ONEREPO ] && continue
 REPOCUT="`echo -n "$ONEREPO" | cut -f 2-4 -d '-'`"
 [ "$REPOS_RADIO" = "" ] && FIRST_DB="$REPOCUT"
 xREPOCUT="$(echo -n "$REPOCUT" | sed -e 's%\-official$%%')" #120905 window too wide.
 REPOS_RADIO="${REPOS_RADIO}<radiobutton><label>${xREPOCUT}</label><action>/tmp/filterversion.sh ${REPOCUT}</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>"
 echo "$REPOCUT" >> /tmp/petget_active_repo_list #120903 needed in findnames.sh
 repocnt=`expr $repocnt + 1`
 #[ $repocnt -ge 5 ] && break	# SFR: no limit
done

FILTER_CATEG="Desktop"
#note, cannot initialise radio buttons in gtkdialog...
echo "Desktop" > /tmp/petget_filtercategory #must start with Desktop.
echo "$FIRST_DB" > /tmp/petget/current-repo-triad #ex: slackware-12.2-official

if [ 0 -eq 1 ];then #w020 disable this choice.
 #filter pkgs by first letter, for more speed. must start with ab...
 echo "ab" > /tmp/petget_pkg_first_char
 FIRSTCHARS="
<radiobutton><label>a,b</label><action>echo ab > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>c,d</label><action>echo cd > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>e,f</label><action>echo ef > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>g,h</label><action>echo gh > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>i,j</label><action>echo ij > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>k,l</label><action>echo kl > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>m,n</label><action>echo mn > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>o,p</label><action>echo op > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>q,r</label><action>echo qr > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>s,t</label><action>echo st > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>u,v</label><action>echo uv > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>w,x</label><action>echo wx > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>y,z</label><action>echo yz > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>0-9</label><action>echo 0123456789 > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
<radiobutton><label>ALL</label><action>echo ALL > /tmp/petget_pkg_first_char</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>
"
 xFIRSTCHARS="<hbox>
${FIRSTCHARS}
</hbox>"
else
 #do not dispay the alphabetic radiobuttons...
 echo "ALL" > /tmp/petget_pkg_first_char
 FIRSTCHARS=""
 xFIRSTCHARS=""
fi

#130330 GUI filtering. see also ui_Classic, ui_Ziggy, filterpkgs.sh ...
GUIONLYSTR="$(gettext 'GUI apps only')"
ANYTYPESTR="$(gettext 'Any type')"
GUIEXCSTR="$(gettext 'GUI, not')" #130331 (look in ui_Classic, ui_Ziggy to see context)
NONGUISTR="$(gettext 'Any non-GUI type')" #130331
export GUIONLYSTR ANYTYPESTR GUIEXCSTR NONGUISTR #used in ui_classic and ui_ziggy
[ ! -f /var/local/petget/gui_filter ] && echo -n "$ANYTYPESTR" > /var/local/petget/gui_filter	# SFR: any type by default

#finds pkgs in repository based on filter category and version and formats ready for display...
/usr/local/petget/filterpkgs.sh $FILTER_CATEG #writes to /tmp/petget/filterpkgs.results

echo '#!/bin/sh
echo $1 > /tmp/petget/current-repo-triad
' > /tmp/filterversion.sh
chmod 777 /tmp/filterversion.sh

ALLCATEGORY=''
if [ "$DISTRO_BINARY_COMPAT" = "puppy" ];then #v424 reintroduce the 'ALL' category.
 ALLCATEGORY="<radiobutton><label>$(gettext 'ALL')</label><action>/usr/local/petget/filterpkgs.sh ALL</action><action>refresh:TREE1</action></radiobutton>"
fi
#100513 also for 't2' (quirky) builds...
if [ "$DISTRO_BINARY_COMPAT" = "t2" ];then #reintroduce the 'ALL' category.
 ALLCATEGORY="<radiobutton><label>$(gettext 'ALL')</label><action>/usr/local/petget/filterpkgs.sh ALL</action><action>refresh:TREE1</action></radiobutton>"
fi

#120515 ditto for gentoo build...
if [ "$DISTRO_BINARY_COMPAT" = "gentoo" ];then #reintroduce the 'ALL' category.
 ALLCATEGORY="<radiobutton><label>$(gettext 'ALL')</label><action>/usr/local/petget/filterpkgs.sh ALL</action><action>refresh:TREE1</action></radiobutton>"
fi

DB_ORDERED="$REPOS_RADIO" #120831

#110118 alternate User Interfaces...
touch /var/local/petget/ui_choice
UI="`cat /var/local/petget/ui_choice`"
[ "$UI" = "" ] && UI="Classic"
. /usr/local/petget/ui_${UI}


RETPARAMS="`gtkdialog4 --program=MAIN_DIALOG`"

#eval "$RETPARAMS"

###END###
