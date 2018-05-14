#!/bin/bash
#(c) Copyright Barry Kauler 2009, puppylinux.com.
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html)
#generates index.html master help page. called from petget, rc.update,
#  /usr/local/petget/installpreview.sh, 3builddistro (in Woof).
#w012 commented-out drop-down for all installed pkgs as too big in Ubuntu-Puppy.
#w016 support/find_homepages (in Woof) used to manually update HOMEPAGEDB variable.
#w019 now have /root/.packages/PKGS_HOMEPAGES
#w464 reintroduce dropdown help for all builtin packages.
#v423 file PKGS_HOMEPAGES is now a db of all known pkgs, not just in puppy.
#120225 copy from raw doc files.

export LANG=C
. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION, DISTRO_PUPPYDATE
. /root/.packages/DISTRO_PKGS_SPECS

WKGDIR="`pwd`"

#120225 this is done in Woof by rootfs-skeleton/pinstall.sh, but do need to do it
#here to support language translations (see /usr/share/sss/doc_strings)...
if [ -f /usr/share/doc/index.html.top-raw ];then #see Woof rootfs-skeleton/pinstall.sh, also /usr/share/sss/doc_strings
 cp -f /usr/share/doc/index.html.top-raw /usr/share/doc/index.html.top
 cp -f /usr/share/doc/index.html.bottom-raw /usr/share/doc/index.html.bottom
 cp -f /usr/share/doc/home-raw.htm /usr/share/doc/home.htm

 cutDISTRONAME="`echo -n "$DISTRO_NAME" | cut -f 1 -d ' '`"
 cPATTERN="s/cutDISTRONAME/${cutDISTRONAME}/g"
 RIGHTVER="$DISTRO_VERSION"
 dPATTERN="s/PUPPYDATE/${DISTRO_PUPPYDATE}/g"
 PATTERN1="s/RIGHTVER/${RIGHTVER}/g"
 PATTERN2="s/DISTRO_VERSION/${DISTRO_VERSION}/g"
 nPATTERN="s/DISTRO_NAME/${DISTRO_NAME}/g"
 
 sed -i -e "$PATTERN1" -e "$PATTERN2" -e "$nPATTERN" -e "$dPATTERN" -e "$cPATTERN" /usr/share/doc/index.html.top
 sed -i -e "$PATTERN1" -e "$PATTERN2" -e "$nPATTERN" -e "$dPATTERN" /usr/share/doc/index.html.bottom
 #...note, /usr/sbin/indexgen.sh puts these together as index.html (normally via rc.update and 3builddistro).
 
 sed -i -e "$nPATTERN" /usr/share/doc/home.htm
fi

#search for installed pkgs with descriptions...

#search .desktop files...
#  -e '\% %d' = ignore .desktop files with spaces, otherwise everything fails..
PKGINFO1="`ls -1 /usr/share/applications | sed -e 's%^%/usr/share/applications/%' -e '\% %d' | xargs cat - | grep '^Name=' | cut -f 2 -d '='`"
#...normal format of each entry is 'name description', ex: 'Geany text editor'.

EXCLLISTsd=" 0rootfs_skeleton autologin bootflash burniso2cd cd/dvd check configure desktop format network pupdvdtool wallpaper pbackup pburn pcdripper pdict pdisk pdvdrsab pmetatagger pschedule pstopwatch prename pprocess pmirror pfind pcdripper pmount puppy pupctorrent pupscan pupx pwireless set text "

cp -f /usr/share/doc/index.html.top /tmp/newinfoindex.xml

#dropdown menu for apps in menu...
echo '<p>Applications available in the desktop menu:</p>' >>/tmp/newinfoindex.xml
echo '<center>
<form name="form">
<select name="site" size="1" onchange="javascript:formHandler()">
' >>/tmp/newinfoindex.xml

EXCLLISTsd="${EXCLLISTsd,,}"

####################################################################
# the ouput of the code below is redirected to /tmp/newinfoindex.xml
(
echo "$PKGINFO1" |
while read ONEINFO
do
  NAMEONLY="${ONEINFO%% *}"
  NAMEONLY="${NAMEONLY,,}"
  EXPATTERN=" $NAMEONLY "
  nEXPATTERN="^$NAMEONLY "
  [[ "${EXCLLISTsd}" == *${EXPATTERN}* ]] && continue
  HOMESITE="http://en.wikipedia.org/wiki/${NAMEONLY}"
  PKGHOME="`grep -i -m1 "$nEXPATTERN" /root/.packages/PKGS_HOMEPAGES`"
  REALHOME=${PKGHOME#* } ## this assumes: name url
  [ "$REALHOME" != "" ] && HOMESITE="$REALHOME"
  echo "<option value=\"${HOMESITE}\">${ONEINFO}"
done

echo '</select>
</form>
</center>
'

#w464 dropdown list of all builtin pkgs...
echo '<p>Complete list of packages (in Puppy or not):</p>
<center>
<form name="form2">
<select name="site2" size="1" onchange="javascript:formHandler2()">
'

awk '{ print "<option value=\"" $2 "\">" $1 }' /root/.packages/PKGS_HOMEPAGES

echo '</select>
</form>
</center>
'

#now complete the index.html file...
cat /usr/share/doc/index.html.bottom

) >> /tmp/newinfoindex.xml
####################################################################

mv -f /tmp/newinfoindex.xml /usr/share/doc/index.html

if [ "$1" = "open" ] ; then
	exec defaulthtmlviewer file:///usr/share/doc/index.html
fi

###END###
