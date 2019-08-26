#!/bin/sh
#called from ui_Classic and ui_Ziggy, after running findnames.sh.
#120908 script created.
#130511 pkg_chooser.sh has created layers-installed-packages (use instead of woof-installed-packages).

export TEXTDOMAIN=petget___versiondiffs
export OUTPUT_CHARSET=UTF-8

#created by findnames.sh...
[ ! -s /tmp/petget_proc/petget/filterpkgs.results.installed ] && exit

#120908 "ALREADY INSTALLED" may not be helpful, as the versions may differ. display these...
DIFFVERITEMS=""
while IFS="|" read ONEPKG ONENAMEONLY ONEVERSION ZZ
do
 #ex: langpack_de-20120718|langpack_de|20120718
 onoPTN="|${ONENAMEONLY}|"
 INSTALLEDPKGS="$(cat /root/.packages/layers-installed-packages /root/.packages/user-installed-packages | grep "$onoPTN" | cut -f 1,3 -d '|' | tr '\n' ' ')"
 for AINSTALLEDPKG in $INSTALLEDPKGS
 do
  AIPKG="$(echo -n "$AINSTALLEDPKG" | cut -f 1 -d '|')"
  AIVER="$(echo -n "$AINSTALLEDPKG" | cut -f 2 -d '|')"
  if ! vercmp $AIVER eq $ONEVERSION;then
   DIFFVERITEMS="${DIFFVERITEMS}<item>${ONEPKG}|${AIPKG}</item>"
  fi
 done
done < /tmp/petget_proc/petget/filterpkgs.results.installed

if [ "$DIFFVERITEMS" = "" ] ; then
	exit
fi

export ppm_versions='<window title="PPM: '$(gettext 'Version differences')'" icon-name="gtk-about">
<vbox space-expand="true" space-fill="true">
  <frame>
    <vbox space-expand="false" space-fill="false">
      <hbox homogeneous="true">
        '"`/usr/lib/gtkdialog/xml_pixmap "dialog-info" popup`"'
      </hbox>
      <text xalign="0" use-markup="true" space-expand="true" space-fill="true">
        <label>"<b>'$(gettext "Version differences")'</b>"</label>
      </text>
      <text xalign="0" space-expand="true" space-fill="true">
        <label>'$(gettext "Normally in the PPM main window, if a package, regardless of version, is already installed, it will not be listed. HOWEVER, the output of a search lists all matching packages, including installed, and identifies already-installed packages with the text 'ALREADY INSTALLED' and a 'tick' icon.")'</label>
      </text>
      <text xalign="0" space-expand="true" space-fill="true">
        <label>'$(gettext "If a package found by a search is a different version than already installed, it is listed below. Please do not install such packages unless there is a particular reason to do so.")'</label>
      </text>
    </vbox>
    <vbox space-expand="true" space-fill="true">
      <table space-expand="true" space-fill="true">
        <label>'$(gettext 'Found package')'|'$(gettext 'Installed package')'</label>
        '${DIFFVERITEMS}'
      </table>
    </vbox>
  </frame>
  <hbox space-expand="false" space-fill="false">
    <button can-default="true" has-default="true">
      <variable>BUTTON_OK</variable>
      <label>'$(gettext 'Ok')'</label>
      <input file stock="gtk-ok"></input>
      <action type="exit">ok</action>
   </button>
  </hbox>
</vbox>
<action signal="show">grabfocus:BUTTON_OK</action>
</window>'

gtkdialog -p ppm_versions

