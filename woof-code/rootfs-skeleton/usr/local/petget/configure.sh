#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/pkg_chooser.sh
#configure package manager
#110118 alternate user interfaces.
#120203 BK: internationalized.
#120210 01micko: Ziggy ui crashes if *all* repos unticked here (no one would do that, but it is still a bug).
#120515 in some cases, Packages-puppy-${DISTRO_FILE_PREFIX}-* may not exist (ex, Racy only has Packages-puppy-wary5-official).
#120529 checkbox to display app thumbnail icons.
#120811 category field now supports sub-category |category;subcategory|, use as icon in ppm main window. -- always enabled.
#121102 Packages-puppy-${DISTRO_FILE_PREFIX}- (or Packages-puppy-${DISTRO_COMPAT_VERSION}-) is now Packages-puppy-${DISTRO_DB_SUBNAME}-. refer /etc/DISTRO_SPECS.
#121129 Update: d/l Packages-puppy-squeeze-official, which wasn't there before, upset this script.

export TEXTDOMAIN=petget___configure.sh
export OUTPUT_CHARSET=UTF-8

#export LANG=C
. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS
. /root/.packages/DISTRO_PET_REPOS
. /root/.packages/PKGS_MANAGEMENT #has PKG_REPOS_ENABLED

#find what repos are currently in use... 120510...
CHECKBOXES_REPOS=""
#for ONEREPO in `ls -1 /root/.packages/Packages-*`
#120510 bugfix with ui_Ziggy. add CHECKBOX_MAIN_REPO var to gui
MAIN_REPO="`ls -1 /root/.packages/Packages-* | grep "puppy\-${DISTRO_DB_SUBNAME}\-" | head -n 1 | sed 's%^/root/.packages/%%'`" #121102 121129
#120515 hmmm, in some cases, Packages-puppy-${DISTRO_FILE_PREFIX}-* may not exist (ex, Racy only has Packages-puppy-wary5-official)...
#121102 ...now using DISTRO_DB_SUBNAME, should always exist.
[ "$MAIN_REPO" = "" ] && MAIN_REPO="`echo "$PACKAGELISTS_PET_ORDER" | tr ' ' '\n' | head -n 1`" #PACKAGELISTS_PET_ORDER is in /root/.packages/DISTRO_PET_REPOS.
[ "$MAIN_REPO" = "" ] && MAIN_REPO="Packages-puppy-noarch-official" #paranoid precaution.
bMAIN_PATTERN=' '"$MAIN_REPO"' '
MAIN_DBNAME="`echo -n "$MAIN_REPO" | sed -e 's%Packages\-%%'`"
CHECKBOX_MAIN_REPO="<checkbox><default>true</default><label>${MAIN_DBNAME}</label><variable>CHECK_${MAIN_DBNAME}</variable><visible>disabled</visible></checkbox>" #hard coded "true"

DBFILESLIST="$(ls -1 /root/.packages/Packages-*)" #121129

PKG_REPOS_ENABLED=" ${PKG_REPOS_ENABLED} " #121129 precaution.
for ONEREPO in `echo "$DBFILESLIST" | grep -v "${MAIN_REPO}" | tr '\n' ' '` #120515 fix. 121129
do
 BASEREPO="`basename $ONEREPO`"
 bPATTERN=' '"${BASEREPO}"' '
 DEFAULT='true'
 [ "`echo -n "$PKG_REPOS_ENABLED" | grep "$bPATTERN"`" = "" ] && DEFAULT='false'
 DBNAME="`echo -n "$BASEREPO" | sed -e 's%Packages\-%%'`"
 CHECKBOXES_REPOS="${CHECKBOXES_REPOS}<checkbox><default>${DEFAULT}</default><label>${DBNAME}</label><variable>CHECK_${DBNAME}</variable></checkbox>"
done

#110118 choose a user interface...
UI="`cat /var/local/petget/ui_choice`"
[ "$UI" = "" ] && UI="Classic"
UI_RADIO="<radiobutton><label>${UI}</label><action>echo -n ${UI} > /var/local/petget/ui_choice</action></radiobutton>"
for ONEUI in Classic Ziggy
do
 [ "$ONEUI" = "$UI" ] && continue
 UI_RADIO="${UI_RADIO}<radiobutton><label>${ONEUI}</label><action>echo -n ${ONEUI} > /var/local/petget/ui_choice</action></radiobutton>"
done

#checkbox for BuildingBlock category
[ "`cat /var/local/petget/bb_category`" = "true" ] && BB_STATE=true || BB_STATE=false

#  <text><label>Choose an alternate User Interface:</label></text>

export CONFIG_DIALOG="<window title=\"$(gettext 'Puppy Package Manager: configure')\" icon-name=\"gtk-about\">
<hbox>

<vbox>
 <frame $(gettext 'Update database')>
  <hbox>
   <text><label>$(gettext 'Puppy has a database file for each package repository. Click this button to download the latest information on what packages are in the repository:')</label></text>
   <button><label>$(gettext 'Update now')</label><action>rxvt -bg yellow -title 'download databases' -e /usr/local/petget/0setup</action></button>
  </hbox>
  <text><label>$(gettext "Note: some repositories are 'fixed' and do not need to be updated. An example of this is the Slackware official version 12.2 repo. An example that does change is the Slackware 'slacky' 12.2 repo which has extra packages for Slackware 12.2. Anyway, to be on the safe side, clicking the above button will update all database files.")</label></text>
  <text><label>$(gettext "Warning: The database information for some repositories is quite large, about 1.5MB for 'slacky' and several MB for Ubuntu/Debian. If you are on dialup, be prepared for this.")</label></text>
  <text><label>$(gettext 'Technical note: if you would like to see the package databases, they are at') /root/.packages/Packages-*. $(gettext 'These are in a standardised format, regardless of which distribution they were obtained from. This format is considerably smaller than that of the original distro.')</label></text>
 </frame>
 <frame $(gettext 'User Interface')>
  ${UI_RADIO}
 </frame>

   <checkbox>
     <label>$(gettext 'Enable BuildingBlock category (for advanced users only!)')</label>
     <variable>varBB_STATE</variable>
     <default>${BB_STATE}</default>
     <action>echo -n \${varBB_STATE} > /var/local/petget/bb_category</action>
   </checkbox>

</vbox>

<vbox>
 <text use-markup=\"true\"><label>\"<b>$(gettext 'Requires restart of PPM to see changes')</b>\"</label></text>
 <frame $(gettext 'Choose repositories')>
  <text><label>$(gettext 'Choose what repositories you would like to have appear in the main GUI window:')</label></text>
  ${CHECKBOXES_REPOS}
  ${CHECKBOX_MAIN_REPO}
  <hbox>
   <text><label>$(gettext 'Adding a new repository currently requires manual editing of some text files. Click this button for further information:')</label></text>
   <button><label>$(gettext 'Add repo help')</label>
   <action>nohup defaulthtmlviewer file:///usr/local/petget/README-add-repo.htm & </action>
   </button>
  </hbox>
 </frame>
 <hbox>
  <button ok></button>
  <button cancel></button>
 </hbox>
</vbox>

</hbox>
</window>"

RETPARAMS="`gtkdialog3 --program=CONFIG_DIALOG`"
#ex:
#  CHECK_puppy-2-official="false"
#  CHECK_puppy-3-official="true"
#  CHECK_puppy-4-official="true"
#  CHECK_puppy-woof-official="false"
#  CHECK_ubuntu-intrepid-main="true"
#  CHECK_ubuntu-intrepid-multiverse="true"
#  CHECK_ubuntu-intrepid-universe="true"
#  EXIT="OK"

[ "`echo -n "$RETPARAMS" | grep 'EXIT' | grep 'OK'`" = "" ] && exit

enabledrepos=" "
repocnt=1
for ONEREPO in `echo "$DBFILESLIST" | tr '\n' ' '` #121129
do
 REPOBASE="`basename $ONEREPO`"
 repoPATTERN="`echo -n "$REPOBASE" | sed -e 's%Packages\\-%%' | sed -e 's%\\-%\\\\-%g'`"
 if [ "`echo "$RETPARAMS" | grep "$repoPATTERN" | grep 'false'`" = "" ];then
  enabledrepos="${enabledrepos}${REPOBASE} "
  repocnt=`expr $repocnt + 1`
  #[ $repocnt -gt 5 ] && break #only allow 5 active repos in PPM.	# SFR: no limit
 fi
done
grep -v '^PKG_REPOS_ENABLED' /root/.packages/PKGS_MANAGEMENT > /tmp/pkgs_management_tmp2
mv -f /tmp/pkgs_management_tmp2 /root/.packages/PKGS_MANAGEMENT
echo "PKG_REPOS_ENABLED='${enabledrepos}'" >> /root/.packages/PKGS_MANAGEMENT


###END###
