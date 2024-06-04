#!/bin/sh
# ppm_advice.sh
#peebee 031122
# Called by pkg_chooser.sh.
# Shows advice only if get-browser.desktop and lx_sfs_mgr are installed.

[ ! -f /usr/share/applications/get-browser.desktop ] && exit

#Issue one-time PPM advice pop-up.
[ -e /var/local/petget/ppm-advice-shown ] && exit
touch /var/local/petget/ppm-advice-shown

export GUI=' 
<window title="Advice on Installing WebBrowsers" resizable="false"> 
<vbox>
  <text><label>This advice will display only once</label></text>
  <text><label>----------------------------</label></text>
  <text><label>The recommended way to install web browers is to</label></text>
  <text><label>use the "Internet - Get Web Browser" menu item</label></text>
  <text><label>to download and install an sfs from SourceForge</label></text>
  <text><label>----------------------------</label></text>
<hbox>
  <button width-request="200" theme-icon-size="48">
  <label>Install web browser</label>
  <input file icon="internet"></input>
  <action>lx_sfs_mgr browser</action>
  </button>
  <button width-request="200" theme-icon-size="48">
  <label>Continue to PPM</label>
  <input file icon="package"></input>
<action>exit:EXIT</action>
  </button>
</hbox>
</vbox> 
</window>' #240528

ok=`gtkdialog --program=GUI --center >/dev/null` #240528
unset GUI

