#!/bin/bash

#set -x ; mkdir -p /root/LOGs; NAME=$(basename "$0"); exec 1>> /root/LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget___pkg_chooser.sh
export OUTPUT_CHARSET=UTF-8

[ "`whoami`" != "root" ] && exec sudo -A ${0} ${@} #110505

# Check input
if [ "$TREE2" != "" ]; then
 if [ "$(grep $TREE2 /tmp/pkgs_to_remove)" = "" ]; then
  echo "$TREE2" >> /tmp/pkgs_to_remove
 fi
else
 exit 0
fi

report_window () {
 #[ ! -f /tmp/remove_pets_quietly ] && exit 0
 /usr/local/petget/finduserinstalledpkgs.sh 
 sync
 rm -f /tmp/pgks_really_removed 2>/dev/null
 rm -f /tmp/pgks_failed_to_remove 2>/dev/null
 for LINE in $(cat /tmp/pkgs_to_remove_done) 
 do 
  REALLY=$(grep $LINE /tmp/petget/installedpkgs.results) 
  if [ "$REALLY" = "" ]; then
   echo $LINE >> /tmp/pgks_really_removed
  else
   echo $LINE >> /tmp/pgks_failed_to_remove
  fi
 done
 
 REMOVED_PGKS="$(</tmp/pgks_really_removed)"
 FAILED_TO_REMOVE="$(</tmp/pgks_failed_to_remove)"
 
 if [ -s /tmp/overall_petget-deps-maybe-rem ];then
  MAYBEREM="`cat /tmp/overall_petget-deps-maybe-rem | cut -f 1 -d ' ' | tr '\n' ' '`"
  MAYBEREMMSG1="$(gettext 'The following package(s) are dependencies for the package(s) you just removed. You may want to remove them too or reinstall the package(s) you just removed'):
<i><b>${MAYBEREM}</b></i>"
 fi

 cat << EOF > /tmp/overall_remove_deport
Packages succesfully uninstalled:
$REMOVED_PGKS

Packages that did not uninstall properly or the user abortded their removal:
$FAILED_TO_REMOVE

Installed packages that may not be needed after the removal of the above:
$MAYBEREM 
EOF

 # Info window/dialogue (display and option to save "missing" info)
 export REPORT_DIALOG='
 <window title="'$(gettext 'Puppy Package Manager')'" icon-name="gtk-about" default_height="550">
 <vbox space-expand="true" space-fill="true">
   '"`/usr/lib/gtkdialog/xml_info fixed package_remove.svg 60 " " "$(gettext "Remove packages report")"`"'
   <hbox space-expand="true" space-fill="true">
     <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
       <hbox space-expand="false" space-fill="false">
         <eventbox name="bg_report" space-expand="true" space-fill="true">
           <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
             '"`/usr/lib/gtkdialog/xml_pixmap dialog-complete.svg 32`"'
             <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#15BC15'"'>'$(gettext 'Success')'</span></b></big> "</label></text>
           </vbox>
         </eventbox>
       </hbox>
       <vbox scrollable="true" shadow-type="0" hscrollbar-policy="2" vscrollbar-policy="1" space-expand="true" space-fill="true">
         <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<i><b>'${REMOVED_PGKS}' </b></i>"</label></text>
       </vbox>
     </hbox>
   </hbox>

   <hbox space-expand="true" space-fill="true">
     <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
       <hbox space-expand="false" space-fill="false">
         <eventbox name="bg_report" space-expand="true" space-fill="true">
           <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
             '"`/usr/lib/gtkdialog/xml_pixmap dialog-error.svg 32`"'
             <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#DB1B1B'"'>'$(gettext 'Failed')'</span></b></big> "</label></text>
           </vbox>
         </eventbox>
       </hbox>
       <vbox scrollable="true" shadow-type="0" hscrollbar-policy="2" vscrollbar-policy="1" space-expand="true" space-fill="true">
         <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<i><b>'${FAILED_TO_REMOVE}' </b></i>"</label></text>
       </vbox>
     </hbox>
   </hbox>

   
   <hbox space-expand="true" space-fill="true">
     <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
       <hbox space-expand="false" space-fill="false">
         <eventbox name="bg_report" space-expand="true" space-fill="true">
           <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
             '"`/usr/lib/gtkdialog/xml_pixmap building_block.svg 32`"'
             <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#bbb'"'>'$(gettext 'Depends')'</span></b></big> "</label></text>
           </vbox>
         </eventbox>
       </hbox>
       <vbox scrollable="true" shadow-type="0" hscrollbar-policy="1" vscrollbar-policy="1" space-expand="true" space-fill="true">
         <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"'${MAYBEREMMSG1}'"</label></text>
       </vbox>
     </hbox>
   </hbox> 
   <hbox space-expand="false" space-fill="false">
     <button>
       <label>'$(gettext 'View details')'</label>
       '"`/usr/lib/gtkdialog/xml_button-icon document_viewer`"'
       <action>defaulttextviewer /tmp/overall_remove_deport &</action>
     </button>
     <button ok></button>
     '"`/usr/lib/gtkdialog/xml_scalegrip`"'
   </hbox>
 </vbox>
 </window>'
 RETPARAMS="`gtkdialog --center -p REPORT_DIALOG`"

 rm -f /tmp/pgks_really_removed
 rm -f /tmp/pgks_failed_to_remove
 rm -f /tmp/pkgs_to_remove_done
 rm -f /tmp/overall_remove_deport
 rm -f /tmp/overall_petget-deps-maybe-rem
 echo 100 > /tmp/petget/install_status_percent
}
export -f report_window

remove_package () {
 [ ! "$(</tmp/pkgs_to_remove)" ] && exit 0
 TOTAL="$(grep -c "[a-z]" /tmp/pkgs_to_remove)"
 COUNT=0
 cp /tmp/pkgs_to_remove /tmp/pkgs_left_to_remove
# cat /tmp/pkgs_to_remove
 for LINE in $(cat /tmp/pkgs_to_remove)
 do 
  TREE2=$LINE
  #output to progressbar
  COUNT=$(($COUNT+1))
  PERCENT=$(($COUNT*100/$TOTAL))
  [ $PERCENT = 100 ] && PERCENT=99
  echo $PERCENT > /tmp/petget/install_status_percent
  echo "$(gettext 'Removing'): $LINE" > /tmp/petget/install_status
  #---
  if [ -f /tmp/remove_pets_quietly ]; then
   if [ "$(cat /var/local/petget/nt_category 2>/dev/null)" = "true" ]; then
    /usr/local/petget/removepreview.sh
   else 
    rxvt -title "$(gettext 'Removing... Do NOT Close')" \
     -fn -misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-*-* -bg black \
     -fg grey -geometry 80x5+50+50 -e /usr/local/petget/removepreview.sh
   fi
  else
   /usr/local/petget/removepreview.sh
  fi
  sed -i "/$TREE2/d" /tmp/pkgs_left_to_remove
  sync
 done
 /usr/local/petget/findmissingpkgs.sh
 /usr/local/petget/finduserinstalledpkgs.sh
 rm -f /tmp/{pkgs_to_remove,pkgs_left_to_remove}
 report_window
 rm -f /tmp/remove_pets_quietly 2>/dev/null
}
export -f remove_package

classic_remove () {
 rm -f /tmp/remove{,_pets}_quietly 2>/dev/null
 cp -a /tmp/pkgs_to_remove /tmp/pkgs_to_remove_done
 remove_package
 echo 100 > /tmp/petget/install_status_percent
}
export -f classic_remove

auto_remove () {
 rm -f /tmp/remove_pets_quietly 2>/dev/null
 touch /tmp/remove_pets_quietly
 cp -a /tmp/pkgs_to_remove /tmp/pkgs_to_remove_done
 remove_package
}
export -f auto_remove

delete_out_entry () {
 sed -i "/$TREE2/d" /tmp/pkgs_to_remove
}
export -f delete_out_entry

case "$1" in
	"$(gettext 'Auto remove')") auto_remove;;
	"$(gettext 'Step by step remove (classic mode)')") classic_remove;;
esac
