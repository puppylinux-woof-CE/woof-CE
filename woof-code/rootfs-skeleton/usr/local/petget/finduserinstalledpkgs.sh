#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/pkg_chooser.sh (actually, from ui_Classic and ui_Ziggy, which are embedded in pkg_chooser.sh)
#find all pkgs that have been user-installed, format for display.
#120813 no longer using /var/local/petget/flg_appicons
#120908 fix for icons (derived from Category field #5 in db).

#/root/.packages/usr-installed-packages has the list of installed pkgs...
touch /root/.packages/user-installed-packages
mkdir -p /tmp/petget_proc/petget
cut -f 1,5,10 -d '|' /root/.packages/user-installed-packages > /tmp/petget_proc/petget/installedpkgs.results

#120529 may have app icons displayed in main window...
cut -f 1,3 -d '|' /tmp/petget_proc/petget/installedpkgs.results > /tmp/petget_proc/petget/installedpkgs.results.post-noicons #120908
#120908 category field: Document;edit becomes Document-edit... (see also postfilterpkgs.sh)
sed 's%;%-%' /tmp/petget_proc/petget/installedpkgs.results > /tmp/petget_proc/petget/installedpkgs.results.post
#120908 probably doesn't matter, but take icon out for prior compatibility...
cp -f /tmp/petget_proc/petget/installedpkgs.results.post-noicons /tmp/petget_proc/petget/installedpkgs.results
grep logo /tmp/petget_proc/petget/installedpkgs.results

###END###
