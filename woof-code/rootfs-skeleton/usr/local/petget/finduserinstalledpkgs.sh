#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/pkg_chooser.sh (actually, from ui_Classic and ui_Ziggy, which are embedded in pkg_chooser.sh)
#find all pkgs that have been user-installed, format for display.
#120813 no longer using /var/local/petget/flg_appicons
#120908 fix for icons (derived from Category field #5 in db).

#/root/.packages/usr-installed-packages has the list of installed pkgs...
touch /root/.packages/user-installed-packages
cut -f 1,5,10 -d '|' /root/.packages/user-installed-packages > /tmp/petget/installedpkgs.results

#120529 may have app icons displayed in main window...
#cp -f /tmp/petget/installedpkgs.results /tmp/petget/installedpkgs.results.post-noicons
cut -f 1,3 -d '|' /tmp/petget/installedpkgs.results > /tmp/petget/installedpkgs.results.post-noicons #120908
#120813 remove...
#FLG_APPICONS="`cat /var/local/petget/flg_appicons`"
#if [ "$FLG_APPICONS" = "true" ];then
# #note, for main tree, this is done in postfilterpkgs.sh.
# #ex: 'abiword0-1.2.3|description of abiword|stuff' becomes 'abiword|abiword0-1.2.3|description of abiword|stuff'
# sed -r -e 's%(^[a-zA-Z]*)%\1|\1%' /tmp/petget/installedpkgs.results > /tmp/petget/installedpkgs.results.post
#else
# cp -f /tmp/petget/installedpkgs.results /tmp/petget/installedpkgs.results.post
#fi
#120908 category field: Document;edit becomes mini-Document-edit... (see also postfilterpkgs.sh)
sed -e 's%|%|mini-%' -e 's%;%-%' /tmp/petget/installedpkgs.results > /tmp/petget/installedpkgs.results.post
#120908 probably doesn't matter, but take icon out for prior compatibility...
cp -f /tmp/petget/installedpkgs.results.post-noicons /tmp/petget/installedpkgs.results

###END###
