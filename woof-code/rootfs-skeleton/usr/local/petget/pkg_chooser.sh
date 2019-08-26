#!/bin/bash
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (/usr/share/doc/legal/lgpl-2.1.txt).
#The Puppy Package Manager main GUI window.

. /etc/rc.d/functions_x

VERSION=2.1.2

export TEXTDOMAIN=petget___pkg_chooser.sh
export OUTPUT_CHARSET=UTF-8

# Do not allow another instance
wait
if ps --no-headers -C pkg_chooser.sh,ppm | grep -qwv "^ *$$"; then #v2.1.2...
 /usr/lib/gtkdialog/box_splash -timeout 3 -bg red -text "$(gettext 'PPM is already running. Exiting.')"
 exit 0
fi

LANG1="${LANG%_*}" #ex: de
HELPFILE="/usr/local/petget/help.htm"
[ -f /usr/local/petget/help-${LANG1}.htm ] && HELPFILE="/usr/local/petget/help-${LANG1}.htm"

[ "`whoami`" != "root" ] && exec sudo -A ${0} ${@} #110505

# Set the skip-space flag
if [ "$(cat /var/local/petget/sc_category 2>/dev/null)" = "true" ] && \
	[ "$(fx_personal_storage_free_mb)" -gt 4000 ]; then
	touch /root/.packages/skip_space_check
else
	rm -f /root/.packages/skip_space_check
	echo false > /var/local/petget/sc_category
fi

# Make sure the download folder exists and is writable
if [ -f /root/.packages/download_path ]; then
 . /root/.packages/download_path
 [ ! -d "$DL_PATH" -o ! -w "$DL_PATH" ] && rm -f /root/.packages/download_path
fi

options_status () {
	[ -f /root/.packages/skip_space_check ] && \
	 MSG_SPACE="$(gettext 'Do NOT check available space.')
	 $(gettext '')"
	[ -f /root/.packages/download_path ] && [ "$DL_PATH" != "/root" ] && \
	 MSG_DPATH="$(gettext 'Download packages in ')${DL_PATH}.
	 $(gettext '')"
	[ "$(cat /var/local/petget/install_mode 2>/dev/null)" = "true" ] && \
	 MSG_TEMPFS="$(gettext 'Save installed programs when we save to savefile.')
	 $(gettext '')"
	[ "$(cat /var/local/petget/nt_category 2>/dev/null)" = "true" ] && \
	 MSG_NOTERM="$(gettext 'Do NOT show terminal with PPM activity.')
	 $(gettext '')"
	[ "$(cat /var/local/petget/db_verbose 2>/dev/null)" = "false" ] && \
	 MSG_NODBTERM="$(gettext 'No user input during database updating.')
	 $(gettext '')" 
	[ "$(cat /var/local/petget/rd_category 2>/dev/null)" = "true" ] && \
	 MSG_REDOWNL="$(gettext 'Redownload packages when already downloaded.')
	 $(gettext '')"
	[ "$(cat /var/local/petget/nd_category 2>/dev/null)" = "true" ] && \
	 MSG_SAVEPKG="$(gettext 'Do NOT delete packages after installation.')
	 $(gettext '')"
	[ "$MSG_SPACE" -o "$MSG_DPATH" -o "$MSG_TEMPFS" -o "$MSG_NOTERM" -o \
	 "$MSG_REDOWNL" -o "$MSG_SAVEPKG" -o "$MSG_NODBTERM" ] && \
	  . /usr/lib/gtkdialog/box_ok "$(gettext 'PPM config options')" info "$(gettext 'PPM is currently running with these configuration options:')
	 ${MSG_SPACE}${MSG_DPATH}${MSG_NOTERM}${MSG_NODBTERM}${MSG_REDOWNL}${MSG_SAVEPKG}${MSG_TEMPFS}"
}
export -f options_status

[ "$(cat /var/local/petget/si_category 2>/dev/null)" = "true" ] && options_status

. /usr/lib/gtkdialog/box_splash -close never -text "$(gettext 'Loading Puppy Package Manager...')" &
SPID=$!

# Remove in case we crashed
clean_flags () {
	rm -f /tmp/petget_proc/{remove,install}{,_pets}_quietly 2>/dev/null
	rm -f /tmp/petget_proc/install_classic 2>/dev/null
	rm -f /tmp/petget_proc/download{_only,}_pet{,s}_quietly 2>/dev/null
	rm -f /tmp/petget_proc/overall_* 2>/dev/null
	rm -f /tmp/petget_proc/ppm_reporting 2>/dev/null
	rm -f /tmp/petget_proc/force{,d}_install 2>/dev/null
	rm -f /tmp/petget_proc/pkgs_to_install* 2>/dev/null
	rm -f /tmp/petget_proc/pkgs_DL_BAD_LIST 2>/dev/null
	unset SETUPCALLEDFROM
}
export -f clean_flags

clean_flags

mkdir -p /tmp/petget_proc/petget #120504
mkdir -p /var/local/petget
echo -n > /tmp/petget_proc/pkgs_to_install
echo 0 > /tmp/petget_proc/petget/install_status_percent
echo "" > /tmp/petget_proc/petget/install_status
touch /tmp/petget_proc/install_pets_quietly

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS
. /root/.packages/PKGS_MANAGEMENT #has PKG_REPOS_ENABLED, PKG_NAME_ALIASES




               ##################################################
               ##                                              ##
               ##               F U N C T I O N S              ##
               ##                                              ##
               ##################################################


add_item (){
	# Exit if called spuriously
	[ "$TREE1" = "" ] && exit 0
	# Make sure that we have atleast one mode flag
	[ ! -f /tmp/petget_proc/install_pets_quietly -a ! -f  /tmp/petget_proc/download_only_pet_quietly \
	 -a ! -f /tmp/petget_proc/download_pets_quietly -a ! -f /tmp/petget_proc/install_classic ] \
	 && touch /tmp/petget_proc/install_pets_quietly
	if [ "$(grep $TREE1 /root/.packages/user-installed-packages)" != "" -a \
	 -f /tmp/petget_proc/install_pets_quietly ]; then
		. /usr/lib/gtkdialog/box_yesno "$(gettext 'Package is already installed')" "$(gettext 'This package is already installed! ')" "$(gettext 'If you want to re-install it, first remove it and then install it again. To download only or use the step-by-step classic mode, select No and then change the Auto Install to another option.')" "$(gettext 'To Abort the process now select Yes.')"
		if [ "$EXIT" = "yes" ]; then
			exit 0
		else
			echo $TREE1 >> /tmp/petget_proc/forced_install
		fi
	fi
	if [ "$TREE1" ] && [ ! "$(grep -F $TREE1 /tmp/petget_proc/pkgs_to_install)" ]; then
		if [ ! -f /root/.packages/skip_space_check ]; then
			echo 0 > /tmp/petget_proc/petget/install_status_percent
			echo "$(gettext "Calculating...")" > /tmp/petget_proc/petget/install_status
		fi
		NEWPACKAGE="$(grep ^$TREE1 /tmp/petget_proc/petget/filterpkgs.results.post)"
		echo "$NEWPACKAGE" >> /tmp/petget_proc/pkgs_to_install
		add_item2 &
	fi
}

add_item2(){
	while true; do
		sleep 0.3
		[ ! "$(grep installed_size_preview <<< "$(ps -eo pid,command)")" ] && break
	done
	touch /tmp/petget_proc/install_quietly
	/usr/local/petget/installed_size_preview.sh "$NEWPACKAGE" ADD
}

remove_item (){
	if [ "$TREE_INSTALL" ]; then
		if [ ! -f /root/.packages/skip_space_check ]; then
			echo 0 > /tmp/petget_proc/petget/install_status_percent
			echo "$(gettext "Calculating...")" > /tmp/petget_proc/petget/install_status
		fi
		REMVPACKAGE="$(grep "$TREE_INSTALL" /tmp/petget_proc/pkgs_to_install)"
		grep -v "$TREE_INSTALL" /tmp/petget_proc/pkgs_to_install > /tmp/petget_proc/pkgs_to_install2
		mv -f /tmp/petget_proc/pkgs_to_install2 /tmp/petget_proc/pkgs_to_install
		PKGNAME=$(echo $TREE_INSTALL | cut -f 1 -d '|')
		sed -i "/$PKGNAME/d" /tmp/petget_proc/forced_install
		if [ "$(cat /tmp/petget_proc/pkgs_to_install)" = "" ]; then
			rm -f /tmp/petget_proc/overall_*
			echo "" > /tmp/petget_proc/petget/install_status
		else
			remove_item2 &
		fi
	fi
}

remove_item2 (){
	while true; do
		sleep 0.3
		[ ! "$(grep installed_size_preview <<< "$(ps -eo pid,command)")" ] && break
	done
	touch /tmp/petget_proc/install_quietly #avoid splashes
	/usr/local/petget/installed_size_preview.sh "$REMVPACKAGE" RMV
}

change_mode () {
	PREVPKG=$(cat /tmp/petget_proc/pkgs_to_install 2>/dev/null)
	case $INSTALL_MODE in
		'Auto install')
			if [ -f /tmp/petget_proc/install_pets_quietly ]; then echo ok
			elif [ "$PREVPKG" != "" ]; then echo changed >> /tmp/petget_proc/mode_changed ;fi
			rm -f /tmp/petget_proc/*_pet{,s}_quietly
			rm -f /tmp/petget_proc/install_classic
			touch /tmp/petget_proc/install_pets_quietly
		;;
		'Download packages (no install)')
			if [ -f /tmp/petget_proc/download_only_pet_quietly ]; then echo ok
			elif [ "$PREVPKG" != "" ]; then echo changed >> /tmp/petget_proc/mode_changed ;fi
			rm -f /tmp/petget_proc/*_pet{,s}_quietly
			rm -f /tmp/petget_proc/install_classic
			echo "" > /tmp/petget_proc/forced_install
			touch /tmp/petget_proc/download_only_pet_quietly
		;;
		'Download all (packages and dependencies)')
			if [ -f /tmp/petget_proc/download_pets_quietly ]; then echo ok
			elif [ "$PREVPKG" != "" ]; then echo changed >> /tmp/petget_proc/mode_changed ;fi
			rm -f /tmp/petget_proc/*_pet{,s}_quietly
			rm -f /tmp/petget_proc/install_classic
			echo "" > /tmp/petget_proc/forced_install
			touch /tmp/petget_proc/download_pets_quietly
		;;
		'Step by step installation (classic mode)')
			if [ ! -f /tmp/petget_proc/install_pets_quietly -a ! -f /tmp/petget_proc/download_only_pet_quietly] \
			 -a ! -f /tmp/petget_proc/download_pets_quietly ]; then echo ok
			elif [ "$PREVPKG" != "" ]; then echo changed >> /tmp/petget_proc/mode_changed ;fi
			rm -f /tmp/petget_proc/*_pet{,s}_quietly
			echo "" > /tmp/petget_proc/forced_install
			touch /tmp/petget_proc/install_classic
		;;
	esac
}

installed_warning () {
	FORCEDPKGS=$(cat /tmp/petget_proc/forced_install 2>/dev/null)
	. /usr/lib/gtkdialog/box_splash -timeout 10 -bg orange -fontsize large -text "$FORCEDPKGS $(gettext ' packages are already installed! Should be remove from the list. If you want to re-install, uninstall first and then install.')"
}
export -f add_item add_item2 remove_item remove_item2 change_mode installed_warning




               ##################################################
               ##                                              ##
               ##                    M A I N                   ##
               ##                                              ##
               ##################################################


touch /root/.packages/user-installed-packages #120603 missing at first boot.
#101129 choose to display EXE, DEV, DOC, NLS pkgs... note, this code-block is also in findnames.sh and filterpkgs.sh...
DEF_CHK_EXE='true'
DEF_CHK_DEV='false'
DEF_CHK_DOC='false'
DEF_CHK_NLS='false'
[ -e /var/local/petget/postfilter_EXE ] && read DEF_CHK_EXE < /var/local/petget/postfilter_EXE
[ -e /var/local/petget/postfilter_DEV ] && read DEF_CHK_DEV < /var/local/petget/postfilter_DEV
[ -e /var/local/petget/postfilter_DOC ] && read DEF_CHK_DOC < /var/local/petget/postfilter_DOC
[ -e /var/local/petget/postfilter_NLS ] && read DEF_CHK_NLS < /var/local/petget/postfilter_NLS
#120515 the script /usr/local/petget/postfilterpkgs.sh handles checkbox actions, is called from ui_Ziggy and ui_Classic.

#finds all user-installed pkgs and formats ready for display...
/usr/local/petget/finduserinstalledpkgs.sh #writes to /tmp/petget_proc/installedpkgs.results

#130511 need to include devx-only-installed-packages, if loaded...
#note, this code block also in check_deps.sh.
if which gcc;then
 cp -f /root/.packages/woof-installed-packages /tmp/petget_proc/ppm-layers-installed-packages
 cat /root/.packages/devx-only-installed-packages >> /tmp/petget_proc/ppm-layers-installed-packages
 sort -u /tmp/petget_proc/ppm-layers-installed-packages > /root/.packages/layers-installed-packages
else
 cp -f /root/.packages/woof-installed-packages /root/.packages/layers-installed-packages
fi
#120224 handle translated help.htm

#100711 moved from findmissingpkgs.sh... 130511 rename woof-installed-packages to layers-installed-packages...
if [ ! -f /tmp/petget_proc/petget_installed_patterns_system ];then
 INSTALLED_PATTERNS_SYS="`cat /root/.packages/layers-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_SYS" > /tmp/petget_proc/petget_installed_patterns_system
 #PKGS_SPECS_TABLE also has system-installed names, some of them are generic combinations of pkgs...
 . /etc/rc.d/BOOTCONFIG
 if [ "$(echo $EXTRASFSLIST | grep devx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION} )" = "" -a \
   "$(echo $LASTUNIONRECORD | grep devx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION} )" = "" ]; then
  INSTALLED_PATTERNS_GEN="`echo "$PKGS_SPECS_TABLE" | grep '^yes' | grep -v 'exe>dev' | cut -f 2 -d '|' |  sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 else
  INSTALLED_PATTERNS_GEN="`echo "$PKGS_SPECS_TABLE" | grep '^yes' | cut -f 2 -d '|' |  sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 fi
 echo "$INSTALLED_PATTERNS_GEN" >> /tmp/petget_proc/petget_installed_patterns_system
 
 #120822 in precise puppy have a pet 'cups' instead of the ubuntu debs. the latter are various pkgs, including 'libcups2'.
 #we don't want libcups2 showing up as a missing dependency, so have to screen these alternative names out...
 case $DISTRO_BINARY_COMPAT in
  ubuntu|debian|devuan|raspbian)
   #for 'cups' pet, we want to create a pattern '/cups|' so can locate all debs with that DB_path entry '.../cups'
    INSTALLED_PTNS_PET="$(grep '\.pet|' /root/.packages/layers-installed-packages | cut -f 2 -d '|' | sed -e 's%^%/%' -e 's%$%|%' -e 's%\-%\\-%g')"
   if [ "$INSTALLED_PTNS_PET" != "/|" ];then
    echo "$INSTALLED_PTNS_PET" > /tmp/petget_proc/petget/installed_ptns_pet
    INSTALLED_ALT_NAMES="$(grep --no-filename -f /tmp/petget_proc/petget/installed_ptns_pet /root/.packages/Packages-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}-* | cut -f 2 -d '|')"
    if [ "$INSTALLED_ALT_NAMES" ];then
     INSTALLED_ALT_PTNS="$(echo "$INSTALLED_ALT_NAMES" | sed -e 's%^%|%' -e 's%$%|%' -e 's%\-%\\-%g')"
     echo "$INSTALLED_ALT_PTNS" >> /tmp/petget_proc/petget_installed_patterns_system
    fi
   fi
  ;;
 esac
 sort -u /tmp/petget_proc/petget_installed_patterns_system > /tmp/petget_proc/petget_installed_patterns_systemx
 mv -f /tmp/petget_proc/petget_installed_patterns_systemx /tmp/petget_proc/petget_installed_patterns_system
fi
#100711 this code repeated in findmissingpkgs.sh...
cp -f /tmp/petget_proc/petget_installed_patterns_system /tmp/petget_proc/petget_installed_patterns_all
if [ -s /root/.packages/user-installed-packages ];then
 INSTALLED_PATTERNS_USER="`cat /root/.packages/user-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_USER" >> /tmp/petget_proc/petget_installed_patterns_all
 #120822 find alt names in compat-distro pkgs, for user-installed pets...
 case $DISTRO_BINARY_COMPAT in
  ubuntu|debian|devuan|raspbian)
   #120904 bugfix, was very slow...
   MODIF1=`stat -c %Y /root/.packages/user-installed-packages` #seconds since epoch.
   MODIF2=0
   [ -f /var/local/petget/installed_alt_ptns_pet_user ] && MODIF2=`stat -c %Y /var/local/petget/installed_alt_ptns_pet_user`
   if [ $MODIF1 -gt $MODIF2 ];then
    INSTALLED_PTNS_PET="$(grep '\.pet|' /root/.packages/user-installed-packages | cut -f 2 -d '|')"
    if [ "$INSTALLED_PTNS_PET" != "" ];then
     xINSTALLED_PTNS_PET="$(echo "$INSTALLED_PTNS_PET" | sed -e 's%^%/%' -e 's%$%|%' -e 's%\-%\\-%g')"
     echo "$xINSTALLED_PTNS_PET" > /tmp/petget_proc/petget/fmp_xipp1
     INSTALLED_ALT_NAMES="$(grep --no-filename -f /tmp/petget_proc/petget/fmp_xipp1 /root/.packages/Packages-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}-* | cut -f 2 -d '|')"
     if [ "$INSTALLED_ALT_NAMES" ];then
      INSTALLED_ALT_PTNS="$(echo "$INSTALLED_ALT_NAMES" | sed -e 's%^%|%' -e 's%$%|%' -e 's%\-%\\-%g')"
      echo "$INSTALLED_ALT_PTNS" > /var/local/petget/installed_alt_ptns_pet_user
      echo "$INSTALLED_ALT_PTNS" >> /tmp/petget_proc/petget_installed_patterns_all
     fi
    fi
    touch /var/local/petget/installed_alt_ptns_pet_user
   else
    cat /var/local/petget/installed_alt_ptns_pet_user >> /tmp/petget_proc/petget_installed_patterns_all
   fi
  ;;
 esac
fi

#process name aliases into patterns (used in filterpkgs.sh, findmissingpkgs.sh) ... 100126...
xPKG_NAME_ALIASES="`echo "$PKG_NAME_ALIASES" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g'`"
echo "$xPKG_NAME_ALIASES" > /tmp/petget_proc/petget_pkg_name_aliases_patterns_raw #110706
cp -f /tmp/petget_proc/petget_pkg_name_aliases_patterns_raw /tmp/petget_proc/petget_pkg_name_aliases_patterns #110706 _raw see findmissingpkgs.sh.

#100711 above has a problem as it has wildcards. need to expand...
#ex: PKG_NAME_ALIASES has an entry 'cxxlibs,glibc*,libc-*', the above creates '|cxxlibs|,|glibc.*|,|libc\-.*|',
#    after expansion: '|cxxlibs|,|glibc|,|libc-|,|glibc|,|glibc_dev|,|glibc_locales|,|glibc-solibs|,|glibc-zoneinfo|'
echo -n "" > /tmp/petget_proc/petget_pkg_name_aliases_patterns_expanded
for ONEALIASLINE in `cat /tmp/petget_proc/petget_pkg_name_aliases_patterns | tr '\n' ' '` #ex: |cxxlibs|,|glibc.*|,|libc\-.*|
do
 echo -n "" > /tmp/petget_proc/petget_temp1
 for PARTONELINE in `echo -n "$ONEALIASLINE" | tr ',' ' '`
 do
  grep "$PARTONELINE" /tmp/petget_proc/petget_installed_patterns_all >> /tmp/petget_proc/petget_temp1
 done
 ZZZ="`echo "$ONEALIASLINE" | sed -e 's%\.\*%%g' | tr -d '\\'`"
 [ -s /tmp/petget_proc/petget_temp1 ] && ZZZ="${ZZZ},`cat /tmp/petget_proc/petget_temp1 | tr '\n' ',' | tr -s ',' | tr -d '\\'`"
 ZZZ="`echo -n "$ZZZ" | sed -e 's%,$%%'`"
 echo "$ZZZ" >> /tmp/petget_proc/petget_pkg_name_aliases_patterns_expanded
done
cp -f /tmp/petget_proc/petget_pkg_name_aliases_patterns_expanded /tmp/petget_proc/petget_pkg_name_aliases_patterns

#w480 PKG_NAME_IGNORE is definedin PKGS_MANAGEMENT file... 100126...
xPKG_NAME_IGNORE="`echo "$PKG_NAME_IGNORE" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g' -e 's%\-%\\-%g'`"
echo "$xPKG_NAME_IGNORE" > /tmp/petget_proc/petget_pkg_name_ignore_patterns

repocnt=0
COMPAT_REPO=""
COMPAT_DBS=""
echo -n "" > /tmp/petget_proc/petget_active_repo_list

#120831 simplify...
REPOS_RADIO=""
repocnt=0
#sort with -puppy-* repos last...
aPRE="`echo -n "$PKG_REPOS_ENABLED" | tr ' ' '\n' | grep -v '\-puppy\-' | tr -s '\n' | tr '\n' ' '`"
bPRE="`echo -n "$PKG_REPOS_ENABLED" | tr ' ' '\n' | grep '\-puppy\-' | tr -s '\n' | tr '\n' ' '`"
for ONEREPO in $aPRE $bPRE #ex: ' Packages-puppy-precise-official Packages-puppy-noarch-official Packages-ubuntu-precise-main Packages-ubuntu-precise-multiverse '
do
 [ ! -f /root/.packages/$ONEREPO ] && continue
 REPOCUT="`echo -n "$ONEREPO" | cut -f 2-4 -d '-'`"
 [ "$REPOS_RADIO" = "" ] && FIRST_DB="$REPOCUT"
 xREPOCUT="$(echo -n "$REPOCUT" | sed -e 's%\-official$%%')" #120905 window too wide.
 REPOS_RADIO="${REPOS_RADIO}<radiobutton space-expand=\"false\" space-fill=\"false\"><label>${xREPOCUT}</label><action>/tmp/petget_proc/filterversion.sh ${REPOCUT}</action><action>/usr/local/petget/filterpkgs.sh</action><action>refresh:TREE1</action></radiobutton>"
 echo "$REPOCUT" >> /tmp/petget_proc/petget_active_repo_list #120903 needed in findnames.sh
 repocnt=$(( $repocnt + 1 ))
 #[ $repocnt -ge 5 ] && break	# SFR: no limit
done

FILTER_CATEG="Desktop"
#note, cannot initialise radio buttons in gtkdialog...
echo "Desktop" > /tmp/petget_proc/petget_filtercategory #must start with Desktop.
echo "$FIRST_DB" > /tmp/petget_proc/petget/current-repo-triad #ex: slackware-12.2-official

#130330 GUI filtering. see also ui_Classic, ui_Ziggy, filterpkgs.sh ...
GUIONLYSTR="$(gettext 'GUI apps only')"
ANYTYPESTR="$(gettext 'Any type')"
GUIEXCSTR="$(gettext 'GUI, not')" #130331 (look in ui_Classic, ui_Ziggy to see context)
NONGUISTR="$(gettext 'Any non-GUI type')" #130331
export GUIONLYSTR ANYTYPESTR GUIEXCSTR NONGUISTR #used in ui_classic and ui_ziggy
[ ! -f /var/local/petget/gui_filter ] && echo -n "$ANYTYPESTR" > /var/local/petget/gui_filter	# SFR: any type by default

#finds pkgs in repository based on filter category and version and formats ready for display...
/usr/local/petget/filterpkgs.sh $FILTER_CATEG #writes to /tmp/petget_proc/petget/filterpkgs.results

echo '#!/bin/sh
echo $1 > /tmp/petget_proc/petget/current-repo-triad
' > /tmp/petget_proc/filterversion.sh
chmod 777 /tmp/petget_proc/filterversion.sh

#run the traditional ui if set in config
if [ "$(cat /var/local/petget/ui_choice 2>/dev/null)" = "Classic" ]; then
	. /usr/local/petget/ui_Classic
	exit 0
fi

progressbar_info () {
	if [ "$(cat /tmp/petget_proc/overall_dependencies | wc -l)" -ge 1 ];then
		NEEDED_PGKS="$(</tmp/petget_proc/overall_dependencies)"
		# Info window/dialogue (display and option to save "missing" info)
		export NEEDED_DIALOG='
		<window title="'$(gettext 'Package Manager')'" icon-name="gtk-about" default_height="350">
		<vbox space-expand="true" space-fill="true">
		  '"`/usr/lib/gtkdialog/xml_info fixed package_add.svg 60 " " "$(gettext "Dependencies needed")"`"'
		  <hbox space-expand="true" space-fill="true">
		    <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
		      <hbox space-expand="false" space-fill="false">
		        <eventbox name="bg_report" space-expand="true" space-fill="true">
		          <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
		            '"`/usr/lib/gtkdialog/xml_pixmap dialog-info.svg 32`"'
		            <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#15BC15'"'>'$(gettext 'Needed')'</span></b></big> "</label></text>
		          </vbox>
		        </eventbox>
		      </hbox>
		      <vbox scrollable="true" shadow-type="0" hscrollbar-policy="2" vscrollbar-policy="1" space-expand="true" space-fill="true">
		        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<i><b>'${NEEDED_PGKS}' </b></i>"</label></text>
		      </vbox>
		    </hbox>
		  </hbox>

		  <hbox space-expand="false" space-fill="false">
		    <button>
		      <label>'$(gettext 'View details')'</label>
		      '"`/usr/lib/gtkdialog/xml_button-icon document_viewer`"'
		      <action>defaulttextviewer /tmp/petget_proc/overall_dependencies &</action>
		    </button>
		    <button ok></button>
		    '"`/usr/lib/gtkdialog/xml_scalegrip`"'
		  </hbox>
		</vbox>
		</window>'
	RETPARAMS="`gtkdialog --center -p NEEDED_DIALOG`"
	fi
}
export -f progressbar_info

# icon switching
ICONDIR="/tmp/petget_proc/petget/icons"
rm -rf "$ICONDIR"
mkdir -p "$ICONDIR"
cp  /usr/share/pixmaps/puppy/package_remove.svg "$ICONDIR"/false.svg
cp  /usr/share/pixmaps/puppy/close.svg "$ICONDIR"/true.svg
ln -sf "$ICONDIR"/true.svg "$ICONDIR"/tgb0.svg

# check screen size
while read a b c ; do
	case $a in -geometry)
		SCRNXY=${b%%+*} #1366x768
		read SCRN_X SCRN_Y <<< "${SCRNXY//x/ }"
		break
	esac
done <<< "$(LANG=C xwininfo -root)"

UO_1="1000"
UO_2="650"
UO_3="210"
UO_4="210"
UO_5="<vbox space-expand=\"true\" space-fill=\"true\">
          <hbox space-expand=\"true\" space-fill=\"true\" height-request=\"300\">"
UO_6="</vbox>"

WIDTH="$UO_1"
[ "$SCRN_X" -le 1000 ] && WIDTH="$((SCRN_X-5))"

S='<window title="'$(gettext 'Package Manager v')''${VERSION}'" width-request="'${WIDTH}'" icon-name="gtk-about" default_height="440">
<vbox space-expand="true" space-fill="true">
  <vbox space-expand="true" space-fill="true">
    <vbox space-expand="false" space-fill="false">
      <hbox spacing="1" space-expand="true" space-fill="true">
        <button tooltip-text="'$(gettext 'Quit package manager')'" space-expand="false" space-fill="false">
          '"`/usr/lib/gtkdialog/xml_button-icon quit`"'
          <action>exit:EXIT</action>
        </button>
        <button tooltip-text="'$(gettext 'Help')'" space-expand="false" space-fill="false">
          '"`/usr/lib/gtkdialog/xml_button-icon help`"'
          <action>defaulthtmlviewer file://'${HELPFILE}' & </action>
        </button>
        <button tooltip-text="'$(gettext 'Configure package manager')'" space-expand="false" space-fill="false">
          '"`/usr/lib/gtkdialog/xml_button-icon preferences`"'
          <action>/usr/local/petget/configure.sh</action>
          <action>/usr/local/petget/filterpkgs.sh</action>
          <action>refresh:TREE1</action>
        </button>
        <togglebutton tooltip-text="'$(gettext 'Open/Close the Uninstall packages window')'" space-expand="false" space-fill="false">
          <label>" '$(gettext 'Uninstall')' "</label>
          <variable>tgb0</variable>
          <input file>'"$ICONDIR"'/false.svg</input>
          <input file>'"$ICONDIR"'/tgb0.svg</input>
          <height>20</height>
          <action>ln -sf '"$ICONDIR"'/$tgb0.svg '"$ICONDIR"'/tgb0.svg</action>
          <action>refresh:tgb0</action>
          <action>save:tgb0</action>
          <output file>'"$ICONDIR"'/outputfile</output>
          <variable>BUTTON_UNINSTALL</variable>
          <action>if true show:VBOX_REMOVE</action>
          <action>if false hide:VBOX_REMOVE</action>
        </togglebutton>
      
        <entry width-request="250" activates-default="true" is-focus="true" primary-icon-stock="gtk-clear" secondary-icon-stock="gtk-find">
          <variable>ENTRY1</variable>
          <action signal="activate">/usr/local/petget/findnames.sh all</action>
          <action signal="activate">refresh:TREE1</action>
          <action signal="activate">/usr/local/petget/show_installed_version_diffs.sh & </action>
          <action signal="secondary-icon-release">/usr/local/petget/findnames.sh all</action>
          <action signal="secondary-icon-release">refresh:TREE1</action>
          <action signal="secondary-icon-release">/usr/local/petget/show_installed_version_diffs.sh & </action>
          <action signal="primary-icon-release">clear:ENTRY1</action>
        </entry>

        <text space-expand="false" space-fill="false"><label>"   "</label></text>

        <comboboxtext width-request="150" space-expand="false" space-fill="false">
          <variable>INSTALL_MODE</variable>
          <item>Auto install</item>
          <item>Step by step installation (classic mode)</item>
          <item>Download packages (no install)</item>
          <item>Download all (packages and dependencies)</item>
          <action>change_mode</action>
        </comboboxtext>
        <button space-expand="false" space-fill="false">
          <variable>BUTTON_INSTALL</variable>
          '"`/usr/lib/gtkdialog/xml_button-icon package_add`"'
          <label>" '$(gettext 'Do it!')' "</label>
          <sensitive>false</sensitive>
          <action condition="command_is_true(if [ \"$(cat /tmp/petget_proc/pkgs_to_install)\" != \"\" ];then echo true;fi)">disable:VBOX_MAIN</action>
          <action condition="command_is_true(if [ \"$(cat /tmp/petget_proc/pkgs_to_install)\" != \"\" ];then echo true;fi)">disable:DEP_INFO</action>
          <action>if [ "$(cat /tmp/petget_proc/forced_install 2>/dev/null)" != "" ]; then touch /tmp/petget_proc/force_install; else rm -f /tmp/petget_proc/force_install; fi </action>
          <action>cut -d"|" -f1,4 /tmp/petget_proc/pkgs_to_install > /tmp/petget_proc/pkgs_to_install_tmp; mv -f /tmp/petget_proc/pkgs_to_install_tmp /tmp/petget_proc/pkgs_to_install</action>
          <action condition="command_is_true(if [ -f /tmp/petget_proc/force_install -a -f /tmp/petget_proc/install_pets_quietly ]; then echo false; else echo true; fi )">/usr/local/petget/installmodes.sh "$INSTALL_MODE" &</action>
          <action condition="command_is_false(if [ -f /tmp/petget_proc/force_install -a -f /tmp/petget_proc/install_pets_quietly ]; then echo false; else echo true; fi )">installed_warning &</action>
          <action condition="command_is_false(if [ -f /tmp/petget_proc/force_install -a -f /tmp/petget_proc/install_pets_quietly ]; then echo false; else echo true; fi )">enable:VBOX_MAIN</action>
          <action condition="command_is_false(if [ -f /tmp/petget_proc/force_install -a -f /tmp/petget_proc/install_pets_quietly ]; then echo false; else echo true; fi )">enable:DEP_INFO</action>
        </button>
        <text space-expand="true" space-fill="true"><label>""</label></text>
      </hbox>
    </vbox>

    <hbox space-expand="true" space-fill="true">
      <vbox visible="false" space-expand="true" space-fill="true">
        <eventbox name="frame_remove">
          <vbox margin="2" space-expand="true" space-fill="true">
            <notebook name="frame_remove" show-tabs="false" show-border="true">
              <vbox margin="2" space-expand="true" space-fill="true">
                <notebook show-tabs="false" show-border="true">
                  <vbox margin="2" space-expand="true" space-fill="true">
                    <tree rubber-banding="true" selection-mode="3" space-expand="true" space-fill="true">
                      <label>'$(gettext 'Installed Package')'|'$(gettext 'Description')'</label>
                      <variable>TREE2</variable>
                      <width>'${UO_2}'</width><height>100</height>
                      <input file icon-column="1">/tmp/petget_proc/petget/installedpkgs.results.post</input>
                      <action signal="button-release-event" condition="command_is_true([[ `echo $TREE2` ]] && echo true)">enable:BUTTON_UNINSTALL</action>
                    </tree>
                    <comboboxtext space-expand="false" space-fill="false">
                      <variable>REMOVE_MODE</variable>
                      <item>'$(gettext 'Auto remove')'</item>
                      <item>'$(gettext 'Step by step remove (classic mode)')'</item>
                    </comboboxtext>
                    <button space-expand="false" space-fill="false">
                      <variable>BUTTON_UNINSTALL</variable>
                      '"`/usr/lib/gtkdialog/xml_button-icon package_remove`"'
                      <label>" '$(gettext 'Remove package')' "</label>
                      <sensitive>false</sensitive>
                      <action condition="command_is_true([[ \"$TREE2\" != \"\" ]] && echo true)">disable:VBOX_MAIN</action>
                      <action>echo "$TREE2" > /tmp/petget_proc/pkgs_to_remove; /usr/local/petget/removemodes.sh "$REMOVE_MODE" &</action>
                    </button>
                  </vbox>
                </notebook>
              </vbox>
            </notebook>
          </vbox>
        </eventbox>
        <variable>VBOX_REMOVE</variable>
      </vbox>

      <hbox space-expand="false" space-fill="false">
        <vbox space-expand="true" space-fill="true">

          <frame '$(gettext 'Category')'>
           <comboboxtext width-request="150" space-expand="false" space-fill="false">
            <variable>CATEGORY</variable>
             <item>Desktop</item>
             <item>System</item>
             <item>Setup</item>
             <item>Utility</item>
             <item>Filesystem</item>
             <item>Graphic</item>
             <item>Document</item>
             <item>Business</item>
             <item>Personal</item>
             <item>Network</item>
             <item>Internet</item>
             <item>Multimedia</item>
             <item>Fun</item>
             <action>/usr/local/petget/filterpkgs.sh $CATEGORY</action>
             <action>refresh:TREE1</action>
           </comboboxtext>
          </frame>

          <frame '$(gettext 'Repositories')'>
            <vbox scrollable="true" shadow-type="0" hscrollbar-policy="2" space-expand="true" space-fill="true">
              '${REPOS_RADIO}'
              <text height-request="1" space-expand="true" space-fill="true"><label>""</label></text>
              <height>128</height>
              <width>50</width>
            </vbox>
          </frame>
          <vbox space-expand="false" space-fill="false">
            <frame '$(gettext 'package types')'>
              <hbox>
                <vbox>
                  <checkbox>
                    <default>'${DEF_CHK_EXE}'</default>
                    <label>EXE</label>
                    <variable>CHK_EXE</variable>
                    <action>/usr/local/petget/postfilterpkgs.sh EXE $CHK_EXE</action>
                    <action>refresh:TREE1</action>
                  </checkbox>
                  <checkbox>
                    <default>'${DEF_CHK_DEV}'</default>
                    <label>DEV</label>
                    <variable>CHK_DEV</variable>
                    <action>/usr/local/petget/postfilterpkgs.sh DEV $CHK_DEV</action>
                    <action>refresh:TREE1</action>
                  </checkbox>
                  <checkbox>
                    <default>'${DEF_CHK_DOC}'</default>
                    <label>DOC</label>
                    <variable>CHK_DOC</variable>
                    <action>/usr/local/petget/postfilterpkgs.sh DOC $CHK_DOC</action>
                    <action>refresh:TREE1</action>
                  </checkbox>
                  <checkbox>
                    <default>'${DEF_CHK_NLS}'</default>
                    <label>NLS</label>
                    <variable>CHK_NLS</variable>
                    <action>/usr/local/petget/postfilterpkgs.sh NLS $CHK_NLS</action>
                    <action>refresh:TREE1</action>
                  </checkbox>
                </vbox>
                <hbox space-expand="true" space-fill="true">
                  <vbox space-expand="false" space-fill="false">
                    <comboboxtext width-request="120">
                      <variable>FILTERCOMBOBOX</variable>
                      <default>'$(</var/local/petget/gui_filter)'</default>
                      <item>'$ANYTYPESTR'</item>
                      <item>'$GUIONLYSTR'</item>
                      <item>GTK+2 '$GUIONLYSTR'</item>
                      <item>GTK+3 '$GUIONLYSTR'</item>
                      <item>Qt4 '$GUIONLYSTR'</item>
                      <item>Qt4 '$GUIEXCSTR' KDE</item>
                      <item>Qt5 '$GUIONLYSTR'</item>
                      <item>Qt5 '$GUIEXCSTR' KDE</item>
                      <item>'$NONGUISTR'</item>
                      <action>echo -n "$FILTERCOMBOBOX" > /var/local/petget/gui_filter</action>
                      <action>/usr/local/petget/filterpkgs.sh</action>
                      <action>refresh:TREE1</action>
                    </comboboxtext>
                  </vbox>
                </hbox>
              </hbox>
            </frame>
          </vbox>
        </vbox>
      </hbox>

      <vbox space-expand="true" space-fill="true">
        <hbox spacing="1" space-expand="true" space-fill="true">
         '${UO_5}'
            <tree hover-selection="true" selection-mode="1" column-resizeable="true|false" space-expand="true" space-fill="true">
              <label>'$(gettext 'Package')'|'$(gettext 'Description')'</label>
              <variable>TREE1</variable>
              <width>'${UO_3}'</width>
              <input file icon-column="1">/tmp/petget_proc/petget/filterpkgs.results.post</input>
              <action signal="button-release-event">add_item</action>
              <action signal="button-release-event">refresh:TREE_INSTALL</action>
              <action signal="button-release-event">enable:BUTTON_INSTALL</action>
            </tree>
          </hbox>
          <hbox space-expand="true" space-fill="true">
            <tree hover-selection="true" selection-mode="1" file-monitor="true" auto-refresh="true" hscrollbar-policy="1" column-visible="true|false|true" tooltip-text="'$(gettext 'Remove item from list by click on it')'" space-expand="false" space-fill="false">
              <label>'$(gettext 'Packages to install')'|'$(gettext 'Description')'|'$(gettext 'Repository')'</label>
              <variable>TREE_INSTALL</variable>
              <input file icon-column="1">/tmp/petget_proc/pkgs_to_install</input>
              <width>'${UO_4}'</width>
              <action signal="button-release-event">remove_item</action>
              <action signal="button-release-event">refresh:TREE_INSTALL</action>
              <action signal="button-release-event" condition="command_is_true([[ ! `cat /tmp/petget_proc/pkgs_to_install` ]] && echo true)">disable:BUTTON_INSTALL</action>
            </tree>
          </hbox>
          '${UO_6}'
        </hbox>
      </vbox>
    </hbox>
    <variable>VBOX_MAIN</variable>
  </vbox>
  <hbox space-expand="false" space-fill="false">
   <eventbox name="dependency_info" space-expand="true" space-fill="true" tooltip-text="'$(gettext 'Click to get a list of the needed dependencies')'">
    <progressbar height-request="25" space-expand="true" space-fill="true">
      <input>while [ -s /tmp/petget_proc/petget/install_status -a "$(ps aux|grep PPM_GUI|grep gtkdialog|wc -l)" -gt 2 ]; do cat /tmp/petget_proc/petget/install_status_percent; cat /tmp/petget_proc/petget/install_status; sleep 1; done</input>
      <action>enable:VBOX_MAIN</action>
      <action>enable:DEP_INFO</action>
      <action>disable:BUTTON_INSTALL</action>
      <action>echo -n > /tmp/petget_proc/pkgs_to_install</action>
      <action>refresh:TREE_INSTALL</action>
      <action>/usr/local/petget/filterpkgs.sh</action>
      <action>refresh:TREE1</action>
      <action>/usr/local/petget/finduserinstalledpkgs.sh</action>
      <action>refresh:TREE2</action>
      <action>echo 0 > /tmp/petget_proc/petget/install_status_percent</action>
      <action>echo "" > /tmp/petget_proc/petget/install_status</action>
    </progressbar>
    '"`/usr/lib/gtkdialog/xml_scalegrip`"'
    <action signal="button-release-event">progressbar_info</action>
   </eventbox>
   '"`/usr/lib/gtkdialog/xml_scalegrip`"'
   <variable>DEP_INFO</variable>
  </hbox>
</vbox>
<action signal="show">kill -9 '$SPID'</action>
<action signal="delete-event">echo -n > /tmp/petget_proc/pkgs_to_install</action>
<action signal="delete-event">rm /tmp/petget_proc/petget/install_status</action>
</window>'
export PPM_GUI="$S"

mkdir -p /tmp/petget_proc/petget
echo 'style "bg_report" {
	bg[NORMAL]="#222" }
widget "*bg_report" style "bg_report"

style "frame_remove" {
	bg[NORMAL]="#222" }
widget "*frame_remove" style "frame_remove"

style "icon-style" {
	GtkStatusbar::shadow_type = GTK_SHADOW_NONE
}
class "GtkWidget" style "icon-style"' > /tmp/petget_proc/petget/gtkrc_ppm

export GTK2_RC_FILES=/root/.gtkrc-2.0:/tmp/petget_proc/petget/gtkrc_ppm
. /usr/lib/gtkdialog/xml_info gtk #build bg_pixmap for gtk-theme

gtkdialog -p PPM_GUI

#and clean up
clean_flags
