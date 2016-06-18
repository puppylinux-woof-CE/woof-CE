#!/bin/sh
#called from installpreview.sh.
#passed param (also variable TREE1) is name of pkg, ex: abiword-1.2.3.
#/tmp/petget/current-repo-triad has the repository that installing from.
#w019 now have /root/.packages/PKGS_HOMEPAGES
#101221 yaf-splash fix.
#110523 Scientific Linux docs.
#120203 BK: internationalized.
#120515 support gentoo arm distro (built from bin tarballs from a gentoo sd image).
#120719 support raspbian.

[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && \
 [ -f /tmp/install_quietly ] && set -x
 #; mkdir -p /tmp/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget___fetchinfo.sh
export OUTPUT_CHARSET=UTF-8

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

#ex: TREE1=abiword-1.2.4 (first field in database entry).
DB_FILE=Packages-`cat /tmp/petget/current-repo-triad` #ex: Packages-slackware-12.2-official

tPATTERN='^'"$TREE1"'|'
DB_ENTRY="`grep "$tPATTERN" /root/.packages/$DB_FILE | head -n 1`"
#line format: pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|
#optionally on the end: compileddistro|compiledrelease|repo| (fields 11,12,13)

DB_nameonly="`echo -n "$DB_ENTRY" | cut -f 2 -d '|'`"
DB_fullfilename="`echo -n "$DB_ENTRY" | cut -f 8 -d '|'`"

DB_DISTRO="`echo -n "$DB_FILE" | cut -f 2 -d '-'`"  #exs: slackware  arch     ubuntu
DB_RELEASE="`echo -n "$DB_FILE" | cut -f 3 -d '-'`" #exs: 12.2       200902   intrepid
DB_SUB="`echo -n "$DB_FILE" | cut -f 4 -d '-'`"     #exs: official   extra    universe

case $DB_DISTRO in
 slackware)
  if [ ! -f /root/.packages/PACKAGES.TXT-${DB_SUB} ];then
#  /usr/lib/gtkdialog/box_splash -font "8x16" -outline 0 -margin 4 -text "Please wait, downloading database file to /root/.packages/PACKAGES.TXT-${DB_SUB}..." &
   if [ ! -f /tmp/install_quietly ]; then
    /usr/lib/gtkdialog/box_splash -close never -text "$(gettext 'Please wait, downloading database file to') /root/.packages/PACKAGES.TXT-${DB_SUB}..." &
    X5PID=$!
   fi
   cd /root/.packages
   case $DB_SUB in
    official)
     wget http://slackware.cs.utah.edu/pub/slackware/slackware-${DB_RELEASE}/PACKAGES.TXT
    ;;
    slacky)
     wget http://repository.slacky.eu/slackware-${DB_RELEASE}/PACKAGES.TXT
    ;;
   esac
   sync
   mv -f PACKAGES.TXT PACKAGES.TXT-${DB_SUB}
   [ ! -f /tmp/install_quietly ] && kill $X5PID || echo
  fi
  cat /root/.packages/PACKAGES.TXT-${DB_SUB} | tr -s ' ' | sed -e 's% $%%' | tr '%' ' ' | tr '\n' '%' | sed -e 's/%%/@/g' | grep -o "PACKAGE NAME: ${DB_fullfilename}[^@]*" | tr '%' '\n' > /tmp/petget_slackware_pkg_extra_info
  sync
  nohup defaulttextviewer /tmp/petget_slackware_pkg_extra_info &
 ;;
 debian|raspbian)
  nohup defaulthtmlviewer http://packages.debian.org/${DB_RELEASE}/${DB_nameonly} &
 ;;
 devuan)
  nohup defaulthtmlviewer http://packages.devuan.org/ &
 ;;
 ubuntu)
  nohup defaulthtmlviewer http://packages.ubuntu.com/${DB_RELEASE}/${DB_nameonly} &
 ;;
 puppy|gentoo)
   #HOMELINK="`grep 'Homepage:' /tmp/gethomepage_2 | grep -o 'href=".*' | cut -f 2 -d '"'`"
  #w019 fast (see also /usr/sbin/indexgen.sh)...
  HOMESITE="http://en.wikipedia.org/wiki/${DB_nameonly}"
  #121217 pkg name might differ - and _ chars...
  nPTN1="^$(echo "${DB_nameonly}" | tr '-' '_') "
  nPTN2="^$(echo "${DB_nameonly}" | tr '_' '-') "
  REALHOME="`cat /root/.packages/PKGS_HOMEPAGES | grep -i "$nPTN1" | head -n 1 | cut -f 2 -d ' '`"
  [ "$REALHOME" = "" ] && REALHOME="`cat /root/.packages/PKGS_HOMEPAGES | grep -i "$nPTN2" | head -n 1 | cut -f 2 -d ' '`"
  [ "$REALHOME" != "" ] && HOMESITE="$REALHOME"
  nohup defaulthtmlviewer $HOMESITE &
 ;;
esac

###END###
