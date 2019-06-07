#!/bin/sh
#choose an installed pkg and find all its dependencies.
#when entered with a passed param, it is a list of pkgs, '|' delimited,
#ex: abiword-1.2.3|aiksaurus-3.4.5|yabby-5.0
#100718 bug fix: code block copied from /usr/local/petget/pkg_chooser.sh
#100718 reduce size of missing-libs list, to fit in window.
#100830 missing libs, but some pkgs have a startup script that makes some libs visible.
#101220 reported missing 'alsa-lib' but wary has 'alsa-lib21a', quick hack fix.
#101221 yaf-splash fix.
#110706 finding missing dependencies fix (running mageia 1).
#120203 BK: internationalized.
#120222 npierce: use list widget, support '_' in name.
#120905 vertical scrollbars, fix window too high.
#130511 need to include devx-only-installed-packages, if loaded.

[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && \
 [ -f /tmp/petget_proc/install_quietly ] && set -x
 #; mkdir -p /tmp/petget_proc/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/petget_proc/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget___check_deps.sh
export OUTPUT_CHARSET=UTF-8

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

echo -n "" > /tmp/petget_proc/missinglibs.txt
echo -n "" > /tmp/petget_proc/missinglibs_details.txt
echo -n "" > /tmp/petget_proc/missingpkgs.txt
echo -n "" > /tmp/petget_proc/missinglibs_cut.txt #100830
echo -n "" > /tmp/petget_proc/missinglibs_hidden.txt #100830

###130511 also this copied from pkg_chooser.sh...
if [ ! -f /root/.packages/layers-installed-packages ];then
 #need to include devx-only-installed-packages, if loaded...
 if which gcc;then
  cp -f /root/.packages/woof-installed-packages /tmp/petget_proc/ppm-layers-installed-packages
  cat /root/.packages/devx-only-installed-packages >> /tmp/petget_proc/ppm-layers-installed-packages
  sort -u /tmp/petget_proc/ppm-layers-installed-packages > /root/.packages/layers-installed-packages
 else
  cp -f /root/.packages/woof-installed-packages /root/.packages/layers-installed-packages
 fi
fi

#######100718 code block copied from /usr/local/petget/pkg_chooser.sh#######
. /root/.packages/PKGS_MANAGEMENT #has PKG_REPOS_ENABLED, PKG_NAME_ALIASES

#finds all user-installed pkgs and formats ready for display...
/usr/local/petget/finduserinstalledpkgs.sh #writes to /tmp/petget_proc/installedpkgs.results

#100711 moved from findmissingpkgs.sh...
if [ ! -f /tmp/petget_proc/petget_installed_patterns_system ];then
 INSTALLED_PATTERNS_SYS="`cat /root/.packages/layers-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_SYS" > /tmp/petget_proc/petget_installed_patterns_system
 #PKGS_SPECS_TABLE also has system-installed names, some of them are generic combinations of pkgs...
 INSTALLED_PATTERNS_GEN="`echo "$PKGS_SPECS_TABLE" | grep '^yes' | cut -f 2 -d '|' |  sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_GEN" >> /tmp/petget_proc/petget_installed_patterns_system
 sort -u /tmp/petget_proc/petget_installed_patterns_system > /tmp/petget_proc/petget_installed_patterns_systemx
 mv -f /tmp/petget_proc/petget_installed_patterns_systemx /tmp/petget_proc/petget_installed_patterns_system
fi
#100711 this code repeated in findmissingpkgs.sh...
cp -f /tmp/petget_proc/petget_installed_patterns_system /tmp/petget_proc/petget_installed_patterns_all
INSTALLED_PATTERNS_USER="`cat /root/.packages/user-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
echo "$INSTALLED_PATTERNS_USER" >> /tmp/petget_proc/petget_installed_patterns_all

#process name aliases into patterns (used in filterpkgs.sh, findmissingpkgs.sh) ... 100126...
xPKG_NAME_ALIASES="`echo "$PKG_NAME_ALIASES" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g'`"
echo "$xPKG_NAME_ALIASES" > /tmp/petget_proc/petget_pkg_name_aliases_patterns_raw #110706
cp -f /tmp/petget_proc/petget_pkg_name_aliases_patterns_raw /tmp/petget_proc/petget_pkg_name_aliases_patterns #110706 _raw see findmissingpkgs.sh

sed -e 's%\\%%g' /tmp/petget_proc/petget_installed_patterns_all > /tmp/petget_proc/petget_installed_patterns_all2 #101220 hack bugfix, \- should be just -.

#100711 above has a problem as it has wildcards. need to expand...
#ex: PKG_NAME_ALIASES has an entry 'cxxlibs,glibc*,libc-*', the above creates '|cxxlibs|,|glibc.*|,|libc\-.*|',
#    after expansion: '|cxxlibs|,|glibc|,|libc-|,|glibc|,|glibc_dev|,|glibc_locales|,|glibc-solibs|,|glibc-zoneinfo|'
echo -n "" > /tmp/petget_proc/petget_pkg_name_aliases_patterns_expanded
for ONEALIASLINE in `cat /tmp/petget_proc/petget_pkg_name_aliases_patterns | tr '\n' ' '` #ex: |cxxlibs|,|glibc.*|,|libc\-.*|
do
 echo -n "" > /tmp/petget_proc/petget_temp1
 for PARTONELINE in `echo -n "$ONEALIASLINE" | tr ',' ' '`
 do
  grep "$PARTONELINE" /tmp/petget_proc/petget_installed_patterns_all2 >> /tmp/petget_proc/petget_temp1 #101220 hack see above.
 done
 ZZZ="`echo "$ONEALIASLINE" | sed -e 's%\.\*%%g' | tr -d '\\'`"
 [ -s /tmp/petget_proc/petget_temp1 ] && ZZZ="${ZZZ},`cat /tmp/petget_proc/petget_temp1 | tr '\n' ',' | tr -s ',' | tr -d '\\'`"
 ZZZ="`echo -n "$ZZZ" | sed -e 's%,$%%'`"
 echo "$ZZZ" >> /tmp/petget_proc/petget_pkg_name_aliases_patterns_expanded
done
cp -f /tmp/petget_proc/petget_pkg_name_aliases_patterns_expanded /tmp/petget_proc/petget_pkg_name_aliases_patterns

#w480 PKG_NAME_IGNORE is definedin PKGS_MANAGEMENT file... 100126...
xPKG_NAME_IGNORE="`echo "$PKG_NAME_IGNORE" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g'`"
echo "$xPKG_NAME_IGNORE" > /tmp/petget_proc/petget_pkg_name_ignore_patterns
#######100718 end copied code block#######

dependcheckfunc() {
 #entered with ex: APKGNAME=abiword-1.2.3
 
 if [ ! -f /tmp/petget_proc/install_quietly ]; then
  /usr/lib/gtkdialog/box_splash -close never -placement center -text "$(gettext 'Checking') ${APKGNAME} $(gettext 'for missing shared library files...')" &
  X1PID=$!
 fi
 
if [ "$RETPARAMS" -o "$(cat /var/local/petget/sd_category 2>/dev/null)" != "true" ]; then
 FNDFILES="`cat /root/.packages/$APKGNAME.files`"
 oldIFS=$IFS
 IFS='
'
 for ONEFILE in $FNDFILES
 do
  ISANEXEC="`file --brief "${ONEFILE}"`"
  case "$ISANEXEC" in *"LSB executable"*|*"shared object"*)
   MISSINGLIBS="`ldd "${ONEFILE}" | grep "not found"`"
   if [ ! "$MISSINGLIBS" = "" ];then
    MISSINGLIBS="`echo "$MISSINGLIBS" | cut -f 2 | cut -f 1 -d " " | tr "\n" " "`"
    echo "$(gettext 'File') $ONEFILE $(gettext 'has these missing library files:')" >> /tmp/petget_proc/missinglibs_details.txt #100718
    echo " $MISSINGLIBS" >> /tmp/petget_proc/missinglibs_details.txt #100718
    echo " $MISSINGLIBS" >> /tmp/petget_proc/missinglibs.txt #100718
   fi ;;
  esac
 done
 IFS=$oldIFS
else
	echo -n > /tmp/petget_proc/missinglibs.txt #skipped
fi

 if [ -s /tmp/petget_proc/missinglibs.txt ];then #100718 reduce size of list, to fit in window...
  MISSINGLIBSLIST="`cat /tmp/petget_proc/missinglibs.txt | tr '\n' ' ' | tr -s ' ' | tr ' ' '\n' | sort -u | tr '\n' ' '`"
  echo "$MISSINGLIBSLIST" > /tmp/petget_proc/missinglibs.txt
  #100830 some packages, such as EudoraOSE-1.0rc1-Lucid.pet used in Lucid Puppy 5.1, have a
  #startup script that makes some libs visible (/opt/eudora), so do this extra check...
  for ONEMISSINGLIB in `cat /tmp/petget_proc/missinglibs.txt` #100830
  do
   if [ "`find /opt /usr/lib /usr/local/lib -maxdepth 3 -name $ONEMISSINGLIB`" == "" ];then
    echo -n "$ONEMISSINGLIB " >> /tmp/petget_proc/missinglibs_cut.txt
   else
    echo -n "$ONEMISSINGLIB " >> /tmp/petget_proc/missinglibs_hidden.txt
   fi
  done
  cp -f /tmp/petget_proc/missinglibs_cut.txt /tmp/petget_proc/missinglibs.txt
 fi
 [ ! -f /tmp/petget_proc/install_quietly ] && kill $X1PID || echo
}

#searches deps of all user-installed pkgs...
missingpkgsfunc() {
 if [ ! -f /tmp/petget_proc/install_quietly ]; then
  /usr/lib/gtkdialog/box_splash -close never -text "$(gettext 'Checking all user-installed packages for any missing dependencies...')" &
  X2PID=$!
 fi
  USER_DB_dependencies="`cat /root/.packages/user-installed-packages | cut -f 9 -d '|' | tr ',' '\n' | sort -u | tr '\n' ','`"
  /usr/local/petget/findmissingpkgs.sh "$USER_DB_dependencies"
  #...returns /tmp/petget_proc/petget_installed_patterns_all, /tmp/petget_proc/petget_pkg_deps_patterns, /tmp/petget_proc/petget_missingpkgs_patterns
  MISSINGDEPS_PATTERNS="`cat /tmp/petget_proc/petget_missingpkgs_patterns`" #v431
  [ ! -f /tmp/petget_proc/install_quietly ] && kill $X2PID || echo
}

if [ $1 ];then
 for APKGNAME in `echo -n $1 | tr '|' ' '`
 do
  [ -f /root/.packages/${APKGNAME}.files ] && dependcheckfunc
 done
else
 exit 1 
fi

if [ -f /tmp/petget_proc/install_pets_quietly ]; then
 LEFT=$(cat /tmp/petget_proc/pkgs_left_to_install | wc -l)
 [ "$LEFT" -le 1 ] && missingpkgsfunc
else
 missingpkgsfunc
fi

PKGS="$APKGNAME"
[ $1 ] && PKGS="`echo -n "${1}" | tr '|' ' '`"

 RETPARAMS='EXIT="OK"'
 rm -f /tmp/petget_proc/petget_missing_dbentries-* 2>/dev/null
 cat /tmp/petget_proc/petget_missingpkgs_patterns_with_versioning >> \
  /tmp/petget_proc/overall_petget_missingpkgs_patterns.txt
 rm -f /tmp/petget_proc/petget_missingpkgs_patterns* 2>/dev/null
 cat /tmp/petget_proc/missinglibs.txt >> /tmp/petget_proc/overall_missing_libs.txt
 cat /tmp/petget_proc/missinglibs_hidden.txt >> /tmp/petget_proc/overall_missing_libs_hidden.txt
 rm -f /tmp/petget_proc/missinglibs* 2>/dev/null

###END###
