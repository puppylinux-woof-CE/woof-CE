#!/bin/bash

export TEXTDOMAIN=petget___pkg_chooser.sh
export OUTPUT_CHARSET=UTF-8

[ "`whoami`" != "root" ] && exec sudo -A ${0} ${@} #110505

if [ -f /root/.packages/download_path ]; then
 . /root/.packages/download_path
fi

clean_up () {
 if [ "$(ls /tmp/petget_proc/*_pet{,s}_quietly /tmp/petget_proc/install_classic 2>/dev/null |wc -l)" -eq 1 ]; then
  for MODE in $(ls /tmp/petget_proc/*_pet{,s}_quietly /tmp/petget_proc/install_classic)
  do
   mv $MODE $MODE.bak
  done
 fi
 mv /tmp/petget_proc/install_quietly /tmp/petget_proc/install_quietly.bak
 echo -n > /tmp/petget_proc/pkgs_to_install
 rm -f /tmp/petget_proc/{install,remove}{,_pets}_quietly 2>/dev/null
 rm -f /tmp/petget_proc/install_classic 2>/dev/null
 rm -f /tmp/petget_proc/download_pets_quietly 2>/dev/null
 rm -f /tmp/petget_proc/download_only_pet_quietly 2>/dev/null
 rm -f /tmp/petget_proc/pkgs_left_to_install 2>/dev/null
 rm -f /tmp/petget_proc/pkgs_to_install_done 2>/dev/null
 rm -f /tmp/petget_proc/overall_pkg_size* 2>/dev/null
 rm -f /tmp/petget_proc/overall_dependencies 2>/dev/null
 rm -f /tmp/petget_proc/mode_changed 2>/dev/null
 rm -f /tmp/petget_proc/force*_install 2>/dev/null
 rm -f /tmp/petget_proc/pkgs_to_install_done 2>/dev/null
 rm -f /tmp/petget_proc/pgks_really_installed 2>/dev/null
 rm -f /tmp/petget_proc/pgks_failed_to_install 2>/dev/null
 rm -f /tmp/petget_proc/overall_petget_missingpkgs_patterns.txt 2>/dev/null
 rm -f /tmp/petget_proc/overall_missing_libs.txt 2>/dev/null
 rm -f /tmp/petget_proc/overall_install_report 2>/dev/null
 rm -f /tmp/petget_proc/pkgs_to_install_bar 2>/dev/null
 rm -f /tmp/petget_proc/manual_pkg_download 2>/dev/null
 rm -f /tmp/petget_proc/ppm_reporting 2>/dev/null
 rm -f /tmp/petget_proc/pkgs_DL_BAD_LIST 2>/dev/null
 rm -rf /tmp/petget_proc/PPM_LOGs/ 2>/dev/null
 mv $MODE.bak $MODE
 mv /tmp/petget_proc/install_quietly.bak /tmp/petget_proc/install_quietly
}
export -f clean_up

report_results () {
 # Info source files
 touch /tmp/petget_proc/ppm_reporting # progress bar flag
 /usr/local/petget/finduserinstalledpkgs.sh #make sure...
 sync
 rm -f /tmp/petget_proc/pgks_really_installed 2>/dev/null
 rm -f /tmp/petget_proc/pgks_failed_to_install 2>/dev/null
 for LINE in $(cat /tmp/petget_proc/pkgs_to_install_done  | cut -f 1 -d '|' | sort | uniq)
 do
  [ "$(echo $LINE)" = "" ] && continue
  if [ -f /tmp/petget_proc/download_pets_quietly -o -f /tmp/petget_proc/download_only_pet_quietly \
   -o -f /tmp/petget_proc/manual_pkg_download ];then
   if [ -f /root/.packages/download_path ];then
    . /root/.packages/download_path
    DOWN_PATH="$DL_PATH"
   else
    DOWN_PATH=$HOME
   fi
   PREVINST=''
   REALLY=$(ls "$DOWN_PATH" | grep $LINE)
   [ "$REALLY" -a "$(grep $LINE /tmp/petget_proc/pkgs_DL_BAD_LIST 2>/dev/null | sort | uniq )" != "" ] && \
    REALLY='' && PREVINST="$(gettext 'was previously downloaded')"
  else
   PREVINST=''
   REALLY=$(grep $LINE /tmp/petget_proc/petget/installedpkgs.results)
   [ "$(grep $LINE /tmp/petget_proc/pgks_failed_to_install_forced 2>/dev/null | sort | uniq )" != "" -o \
    "$(grep $LINE /tmp/petget_proc/pkgs_DL_BAD_LIST 2>/dev/null | sort | uniq )" != "" ] \
    && REALLY='' && PREVINST="$(gettext 'was already installed')"
  fi
  if [ "$REALLY" != "" ]; then
   echo $LINE >> /tmp/petget_proc/pgks_really_installed
  else
   echo $LINE $PREVINST >> /tmp/petget_proc/pgks_failed_to_install
  fi
 done
 rm -f /tmp/petget_proc/pgks_failed_to_install_forced

 [ -f /tmp/petget_proc/pgks_really_installed ] && INSTALLED_PGKS="$(</tmp/petget_proc/pgks_really_installed)" \
  || INSTALLED_PGKS=''
 [ -f /tmp/petget_proc/pgks_failed_to_install ] && FAILED_TO_INSTALL="$(</tmp/petget_proc/pgks_failed_to_install)" \
  || FAILED_TO_INSTALL=''
 #MISSING_PKGS=$(cat /tmp/petget_proc/overall_petget_missingpkgs_patterns.txt |sort|uniq )
 MISSING_LIBS=$(cat /tmp/petget_proc/overall_missing_libs.txt 2>/dev/null | tr ' ' '\n' | sort | uniq )
 NOT_IN_PATH_LIBS=$(cat /tmp/petget_proc/overall_missing_libs_hidden.txt 2>/dev/null | tr ' ' '\n' | sort | uniq )
 cat << EOF > /tmp/petget_proc/overall_install_report
Packages succesfully Installed or Downloaded 
$INSTALLED_PGKS

Packages that failed to be Installed or Downloaded, or were aborted be the user
$FAILED_TO_INSTALL

Missing Shared Libraries
$MISSING_LIBS

Existing Libraries that may be in a location other than /lib and /usr/lib
$NOT_IN_PATH_LIBS
EOF

 # Info window/dialogue (display and option to save "missing" info)
 if [ "$MISSING_LIBS" ];then
  MISSINGMSG1="<i><b>$(gettext 'These libraries are missing:')
${MISSING_LIBS}</b></i>"
  LM='  <hbox space-expand="true" space-fill="true">
    <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
      <hbox space-expand="false" space-fill="false">
        <eventbox name="bg_report" space-expand="true" space-fill="true">
          <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
            '"`/usr/lib/gtkdialog/xml_pixmap building_block.svg 32`"'
            <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#bbb'"'>'$(gettext 'Libs')'</span></b></big> "</label></text>
          </vbox>
        </eventbox>
      </hbox>
      <vbox scrollable="true" shadow-type="0" hscrollbar-policy="1" vscrollbar-policy="1" space-expand="true" space-fill="true">
        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"'${MISSINGMSG1}'"</label></text>
      </vbox>
    </hbox>
  </hbox>'
 fi
 if [ "$NOT_IN_PATH_LIBS" ];then #100830
  MISSINGMSG1="<i><b>${MISSINGMSG1}</b></i>
 
$(gettext 'These needed libraries exist but are not in the library search path (it is assumed that a startup script in the package makes these libraries loadable by the application):')
<i><b>${NOT_IN_PATH_LIBS}</b></i>"
 fi

 if [ -s /tmp/petget_proc/petget-installed-pkgs-log ];then
  BUTTON_TRIM="<button><input file stock=\"gtk-execute\"></input><label>$(gettext 'Trim the fat')</label><action type=\"exit\">BUTTON_TRIM_FAT</action></button>"
 fi

 export REPORT_DIALOG='
 <window title="'$(gettext 'Package Manager')'" icon-name="gtk-about" default_height="550">
 <vbox>
  '"`/usr/lib/gtkdialog/xml_info fixed package_add.svg 60 " " "$(gettext "Package install/download report")"`"'
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
        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<i><b>'${INSTALLED_PGKS}' </b></i>"</label></text>
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
        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<i><b>'${FAILED_TO_INSTALL}' </b></i>"</label></text>
      </vbox>
    </hbox>
  </hbox>

  '${LM}'

  <hbox space-expand="false" space-fill="false">
     <button ok></button>
     <button>
      <label>'$(gettext 'View details')'</label>
      <input file stock="gtk-dialog-info"></input>
      <action>defaulttextviewer /tmp/petget_proc/overall_install_report &</action>
     </button>
     '${BUTTON_TRIM}'
     '"`/usr/lib/gtkdialog/xml_scalegrip`"'
  </hbox>
 </vbox>
 </window>'
 RETPARAMS="`gtkdialog --center -p REPORT_DIALOG`"
 eval "$RETPARAMS"
 echo 100 > /tmp/petget_proc/petget/install_status_percent
 
  #trim the fat...
 if [ "$EXIT" = "BUTTON_TRIM_FAT" ];then
  INSTALLEDPKGNAMES="`cat /tmp/petget_proc/petget-installed-pkgs-log | cut -f 2 -d ' ' | tr '\n' ' '`"
  #101013 improvement suggested by L18L...
  CURRLOCALES="`locale -a | grep _ | cut -d '_' -f 1`"
  LISTLOCALES="`echo -e -n "en\n${CURRLOCALES}" | sort -u | tr -s '\n' | tr '\n' ',' | sed -e 's%,$%%'`"
  export PPM_TRIM_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\" resizable=\"false\">
  <vbox>
   <pixmap><input file>/usr/share/pixmaps/puppy/dialog-question.svg</input></pixmap>
   <text><label>$(gettext "You have chosen to 'trim the fat' of these installed packages:")</label></text>
   <text use-markup=\"true\"><label>\"<b>${INSTALLEDPKGNAMES}</b>\"</label></text>
   <frame Locale>
   <text><label>$(gettext 'Type the 2-letter country designations for the locales that you want to retain, separated by commas. Leave blank to retain all locale files (see /usr/share/locale for examples):')</label></text>
   <entry><default>${LISTLOCALES}</default><variable>ENTRY_LOCALE</variable></entry>
   </frame>
   <frame $(gettext 'Documentation')>
   <checkbox><default>true</default><label>$(gettext 'Tick this to delete documentation files')</label><variable>CHECK_DOCDEL</variable></checkbox>
   </frame>
   <frame $(gettext 'Development')>
   <checkbox><default>true</default><label>$(gettext 'Tick this to delete development files')</label><variable>CHECK_DEVDEL</variable></checkbox>
   <text><label>$(gettext '(only needed if these packages are required as dependencies when compiling another package from source code)')</label></text>
   </frame>
   <text><label>$(gettext "Click 'OK', or if you decide to chicken-out click 'Cancel':")</label></text>
   <hbox>
    <button ok></button>
    <button cancel></button>
   </hbox>
  </vbox>
  </window>"
  RETPARAMS="`gtkdialog -p PPM_TRIM_DIALOG`"
  eval "$RETPARAMS"
  [ "$EXIT" != "OK" ] && exit $EXITVAL
  if [ ! -f /tmp/petget_proc/install_quietly ]; then
   /usr/lib/gtkdialog/box_splash -text "$(gettext 'Please wait, trimming fat from packages...')" &
   X4PID=$!
  fi
  elPATTERN="`echo -n "$ENTRY_LOCALE" | tr ',' '\n' | sed -e 's%^%/%' -e 's%$%/%' | tr '\n' '|'`"
  for PKGNAME in $INSTALLEDPKGNAMES
  do
   (
   cat /root/.packages/${PKGNAME}.files |
   while read ONEFILE
   do
    [ ! -f "$ONEFILE" ] && echo "$ONEFILE" && continue
    [ -h "$ONEFILE" ] && echo "$ONEFILE" && continue
    #find out if this is an international language file...
    if [ "$ENTRY_LOCALE" != "" ];then
     if [ "`echo -n "$ONEFILE" | grep --extended-regexp '/locale/|/nls/|/i18n/' | grep -v -E "$elPATTERN"`" != "" ];then
      rm -f "$ONEFILE"
      continue
     fi
    fi
    #find out if this is a documentation file...
    if [ "$CHECK_DOCDEL" = "true" ];then
     if [ "`echo -n "$ONEFILE" | grep --extended-regexp '/man/|/doc/|/doc-base/|/docs/|/info/|/gtk-doc/|/faq/|/manual/|/examples/|/help/|/htdocs/'`" != "" ];then
      rm -f "$ONEFILE" 2>/dev/null
      continue
     fi
    fi
    #find out if this is development file...
    if [ "$CHECK_DEVDEL" = "true" ];then
     if [ "`echo -n "$ONEFILE" | grep --extended-regexp '/include/|/pkgconfig/|/aclocal|/cvs/|/svn/'`" != "" ];then
      rm -f "$ONEFILE" 2>/dev/null
      continue
     fi
     #all .a and .la files... and any stray .m4 files...
     if [ "`echo -n "$ONEBASE" | grep --extended-regexp '\.a$|\.la$|\.m4$'`" != "" ];then
      rm -f "$ONEFILE"
      continue
     fi
    fi
    echo "$ONEFILE"
   done
   ) > /tmp/petget_proc/petget_pkgfiles_temp
   mv -f /tmp/petget_proc/petget_pkgfiles_temp /root/.packages/${PKGNAME}.files
  done
  [ "$X4PID" ] && kill $X4PID
 fi
}
export -f report_results

check_total_size () {
 rm -f /tmp/petget_proc/petget_deps_visualtreelog 2>/dev/null
 rm -f /tmp/petget_proc/petget_frame_cnt 2>/dev/null
 rm -f /tmp/petget_proc/petget_missingpkgs_patterns{2,_acc,_acc0,_acc-prev,x0,_and_versioning_level1} 2>/dev/null
 rm -f /tmp/petget_proc/petget_moreframes 2>/dev/null
 rm -f /tmp/petget_proc/petget_tabs 2>/dev/null
 rm -f /tmp/petget_proc/pkgs_to_install_bar 2>/dev/null
 #required size
 NEEDEDK_PLUS=$(awk '{ sum += $1 } END { print sum }' /tmp/petget_proc/overall_pkg_size)
 [ ! "$NEEDEDK_PLUS" ] && NEEDEDK_PLUS=0
 NEEDEDK=$(( $NEEDEDK_PLUS / 768 )) # 1.5x
 ACTION_MSG=$(gettext 'This is not enough space to download and install the packages (including dependencies) you have selected.')
 if [ -f /tmp/petget_proc/download_pets_quietly -o -f /tmp/petget_proc/download_only_pet_quietly ]; then
  NEEDEDK=$(( $NEEDEDK / 3 )) # 0.5x
  [ "$DL_PATH" ] && DOWN_PATH="$DL_PATH" || DOWN_PATH="/root"
  ACTION_MSG="$(gettext 'This is not enough space to download the packages (including dependencies) you have selected in ')${DOWN_PATH}."
 fi
 if [ "$(cat /var/local/petget/nd_category 2>/dev/null)" = "true" ]; then
  NEEDEDKDOWN=$(($NEEDEDK / 3 ))
 else
  NEEDEDKDOWN="$NEEDEDK" # so will not trigger warning
 fi
 #---
 . /etc/rc.d/functions_x
 AVAILABLE=$SIZEFREEM
 if [ ! "$AVAILABLE" ]; then
	echo "Free space estimation error. Exiting" > /tmp/petget_proc/petget/install_status
	. /usr/lib/gtkdialog/box_ok "$(gettext 'Free space error')" error "$(gettext 'This is a rare error that fails to report the available free space. It should be OK after a restart')"
	clean_up
	exit 1
 fi
 if [ "$DL_PATH" -a ! "$DL_PATH" = "/root" ]; then
  if [ -f /tmp/petget_proc/download_pets_quietly -o -f /tmp/petget_proc/download_only_pet_quietly \
   -o "$(cat /var/local/petget/nd_category 2>/dev/null)" = "true" ]; then
   SAVEAVAILABLE=$(df -m "$DL_PATH"| awk 'END {print $4}')
  else
   SAVEAVAILABLE="$AVAILABLE" # so will not trigger warning
  fi
 else
  SAVEAVAILABLE="$AVAILABLE" # so will not trigger warning
 fi
 if [ -f /tmp/petget_proc/download_pets_quietly -o -f /tmp/petget_proc/download_only_pet_quietly ]; then
  [ "$SAVEAVAILABLE" != "$AVAILABLE" ] && AVAILABLE="$SAVEAVAILABLE"
 fi
 PACKAGES=$(cat /tmp/petget_proc/pkgs_to_install | cut -f 1 -d '|')
 DEPENDENCIES=$(cat /tmp/petget_proc/overall_dependencies 2>/dev/null | sort | uniq)
 [ "$AVAILABLE" = "0" -o  "$AVAILABLE" = "" ] && echo "No space left on device. Exiting" \
	> /tmp/petget_proc/petget/install_status && clean_up && exit 0
 #statusbar in main gui
 PERCENT=$((${NEEDEDK}*100/${AVAILABLE}))
 [ $PERCENT -gt 99 ] && PERCENT=99
 if [ -s /tmp/petget_proc/overall_pkg_size ] && [ $PERCENT = 0 ]; then PERCENT=1; fi
 echo "$PERCENT" > /tmp/petget_proc/petget/install_status_percent
 if [ "$(cat /tmp/petget_proc/pkgs_to_install /tmp/petget_proc/overall_dependencies 2>/dev/null)" = "" ]; then
  echo "" > /tmp/petget_proc/petget/install_status
 else
  cat /tmp/petget_proc/pkgs_to_install | cut -f1 -d '|' > /tmp/petget_proc/pkgs_to_install_bar
  if [ -f /tmp/petget_proc/install_pets_quietly -o -f /tmp/petget_proc/install_classic ]; then
   if [ "$(cat /var/local/petget/nd_category 2>/dev/null)" != "true" ]; then
    BARNEEDEDK=$(( 2 * ${NEEDEDK} / 3 ))
    BARMSG="$(gettext 'to install')"
   else
    BARNEEDEDK=${NEEDEDK}
    BARMSG="$(gettext 'to install (and keep pkgs)')"
   fi
  else
   BARNEEDEDK=${NEEDEDK}
   BARMSG="$(gettext 'to download')"
  fi
  echo "$(gettext 'Packages (with deps)'): $(cat /tmp/petget_proc/pkgs_to_install_bar /tmp/petget_proc/overall_dependencies 2>/dev/null |sort | uniq | wc -l)    -   $(gettext 'Required space') ${BARMSG}: ${BARNEEDEDK}MB   -   $(gettext 'Available'): ${AVAILABLE}MB" > /tmp/petget_proc/petget/install_status
 fi
 #Check if enough space on system
 if [ "$NEEDEDKDOWN" -ge "$SAVEAVAILABLE" -a "$AVAILABLE" -ge "$NEEDEDK" ]; then
  ACTION_MSG="$(gettext 'Although there is sufficient space to install the packages, there is no space in your download folder, ')$DL_PATH$(gettext ', to save the packages (including dependencies). ')"
  AVAILABLE="$SAVEAVAILABLE"
 fi
 if [ "$NEEDEDK" -ge "$AVAILABLE" -o "$NEEDEDKDOWN" -ge "$SAVEAVAILABLE" ]; then
  export PPM_error='
  <window title="PPM - '$(gettext 'Space needed')'" icon-name="gtk-no" resizable="false">
  <vbox space-expand="true" space-fill="true">
    <frame '$(gettext 'Error')'>
      <hbox homogeneous="true">
        '"`/usr/lib/gtkdialog/xml_pixmap dialog-error.svg popup`"'
      </hbox>
      <hbox border-width="10" homogeneous="true">
        <vbox space-expand="true" space-fill="true">
          <text xalign="0" use-markup="true"><label>"'$(gettext 'Available space on your system is')' '${AVAILABLE}' MB. <b>'${ACTION_MSG}'</b> '$(gettext 'Please delete some files or resize your puppy save area or change package save location, as appropriate.')'"</label></text>
          <vbox scrollable="true" shadow-type="0" height="150" width="350" space-expand="true" space-fill="true">
            <text xalign="0"><label>"'$PACKAGES'"</label></text>
            <text xalign="0"><label>"'$DEPENDENCIES'"</label></text>
          </vbox>
        </vbox>
       </hbox>
    </frame>
    <hbox space-expand="false" space-fill="false">
      <button>
        '"`/usr/lib/gtkdialog/xml_button-icon ok`"'
        <label>" '$(gettext 'Ok')' "</label>
      </button>
    </hbox>
  </vbox>
  </window>'
  gtkdialog --center -p PPM_error
  killall yaf-splash
  if [ ! -f /tmp/petget_proc/install_classic ]; then
   echo "" > /tmp/petget_proc/petget/install_status
   echo 0 > /tmp/petget_proc/petget/install_status_percent
   clean_up
  else
    . /usr/lib/gtkdialog/box_yesno "$(gettext 'Last warning')" "$(eval echo $(gettext '$NEEDEDK of the $AVAILABLE  available MB will be used to install the package\(s\) you selected.'))" "<b>$(gettext 'It is NOT sufficient. Please exit now.')</b>"  "$(gettext 'However, if you are sure about the step-by-step process, take a risk.')" "$(gettext 'Do you want to cancel installation?')"
   if [ "$EXIT" = "yes" ]; then
    echo 0 > /tmp/petget_proc/petget/install_status_percent
    echo "" > /tmp/petget_proc/petget/install_status
    clean_up
   else
    echo "good luck"
   fi
  fi
 fi
}
export -f check_total_size

status_bar_func () {
 while $1 ; do
  TOTALPKGS=$(cat /tmp/petget_proc/pkgs_to_install_bar /tmp/petget_proc/overall_dependencies 2>/dev/null |sort | uniq | wc -l)
  DONEPGKS=$(cat /tmp/petget_proc/overall_package_status_log 2>/dev/null | wc -l)
  PERCENT=$(( $DONEPGKS * 100 / $TOTALPKGS ))
  [ $PERCENT = 100 ] && PERCENT=99
  echo $PERCENT > /tmp/petget_proc/petget/install_status_percent
  sleep 0.7
  [ -f /tmp/petget_proc/ppm_reporting ] && break
 done
}
export -f status_bar_func
 
install_package () {
 #set -x
 [ "$(cat /tmp/petget_proc/pkgs_to_install)" = "" ] && exit 0
 cat /tmp/petget_proc/pkgs_to_install | tr ' ' '\n' > /tmp/petget_proc/pkgs_left_to_install
 rm -f /tmp/petget_proc/overall_package_status_log
 echo 0 > /tmp/petget_proc/petget/install_status_percent
 echo "$(gettext "Calculating total required space...")" > /tmp/petget_proc/petget/install_status
 [ ! -f /root/.packages/skip_space_check ] && check_total_size
 #status_bar_func & #-----------
 while IFS="|" read TREE1 REPO zz #TREE1|REPO
 do
   [ -z "$TREE1" ] && continue
   echo "$REPO" > /tmp/petget_proc/petget/current-repo-triad
   if [ -f /tmp/petget_proc/install_quietly ];then
    if [  "$(grep $TREE1 /root/.packages/user-installed-packages 2>/dev/null)" = "" \
     -a -f /tmp/petget_proc/install_pets_quietly ]; then
     if [ "$(cat /var/local/petget/nt_category 2>/dev/null)" = "true" ]; then
      /usr/local/petget/installpreview.sh
     else
	  rxvt -title "$VTTITLE... $(gettext 'Do NOT close')" \
	  -fn -misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-*-* -bg black \
      -fg grey -geometry 80x5+50+50 -e /usr/local/petget/installpreview.sh
     fi
    else
     if [ "$(cat /var/local/petget/nt_category 2>/dev/null)" = "true" ]; then
      /usr/local/petget/installpreview.sh
     else
	  rxvt -title "$VTTITLE... $(gettext 'Do NOT close')" \
	  -fn -misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-*-* -bg black \
      -fg grey -geometry 80x5+50+50 -e /usr/local/petget/installpreview.sh
     fi
    fi
   else
    /usr/local/petget/installpreview.sh
    if [ $? -eq 100 ] ; then
       exit
    fi
   fi
   /usr/local/petget/finduserinstalledpkgs.sh
   sed -i "/$TREE1/d" /tmp/petget_proc/pkgs_left_to_install
 done < /tmp/petget_proc/pkgs_to_install
 sync
 report_results
 clean_up
}
export -f install_package

recalculate_sizes () {
	if [ "$(grep changed /tmp/petget_proc/mode_changed 2>/dev/null)" != "" ]; then
		rm -f /tmp/petget_proc/overall_*
		while read LINE
		do
			/usr/local/petget/installed_size_preview.sh $LINE ADD
		done < /tmp/petget_proc/pkgs_to_install
	else
		echo "cool!"
	fi
	rm -f /tmp/petget_proc/mode_changed
}
export -f recalculate_sizes

wait_func () {
	. /usr/lib/gtkdialog/box_splash -close never -text "$(gettext 'Please wait, calculating total required space for the installation...')" &
	X1PID=$!
	recalculate_sizes
	while true ; do
		sleep 0.5
		[ "$(ps -eo pid,command | grep installed_size_preview | grep -v grep)" = "" ] && break
	done
	kill -9 $X1PID
}
export -f wait_func

. /etc/rc.d/functions_x
SIZEFREEM=$(fx_personal_storage_free_mb)
export SIZEFREEM

case "$1" in
	check_total_size)
		touch /tmp/petget_proc/install_quietly #avoid splashes
		check_total_size
		;;
	'Auto install')
		wait_func
		rm -f /tmp/petget_proc/install_pets_quietly
		rm -f /tmp/petget_proc/install_classic 2>/dev/null
		rm -f /tmp/petget_proc/download_pets_quietly 2>/dev/null
		rm -f /tmp/petget_proc/download_only_pet_quietly 2>/dev/null
		touch /tmp/petget_proc/install_quietly
		touch /tmp/petget_proc/install_pets_quietly
		cp -a /tmp/petget_proc/pkgs_to_install /tmp/petget_proc/pkgs_to_install_done
		VTTITLE=Installing
		export VTTITLE
		install_package
		unset VTTITLE
		;;
	'Download packages (no install)')
		wait_func
		rm -f /tmp/petget_proc/install_pets_quietly
		rm -f /tmp/petget_proc/install_classic 2>/dev/null
		rm -f /tmp/petget_proc/download_pets_quietly 2>/dev/null
		rm -f /tmp/petget_proc/download_only_pet_quietly 2>/dev/null
		touch /tmp/petget_proc/install_quietly
		touch /tmp/petget_proc/install_pets_quietly
		touch /tmp/petget_proc/download_only_pet_quietly 
		cp -a /tmp/petget_proc/pkgs_to_install /tmp/petget_proc/pkgs_to_install_done
		VTTITLE=Downloading
		export VTTITLE
		install_package
		unset VTTITLE
		;;
	'Step by step installation (classic mode)')
		wait_func
		rm -f /tmp/petget_proc/install{,_pets}_quietly
		rm -f /tmp/petget_proc/download_pets_quietly 2>/dev/null
		rm -f /tmp/petget_proc/download_only_pet_quietly 2>/dev/null
		touch /tmp/petget_proc/install_classic
		cp -a /tmp/petget_proc/pkgs_to_install /tmp/petget_proc/pkgs_to_install_done
		install_package
		;;
esac
