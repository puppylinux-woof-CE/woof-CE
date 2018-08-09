# This function library is a descendant of the Wifi Access Gadget
# created by Keenerd. It went to several modifications to finally 
# be fully integrated into the ethernet/network wizard.
#v430 tempestuous: update for 2.6.30.5 kernel.

# History of wag-profiles
# Dougal: port to gtkdialog3 and add icons
# Update: Jul. 4th 2007: rearrange the main window, add disabling of WPA button
# Update: Jul. 13th: add usage of wlanctl for prism2_usb module
# Update: Jul. 17th: fix broken pipe when running /tmp/wireless-config
# Update: Jul. 29th: split iwconfig commands into multiple lines, add security option
# Update: Jul. 31th: add security and scanning for prism2_usb
# Update: Aug.  1st: add usage of the scanned cell mode -- used to be ignored
# Update: Aug. 17th: fixed problem with "<hidden>" essid in WPA and made some improvements
# 	to parsing scan results
# Update: Aug. 21st: add WPA2 code
# Update: Aug. 23rd: fixed missing WPA2 instance
# Update: Oct.  2nd: from Craig: add r8180|r8187 + support all prism2 modules
# Update: Dec.  2nd: change minimum passphrase length to 8 chars
# Update: Jan. 2nd 2008: comment out wpa_cli reconfigure as pointed out by Pizza
# Update: Mar.  7th: squash dialog a bit, for 7" screens
# Update: Mar. 15th: fix "grep -A 10" to "-A 11"
# Update: Jun. 25th: add new wireless drivers to case structure
# Update: Jun. 29th: improve getCellParameters, so we get ALL info for the cell
# Update: Jul.  6th: add escaping of funny chars when generating PSK
# 					 add new function: validateWpaAuthentication
#  					 add new function: cleanUpInterface
# Update: Jul.  8th: add increasing rate for ath5k
# Update: Jul. 15th: convert to new config setup, add assignProfileData, runPrismScan
# Update: Jul. 20th: change "Supp." and "Hidden" to "Broadcast SSID" and "Hidden SSID"
# Update: Jul. 21st: fix loadProfileData -- filename got truncated
# Update: Jul. 22nd: fix loadProfileData again: use grep -l 
#					 add wlan_tkip loading for ath_pci
# Update: Jul. 23rd: fix the code for returning an error from interface config
# Update: Jul. 24th: improve profiles dialog, move "scan" button to top
# Update: Jul. 25th: add some failsafes for saving bad profiles, to fix crashes
# Update: Jul. 28th: remove the code returning "failure" in case of a failed command
# Update: Jul. 30th: change redirection to DEBUG_OUTPUT to _append_
# Update: Aug.  1st: move configuration files into /etc/network-wizard
# Update: Aug. 15th: add Mode:Master to getCellParameters
#					 add CELL_ENC_TYPE, so scan dialog shows actuall type
# Update: Aug. 16th: add support for Extra:rsn_ie (=WPA2) in scan window
# Update: Aug. 18th: add iwconfig commands to cleanUpInterface
# Update: Aug. 20th: fix bug with two IE: lines for same cell
# Update: Aug. 23rd: use "wpa_cli terminate" to properly kill wpa_supplicant
#					 create killDhcpcd and use in cleanUpInterface
# 	in setupScannedProfile, default to WPA_AP_SCAN="1" if SSID exists
# Update: Aug. 25th: add ndiswrapper to modules allowed to use WPA
#					 add option to reset pcmcia card if scan fails
# Update: Sep. 12th: if scan finds no networks, try again before giving dialog
#					 create create*Dialog functions to build dialogs with gtkdialog
# Update: Sep. 13th: comment out CELL_ENC_TYPE code: "IE:" isn't reliable 
#					 update ath5k rate increase to use "ath5k*"
# Update: Sep. 15th: add to cleanUpInterface setting mode to managed (suggested by Nym1)
# Update: Sep. 16th: add clean_up_gtkdialog and rename dialog variables
#					 add giveNoNetworkDialog, so user knows profile isn't saved
#					 replace all `` subshells with $()
# Update: Sep. 17th: add "retry" option to buildPrismScanWindow...
# Update: Sep. 18th: add cleanUpInterface before wireless scans...
# Update: Sep. 21st: validateWpaAuthentication, double max time to 30 (old code had 60!)
#					 replace gxmessage and Xdialog --progress with gtkdialog
# Update: Sep. 22nd: add fancy new wpa_supplicant progressbar
# Update: Sep. 23rd: in killDhcpcd, replace dhcpcd -k with manual kill
# Update: Sep. 24th: add improved wpa fail dialog and killing of wpa_supplicant on failure!
#					 add to useWpaSupplicant "wizard" parameter, for running from rc.network
#					 in killDhcpcd, kill from .pid files and make /var/lib/dhcpcd checked first
#					 move setupDHCP over from net-setup.sh and add new progressbar
# Update: Sep. 28th: add suggestions to createNoNetworksDialog
#					 create giveErrorDialog, so can reuse code
# Update: Sep. 30th: setupDHCP: add echoing of all dhcpcd output to $DEBUG_OUTPUT
#					 remove NWID from advanced fields: it's pre 802.11...
#					 add ERROR to interface raising in cleanUpInterface
# Update: Oct.  1st: add disabling of irrelevant encryption buttons when profile loaded
# Update: Oct. 10th: add more WPA supporting modules from tempestuous+ alphabetize wext mods
#					 fix bug when WPA passphrase has spaces in it (quote inner subshell)
#					 move wpa psk code into function (getWpaPSK)
#					 create wpa_supplicant config file when profile saved (saveWpaProfile)
#					 cancel the wpa_cli code in useWpaSupplicant (since done already with sed)
# Update: Oct. 13th: make ap_scan default to 2 for ndiswrapper (even with broadcast ssid)
# Update: Oct. 16th: disabling quoting of 64-char psk in wpa_supplicant config files
# Update: Oct. 27th: add rt28[67]0* to WPA whitelist
# Update: Oct. 29th: localize
# Update: Oct. 31st: comment out the route table flushing in cleanUpInterface
# Update: Nov.  7th: move rtl818[07] to the list of "wext" using modules.
# Update: Dec.  7th: Remove the escaping of chars when running wpa_passphrase
# Update: Feb. 8th 2009: Handle funny chars in key: escape gtkdialog output and config variable
# Update: Feb. 10th: remove bashisms
# Update: Mar.  2nd: in saveWpaProfile, change sed commands to start with \W (not tab)
# Update: Mar.  3rd: in the wpa_passphrase subshell, add 'grep -v', due to [^#] not working...
# Update: Mar.  6th: in setupDHCP, if not running from X, add flag to stop dhcpcdProgress
# Update: Mar. 15th: add iwl5100 and iwlagn to WPA-supporting mmodules (I assume they do...)
# Update: Mar. 19th: move to using tmp files for wireless scans, add Get_Cell_Parameters
#					 update giveNoWPADialog to offer the user to add module to list
# Update: Mar. 26th: add 5 second sleep between wireless scans for pcmcia cards
# Update: Mar. 29th: move 5 second sleep to before scanning at all, in waitForPCMCIA
#					 add running "iwconfig "$INTERFACE" key on" before setting key
# Update: Mar. 30th: in assembleProfileData, quote the key when echoing to sed!
# Update: Apr.  1st: in buildProfilesWindow, quote the default title, ssid and key
#					 change pcmcia sleep detection to module name being *_cs...
# Update: Apr.  2nd: add checkIsPCMCIA, 
#					 move interface cleanup out if buildScanWindow, add ifconfig down/up
# Update: Apr.  4th: fix checkIsPCMCIA
# 25feb10: shinobar and minomushi: wait if setting essid failed
# 7mar10:  avoid dhcpcd error writing in /var/lib/dhcpcd, typo L_TITLE_Puppy_Network_Wizard at line 1355
#121117 rerwin: add dropwait option to dhcpcd startup; correct "abort" button action for pid; correct dhcpcd error test.
#131225 shinobar: retry with WPA/AES
#150606 revert dropwait mod (121117, obsolete).
#170504 correct clean_up_gtkdialog PID extraction 
#170509 rerwin: replace gtkdialog3 with gtkdialog.
#170622 display networks in order of signal quality (except prism2); remove cell number from display.

#
# Paul Siu
# Ver 1.1 Jun 09, 2007
#  Added support for ralink wireless network adapters.
#
# Rarsa
# Ver 1.0 Oct 23, 2006
#  Reorganized code
#  Integrated into net-setup (the Puppy Ethernet/Network wizard)

# History of Wifi Access Gadget
# Keenerd
# ver 0.4.0
#  under development
#  new ping dialog
#  profile generator
#  new interface
#  replace xmessage dialogs
#  automatic dhcpcd handling
# ver 0.3.2
#  10+ cells
#  socket-test in main program
#  improved pupget registration
#  improved ifconfig use
#  improved ad-hoc support
#  waiting dialog
#  slightly prettier xmessage
# ver 0.3.1
#  improved 1.0.5 compatability
#  bug fixes
# ver 0.3.0
#  profiles
#  help interface
#  install to /usr
# ver 0.2.6
#  additional scan error handling
#  additional dhcpcd error handling
#  smarter buttons
#  PCMCIA optional
#  rewrote everything (bug hunt/verbose code)
#  new debug script
# ver 0.2.5
#  essid with spaces
#  external wag-conf
#  no overwrite of user files on reinstall
#  better socket testing
# ver 0.2.4
#  autodetect adapter from /proc/net/wireless
#  ping moved to seperate button
#  got rid of silly disk writes
#  added socket testing
# ver 0.2.3
#  usability improvements in documentation and installer
# ver 0.2.2
#  reports open networks
#  refresh in Scan dialog
#  dotpupped
# ver 0.2.1
#  scan bug fixed
#  partial support of Wifi-Beta
#  intelligent buttons
# ver 0.2.0
#  interactive scanning
#  public release
# ver 0.1.0
#  interactive command buttons
# ver 0.0.0
#  basic diagnostic listing

## Dougal: dirs where config files go
# network profiles, like the blocks in /etc/WAG/profile-conf used to be
# named ${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf
PROFILES_DIR='/etc/network-wizard/wireless/profiles'
[ -d $PROFILES_DIR ] || mkdir -p $PROFILES_DIR
# wpa_supplicant.conf files
# named ${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf
WPA_SUPP_DIR='/etc/network-wizard/wireless/wpa_profiles'
[ -d $WPA_SUPP_DIR ] || mkdir -p $WPA_SUPP_DIR
# configuration data for wireless interfaces (like if they support wpa)
# named $HWADDRESS.conf (assuming the HWaddress is more unique than interface name...)
# mainly intended to know if interface has been "configured"...
WLAN_INTERFACES_DIR='/etc/network-wizard/wireless/interfaces'
[ -d $WLAN_INTERFACES_DIR ] || mkdir -p $WLAN_INTERFACES_DIR

# a file where WPA-supporting modules not included in the default list can be added
Extra_WPA_Modules_File='/etc/network-wizard/wpa_modules'

## Dougal: put this into a variable
BLANK_IMAGE=/usr/share/pixmaps/net-setup_btnsize.png

#=============================================================================
setupDHCP()
{
	# 7mar10:  avoid dhcpcd error writing in /var/lib/dhcpcd
	mkdir -p /var/lib/dhcpcd && touch /var/lib/dhcpcd
	# max time we will wait for (used in dhcpcdProgress and used to decide I_INC)
	local MAX_TIME='30'
	# by how much we multiply the time to get percentage (3 for 30 seconds max time)
	local I_MULTIPLY='3'
	if [ "$HAVEX" = "yes" ]; then
		# Create a temporary fifo to pass messages to progressbar (can't just pipe to it)
		local PROGRESS_OUTPUT=/tmp/progress-fifo$$
		mkfifo $PROGRESS_OUTPUT
		export Dhcpcd_Progress_Dialog="<window title=\"$L_TITLE_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
<vbox>
  <text><label>\"$(eval echo $L_TEXT_Dhcpcd_Progress)\"</label></text>
  <frame $L_FRAME_Progress>
      <progressbar>
      <label>Connecting</label>
      <input>while read bla ; do case \$bla in [0-9]*) ;; *) echo \"\$bla\" >>$DEBUG_OUTPUT ;; esac ; case \$bla in Debug*) continue ;; esac ; echo \"\$bla\" ; done</input>
      <action type=\"exit\">Ready</action>
    </progressbar>
  </frame>
  <hbox>
   <button>
     <label>$L_BUTTON_Abort</label>
     <input file stock=\"gtk-stop\"></input>
     <action>kill \$(ps ax | grep \"dhcpcd -d -I  \" | grep -v \"grep\" | grep -w \"$INTERFACE\" | awk '{print \$1}')</action>
     <action>EXIT:Abort</action>
   </button>
  </hbox>
 </vbox>
</window>" #121117 fix Abort action
		gtkdialog --program=Dhcpcd_Progress_Dialog <$PROGRESS_OUTPUT >/dev/null &
		local XPID=$!
	else
		local PROGRESS_OUTPUT=$DEBUG_OUTPUT
		# we need some marker to let the progress function know we're done
		local TmpMarker=/tmp/setupDHCP.$(date +%N)
	fi
	# Run everything in a subshell, so _all_ the echoes go into gtkdialog
	# (we can't just use a pipe, since it will be attached to only one process)
	(
		# A function that does the incrementing of the progressbar
		# (It could have just been a loop, but the code is clearer this way...)
		# $1 - XPID, so we know if the user aborted
		dhcpcdProgress(){
			for i in $(seq 1 $MAX_TIME)
			do
				sleep 1
				# see if user aborted 
				if [ "$HAVEX" = "yes" ]; then
					pidof gtkdialog 2>&1 |grep -q "$1" || return
					# exit the function
				else
					if [ -f "$TmpMarker" ] ; then
						rm "$TmpMarker"
						return
					fi
				fi
				#  i*3 will only get us up to 90% at 30 sec, but still... this
				#+ could be tweaked and obviously needs to be adjusted to the max time 
				echo $((i*$I_MULTIPLY))
			done
		}

		# Run the function that echoes the numbers that increment the progressbar
		dhcpcdProgress "$XPID" & 
		
		# Run dhcpcd. The output goes to the text in the progressbar...
		DHCPCDLOG="$(dhcpcd -d -I '' "$INTERFACE" 2>&1)"
		HAS_ERROR=$?
		echo "$DHCPCDLOG" | tee /tmp/dhcpcd.log
		echo "$DHCPCDLOG" | grep -q 'Error' && HAS_ERROR=1 #121117
		# we're in a subshell, so variables set here will not be seen outside...
		echo "$HAS_ERROR" > /tmp/net-setup_HAS_ERROR.txt
		# close progressbar
		if [ "$HAVEX" = "yes" ] ; then
			pidof gtkdialog 2>&1 | grep -q "$XPID" && echo "100"
		else
			touch "$TmpMarker"
		fi
	# close subshell
	) 2>&1 >> $PROGRESS_OUTPUT
	

	read HAS_ERROR < /tmp/net-setup_HAS_ERROR.txt
	rm /tmp/net-setup_HAS_ERROR.txt
	
	## Clean up:
	if [ -n "$XPID" ] ;then
		kill $XPID >/dev/null 2>&1
		# any rogue gtkdialog processes
		clean_up_gtkdialog Dhcpcd_Progress_Dialog
	fi
	if [ "$HAVEX" = "yes" ]; then # it's a pipe
		rm $PROGRESS_OUTPUT
	fi
	if [ $HAS_ERROR -eq 0 ]
	then
    	# Dougal: not sure about this -- maybe add something? need to know we've used it
		MODECOMMANDS=""
	else
		MODECOMMANDS=""
		# need to kill dhcpcd, since it keeps running even with an error!
		killDhcpcd "$INTERFACE"
	fi

	return $HAS_ERROR
} #end of setupDHCP

#=============================================================================
showProfilesWindow()
{
	INTERFACE="$1"
	# Dougal: find driver and set WPA driver from it
	INTMODULE=$(readlink /sys/class/net/$INTERFACE/device/driver)
    INTMODULE=${INTMODULE##*/}
	case "$INTMODULE" in 
	 #hostap*) CARD_WPA_DRV="hostap" ;; removed Oct 2011
	 #rt61|rt73) CARD_WPA_DRV="ralink" ;; removed Oct 2011
	 #r8180|r8187) CARD_WPA_DRV="ipw" ;; removed Oct 2011
	 # Dougal: all lines below are "wext" (split and alphabetized for readability)
	 r8180|rtl819*|vt665*) CARD_WPA_DRV="wext" ;;#v511
	 ath_pci) modprobe wlan_tkip ; CARD_WPA_DRV="wext" ;;
	 ath5k*|ath9k*|b43|b43legacy|bcm43xx) CARD_WPA_DRV="wext" ;;
	 ipw2100|ipw2200|ipw3945|iwl3945|iwl4965|iwl5100|iwlagn) CARD_WPA_DRV="wext" ;;
	 ndiswrapper|p54pci|p54usb|rndis_wlan) CARD_WPA_DRV="wext" ;;
	 rt61pci|rt73usb|rt2400pci|rt2500*|rt28[67]0*|rtl8180|rtl8187) CARD_WPA_DRV="wext" ;;
	 zd1211|zd1211b|zd1211rw) CARD_WPA_DRV="wext" ;;
	 ar9170usb|at76c50x-usb|libertas_cs|libertas_sdio|libertas_tf_usb|mwl8k|usb8xxx) CARD_WPA_DRV="wext" ;; #v430
	 usb|brcm*|hostap*) CARD_WPA_DRV="wext" ;; #Sep 2011, Oct 2011
	 ar55*) CARD_WPA_DRV="wext" ;; #tempestuous April 2011
	 *) # doesn't support WPA encryption
	   # add an option to add modules to file
	   if [ -f "$Extra_WPA_Modules_File" ] &&\
	        CARD_WPA_DRV=$(grep -m1 "^$INTMODULE:" $Extra_WPA_Modules_File) ; then
	     CARD_WPA_DRV=${CARD_WPA_DRV#*:}
	   else
         CARD_WPA_DRV="" 
		 giveNoWPADialog
	   fi
	   ;;
	esac
	
	# Dougal: add usage of wlan-ng, for prism2_usb module
	case "$INTMODULE" in prism2_*) USE_WLAN_NG="yes" ;; esac
	
	refreshProfilesWindowInfo
	setupNewProfile
	EXIT=""
	while true
	do

		buildProfilesWindow

		I=$IFS; IFS=""
		## Add escaping of funny chars before we eval the statement!
		for STATEMENT in  $(gtkdialog --program NETWIZ_Profiles_Window | sed 's%\$%\\$%g ; s%`%\\`%g ; s%"%\\"%g ; s%=\\"%="%g ; s%\\"$%"%g' ); do
			eval $STATEMENT
		done
		IFS=$I
		clean_up_gtkdialog NETWIZ_Profiles_Window
		unset NETWIZ_Profiles_Window

		case "$EXIT" in
			"abort" | "19" ) # Back or close window
				break
				;; # Do Nothing, It will exit the while loop
			"11" ) # Scan
				showScanWindow
				;; 
			"12" ) # New profile
				setupNewProfile
				;;
			"20" ) # Save
				assembleProfileData
				saveProfiles
				refreshProfilesWindowInfo
				loadProfileData "${CURRENT_PROFILE}"
				;;
			"21" ) # Delete
				deleteProfile
				NEW_PROFILE_DATA=""
				#saveProfiles
				refreshProfilesWindowInfo
				setupNewProfile
				;;
			"22" ) # Use This Profile
				  if useProfile ; then
				  	return 0
				  else # Dougal: add new message to say it failed
				  	return 2
				  fi
				;;
			"40" ) # Advanced fields
				if [ "$ADVANCED" ] ; then
					unset -v ADVANCED
				else
					ADVANCED=1
				fi
				;;
			##  Dougal: comment out all the button shading below, so they
			##+ only get shaded when loading a profile! 
			"50" ) # No encryption
				PROFILE_ENCRYPTION="Open"
				#ENABLE_WEP_BUTTON='false'
				#ENABLE_WPA_BUTTON='false'
				#ENABLE_WPA2_BUTTON='false'
				#ENABLE_OPEN_BUTTON='true'
				;;
			"51" ) # WEP
				PROFILE_ENCRYPTION="WEP"
				#ENABLE_WEP_BUTTON='true'
				#ENABLE_WPA_BUTTON='false'
				#ENABLE_WPA2_BUTTON='false'
				#ENABLE_OPEN_BUTTON='false'
				;;
			"52" ) # WPA
				PROFILE_ENCRYPTION="WPA"
				PROFILE_WPA_TYPE=""
				#ENABLE_WEP_BUTTON='false'
				#ENABLE_WPA_BUTTON='true'
				#ENABLE_WPA2_BUTTON='false'
				#ENABLE_OPEN_BUTTON='false'
				;;
			"53" ) # WPA2
				PROFILE_ENCRYPTION="WPA2"
				PROFILE_WPA_TYPE="2"
				#ENABLE_WEP_BUTTON='false'
				#ENABLE_WPA_BUTTON='false'
				#ENABLE_WPA2_BUTTON='true'
				#ENABLE_OPEN_BUTTON='false'
				;;
			load) # If it wasn't any other button, it must be a profile button
				PROFILE_TITLES="$( echo "$PROFILE_TITLES" | grep -v \"#NEW#\" )"
				CURRENT_PROFILE="$PROFILE_COMBO"
				loadProfileData "$CURRENT_PROFILE"
				
				;;
		esac

	done

	return 1

} # end showProfilesWindow

giveNoWPADialog(){
	export NETWIZ_No_WPA_Dialog="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-dialog-info\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\">
    <input file stock=\"gtk-dialog-info\"></input>
  </pixmap>
  <text use-markup=\"true\">
    <label>\"${L_TEXT_No_Wpa_p1}<b>${INTMODULE}</b>${L_TEXT_No_Wpa_p2}\"</label>
  </text>
  <text use-markup=\"true\">
    <label>\"${L_TEXT_No_Wpa_Ask}\"</label>
  </text>
  <hbox>
	<button>
	  <label>$L_BUTTON_No</label>
	  <input file stock=\"gtk-no\"></input>
	  <action>EXIT:cancel</action>
	</button>
	<button>
	  <label>$L_BUTTON_Add_WPA</label>
	  <action>EXIT:10</action>
	</button>
  </hbox>
 </vbox>
</window>"

	for ONE in $( gtkdialog --program=NETWIZ_No_WPA_Dialog )
	do eval $ONE
	done
	clean_up_gtkdialog NETWIZ_No_WPA_Dialog
	unset NETWIZ_No_WPA_Dialog
	[ "$EXIT" = "10" ] || return
	# give dialog with details we're going to add
	export NETWIZ_WPA_Details_Dialog="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-info\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"5\">
    <input file stock=\"gtk-info\"></input>
  </pixmap>
  <text>
    <label>${L_TEXT_Wpa_Add_p1}${Extra_WPA_Modules_File}${L_TEXT_Wpa_Add_p2}</label>
  </text>
  <hbox>
    <text><label>${L_ENTRY_Wpa_Add_Module}</label></text>
    <entry editable=\"false\">
	  <default>$INTMODULE</default>
      <variable>ENTRY1</variable>
    </entry>
  </hbox>
  <hbox>
    <text><label>${L_ENTRY_Wpa_Add_WEXT}</label></text>
    <entry>
	  <default>wext</default>
      <variable>ENTRY2</variable>
    </entry>
  </hbox>
  <hbox>
   <button ok></button>
   <button cancel></button>
  </hbox>
 </vbox>
</window>"

	for ONE in $( gtkdialog --program=NETWIZ_WPA_Details_Dialog )
	do eval $ONE
	done
	clean_up_gtkdialog NETWIZ_WPA_Details_Dialog
	unset NETWIZ_WPA_Details_Dialog
	[ "$EXIT" = "OK" ] || return
	# add the details
	[ -z "$ENTRY2" ] && ENTRY2=wext
	echo "$ENTRY1:$ENTRY2" >> $Extra_WPA_Modules_File
	CARD_WPA_DRV="$ENTRY2"
}

#=============================================================================
refreshProfilesWindowInfo()
{
	PROFILE_TITLES=$(grep -F 'TITLE=' ${PROFILES_DIR}/*.conf | cut -d= -f2 | tr -d '"' | tr " " "_" )
} # end refreshProfilesWindowInfo

#=============================================================================
buildProfilesWindow()
{
	DEFAULT_TITLE=""
	DEFAULT_ESSID=""
	DEFAULT_KEY=""
	DEFAULT_NWID=""
	DEFAULT_FREQ=""
	DEFAULT_CHANNEL=""
	DEFAULT_AP_MAC=""

	if [ "$PROFILE_MODE" = "ad-hoc" ] ; then
		PROFILE_MODE_M="false"
		PROFILE_MODE_A="true"
		DEFAULT_MODE_M="<default>${PROFILE_MODE_M}</default><visible>disabled</visible>"
		DEFAULT_MODE_A="<default>${PROFILE_MODE_A}</default>"
	else
		PROFILE_MODE_M="true"
		PROFILE_MODE_A="false"
		DEFAULT_MODE_M="<default>${PROFILE_MODE_M}</default>"
		DEFAULT_MODE_A="<default>${PROFILE_MODE_A}</default><visible>disabled</visible>"
	fi
    
    ## Dougal: add security option for iwconfig/wlanctl-ng
    if [ "$PROFILE_SECURE" = "open" ] ; then
		PROFILE_SECURE_R="false"
		PROFILE_SECURE_O="true"
		DEFAULT_SECURE_R="<default>${PROFILE_SECURE_R}</default><visible>disabled</visible>"
		DEFAULT_SECURE_O="<default>${PROFILE_SECURE_O}</default>"
	else
		PROFILE_SECURE_R="true"
		PROFILE_SECURE_O="false"
		DEFAULT_SECURE_R="<default>${PROFILE_SECURE_R}</default>"
		DEFAULT_SECURE_O="<default>${PROFILE_SECURE_O}</default><visible>disabled</visible>"
	fi
	if [ "$PROFILE_WPA_AP_SCAN" = "1" ] ; then # WPA Supplicant 
		PROFILE_WPA_AP_SCAN_S="true"
		PROFILE_WPA_AP_SCAN_D="false"
		PROFILE_WPA_AP_SCAN_H="false"
		DEFAULT_WPA_AP_SCAN_S="<default>${PROFILE_WPA_AP_SCAN_S}</default>"
		DEFAULT_WPA_AP_SCAN_D="<default>${PROFILE_WPA_AP_SCAN_D}</default><visible>disabled</visible>"
		DEFAULT_WPA_AP_SCAN_H="<default>${PROFILE_WPA_AP_SCAN_H}</default><visible>disabled</visible>"
	elif [ "$PROFILE_WPA_AP_SCAN" = "0" ] ; then # Driver
		PROFILE_WPA_AP_SCAN_S="false"
		PROFILE_WPA_AP_SCAN_D="true"
		PROFILE_WPA_AP_SCAN_H="false"
		DEFAULT_WPA_AP_SCAN_S="<default>${PROFILE_WPA_AP_SCAN_S}</default><visible>disabled</visible>"
		DEFAULT_WPA_AP_SCAN_D="<default>${PROFILE_WPA_AP_SCAN_D}</default>"
		DEFAULT_WPA_AP_SCAN_H="<default>${PROFILE_WPA_AP_SCAN_H}</default><visible>disabled</visible>"
	else # Hidden SSID
		PROFILE_WPA_AP_SCAN_S="false"
		PROFILE_WPA_AP_SCAN_D="false"
		PROFILE_WPA_AP_SCAN_H="true"
		DEFAULT_WPA_AP_SCAN_S="<default>${PROFILE_WPA_AP_SCAN_S}</default><visible>disabled</visible>"
		DEFAULT_WPA_AP_SCAN_D="<default>${PROFILE_WPA_AP_SCAN_D}</default><visible>disabled</visible>"
		DEFAULT_WPA_AP_SCAN_H="<default>${PROFILE_WPA_AP_SCAN_H}</default>"
	fi

	[ "$PROFILE_TITLE" ] && DEFAULT_TITLE="<default>\"${PROFILE_TITLE}\"</default>"
	[ "$PROFILE_ESSID" ] && DEFAULT_ESSID="<default>\"${PROFILE_ESSID}\"</default>"
	[ "$PROFILE_KEY" ] && DEFAULT_KEY="<default>\"${PROFILE_KEY}\"</default>"
	[ "$PROFILE_FREQ" ] && DEFAULT_FREQ="<default>${PROFILE_FREQ}</default>"
	[ "$PROFILE_CHANNEL" ] && DEFAULT_CHANNEL="<default>${PROFILE_CHANNEL}</default>"
	[ "$PROFILE_AP_MAC" ] && DEFAULT_AP_MAC="<default>${PROFILE_AP_MAC}</default>"

	buildProfilesWindowButtons
	
	setAdvancedFields
	
	case "$PROFILE_ENCRYPTION" in
		WEP)
			setWepFields
			;; 
		WPA)
			setWpaFields
			;; 
		WPA2)
			setWpaFields
			;; 
		* ) 
			setNoEncryptionFields
			;; 
	esac
		
	export NETWIZ_Profiles_Window="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
<vbox>
	<hbox>
		<text use-markup=\"true\"><label>\"$L_TEXT_Profiles_Window\"</label></text>
		<button>
			<label>$L_BUTTON_Scan</label>
			<input file stock=\"gtk-zoom-100\"></input>
			<action>EXIT:11</action>
		</button>
	</hbox>	
	<frame  $L_FRAME_Load_Existing_Profile >
		<hbox>
			<text>
				<label>\"$L_TEXT_Select_Profile\"</label>
			</text>
			<combobox>
				<variable>PROFILE_COMBO</variable>
				${PROFILE_BUTTONS}
			</combobox>
			<button>
				<label>$L_BUTTON_Load</label>
				<input file stock=\"gtk-apply\"></input>
				<action>EXIT:load</action>
			</button>
		</hbox>
	</frame>
	<frame  $L_FRAME_Edit_Profile >
		<vbox>
			
			<hbox>
				<vbox>
					<text><label>\"$L_TEXT_Encryption\"</label></text>
					<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				</vbox>
				<vbox>
				<button sensitive=\"$ENABLE_OPEN_BUTTON\">
					<label>$L_BUTTON_Open</label>
					<action>EXIT:50</action>
				</button>
				<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				</vbox>
				<vbox>
					<button sensitive=\"$ENABLE_WEP_BUTTON\">
						<label>WEP</label>
						<action>EXIT:51</action>
					</button>
					<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				</vbox>
				<vbox>
					<button sensitive=\"$ENABLE_WPA_BUTTON\">
						<label>WPA</label>
						<action>EXIT:52</action>
					</button>
					<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				</vbox>
				<vbox>
					<button sensitive=\"$ENABLE_WPA2_BUTTON\">
						<label>WPA2</label>
						<action>EXIT:53</action>
					</button>
					<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				</vbox>
			</hbox>
			
			<hbox>
				<vbox>
					<text><label>\"$L_TEXT_Profile_Nmae\"</label></text>
					<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				</vbox>
				<entry>
					<variable>PROFILE_TITLE</variable>
					${DEFAULT_TITLE}
				</entry>
			</hbox>
			
			<hbox>
				<vbox>
					<text><label>\"$L_TEXT_Essid\"</label></text>
					<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				</vbox>
				<entry>
					<variable>PROFILE_ESSID</variable>
					${DEFAULT_ESSID}
				</entry>
			</hbox>
			<hbox>
				<text><label>$L_TEXT_Mode</label></text>
				<vbox>
					<checkbox>
						<label>$L_CHECKBOX_Managed</label>
						<variable>PROFILE_MODE_M</variable>
						<action>if true disable:PROFILE_MODE_A</action>
						<action>if false enable:PROFILE_MODE_A</action>
						${DEFAULT_MODE_M}
					</checkbox>	
				</vbox>
				<vbox>
					<checkbox>
						<label>\"$L_CHECKBOX_Adhoc\"</label>
						<variable>PROFILE_MODE_A</variable>
						<action>if true disable:PROFILE_MODE_M</action>
						<action>if false enable:PROFILE_MODE_M</action>
						${DEFAULT_MODE_A}
					</checkbox>					
				</vbox>
				<text><label>\"$L_TEXT_Security\"</label></text>
				<vbox>
					<checkbox>
						<label>$L_CHECKBOX_Open</label>
						<variable>PROFILE_SECURE_O</variable>
						<action>if true disable:PROFILE_SECURE_R</action>
						<action>if false enable:PROFILE_SECURE_R</action>
						${DEFAULT_SECURE_O}
					</checkbox>					
				</vbox>
				<vbox>
					<checkbox>
						<label>$L_CHECKBOX_Restricted</label>
						<variable>PROFILE_SECURE_R</variable>
						<action>if true disable:PROFILE_SECURE_O</action>
						<action>if false enable:PROFILE_SECURE_O</action>
						${DEFAULT_SECURE_R}
					</checkbox>			
				</vbox>
			</hbox>
			
			${ENCRYPTION_FIELDS}
			
			<hbox>
				<button>
					<label>$L_BUTTON_Save</label>
					<input file stock=\"gtk-save\"></input>
					<action>EXIT:20</action>
				</button>
				<button>
					<label>$L_BUTTON_Delete</label>
					<input file stock=\"gtk-delete\"></input>
					<action>EXIT:21</action>
				</button>
				<button>
					<label>$L_BUTTON_Use_Profile</label>
					<action>EXIT:22</action>
				</button>
			</hbox>
		</vbox>
	</frame>

	<hbox>
		<button>
		  <label>$L_BUTTON_New_Profile</label>
		  <input file stock=\"gtk-new\"></input>
		  <action>EXIT:12</action>
		</button>				
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
		<button>
			<label>${ADVANCED_LABEL}</label>
			<input file icon=\"${ADVANCED_ICON}\"></input>
			<action>EXIT:40</action>
		</button>
		<button>
		  <label>$L_BUTTON_Back</label>
		  <input file stock=\"gtk-go-back\"></input>
		  <action>EXIT:19</action>
		</button>
	</hbox>
</vbox>
</window>"
}

#=============================================================================
setNoEncryptionFields()
{
	ENCRYPTION_FIELDS="$ADVANCED_FIELDS"
}

#=============================================================================
setWepFields()
{
	ENCRYPTION_FIELDS="
<hbox>
	<vbox>
		<text><label>$L_TEXT_Key</label></text>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	</vbox>
	<entry>
		<variable>PROFILE_KEY</variable>
		${DEFAULT_KEY}
	</entry>
</hbox>
${ADVANCED_FIELDS}
"
}

#=============================================================================
setWpaFields()
{
	ENCRYPTION_FIELDS="
<hbox>
	<vbox>
		<text><label>$L_TEXT_AP_Scan</label></text>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	</vbox>
	<vbox>
		<checkbox>
			<label>$L_CHECKBOX_Hidden_SSID</label>
			<variable>PROFILE_WPA_AP_SCAN_H</variable>
			<action>if true disable:PROFILE_WPA_AP_SCAN_D</action>
			<action>if true disable:PROFILE_WPA_AP_SCAN_S</action>
			<action>if false enable:PROFILE_WPA_AP_SCAN_D</action>
			<action>if false enable:PROFILE_WPA_AP_SCAN_S</action>
			${DEFAULT_WPA_AP_SCAN_H}
		</checkbox>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	</vbox>
	<vbox>
		<checkbox>
			<label>$L_CHECKBOX_Broadcast_SSID</label>
			<variable>PROFILE_WPA_AP_SCAN_S</variable>
			<action>if true disable:PROFILE_WPA_AP_SCAN_D</action>
			<action>if true disable:PROFILE_WPA_AP_SCAN_H</action>
			<action>if false enable:PROFILE_WPA_AP_SCAN_D</action>
			<action>if false enable:PROFILE_WPA_AP_SCAN_H</action>
			${DEFAULT_WPA_AP_SCAN_S}
		</checkbox>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	</vbox>
	<vbox>
		<checkbox>
			<label>$L_CHECKBOX_Driver</label>
			<variable>PROFILE_WPA_AP_SCAN_D</variable>
			<action>if true disable:PROFILE_WPA_AP_SCAN_S</action>
			<action>if true disable:PROFILE_WPA_AP_SCAN_H</action>
			<action>if false enable:PROFILE_WPA_AP_SCAN_S</action>
			<action>if false enable:PROFILE_WPA_AP_SCAN_H</action>
			${DEFAULT_WPA_AP_SCAN_D}
		</checkbox>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	</vbox>
	<vbox>
		<text><label>\"       \"</label></text>
	</vbox>
</hbox>
<hbox>
	<vbox>
		<text><label>$L_TEXT_Shared_Key</label></text>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	</vbox>
	<entry>
		<variable>PROFILE_KEY</variable>
		${DEFAULT_KEY}
	</entry>
</hbox>
"
}

setAdvancedFields()
{
	if [ ! "$ADVANCED" ] ; then
		ADVANCED_LABEL="$L_LABEL_Advanced"
		ADVANCED_ICON="gtk-add"
		ADVANCED_FIELDS=""
	else
		ADVANCED_LABEL="$L_LABEL_Basic"
		ADVANCED_ICON="gtk-remove"
		ADVANCED_FIELDS="
<hbox>
	<vbox>
		<text><label>$L_TEXT_Frequency</label></text>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	</vbox>
	<entry>
		<variable>PROFILE_FREQ</variable>
		${DEFAULT_FREQ}
	</entry>
</hbox>
<hbox>
	<vbox>
		<text><label>$L_TEXT_Channel</label></text>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	</vbox>
	<entry>
		<variable>PROFILE_CHANNEL</variable>
		${DEFAULT_CHANNEL}
	</entry>
</hbox>
<hbox>
	<vbox>
		<text><label>\"$L_TEXT_AP_MAC\"</label></text>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	</vbox>
	<entry>
		<variable>PROFILE_AP_MAC</variable>
		${DEFAULT_AP_MAC}
	</entry>
</hbox>"	
	fi
}

#=============================================================================
buildProfilesWindowButtons()
{
	PROFILE_BUTTONS=""

	for PROFILE in $PROFILE_TITLES
	do
    if [ "$PROFILE" != "#NEW#" ] ; then
		PROFILE_BUTTONS="${PROFILE_BUTTONS}<item>${PROFILE}</item>"
	fi
  done
} # end buildProfileWindowButtons

#=============================================================================
setupNewProfile ()
{
	PROFILE_TITLE=""
	PROFILE_ESSID=""
	PROFILE_MODE="managed"
	PROFILE_SECURE="open"
	PROFILE_KEY=""
	PROFILE_NWID=""
	PROFILE_FREQ=""
	PROFILE_CHANNEL=""
	PROFILE_AP_MAC=""
	PROFILE_ENCRYPTION="Open"
	#  Need to use separate variables, so when a profile is loaded that has
	#+ open/WEP, it doesn't blank out everything, just the profile one...
	#  Need the card one for shading WPA buttons
	PROFILE_WPA_DRV="$CARD_WPA_DRV"
	# Enable all buttons by default
	ENABLE_WEP_BUTTON='true'
	ENABLE_WPA_BUTTON='true'
	ENABLE_WPA2_BUTTON='true'
	ENABLE_OPEN_BUTTON='true'
	# Dougal: disable the WPA buttons if interface doesn't support it.
	if [ ! "$CARD_WPA_DRV" ] ; then 
		ENABLE_WPA_BUTTON='false'
		ENABLE_WPA2_BUTTON='false'
	fi
	
	PROFILE_TITLES="$( echo "$PROFILE_TITLES" | grep -v \"#NEW#\" )"
	PROFILE_TITLES="$PROFILE_TITLES
#NEW#"
	CURRENT_PROFILE="#NEW#"

} # end setupNewProfile

#=============================================================================
# this is code from loadPrifileData, moved here so can be used at boot... 
# (rather daft all this, should change profiles to contain PROFILE_ names)
assignProfileData(){
	# now assign to PROFILE_ names...
	PROFILE_WPA_DRV="$WPA_DRV"
	PROFILE_WPA_TYPE="$WPA_TYPE"
	PROFILE_WPA_AP_SCAN="$WPA_AP_SCAN"
	PROFILE_ESSID="$ESSID"
	PROFILE_NWID="$NWID"
	PROFILE_KEY="$KEY"
	PROFILE_MODE="$MODE"
	PROFILE_SECURE="$SECURE"
	PROFILE_FREQ="$FREQ"
	PROFILE_CHANNEL="$CHANNEL"
	PROFILE_AP_MAC="$AP_MAC"
	[ "$PROFILE_ESSID" = "<hidden>" ] && PROFILE_ESSID=""

	if [ "$PROFILE_KEY" = "" ] ; then
		PROFILE_ENCRYPTION="Open"
		ENABLE_WEP_BUTTON='false'
		ENABLE_WPA_BUTTON='false'
		ENABLE_WPA2_BUTTON='false'
		ENABLE_OPEN_BUTTON='true'
	elif [ "$PROFILE_WPA_DRV" = "" ] ; then
		PROFILE_ENCRYPTION="WEP"
		ENABLE_WEP_BUTTON='true'
		ENABLE_WPA_BUTTON='false'
		ENABLE_WPA2_BUTTON='false'
		ENABLE_OPEN_BUTTON='false'
	elif [ "$PROFILE_WPA_TYPE" ] ; then # Dougal: add WPA2
		PROFILE_ENCRYPTION="WPA2"
		ENABLE_WEP_BUTTON='false'
		ENABLE_WPA_BUTTON='false'
		ENABLE_WPA2_BUTTON='true'
		ENABLE_OPEN_BUTTON='false'
	else
		PROFILE_ENCRYPTION="WPA"
		ENABLE_WEP_BUTTON='false'
		ENABLE_WPA_BUTTON='true'
		ENABLE_WPA2_BUTTON='false'
		ENABLE_OPEN_BUTTON='false'
	fi 
} # end assignProfileData

#=================================================================n============
loadProfileData()
{
	# Dougal: added "SECURE" param, increment the "-A" below
	PROFILE_TITLE="$1"
	#PROFILE_DATA=`grep -A 11 -E "TITLE[0-9]+=\"${PROFILE_TITLE}\"" /etc/WAG/profile-conf`
	## Dougal: I'm not sure about the name -- maybe need to change underscores to spaces?
	PROFILE_FILE=$( grep -l "TITLE=\"${PROFILE_TITLE}\"" ${PROFILES_DIR}/*.conf | head -n1 )
	# add failsafe, in case there is none
	[ "$PROFILE_FILE" ] || return
	# Dougal: source config file
	. "$PROFILE_FILE"
	# now assign to PROFILE_ names...
	assignProfileData
} # end loadProfileData

#=============================================================================
assembleProfileData()
{
	if [ "$PROFILE_MODE_A" = "true" ] ; then
		PROFILE_MODE="ad-hoc"
	else
		PROFILE_MODE="managed"
	fi
	
	if [ "$PROFILE_SECURE_O" = "true" ] ; then
		PROFILE_SECURE="open"
	else
		PROFILE_SECURE="restricted"
	fi

	if [ "$PROFILE_WPA_AP_SCAN_H" = "true" ] ; then
		PROFILE_WPA_AP_SCAN="2"
	elif [ "$PROFILE_WPA_AP_SCAN_D" = "true" ] ; then
		PROFILE_WPA_AP_SCAN="0"
	else # WPA supplicant does the scanning
		PROFILE_WPA_AP_SCAN="1"
	fi

	case $PROFILE_ENCRYPTION in
		WPA|WPA2)
			;;
		WEP)
			PROFILE_WPA_DRV=""
			PROFILE_WPA_AP_SCAN=""
			;;
		*)
			PROFILE_KEY=""
			PROFILE_WPA_DRV=""
			PROFILE_WPA_AP_SCAN=""
			;;		
	esac

	PROFILE_TITLE="$(echo "$PROFILE_TITLE" | tr ' ' '_')"
	# (BASHISM!)
	#PROFILE_TITLE=${PROFILE_TITLE// /_}

	NEW_PROFILE_DATA="TITLE=\"${PROFILE_TITLE}\"
        WPA_DRV=\"${PROFILE_WPA_DRV}\"
        WPA_TYPE=\"$PROFILE_WPA_TYPE\"
        WPA_AP_SCAN=\"${PROFILE_WPA_AP_SCAN}\"
        ESSID=\"${PROFILE_ESSID}\"
        NWID=\"${PROFILE_NWID}\"
        KEY=\"$(echo "$PROFILE_KEY" | sed 's%\$%\\$%g ; s%`%\\`%g ; s%"%\\"%g')\"
        MODE=\"${PROFILE_MODE}\"
        SECURE=\"${PROFILE_SECURE}\"
        FREQ=\"${PROFILE_FREQ}\"
        CHANNEL=\"${PROFILE_CHANNEL}\"
        AP_MAC=\"${PROFILE_AP_MAC}\"
        "
} # end assembleProfileData

#=============================================================================
deleteProfile(){
	# skip the templates...
	case $PROFILE_TITLE in autoconnect|template) return ;; esac 
	if [ -s "${PROFILES_DIR}/${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf" ] ; then
		rm "${PROFILES_DIR}/${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf"
	fi
} # end deleteProfile

#=============================================================================
## Dougal: we don't need all the mess here if not using one config file...
saveProfiles ()
{
	CURRENT_PROFILE=$( echo "$NEW_PROFILE_DATA" | grep -F "TITLE=" | cut -d= -f2 | tr -d '"' )
	# Dougal: the templates aren't named after the mac address... (none)
	case $CURRENT_PROFILE in autoconnect|template) return ;; esac 
	# add failsafe: skip if no mac address exists
	if [ -z "$PROFILE_AP_MAC" ] ; then
	  #giveNoNetworkDialog
	  giveErrorDialog "$L_MESSAGE_Bad_Profile"
	  return
	fi
	echo "$NEW_PROFILE_DATA" > "${PROFILES_DIR}/${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf"
	# create wpa_supplicant config file
	case $PROFILE_ENCRYPTION in WPA|WPA2) saveWpaProfile ;; esac
} # end saveProfiles

#=============================================================================
# A function to create an appropriate wpa_supplicant config, rather than use wpa_cli
saveWpaProfile(){
	# first, get the WPA PSK (might have an error)
	getWpaPSK || return 1
	
	WPA_CONF="${WPA_SUPP_DIR}/${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf"
	if [ ! -e "$WPA_CONF" ] ; then
		# copy template
		cp -a "${WPA_SUPP_DIR}/wpa_supplicant$PROFILE_WPA_TYPE.conf" "$WPA_CONF"
	fi
	# need to escape the original phrase for sed
	## (need to be escaped twice (extra \\) if we want the result escaped)
	ESCAPED_PHRASE="$( echo "$PROFILE_KEY" | sed 's%\\%\\\\%g ; s%\$%\\$%g ; s%`%\\`%g ; s%"%\\"%g ; s%\/%\\/%g' )"

	# need to change ap_scan, ssid and psk
	sed -i "s/ap_scan=.*/ap_scan=$PROFILE_WPA_AP_SCAN/" "$WPA_CONF"
	sed -i "s/\Wssid=.*/	ssid=\"$PROFILE_ESSID\"/" "$WPA_CONF"
	sed -i "s/\Wpsk=.*/	#psk=\"$ESCAPED_PHRASE\"\n	psk=$PSK/" "$WPA_CONF"
	#sed -i "s/	psk=.*/	psk=\"$PSK\"/" "$WPA_CONF"
	return 0
}

#=============================================================================
# A function to get the psk from wpa_passphrase (moved out of useWpaSupplicant
getWpaPSK(){
	# If key is not hex, then convert to hex
	echo "$PROFILE_KEY" | grep -Eq "^[0-9a-fA-F]{64}$"
	if [ $? -eq 0 ] ; then
		PSK="$PROFILE_KEY"
	else
		#KEY_SIZE=`echo "${PROFILE_KEY}" | wc -c`
		KEY_SIZE=${#PROFILE_KEY}
		if [ $KEY_SIZE -lt 8 ] || [ $KEY_SIZE -gt 64 ] ; then
			giveErrorDialog "Error!
Shared key must be either
- ASCII between 8 and 63 characters
- 64 characters hexadecimal
"
			return 1
		else #if [ $KEY_SIZE -lt 8 ] || [ $KEY_SIZE -gt 64 ] 
			# Dougal: add escaping of funny chars in passphrase
			# also quote the inner subshell
			# No! don't need subshell apparently, escaping chars is unneeded
			#"$( echo "$PROFILE_KEY" | sed 's%\$%\\$%g ; s%`%\\`%g ; s%"%\\"%g' )"
			##  Strage: the first grep below was enough for me, but a user got
			##+ errors, because it didn't filter out the "#psk" line!
			PSK=$(wpa_passphrase "$PROFILE_ESSID" "$PROFILE_KEY" | \
				   grep -F "psk=" | grep -Fv '#psk' | cut -d"=" -f2 )
			echo "PSK is |$PSK|" >> $DEBUG_OUTPUT
			# make sure we got something!
			if [ ! "$PSK" ] ; then
			  giveErrorDialog "$L_MESSAGE_Bad_PSK"
			  return 1
			fi
		fi #if [ $KEY_SIZE -lt 8 ] || [ $KEY_SIZE -gt 64 ] ; then
	fi #if [ $? -eq 0 ] ; then #check for hex
	return 0
}

#=============================================================================
# A function that gives an error message using gtkdialog
# $@: the dialog text
giveErrorDialog(){
	# always echo it, too, for debug purposes
	echo "$@" >> $DEBUG_OUTPUT
	[ "$HAVEX" = "yes" ] || return
	export NETWIZ_ERROR_DIALOG="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-dialog-error\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\">
      <input file stock=\"gtk-dialog-error\"></input>
    </pixmap>
  <text>
    <label>\"$@\"</label>
  </text>
  <hbox>
    <button ok></button>
  </hbox>
 </vbox>
</window>"

	gtkdialog --program NETWIZ_ERROR_DIALOG >/dev/null 2>&1
	clean_up_gtkdialog NETWIZ_ERROR_DIALOG
	unset NETWIZ_ERROR_DIALOG
}

#=============================================================================
#131225 shinobar: retry with WPA/AES
switchTkipAes() {
	WPA_CONF="${WPA_SUPP_DIR}/${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf"
	ENCRYPT_NOW=$(grep 'pairwise=' "$WPA_CONF" |cut -s -d'=' -f2)
	[ "$ENCRYPT_NOW" = "TKIP" ] && ENCRYPT_NEXT="CCMP" || ENCRYPT_NEXT="TKIP"
	sed -i -e "s/=$ENCRYPT_NOW/=$ENCRYPT_NEXT/" "$WPA_CONF"
}

useProfile ()
{
	case $PROFILE_ENCRYPTION in
		WPA|WPA2)
		    #131225 shinobar: retry with WPA/AES
		    rm -f /tmp/wag-profiles-retry.flg
			useWpaSupplicant wizard
			STATUS=$?
			if [ -e /tmp/wag-profiles-retry.flg ]; then
			  switchTkipAes
			  useWpaSupplicant wizard
			  STATUS=$?
			fi
			[ $STATUS -eq 0 ] || return 1
			;;
		WPA2) useWpaSupplicant wizard || return 1
			;;
		*)
			if [ "$USE_WLAN_NG" ] ; then
			  useWlanctl || return 1
			else 
			  useIwconfig || return 1
			fi
			;;		
	esac
} # end useProfile

#=============================================================================
killWpaSupplicant ()
{
	# If there are supplicant processes for the current interface, kill them
	[ -d /var/run/wpa_supplicant ] || return
	[ "$INTERFACE" ] || INTERFACE="$1"
	wpa_cli -i "$INTERFACE" terminate 2>&1 |grep -v 'Failed to connect'
	[ -e /var/run/wpa_supplicant/$INTERFACE ] && rm -rf /var/run/wpa_supplicant/$INTERFACE
} # end killWpaSupplicant

# Dougal: put this into a function, for maintainability and so it can be used in setupDHCP
killDhcpcd(){
	[ "$INTERFACE" ] || INTERFACE="$1"
	## Dougal: check /var first, since /etc/dhcpc might exist in save file from the past...
	if [ -d /var/lib/dhcpcd ] ; then
	  if [ -s /var/run/dhcpcd-${INTERFACE}.pid ] ; then
	    kill $( cat /var/run/dhcpcd-${INTERFACE}.pid )
	    rm -f /var/run/dhcpcd-${INTERFACE}.* 2>/dev/null
	  fi
	  #begin rerwin - Retain duid, if any, so all interfaces can use
	  #it (per ipv6) or delete it if using MAC address as client ID.    rerwin
	  rm -f /var/lib/dhcpcd/dhcpcd-${INTERFACE}.* 2>/dev/null  #.info
#end rerwin
	  #rm -f /var/run/dhcpcd-${INTERFACE}.* 2>/dev/null #.pid
	elif [ -d /etc/dhcpc ];then
	  if [ -s /etc/dhcpc/dhcpcd-${INTERFACE}.pid ] ; then
	    kill $( cat /etc/dhcpc/dhcpcd-${INTERFACE}.pid )
	    rm /etc/dhcpc/dhcpcd-${INTERFACE}.pid 2>/dev/null
	  fi
	  rm /etc/dhcpc/dhcpcd-${INTERFACE}.* 2>/dev/null 
	  #if left over from last session, causes trouble.	  
	fi
} # end killDhcpcd

#=============================================================================
# a function to clean up before configuring interface
# list of stuff stolen from wicd
# $1: interface name
cleanUpInterface(){
	# put interface down
	#ifconfig "$1" down
	killDhcpcd "$1"
	# kill wpa_supplicant
	killWpaSupplicant "$1"
	# clean up some wireless stuff (taken from wifi-radar)
	if [ "$IS_WIRELESS" = "yes" ] ; then
	  iwconfig "$1" essid off
	  iwconfig "$1" key off
	  iwconfig "$1" mode managed # auto doesn't exist anymore??
	  iwconfig "$1" channel auto
	fi
	# put interface down
	ifconfig "$1" down
	# reset ip address (set a false one)
	ifconfig "$1" 0.0.0.0
	if ! ERROR=$(ifconfig "$1" up 2>&1) ; then
	  giveErrorDialog "${L_MESSAGE_Failed_To_Raise_p1}${1}${L_MESSAGE_Failed_To_Raise_p2} ifconfig $1 up
$L_MESSAGE_Failed_To_Raise_p3
$ERROR
"
	  return 1
	fi
	return $?
} # end cleanUpInterface
#=============================================================================
## Dougal: function to kill stray processes
## dialog variable passed as param
clean_up_gtkdialog(){
 [ "$1" ] || return
 for I in $( ps -fC gtkdialog | grep "$1" | tr -s ' ' | cut -f 2 -d ' ' | tr '\n' ' ' ) #170504
 do kill $I
 done 
}

#=============================================================================
useIwconfig ()
{
  #(
	# Dougal: give the text message even when using dialog (for debugging)
	echo "Configuring interface $INTERFACE to network $PROFILE_ESSID with iwconfig..."
	if [ "$HAVEX" = "yes" ]; then 
	  export NETWIZ_Connecting_DIALOG="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\"><input file stock=\"gtk-network\"></input></pixmap>
  <text><label>\"${L_MESSAGE_Configuring_Interface_p1}${INTERFACE}${L_MESSAGE_Configuring_Interface_p2}${PROFILE_ESSID}...
\"</label></text>
 </vbox></window>"
	  gtkdialog --program NETWIZ_Connecting_DIALOG &
	  local XPID=$!	  
	fi
	#killWpaSupplicant
	# Dougal: reset the interface
	cleanUpInterface "$INTERFACE" >> $DEBUG_OUTPUT 2>&1
	MAXWAIT=8
	WAIT=1
   while [ $WAIT -lt $MAXWAIT ]; do
 	sleep $WAIT
	#echo "X"
	#RUN_IWCONFIG=""
	STATUS=0
	# Dougal: re-order these a bit, to match order in wicd
	[ "$PROFILE_MODE" ] && iwconfig "$INTERFACE" mode $PROFILE_MODE >> $DEBUG_OUTPUT 2>&1
	[ "$PROFILE_ESSID" ] && iwconfig "$INTERFACE" essid "$PROFILE_ESSID" >> $DEBUG_OUTPUT 2>&1
	[ "$PROFILE_CHANNEL" ] && iwconfig "$INTERFACE" channel $PROFILE_CHANNEL >> $DEBUG_OUTPUT 2>&1
	[ "$PROFILE_AP_MAC" ] && iwconfig "$INTERFACE" ap $PROFILE_AP_MAC >> $DEBUG_OUTPUT 2>&1
	[ "$PROFILE_NWID" ] && iwconfig "$INTERFACE" nwid $PROFILE_NWID >> $DEBUG_OUTPUT 2>&1
	[ "$PROFILE_FREQ" ] && iwconfig "$INTERFACE" freq $PROFILE_FREQ >> $DEBUG_OUTPUT 2>&1
	if [ "$PROFILE_KEY" ] ; then
	  iwconfig "$INTERFACE" key on >> $DEBUG_OUTPUT 2>&1
	  iwconfig "$INTERFACE" key $PROFILE_SECURE "$PROFILE_KEY" >> $DEBUG_OUTPUT 2>&1
	fi
	# Dougal: add increasing of rate for ath5k
	case $INTMODULE in ath5k*) iwconfig "$INTERFACE" rate 11M >> $DEBUG_OUTPUT 2>&1 ;; esac

	if [ "$PROFILE_ESSID" ] ; then
	   sleep $WAIT
	   IWCONFIG=$(iwconfig "$INTERFACE")
	   echo $IWCONFIG | grep -q "ESSID:.$PROFILE_ESSID.[ ]"  || STATUS=1
	fi
	[ $STATUS -eq 0 ] && break
	WAIT=$(expr $WAIT + $WAIT)
    [ $WAIT -lt $MAXWAIT ] && echo "Waiting time ${WAIT} seconds" >&2
   done
	#echo "X"
	if [ "$XPID" ] ;then
	  kill $XPID >/dev/null 2>&1
	  clean_up_gtkdialog NETWIZ_Connecting_DIALOG
	fi
	unset NETWIZ_Connecting_DIALOG
	return $STATUS
} # end useIwconfig

#=============================================================================
# Dougal: add this for the prism2_usb module
useWlanctl(){
  #(
	# Dougal: give the text message even when using dialog (for debugging)
	echo "Configuring interface $INTERFACE to network $PROFILE_ESSID with wlanctl-ng..."
	if [ "$HAVEX" = "yes" ]; then 
	  export NETWIZ_Connecting_DIALOG="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\"><input file stock=\"gtk-network\"></input></pixmap>
  <text><label>\"${L_MESSAGE_Configuring_Interface_p1}${INTERFACE}${L_MESSAGE_Configuring_Interface_p2}${PROFILE_ESSID}...
\"</label></text>
 </vbox></window>"
	  gtkdialog --program NETWIZ_Connecting_DIALOG &
	  local XPID=$!	  
	fi
	#killWpaSupplicant
	cleanUpInterface "$INTERFACE" >> $DEBUG_OUTPUT 2>&1
	#echo "X"
	# create code for running wlanctl-ng
	wlanctl-ng $INTERFACE lnxreq_ifstate ifstate=enable
	# need to check if PROFILE_KEY exists, to know if we're using WEP or not
	if [ "$PROFILE_KEY" ] ; then
	  # need to split the key into pairs
	  A=1
	  WLAN_KEY=""
	  for ONE in 1 2 3 4 5
	  do
	    WLAN_KEY="$WLAN_KEY$(expr substr $PROFILE_KEY $A 2):"
	    A=$((A+2))
	  done
	  WLAN_KEY=${WLAN_KEY%:}
	  #WLANNG_CODE="$WLANNG_CODE
	  wlanctl-ng $INTERFACE lnxreq_hostwep decrypt=true encrypt=true
	  wlanctl-ng $INTERFACE dot11req_mibset mibattribute=dot11PrivacyInvoked=true
	  wlanctl-ng $INTERFACE dot11req_mibset mibattribute=dot11WEPDefaultKeyID=0
	  wlanctl-ng $INTERFACE dot11req_mibset mibattribute=dot11ExcludeUnencrypted=true
	  wlanctl-ng $INTERFACE dot11req_mibset mibattribute=dot11WEPDefaultKey0=$WLAN_KEY
	  #"
	fi
	## Dougal: probably need to change PROFILE_SECURE to right format
	## (I'm leaving it the same everywhere else -- so gui looks the same)
	case "$PROFILE_SECURE" in
	 open) WLAN_SECURE="opensystem" ;;
	 restricted) WLAN_SECURE="sharedkey" ;;
	esac 
	#WLANNG_CODE="$WLANNG_CODE
	wlanctl-ng $INTERFACE lnxreq_autojoin ssid=$PROFILE_ESSID authtype=$WLAN_SECURE
	#"
	
	#echo "X"
	if [ "$XPID" ] ;then
	  kill $XPID >/dev/null 2>&1
	  clean_up_gtkdialog NETWIZ_Connecting_DIALOG
	fi
	unset NETWIZ_Connecting_DIALOG
	return 0
  #) | Xdialog --title "Puppy Ethernet Wizard" --progress "Saving profile" 0 0 3
} # end useWlanctl
#=============================================================================
# function to validate that the wpa_supplicant authentication process was successful.
# $1: interface name
# $2: XPID of gtkdialog progressbar (so we can check if the user clicked "abort")
# (times in wicd were 15, 3, 1 (sleep), +5 (if rescan) )
validateWpaAuthentication(){
	# Max time we wait for connection to complete (+1 since loop checks at start)
	local MAX_TIME='31'
	# The max time after starting in which we allow the status to be "DISCONNECTED"
	local MAX_DISCONNECTED_TIME=4
	START_TIME=$(date +%s)
	# The elapsed time since starting (calculated at the bottom of the loop)
	ELAPSED=0
	while [ $ELAPSED -lt $MAX_TIME ] ; do
		sleep 1
		# see if user aborted 
		if [ "$2" ] ; then
		  pidof gtkdialog 2>&1 |grep -q "$2" || return 2
		fi
		# change to lower case, to make it more clear when displayed
		RESULT=$(wpa_cli -i "$1" status 2>>$DEBUG_OUTPUT |grep 'wpa_state=' | tr A-Z a-z |tr '_' ' ')
		[ "$RESULT" ] || return 3
		RESULT=${RESULT#*=}
		#echo "$RESULT"
		echo "${L_ECHO_Status_p1}${ELAPSED}${L_ECHO_Status_p2}${RESULT}"
		case $RESULT in
		  *completed*) return 0 ;;
		  *disconnected*) 
		    if [ $ELAPSED -gt $MAX_DISCONNECTED_TIME ] ; then
		      # Force a rescan to get wpa_supplicant moving again.
		      # Dougal: explanation from wicd:
		      # This works around authentication validation sometimes failing for
		      # wpa_supplicant because it remains in a DISCONNECTED state for 
		      # quite a while, after which a rescan is required, and then
		      # attempting to authenticate.  This whole process takes a long
		      # time, so we manually speed it up if we see it happening.
		      echo "forcing wpa_supplicant to rescan:" >>$DEBUG_OUTPUT
		      wpa_cli -i "$1" scan >>$DEBUG_OUTPUT 2>&1
		      MAX_TIME=$((MAX_TIME+5))
		      MAX_DISCONNECTED_TIME=$((MAX_DISCONNECTED_TIME+4))
		    fi
		    ;;
		esac
		# echo X for progress dialog
		#echo -n "X"
		#sleep 1
		ELAPSED=$(($(date +%s)-$START_TIME))
	done
	return 1
} # end validateWpaAuthentication
#=============================================================================
useWpaSupplicant ()
{
	# add an option for running some parts only from the wizard
	if [ "$1" = "wizard" ] ; then
		# Dougal: moved all below code to a function
		getWpaPSK || return 1
		# Dougal: make wpa_supplicant config file match mac address
		WPA_CONF="${WPA_SUPP_DIR}/${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf"
		if [ ! -e "$WPA_CONF" ] ; then
	  		# copy template
			#cp -a "${WPA_SUPP_DIR}/wpa_supplicant$PROFILE_WPA_TYPE.conf" "$WPA_CONF"
			# no, now this is done while saving, give message if failed
			giveErrorDialog "$L_MESSAGE_No_Wpaconfig_p1
$WPA_CONF
$L_MESSAGE_No_Wpaconfig_p2"
			return 1
		fi
		cleanUpInterface "$INTERFACE" >> $DEBUG_OUTPUT 2>&1
	else # running from rc.network
    	WPA_CONF="$1"
	fi #if [ "$1" = "wizard" ] ; then	
	# Dougal: give the text message even when using dialog (for debugging)
	echo "Configuring interface $INTERFACE to network $PROFILE_ESSID with wpa_supplicant..." >> $DEBUG_OUTPUT
	
	###### run dialog
	if [ "$HAVEX" = "yes" ]; then 
		# Create a temporary fifo to pass messages to progressbar (can't just pipe to it)
		PROGRESS_OUTPUT=/tmp/progress-fifo$$
		mkfifo $PROGRESS_OUTPUT
		# The progressbar dialog
		# It contains a loop that starts from 1 and increments by 3, so 1+33*3=100%
		# (33= first three messages + 30 iterations of loop in validate...)
		# If it recieves "end" it will skip to 100.
		export NETWIZ_Scan_Progress_Dialog="<window title=\"$L_TITLE_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
<vbox>
  <text><label>\"${L_TEXT_WPA_Progress_p1}${PROFILE_ENCRYPTION}${L_TEXT_WPA_Progress_p2}${PROFILE_ESSID}${L_TEXT_WPA_Progress_p3}\"</label></text>
  <frame $L_FRAME_Progress>
      <progressbar>
      <label>Connecting</label>
      <input>i=1 ; while read bla ; do i=\$((i+3)) ; case \$bla in end) i=100 ;; esac ; echo \$i ;echo \"\$bla\" ; done</input>
      <action type=\"exit\">Ready</action>
    </progressbar>
  </frame>
  <hbox>
   <button>
     <label>$L_BUTTON_Abort</label>
     <input file stock=\"gtk-stop\"></input>
     <action>EXIT:Abort</action>
   </button>
  </hbox>
 </vbox>
</window>"
		gtkdialog --program=NETWIZ_Scan_Progress_Dialog <$PROGRESS_OUTPUT &
		local XPID=$!
	else
		PROGRESS_OUTPUT=$DEBUG_OUTPUT
	fi
	# Use a subshell to redirect echoes to fifo 
	# (need one subshell, since redirecting something like a function will 
	#+ freeze the progress bar when it ends)
	####################################################################
	(
		echo "$L_ECHO_Starting"
		# Dougal: add increasing of rate for ath5k
		case $INTMODULE in ath5k*) iwconfig "$INTERFACE" rate 11M >> $DEBUG_OUTPUT 2>&1;; esac 	
		echo "$L_ECHO_Initializing_Wpa"
		wpa_supplicant -i "$INTERFACE" -D "$PROFILE_WPA_DRV" -c "$WPA_CONF" -B >> $DEBUG_OUTPUT 2>&1

		echo "Waiting for connection... " >> $DEBUG_OUTPUT 2>&1

		echo "trying to connect"
		# Dougal: use function based on wicd code
		# (note that it echoes the X's for the progress dialog)
		# have different return values:
		validateWpaAuthentication "$INTERFACE" "$XPID"
		case $? in
		 0) # success  
		   #WPA_STATUS="COMPLETED"
		   echo "COMPLETED" >/tmp/wpa_status.txt
		   echo "completed" >> $DEBUG_OUTPUT
		   # end the progress bar
		   echo end
		   ;;
		 1) # timeout
		   echo "timeout" >> $DEBUG_OUTPUT
		   # end the progress bar
		   echo end
		   ;;
		 2) # user aborted
		   echo aborted >>$DEBUG_OUTPUT
		   ;;
		 3) # error
		   echo "error while running:" >>$DEBUG_OUTPUT
		   echo "wpa_cli -i $INTERFACE status | grep 'wpa_state=' " >>$DEBUG_OUTPUT
		   # end the progress bar
		   echo end
		   ;;
		esac
		
		# Dougal: close the -n above
		echo  >> $DEBUG_OUTPUT 2>&1
		#echo -n "$WPA_STATUS" > /tmp/wpa_status.txt
		#echo "---" >> ${TMPLOG} 2>&1
	) >>$PROGRESS_OUTPUT
	####################################################################
  #| Xdialog --title "Puppy Ethernet Wizard" --progress "Acquiring WPA connection\n\nThere may be a delay up to 60 seconds." 0 0 20
	if [ "$XPID" ] ;then
	  kill $XPID >/dev/null 2>&1
	  clean_up_gtkdialog NETWIZ_Scan_Progress_Dialog
	fi
	unset NETWIZ_Scan_Progress_Dialog
	###########
	if [ "$HAVEX" = "yes" ]; then # it's a pipe
		rm $PROGRESS_OUTPUT
	fi
	#cat $TMPLOG >> $DEBUG_OUTPUT
	WPA_STATUS="$(cat /tmp/wpa_status.txt)"
	rm /tmp/wpa_status.txt
	
	if [ "$WPA_STATUS" = "COMPLETED" ] ; then
		return 0
	fi
	# if we're here, it failed
	#131225 shinobar: retry with WPA/AES
	if [ "$PROFILE_ENCRYPTION" = "WPA" ] && [ ! -e /tmp/wag-profiles-retry.flg ]; then
	  touch  /tmp/wag-profiles-retry.flg
	  WPA_CONF="${WPA_SUPP_DIR}/${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf"
	  ENCRYPT_NOW=$(grep 'pairwise=' "$WPA_CONF" |cut -s -d'=' -f2)
	  [ "$ENCRYPT_NOW" = "TKIP" ] && ENCRYPT_NEXT="CCMP" || ENCRYPT_NEXT="TKIP"
	  ENCRYPT_NEXT_DISP=$ENCRYPT_NEXT
	  [ "$ENCRYPT_NEXT" = "CCMP" ] && ENCRYPT_NEXT_DISP="AES" # show 'AES' rather than 'CCMP'
	  [ "$L_MESSAGE_TKIP_Failed" ] || L_MESSAGE_TKIP_Failed="failed, but you can retry with another encryption"
	  MSG="WPA/$ENCRYPT_NOW $L_MESSAGE_TKIP_Failed $ENCRYPT_NEXT_DISP."
	  BUTTONS="<hbox>
   <button>
    <label>$L_BUTTON_Details</label>
    <input file stock=\"gtk-info\"></input>
    <action>EXIT:Details</action>
   </button>
  </hbox>
  <hbox><button>
      <label>\"$L_BUTTON_Retry\"</label>
      <input file stock=\"gtk-redo\"></input>
      <action>EXIT:retry</action>
    </button>
    <button cancel></button>
    </hbox>"
    else
      rm -f  /tmp/wag-profiles-retry.flg
      MSG="$L_MESSAGE_WPA_Failed"
      BUTTONS="<hbox>
   <button>
    <label>$L_BUTTON_Details</label>
    <input file stock=\"gtk-info\"></input>
    <action>EXIT:Details</action>
   </button><button ok></button>
   </hbox>"
	fi
	if [ "$1" = "wizard" ] && [ "$HAVEX" = "yes" ] ; then
		export NETWIZ_No_WPA_Connection_Dialog="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-dialog-error\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\"><input file stock=\"gtk-dialog-error\"></input></pixmap>
  <text>
    <label>\"$MSG\"</label>
  </text>
  $BUTTONS
 </vbox>
</window>"

		I=$IFS; IFS=""
		for STATEMENT in  $(gtkdialog --program NETWIZ_No_WPA_Connection_Dialog); do
			eval $STATEMENT
		done
		IFS=$I
		clean_up_gtkdialog NETWIZ_No_WPA_Connection_Dialog
		unset NETWIZ_No_WPA_Connection_Dialog
		#131225 shinobar: retry with WPA/AES
		[ "$EXIT" = "retry" ] || rm -f /tmp/wag-profiles-retry.flg
		if [ "$EXIT" = "Details" ] ; then
		  EXIT="Refresh"
		  while [ "$EXIT" = "Refresh" ] ; do
		    # iwconfig info
		    IW_INFO="$(iwconfig $INTERFACE |grep -o 'Access Point: .*\|Link Quality:[0-9]* ' )"
		    export NETWIZ_WPA_Status_Dialog="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
 <vbox>
  <frame $L_FRAME_Connection_Info >
  <text>
    <label>\"$IW_INFO\"</label>
  </text>
  </frame>
  <frame ${L_FRAME_wpa_cli_Outeput}'wpa_cli -i $INTERFACE status' >
   <edit cursor-visible=\"false\" accepts-tab=\"false\">
    <variable>EDITOR</variable>
    <width>300</width><height>150</height>
    <default>\"$(wpa_cli -i $INTERFACE status 2>&1)\"</default>
   </edit>
  </frame>
  <hbox>
   <button>
    <label>$L_BUTTON_Refresh</label>
    <input file stock=\"gtk-refresh\"></input>
    <action>EXIT:Refresh</action>
   </button>
   <button ok></button>
  </hbox>
 </vbox>
</window>"
		    I=$IFS; IFS=""
		    for STATEMENT in  $(gtkdialog --program NETWIZ_WPA_Status_Dialog); do
			  eval $STATEMENT
		    done
		    IFS=$I
		  done # while [ "$EXIT" = "Refresh" ] 
		  clean_up_gtkdialog NETWIZ_WPA_Status_Dialog
		  unset NETWIZ_WPA_Status_Dialog
		fi #if [ "$EXIT" = "Details" ] ; then
	fi #if [ "$1" = "wizard" ] && [ "$HAVEX" = "yes" ] ; then
	# if we're here, connection failed -- kill wpa_supplicant!
	wpa_cli -i "$INTERFACE" terminate >>$DEBUG_OUTPUT
	return 1
} # end useWpaSupplicant

#=============================================================================
checkIsPCMCIA(){
  IsPCMCIA=""
  if PciSlot=$(grep -F 'PCI_SLOT_NAME=' /sys/class/net/$INTERFACE/device/uevent) ; then
    if [ -d /sys/class/pcmcia_socket/pcmcia_socket[0-9]/device/${PciSlot#PCI_SLOT_NAME=} ]
	then  IsPCMCIA=yes
    fi
  fi
}

#=============================================================================
waitForPCMCIA(){
	export NETWIZ_Wait_For_PCMCIA_Dialog="<window title=\"$L_TITLE_Network_Wizard\" window-position=\"1\">
 <progressbar>
  <label>\"$L_PROGRESS_Waiting_For_PCMCIA\"</label>
  <input>i=0 ; while read bla ; do i=\$((i+20)) ; echo \$i ; done</input>
  <action type=\"exit\">Ready</action>
 </progressbar>
</window>"

	for i in 1 2 3 4 5 ; do
		sleep 1
		echo X
	done | gtkdialog --program=NETWIZ_Wait_For_PCMCIA_Dialog >/dev/null
	clean_up_gtkdialog NETWIZ_Wait_For_PCMCIA_Dialog
} # end of waitForPCMCIA

#=============================================================================
showScanWindow()
{
	# do the cleanup here, so devices have a chance to "settle" before scanning
	cleanUpInterface "$INTERFACE" >> $DEBUG_OUTPUT 2>&1
	sleep 1
	checkIsPCMCIA # sets IsPCMCIA
	# Dougal: this replaces Xdialog at the end of the subshells in Build*ScanWindow
	export NETWIZ_Scan_Progress_Dialog="<window title=\"$L_TITLE_Network_Wizard\" window-position=\"1\">
 <progressbar>
  <label>\"$L_PROGRESS_Scanning_Wireless\"</label>
  <input>i=1 ; while read bla ; do i=\$((i+33)) ; echo \$i ; done</input>
  <action type=\"exit\">Ready</action>
 </progressbar>
</window>"

	# add waiting for pcmcia to "settle"...
	[ -n "$IsPCMCIA" ] && waitForPCMCIA
	if [ "$USE_WLAN_NG" = "yes" ] ; then
	  buildPrismScanWindow
	else
	  buildScanWindow
	fi

	SCANWINDOW_RESPONSE="$(sh /tmp/net-setup_scanwindow)"
	# add support for trying again with pcmcia cards
	case $? in 
	 101)
	  pccardctl eject
	  pccardctl insert
	  [ -n "$IsPCMCIA" ] && waitForPCMCIA
	  if [ "$USE_WLAN_NG" = "yes" ] ; then
	    buildPrismScanWindow retry
	  else
	    buildScanWindow retry
	  fi
	  SCANWINDOW_RESPONSE="$(sh /tmp/net-setup_scanwindow)"
	  ;;
	 111)
	  [ -n "$IsPCMCIA" ] && waitForPCMCIA
	  if [ "$USE_WLAN_NG" = "yes" ] ; then
	    buildPrismScanWindow retry
	  else
	    buildScanWindow retry
	  fi
	  SCANWINDOW_RESPONSE="$(sh /tmp/net-setup_scanwindow)"
	  ;;
	esac
	
	unset NETWIZ_Scan_Progress_Dialog

	CELL=$(echo "$SCANWINDOW_RESPONSE" | grep -Eo "[0-9]+")

	[ -n "$CELL" ] && setupScannedProfile 

} # end of showScanWindow

#=============================================================================
# $1 might be "retry", to let us know we've already tried once...
buildScanWindow()
{
	SCANWINDOW_BUTTONS=""
	(
		#  Dougal: use files for the scan results, so we can try a few times
		#+ and see which is biggest (sometimes not all networks show)
		rm /tmp/net-setup_scan*.tmp >/dev/null 2>&1
		iwlist "$INTERFACE" scan >/tmp/net-setup_scan1.tmp 2>>$DEBUG_OUTPUT
		echo "X"
		
		#SCANALL=$(iwlist "$INTERFACE" scan 2>>$DEBUG_OUTPUT)
		sleep 1
		iwlist "$INTERFACE" scan >/tmp/net-setup_scan2.tmp 2>>$DEBUG_OUTPUT
		echo "X"

		ScanListFile=$(du -b /tmp/net-setup_scan*.tmp |sort -n | tail -n1 |cut -f2)
		echo "$ScanListFile" > /tmp/net-setup_scanlistfile
		grep -Eo 'Cell [0-9]+|Signal level=-*[0-9]+ dBm' $ScanListFile | sed -e '/Cell / {;N;s/Cell \([0-9][0-9]*\).*=\([0-9-][0-9]*\).*/\1@\2/;}' > /tmp/net-setup_cell_signal.tmp #170622
		#if [ -z "$SCAN_LIST" ]; then
		if [ ! -s /tmp/net-setup_cell_signal.tmp ]; then #170622
			# Dougal: a little awkward... want to give an option to reset pcmcia card
			FI_DRIVER=$(readlink /sys/class/net/$INTERFACE/device/driver)
			if [ "$1" = "retry" ] ; then # we're on the second try already
				createNoNetworksDialog
			elif [ -n "$IsPCMCIA" ] ; then
				createRetryPCMCIAScanDialog
			else
				createRetryScanDialog
			fi
		else
			# give each Cell its own button
			CELL_LIST="$(sort -g -r -t @ -k 2 /tmp/net-setup_cell_signal.tmp)" #170622
			for CELL in $(echo "$CELL_LIST" | cut -f 1 -d '@') ; do #170622
				#getCellParameters $CELL
				Get_Cell_Parameters $CELL
				[ -z "$CELL_ESSID" ] && CELL_ESSID="(hidden ESSID)"
				SCANWINDOW_BUTTONS="$SCANWINDOW_BUTTONS \"$CELL\" \"$CELL_ESSID (${CELL_MODE}; ${L_SCANWINDOW_Encryption}$CELL_ENC_TYPE)\" off \"${L_SCANWINDOW_Channel}${CELL_CHANNEL}; ${L_SCANWINDOW_Frequency}${CELL_FREQ}; ${L_SCANWINDOW_AP_MAC}${CELL_AP_MAC};
${L_SCANWINDOW_Strength}${CELL_QUALITY}\"" 
			done
			echo "Xdialog --left --no-tags --item-help --stdout --title \"$L_TITLE_Puppy_Network_Wizard\" --radiolist \"$L_TEXT_Scanwindow\"  20 60 4  \
	${SCANWINDOW_BUTTONS} 2> /dev/null" > /tmp/net-setup_scanwindow #170622
		fi
		echo "X"
	)  | gtkdialog --program=NETWIZ_Scan_Progress_Dialog >/dev/null
	clean_up_gtkdialog NETWIZ_Scan_Progress_Dialog
	
	#SCAN_LIST="$(cat /tmp/net-setup_scanlist)"
	read ScanListFile < /tmp/net-setup_scanlistfile
	# run ifconfig down/up, as apparently it is needed for actually configuring to work properly...
	ifconfig "$INTERFACE" down
	ifconfig "$INTERFACE" up
} #end of buildScanWindow

#=============================================================================
createNoNetworksDialog(){
  echo 'clean_up_gtkdialog(){
 [ "$1" ] || return
 for I in $(ps -fC gtkdialog | grep "$1" | tr -s ' ' | cut -f 2 -d ' ' | tr '\n' ' ')
 do kill $I
 done 
}

export NETWIZ_SCAN_ERROR_DIALOG="<window title=\"'"$L_TITLE_Puppy_Network_Wizard"'\" icon-name=\"gtk-dialog-warning\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\">
      <input file stock=\"gtk-dialog-warning\"></input>
    </pixmap>
  <text>
    <label>\"'"$L_TEXT_No_Networks_Detected"'\"</label>
  </text>
  <hbox>
    <button ok></button>
  </hbox>
 </vbox>
</window>"

gtkdialog --program NETWIZ_SCAN_ERROR_DIALOG
clean_up_gtkdialog NETWIZ_SCAN_ERROR_DIALOG
exit 0
' > /tmp/net-setup_scanwindow #170504
}

#=============================================================================
createRetryScanDialog(){
    echo 'clean_up_gtkdialog(){
 [ "$1" ] || return
 for I in $(ps -fC gtkdialog | grep "$1" | tr -s ' ' | cut -f 2 -d ' ' | tr '\n' ' ')
 do kill $I
 done 
}

export NETWIZ_SCAN_ERROR_DIALOG="<window title=\"'"$L_TITLE_Puppy_Network_Wizard"'\" icon-name=\"gtk-dialog-warning\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\">
      <input file stock=\"gtk-dialog-warning\"></input>
    </pixmap>
  <text>
    <label>\"'"$L_TEXT_No_Networks_Retry"'\"</label>
  </text>  
  <hbox>
    <button>
      <label>'"$L_BUTTON_Retry"'</label>
      <input file stock=\"gtk-redo\"></input>
      <action>EXIT:retry</action>
    </button>
    <button cancel></button>
  </hbox>
 </vbox>
</window>"

I=$IFS; IFS=""
for STATEMENT in  $(gtkdialog --program NETWIZ_SCAN_ERROR_DIALOG); do
	eval $STATEMENT
done
IFS=$I
clean_up_gtkdialog NETWIZ_SCAN_ERROR_DIALOG

case $EXIT in
Cancel) exit 0 ;;
retry) exit 111 ;;
esac
' > /tmp/net-setup_scanwindow #170504
}

#=============================================================================
createRetryPCMCIAScanDialog(){
  echo 'clean_up_gtkdialog(){
 [ "$1" ] || return
 for I in $(ps -fC gtkdialog | grep "$1" | tr -s ' ' | cut -f 2 -d ' ' | tr '\n' ' ')
 do kill $I
 done 
}

export NETWIZ_SCAN_ERROR_DIALOG="<window title=\"'"$L_TITLE_Puppy_Network_Wizard"'\" icon-name=\"gtk-dialog-warning\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\">
      <input file stock=\"gtk-dialog-warning\"></input>
    </pixmap>
  <text>
    <label>\"'"$L_TEXT_No_Networks_Retry_Pcmcia"'\"</label>
  </text>
  <hbox>
    <button>
      <label>'"$L_BUTTON_Retry"'</label>
      <input file stock=\"gtk-redo\"></input>
      <action>EXIT:retry</action>
    </button>
    <button cancel></button>
  </hbox>
 </vbox>
</window>"

I=$IFS; IFS=""
for STATEMENT in  $(gtkdialog --program NETWIZ_SCAN_ERROR_DIALOG); do
	eval $STATEMENT
done
IFS=$I
clean_up_gtkdialog NETWIZ_SCAN_ERROR_DIALOG

case $EXIT in
Cancel) exit 0 ;;
retry) exit 101 ;;
esac
' > /tmp/net-setup_scanwindow #170504
}

#=============================================================================
# Dougal: put this into a function, so we can use it at boot time
# (note that it echoes Xs for the progress bar)
runPrismScan()
{
	INTERFACE="$1"
	# enable interface
	wlanctl-ng "$INTERFACE" lnxreq_ifstate ifstate=enable >/tmp/wlan-up 2>&1
	# scan (first X echoed only afterwards!
	wlanctl-ng "$INTERFACE" dot11req_scan bsstype=any \
	 bssid=ff:ff:ff:ff:ff:ff ssid="" scantype=both \
	  channellist="00:01:02:03:04:05:06:07:08:09:0a:0b:00:00" \
	   minchanneltime=200 maxchanneltime=250 >/tmp/prism-scan-all 2>/dev/null
	echo "X"
	# get number of access points (make sure we get integer)
	POINTNUM=$(grep -F 'numbss=' /tmp/prism-scan-all 2>/dev/null | cut -d= -f2 | grep [0-9])
	rm /tmp/prism-scan-all >/dev/null 2>&1
	## Dougal: not sure about this -- need a way to make sure we get something
	#if grep -F 'resultcode=success' /tmp/prism-scan-all ; then
	if [ "$POINTNUM" ] ; then
	  # get scan results for all access points
	  for P in $(seq 0 $POINTNUM)
	  do
	    wlanctl-ng "$INTERFACE" dot11req_scan_results bssindex=$P >/tmp/prism-scan$P 2>/dev/null
	  done
	  echo "X"
	else # let us know it failed
	  return 1
	fi
	return 0
}
#=============================================================================
buildPrismScanWindow()
{
  SCANWINDOW_BUTTONS=""
  (
	# do a cleanup first (raises interface, so need to put it down after)
	cleanUpInterface "$INTERFACE" >> $DEBUG_OUTPUT 2>&1
	ifconfig "$INTERFACE" down
	if runPrismScan "$INTERFACE" ; then
	  # create buttons (POINTNUM set in function)
	  for P in $(seq 0 $POINTNUM)
	  do
	    grep -Fq 'resultcode=success' /tmp/prism-scan$P || continue
	    getPrismCellParameters $P
	    [ "$CELL_ESSID" = "" ] && CELL_ESSID="$L_SCANWINDOW_Hidden_SSID"
		# might add test here for some params, then maybe skip
		SCANWINDOW_BUTTONS="${SCANWINDOW_BUTTONS} \"$P\" \"${CELL_ESSID} (${CELL_MODE}; ${L_SCANWINDOW_Encryption}${CELL_ENCRYPTION})\" off \"${L_SCANWINDOW_Channel}${CELL_CHANNEL}; ${L_SCANWINDOW_AP_MAC}${CELL_AP_MAC}\"" 
	  done
	else
	  echo "X"
	fi
	if [ "$SCANWINDOW_BUTTONS" ] ; then
		echo "Xdialog --left --item-help --stdout --title \"$L_TITLE_Puppy_Network_Wizard\" --radiolist \"$L_TEXT_Prism_Scan\"  20 60 4  \
	${SCANWINDOW_BUTTONS} 2> /dev/null" > /tmp/net-setup_scanwindow
	else
	  #echo "Xdialog --left --title \"Puppy Network Wizard:\" --msgbox \"No networks detected\" 0 0 " > /tmp/net-setup_scanwindow
	  if [ "$1" = "retry" ] ; then # we're on the second try already
	  	createNoNetworksDialog
	  elif [ -n "$IsPCMCIA" ] ; then
		createRetryPCMCIAScanDialog
	  else
		createRetryScanDialog
	  fi
	fi
	echo "X"
  )  | gtkdialog --program=NETWIZ_Scan_Progress_Dialog >/dev/null
	# clean up
	clean_up_gtkdialog NETWIZ_Scan_Progress_Dialog
	
} #end of buildPrismScanWindow

#=============================================================================
setupScannedProfile()
{
	setupNewProfile
	if [ "$USE_WLAN_NG" = "yes" ] ; then
	  getPrismCellParameters $CELL
	  # clean up from earlier
	  rm -f /tmp/prism-scan*
	else
	  #getCellParameters $CELL
	  Get_Cell_Parameters $CELL
	fi
	# Dougal: setupNewProfile always sets PROFILE_MODE to "ad-hoc"!
	case "$CELL_MODE" in
	  Managed|infrastructure) PROFILE_MODE="managed" ;;
	  Ad-Hoc) PROFILE_MODE="ad-hoc" ;;
	esac
	PROFILE_ESSID="$CELL_ESSID"
	PROFILE_TITLE="$CELL_ESSID"
	PROFILE_FREQ="$CELL_FREQ"
	PROFILE_CHANNEL="$CELL_CHANNEL"
	PROFILE_AP_MAC="$CELL_AP_MAC"

	case $CELL_ENCRYPTION in 
	  on|true) PROFILE_KEY="$L_TEXT_Provide_Key" ;;
	  *) PROFILE_KEY="" ;;
	esac
	# Dougal: add this, so it defaults to "broadcast SSID" if we have an SSID...
	# add always using 2 with ndiswrapper
	if [ -n "$PROFILE_ESSID" -a "$INTMODULE" != "ndiswrapper" ] ;then
	  PROFILE_WPA_AP_SCAN="1"
	else
	  PROFILE_WPA_AP_SCAN="2"
	fi
} # end of setupScannedProfile

#=============================================================================
getCellParameters()
{
	CELL=$1
	# Dougal: try and get exactly everything matching our cell
	START=$(echo "$SCAN_LIST" | grep -F -n "Cell $CELL" |cut -d: -f1)
	NEXT=$(expr $CELL + 1)
	[ ${#NEXT} -lt 2 ] && NEXT="0$NEXT"
	END=$(echo "$SCAN_LIST" | grep -F -n "Cell $NEXT" |cut -d: -f1)
	# there might not be one...
	if [ "$END" ] ; then
	  END=$((END-1))
	else
	  END=$(echo "$SCAN_LIST" | wc -l)
	fi
	SCAN_CELL=$(echo "$SCAN_LIST" | sed -n "${START},${END}p")
	CELL_ESSID=$(echo "$SCAN_CELL" | grep -E -o 'ESSID:".+"' | grep -E -o '".+"' | grep -E -o '[^"]+')
	[ "$CELL_ESSID" = "<hidden>" ] && CELL_ESSID=""
	CELL_FREQ=$(echo "$SCAN_CELL" | grep "Frequency" | grep -Eo '[0-9]+\.[0-9]+ +G' | sed -e 's/ G/G/') 
	CELL_CHANNEL=$(echo "$SCAN_CELL" | grep "Frequency" | grep -Eo 'Channel [0-9]+' | cut -f2 -d" ")
	[ ! "$CELL_CHANNEL" ] && CELL_CHANNEL=$(echo "$SCAN_CELL" | grep -F 'Channel:' | grep -Eo [0-9]+)
	# Dougal: below was 'cut -d":" -f2-' 
	CELL_QUALITY=$(echo "$SCAN_CELL" | grep 'Quality=' | cut -d'=' -f2 | cut -d' ' -f1)
	[ ! "$CELL_QUALITY" ] && CELL_QUALITY=$(echo "$SCAN_CELL" | grep "Quality" | tr -s ' ')
	CELL_AP_MAC=$(echo "$SCAN_CELL" | grep -E -o '[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}')
	CELL_MODE=$(echo "$SCAN_CELL" | grep -o 'Mode:Managed\|Mode:Ad-Hoc\|Mode:Master' | cut -d":" -f2)
	CELL_ENCRYPTION=$(echo "${SCAN_CELL}" | grep -F 'Encryption key:' | cut -d: -f2 | tr -d ' ')
	CELL_ENC_TYPE="$CELL_ENCRYPTION"
} # end of getCellParameters

#=============================================================================
# a modified version of the above, that uses a file rather than SCAN_LIST
## it sexpects the variable ScanListFile to be set (file containing scan output)
Get_Cell_Parameters(){
	# Dougal: try and get exactly everything matching our cell
	START=$(grep -F -n "Cell $1" $ScanListFile |cut -d: -f1)
    # remove the 0 from the cell number, so the shell won't think it's hex or something
	case $1 in
	 0[1-9]) Acell=${1#0} ;;
	 *) Acell=$1 ;;
	esac
	NEXT=$((Acell+1))
	[ ${#NEXT} -lt 2 ] && NEXT="0$NEXT"
	END=$(grep -F -n "Cell $NEXT" $ScanListFile |cut -d: -f1)
	# there might not be one...
	if [ -n "$END" ] ; then
	  END=$((END-1))
	else
	  END=$(wc -l $ScanListFile | awk '{print $1}')
	fi
	SCAN_CELL=$(sed -n "${START},${END}p" $ScanListFile)
	CELL_ESSID=$(echo "$SCAN_CELL" | grep -E -o 'ESSID:".+"' | grep -E -o '".+"' | grep -E -o '[^"]+')
	[ "$CELL_ESSID" = "<hidden>" ] && CELL_ESSID=""
	CELL_FREQ=$(echo "$SCAN_CELL" | grep "Frequency" | grep -Eo '[0-9]+\.[0-9]+ +G' | sed -e 's/ G/G/') 
	CELL_CHANNEL=$(echo "$SCAN_CELL" | grep "Frequency" | grep -Eo 'Channel [0-9]+' | cut -f2 -d" ")
	[ -z "$CELL_CHANNEL" ] && CELL_CHANNEL=$(echo "$SCAN_CELL" | grep -F 'Channel:' | grep -Eo [0-9]+)
	# Dougal: below was 'cut -d":" -f2-' 
	CELL_QUALITY=$(echo "$SCAN_CELL" | grep 'Quality=' | cut -d'=' -f2 | cut -d' ' -f1)
	[ -z "$CELL_QUALITY" ] && CELL_QUALITY=$(echo "$SCAN_CELL" | grep "Quality" | tr -s ' ')
	CELL_AP_MAC=$(echo "$SCAN_CELL" | grep -E -o '[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}')
	CELL_MODE=$(echo "$SCAN_CELL" | grep -o 'Mode:Managed\|Mode:Ad-Hoc\|Mode:Master' | cut -d":" -f2)
	CELL_ENCRYPTION=$(echo "${SCAN_CELL}" | grep -F 'Encryption key:' | cut -d: -f2 | tr -d ' ')
	CELL_ENC_TYPE="$CELL_ENCRYPTION"
	
} # end of Get_Cell_Parameters
#=============================================================================

getPrismCellParameters()
{
	CELL=$1
	CELL_ESSID=$(grep -F 'ssid=' /tmp/prism-scan$CELL | grep -v 'bssid=' | cut -d"'" -f2) 
	CELL_CHANNEL=$(grep -F 'dschannel=' /tmp/prism-scan$CELL | cut -d= -f2)
	## Dougal: not sure about this: maybe skip ones without anything?
	CELL_AP_MAC=$(grep -F 'bssid=' /tmp/prism-scan$CELL | cut -d= -f2 | grep -E  '[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}')
	## Dougal: might need to do something to fit this to checkboxes
	CELL_MODE=$(grep -F 'bsstype=' /tmp/prism-scan$CELL | cut -d= -f2)
	## Dougal: maybe do something with "no_value"
	CELL_ENCRYPTION=$(grep -F 'privacy=' /tmp/prism-scan$CELL | cut -d= -f2)
} # end of getPrismCellParameters

#=============================================================================
#=============== START OF SCRIPT BODY ====================
#=============================================================================

# If ran by itself it shows the interface, Otherwise it's only used as a function library
CURRENT_CONTEXT=$(expr "$0" : '.*/\(.*\)$' )
if [ "${CURRENT_CONTEXT}" = "wag-profiles.sh" ] ; then
	INTERFACE="$1"
	DEBUG_OUTPUT="/dev/stderr"
	showProfilesWindow "$1"
fi 
#DEBUG_OUTPUT="/dev/stdout"
[ ! "${DEBUG_OUTPUT}" ] && DEBUG_OUTPUT="/dev/null"

#=============================================================================
#=============== END OF SCRIPT BODY ====================
#=============================================================================

