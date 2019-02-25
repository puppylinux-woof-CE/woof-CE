#!/bin/bash
#(c) copyright Barry Kauler 2004 www.puppylinux.org
#Puppy ethernet network setup script.
#I got some bits of code from:
# trivial-net-setup, by Seth David Schoen <schoen@linuxcare.com> (c)2002
# Thanks to GuestToo and other guys on the Puppy Forum for bug finding.
# Rarsa (Raul Suarez) reorganized the code and cleaned up the user interface
# Ported to gtkdialog3 and abused by Dougal, June 2007
# Update: Jul.  4th: redesign main dialog, change "Load module" dialog
# Update: Jul. 10th: change INTERFACEBUTTONS format, add findInterfaceInfo function
# Update: Jul. 11th: move findLoadedModules into tryLoadModule
# Update: Jul. 12th: move "save" and "unload" buttons out of main dialog
# Update: Jul. 13th: add "sleep 3" after loading usb modules, fixed bug in findInterfaceInfo
# Update: Jul. 13th: fix problem with tree height
# Update: Jul. 19th: add recognition of prism2_usb interfaces as wireless
# Update: Aug.  1st: fix spelling...
# Update: Dec. 30th: add "-I ''" to lines 840 and 863 to fix Rerwin's problem)
# Update: Mar. 2008: squash dialogs down a bit
# Update: Jun. 25th: add some updates from Barry's version:
#						- ndiswrapper check for native module already loaded
#						- compat for dhcpcd using /var
#						- ndiswrapper mention in text for "load module" button
#					 also improve finding device-info
# Update: Jun. 29th: add check for /sys/class/net/$INTERFACE/wireless (in checkIfIsWireless)
# Update: Jul.  6th: add use of cleanUpInterface
# Update: Jul.  7th: cancel the cd into APPDIR!
# Update: Jul. 10th: disable all the usb-autoloading code -- udev handles it
# Update: Jul. 10th: add cleanUpTmp
# Update: Jul. 15th: convert to new config setup
# Update: Jul. 20th: try and add support for static ip with wireless
# Update: Jul. 23rd: add message for failed wireless profile config
#					 change DEBUG_OUTPUT for the debug case to stderr
# Update: Jul. 27th: remove usage of lspci from pcmcia check
#					 find info on usb devices directly from /sys
# Update: Jul. 28th: add getting interface info from module, if none found otherwise
# Update: Jul. 30th: change redirection to DEBUG_OUTPUT to _append_
# Update: Aug.  1st: move configuration files into /etc/network-wizard
# Update: Aug. 18th: reinstate IS_WIRELESS, needed for message in testInterface, also add to config file
# Update: Aug. 23rd: add use of killDhcpcd
# Update: Sep.  1st: add firewire code
# Update: Sep.  3rd: add blanking of gateway if it's 0.0.0.0
#					 fix one nameserver being read twice in showStaticIPWindow
# Update: Sep.  4th: if user blanked dns servers, set them to 0.0.0.0
# Update: Sep. 15th: disable bringing interface down/up when setting static ip
#					 add "dev $INTERFACE" to route commands
# Update: Sep. 16th: add clean_up_gtkdialog support and rename dialog variables
#					 replace all `` subshells with $()
# Update: Sep. 18th: add "non-Vista" comment for Ndiswrapper button.
# Update: Sep. 24th: kill dhcpcd if it returns error!
#					 move setupDHCP over to wag-profiles.sh, so it can be used by rc.network
# Update: Sep. 28th: add unloadSpecificModule: "Unload" button in "Load Module" dialog
# Update: Sep. 30th: rewrite loadSpecificModule in gtkdialog
#					 change tryLoadModule to recognize module params and add ERROR display 
#					 change various error messages to use giveErrorDialog+ERROR
# Update: Oct.  5th: add askWhichInterfaceForNdiswrapper and offerToBlacklistModule
#					 move ndiswrapper to a separate tab in the "Load module" dialog
# Update: Oct. 22nd: add Barry's code to clean up old-wizard config files
# Update: Oct. 23rd: in showLoadModuleWindow, add sleeping up to 10sec to wait for new int.
#					 add blacklist_module, to handle adding module to skiplist
#					 remove the "dev..." from the end of route commands...
# Update: Oct. 25th: start localizing
# Update: Oct. 26th: finish localizing
#					 add giveAcxDialog, to offer the user to blacklist rather than unload
# Update: Oct. 28th: tidy up the code for finding new interfaces
# Update: Oct. 31st: check for locale files both of type "ab_CD" and "ab"
# Update: Nov.  7th: add deleting old backups of resolve.conf
# Update: Feb. 8th 2009: Clean up static ip info from profile if changed (PaulBx1 suggested)
# Update: Feb. 22nd: change the backing up of resolve.conf so it only saves as resolv.conf.old
# Update: Mar. 19th: add wireless scan files to cleanUpTmp, change shebang to bash
# Update: Apr.  1st: improve finding of usb device info from /sys
#111015 BK: strip out chars that might upset gtkdialog.
#170329 rerwin: set as current network exec, retaining previous exec name.
#170509 rerwin: replace gtkdialog3 with gtkdialog.
#170514 add message about already running
#180923 v2.0:  move network wizard to its package directory.
#190213 replace functions validip with validip4, dotquad with ip2dec.
#190217 v2.1: shorten wait after link timeout; remember choice of interface for boot-up; stop interfaces other than that selected, before starting selected interface; separate 'running' test and 'current exec' logic, so exec change avoided if main window aborted (X); refine 'already running' dialog & add to locale files.
#190223 v2.1.1: Avoid exec change on exiting if no interface buttons used.

# $1: interface
interface_is_wireless() {
	if [ ! "$1" ] ; then
		return 1 #error
	fi
	if grep -q "${1}:" /proc/net/wireless ; then
		return 0 #yes
	fi
	if [ -d /sys/class/net/${1}/wireless ] ; then
		return 0 #yes
	fi
	# k3.2.x: my problematic wireless pci adapter is only recognized by iwconfig..
	# hmm with 2 pci wireless adapters only iwconfig does the trick
	if iwconfig ${1} 2>&1 | grep -q 'no wireless' ; then
		return 1 #no
	fi
	return 0 #yes
}

if [ -d /usr/local/network-wizard ] ; then #180923...
	APPDIR='/usr/local/network-wizard'
else
	APPDIR="$(dirname $0)"
	[ "$APPDIR" = "." ] && APPDIR="$(pwd)"
fi

# Dougal: add localization
mo=net-setup.mo
#lng=${LANG%.*}
# always start by sourceing the English version (to fill in gaps)
. "/usr/share/locale/en/LC_MESSAGES/$mo"
if [ -f "/usr/share/locale/${LANG%.*}/LC_MESSAGES/$mo" ];then
  . "/usr/share/locale/${LANG%.*}/LC_MESSAGES/$mo"
elif [ -f "/usr/share/locale/${LANG%_*}/LC_MESSAGES/$mo" ];then
  . "/usr/share/locale/${LANG%_*}/LC_MESSAGES/$mo"
fi

# Check if output should go to the console
if [ "${1}" = "-d" ] ; then
	DEBUG_OUTPUT=/dev/stderr
else
	DEBUG_OUTPUT=/dev/null
fi

if [ ! -f /tmp/services/networkmodules -a ! -f /tmp/networkmodules ] ; then #compatability
	updatenetmoduleslist.sh
fi
[ -d /tmp/services ] && TMPDIR=/tmp/services || TMPDIR=/tmp #compatability

# basic configuration info for interface
# named $HWADDRESS.conf (assuming the HWaddress is more unique than interface name...)
# mainly intended to know if interface has been "configured"...
NETWORK_INTERFACES_DIR='/etc/network-wizard/network/interfaces'
[ -d $NETWORK_INTERFACES_DIR ] || mkdir -p $NETWORK_INTERFACES_DIR

# file used to list blacklisted modules
#BLACKLIST_FILE="/etc/rc.d/blacklisted-modules.$(uname -r)"

#  Dougal: need some elegant way to find out if we're running from X
#+ (pidof X isn't good, since we might be running in the background at boot...)
# for now, just set it from here (wag-profiles isn't really used alone)
HAVEX='yes'

## Dougal: put this into a variable
BLANK_IMAGE=/usr/share/pixmaps/net-setup_btnsize.png

#==================================================================

### $1:ipv4
function ip2dec() { #ip to decimal
	local a b c d ip=$@
	IFS=. read -r a b c d <<< "$ip"
	printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))" #return value
}

### $1:ipv4
function validip4() { #replace dotquad.c to parse $1 as a dotted-quad IP address
	local ip=$1
	local stat=1
	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
			&& ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi
	return $stat
}

#=============================================================================
#============= FUNCTIONS USED IN THE SCRIPT ==============
#=============================================================================
. ${APPDIR}/ndiswrapperGUI.sh
. ${APPDIR}/wag-profiles.sh

showMainWindow()
{
	MAIN_RESPONSE=""

	while true
	do

		buildMainWindow

		I=$IFS; IFS=""
		for STATEMENT in  $(gtkdialog --program NETWIZ_Main_Window); do
			eval $STATEMENT 2>/dev/null
		done
		IFS=$I
		clean_up_gtkdialog NETWIZ_Main_Window
		unset NETWIZ_Main_Window

		# Dougal: this is simpler than all the grep business.
		# Could integrate into main case-structure, but not sure about MAIN_RESPONSE
		case "$EXIT" in 
		  Interface_*) INTERFACE=${EXIT#Interface_} ; MAIN_RESPONSE=13 ;;
		  *) MAIN_RESPONSE=${EXIT} ;;
		esac
		
		# Dougal: blank the "Done" button, in case we go to 13 and back
		DONEBUTTON=""
			
		case $MAIN_RESPONSE in
			10) showLoadModuleWindow ;;
			17) saveNewModule ;;
			18) unloadNewModule ;;
			19) break ;;
			13) which connectwizard_exec &>/dev/null \
				  && connectwizard_exec net-setup.sh #190217
				local HWADDRESS=$(ifconfig "$INTERFACE" | grep "^$INTERFACE" | tr -s ' ' | cut -d' ' -f5) #190217
				ln -snf $HWADDRESS.conf ${NETWORK_INTERFACES_DIR}/selected_conf #190217
				showConfigureInterfaceWindow "$INTERFACE" ;;
			66) AutoloadUSBmodules ;;
			#21) showHelp  ;;
			abort) break ;;
		esac

	done

} # end of showMainWindow

#=============================================================================
getInterfaceList(){
  #we need to know what ethernet interfaces are there...
  INTERFACE_NUM=$(ifconfig -a | grep -Fc 'Link encap:Ethernet')
  INTERFACES="$(ifconfig -a | grep -F 'Link encap:Ethernet' | cut -f1 -d' ' | tr '\n' ' ')"
  # Dougal: this is for ethernet-over-firewire
  for ONE in $(grep -w 24 /sys/class/net/*/type | cut -d '/' -f5) ; do
    case $INTERFACES in *$ONE*) continue ;; esac
    INTERFACES="$INTERFACES $ONE"
    INTERFACE_NUM=$((INTERFACE_NUM+1))
  done
  INTERFACEBUTTONS=""
  INTERFACE_DATA=""
}

#=============================================================================
refreshMainWindowInfo ()
{
  # Dougal: comment out and move to the showLoadModuleWindow -- only used there...
  #findLoadedModules
  getInterfaceList

  for INTERFACE in $INTERFACES
  do
    [ "$INTERFACE" ] || continue
    # Dougal: use function for finding/setting info to be used in tree (below) 
    findInterfaceInfo "$INTERFACE"
    
    ## Dougal: use a tree to display interface info
    INTERFACE_DATA="$INTERFACE_DATA <item>$INTERFACE|$INTTYPE|$FI_DRIVER|$TYPE: $INFO</item>"
    # add to display list
    INTERFACEBUTTONS="
${INTERFACEBUTTONS}
<vbox>
	<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	<button>
		<label>${INTERFACE}</label>
		<action>EXIT:Interface_${INTERFACE}</action>
	</button>	
</vbox>"
  done

  if [ "$INTERFACE_DATA" ] ; then
    # Get the right height for the tree...
    case "$INTERFACE_NUM" in
     1) HEIGHT=70 ;;
     2) HEIGHT=100 ;;
     3) HEIGHT=125 ;;
     4) HEIGHT=150 ;;
     5) HEIGHT=175 ;;
     6) HEIGHT=200 ;;
    esac
    INTERFACEBUTTONS="
    <tree>
    	<label>$L_LABEL_Interface_Tree_Header</label>
    	$INTERFACE_DATA
    	<height>$HEIGHT</height><width>350</width>
    	<variable>SELECTED_INTERFACE</variable>
  	</tree>
  	<hbox>
  		$INTERFACEBUTTONS
  	</hbox>"
  fi

  case $INTERFACE_NUM in 
    0) # no interfaces
      echo "$L_ECHO_No_Interfaces_Message" > /tmp/net-setup_MSGINTERFACES.txt
      ;;
    1) # only one
      echo "$L_ECHO_One_Interface_Message"  > /tmp/net-setup_MSGINTERFACES.txt
      ;;
    *) # more than one interface
      echo "$L_ECHO_Multiple_Interfaces_Message"  > /tmp/net-setup_MSGINTERFACES.txt
      ;;
  esac

} # end refreshMainWindowInfo

#=============================================================================
buildMainWindow ()
{
	echo "${TOPMSG}" > /tmp/net-setup_TOPMSG.txt


	export NETWIZ_Main_Window="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
<vbox>
	
	<text><label>\"$(cat /tmp/net-setup_TOPMSG.txt)\"</label></text>	
	<frame  $L_FRAME_Interfaces >
		<vbox>
			<text>
				<label>\"$(cat /tmp/net-setup_MSGINTERFACES.txt)\"</label>
			</text>
			
			${INTERFACEBUTTONS}
		</vbox>
	</frame>
	
	<frame  $L_FRAME_Network_Modules >
	  ${USB_MODULE_BUTTON}
	  ${MODULEBUTTONS}
	</frame>
	<hbox>
		<button help>
			<action>$HELP_COMMAND > /dev/null 2>&1 & </action>
		</button>
		<button>
			 <label>$L_BUTTON_Exit</label>
			 <input file stock=\"gtk-quit\"></input>
			 <action>EXIT:19</action>
		</button>
	</hbox>
</vbox>
</window>"
}

#=============================================================================
showLoadModuleWindow()
{
  findLoadedModules
  echo -n "" > /tmp/ethmoduleyesload.txt
  # Dougal: create list of modules (pipe delimited)
  sort $TMPDIR/networkmodules | tr '"' '|' | tr ':' '|' | sed 's%|$%%g' | tr -s ' ' >/tmp/module-list

  export NETWIZ_LOAD_MODULE_DIALOG="<window title=\"$L_TITLE_Load_Network_Module\" icon-name=\"gtk-execute\" window-position=\"1\">
<vbox>
 <notebook labels=\"$L_NOTEBOOK_Modules_Header\">
  <vbox>
   <pixmap><input file>$BLANK_IMAGE</input></pixmap>
   <hbox>
    <text><label>\"$L_TEXT_Select_Module_Tab\"</label></text>
    <text><label>\"     \"</label></text>
    <vbox>
     <pixmap><input file>$BLANK_IMAGE</input></pixmap>
     <button>
   	  <label>$L_BUTTON_Load</label>
	  <input file stock=\"gtk-apply\"></input>
	  <action>EXIT:load</action>
     </button>
    </vbox>
   </hbox>
   <pixmap><input file>$BLANK_IMAGE</input></pixmap>
   <tree>
    <label>$L_LABEL_Module_Tree_Header</label>
    <input>cat /tmp/module-list</input>
    <height>200</height><width>550</width>
    <variable>NEW_MODULE</variable>
   </tree>
  </vbox>
  
  <vbox>
   <text><label>\"     \"</label></text>

    <text use-markup=\"true\">
     <label>\"$L_TEXT_Ndiswrapper_Tab\"</label>
    </text>
    <text>
     <label>\"     \"</label>
    </text>
	<hbox>
	 <button>
	  <label>$L_BUTTON_Use_Ndiswrapper</label>
	  <input file stock=\"gtk-execute\"></input>
	  <action>EXIT:ndiswrapper</action>
     </button>
    </hbox>
  </vbox>
  
  <vbox>
   <text><label>\"     \"</label></text>
   <hbox>
    <text use-markup=\"true\">
     <label>\"$L_TEXT_More_Tab\"</label>
    </text>
    <text>
     <label>\"     \"</label>
    </text>
    <vbox>
     <text>
      <label>\"     \"</label>
     </text>
     <button>
	  <label>$L_BUTTON_Specify</label>
	  <input file stock=\"gtk-index\"></input>
	  <action>EXIT:specify</action>
     </button>
     <button>
	  <label>$L_BUTTON_Unload</label>
	  <input file stock=\"gtk-undo\"></input>
	  <action>EXIT:unload</action>
     </button>
     <button>
	  <label>$L_BUTTON_Autoprobe</label>
	  <input file stock=\"gtk-refresh\"></input>
	  <action>EXIT:auto</action>
     </button>
    </vbox>
   </hbox>
  </vbox>
  
  </notebook>
  <hbox>
   <button cancel></button>
  </hbox> 
 </vbox>
</window>"

  I=$IFS; IFS=""
  for STATEMENT in  $(gtkdialog --program NETWIZ_LOAD_MODULE_DIALOG); do
	eval $STATEMENT 2>/dev/null
  done
  IFS=$I
  clean_up_gtkdialog NETWIZ_LOAD_MODULE_DIALOG
  unset NETWIZ_LOAD_MODULE_DIALOG
  
  case "$EXIT" in
    auto)	autoLoadModule ;;
    unload)	unloadSpecificModule ; showLoadModuleWindow ;  return ;;
    ndiswrapper)	loadNdiswrapperModule ;;
    specify)	loadSpecificModule ;;
    load)	if [ "$NEW_MODULE" ] ; then
    		  tryLoadModule "$NEW_MODULE"
    		else
    		  TOPMSG="$L_TOPMSG_Load_Module_None_Selected" 
    		fi ;;
    cancel) TOPMSG="$L_TOPMSG_Load_Module_Cancel"  ;;
  esac

  #NEWLOADED="$(cat /tmp/ethmoduleyesload.txt)"
  #NEWLOADf1=${NEWLOADED%% *} #remove any extra params.
  read NEWLOADED </tmp/ethmoduleyesload.txt
  NEWLOADf1=${NEWLOADED%% *}
  if [ "${NEWLOADED}" ];then
	##### add new code here: find new interface, then give window naming it
	##### and offering to save/unload
	##### ONLY AFTER that refresh main window   
	# Save the old interface list
	OLD_INTERFACES="$INTERFACES"
	OLD_NUM="$INTERFACE_NUM"
	# Dougal: add sleeping a few seconds, in case it takes time to initialize
	for i in $(seq 1 10)
	do
	  #NEW_NUM=$(ifconfig -a | grep -Fc "Link encap:Ethernet")
	  getInterfaceList
	  [ $INTERFACE_NUM -gt $OLD_NUM ] && break
	  sleep 1
	done
	
	#NEW_NUM=$(ifconfig -a | grep -Fc "Link encap:Ethernet")
	NEW_INTERFACES=""
	NEW_DATA=""
	NEW_INTERFACES_FRAME=""
	if [ $INTERFACE_NUM -gt $OLD_NUM ] ; then # got a new interface
	  DIFF=$((INTERFACE_NUM-OLD_NUM))
	  
	  #for ANEW in $(ifconfig -a | grep -F 'Link encap:Ethernet' |cut -f1 -d' ')
	  for ANEW in $INTERFACES
	  do 
	    case "$OLD_INTERFACES" in *$ANEW*) continue ;; esac
	    # If we got here, it's a new one
	    NEW_INTERFACES="$NEW_INTERFACES $ANEW"
	  done
	  
	  for ANEW in $NEW_INTERFACES
	  do
	    # get info for it
	    findInterfaceInfo $ANEW
	    # add to code for new interface dialog
	    NEW_DATA="$NEW_DATA <item>$ANEW|$INTTYPE|$FI_DRIVER|$TYPE: $INFO</item>"
	  done
	  # Set message telling about new interfaces
	  if [ $DIFF -eq 1 ] ; then
	    NEW_MESSAGE="$L_MESSAGE_One_New_Interface"
	  else
	    NEW_MESSAGE="$L_MESSAGE_Multiple_New_Interfaces"
	  fi
	  # create the frame with the new interfaces
	  case "$DIFF" in
       1) HEIGHT=65 ;;
       2) HEIGHT=100 ;;
       3) HEIGHT=125 ;;
       4) HEIGHT=150 ;;
       5) HEIGHT=175 ;;
       6) HEIGHT=200 ;;
      esac
      NEW_INTERFACES_CODE="
  <frame  $L_FRAME_New_Interfaces >
    <text><label>$NEW_MESSAGE</label></text>
    <tree>
    	<label>$L_LABEL_New_Interfaces_Tree_Header</label>
    	$NEW_DATA
    	<height>$HEIGHT</height><width>400</width>
    	<variable>SELECTED_INTERFACE</variable>
  	</tree>
  </frame>
  
    <text>
      <label>\"$L_TEXT_New_Interfaces_p1 $NEWLOADf1 $L_TEXT_New_Interfaces_p2\"</label>
    </text>
    <hbox>
	  
	  <button>
		<label>$L_BUTTON_Save</label>
		<input file stock=\"gtk-save\"></input>
		<action>EXIT:save</action>
	  </button>
    
  "
	
	else #if [ $NEW_NUM -gt $INTERFACE_NUM ] ; then
	  NEW_INTERFACES_CODE="
  <text><label>$L_TEXT_No_New_Interfaces1</label></text>
  <text><label>\" \"</label></text>
  
    <text>
      <label>\"$L_TEXT_No_New_Interfaces2\"</label>
    </text>    
    <hbox>
	  <button>
	    <label>$L_BUTTON_Unload</label>
	    <input file stock=\"gtk-undo\"></input>
	    <action>EXIT:unload</action>
	  </button>
    "
	fi #if [ $NEW_NUM -gt $INTERFACE_NUM ] 
	# give dialog with two buttons and appropriate message
	export NETWIZ_NEW_MODULE_DIALOG="<window title=\"$L_TITLE_New_Module_Loaded\" icon-name=\"gtk-execute\" window-position=\"1\">
<vbox>
  <pixmap><input file>$BLANK_IMAGE</input></pixmap>
  <text><label>\"$L_TEXT_New_Module_Loaded $NEWLOADf1\"</label></text>
  <pixmap><input file>$BLANK_IMAGE</input></pixmap>
  $NEW_INTERFACES_CODE
  
   <button cancel></button>
  </hbox> 
</vbox>
</window>"
	
	# Run new dialog
	I=$IFS; IFS=""
    for STATEMENT in  $(gtkdialog --program NETWIZ_NEW_MODULE_DIALOG); do
	  eval $STATEMENT 2>/dev/null
    done
    IFS=$I
    clean_up_gtkdialog NETWIZ_NEW_MODULE_DIALOG
    unset NETWIZ_NEW_MODULE_DIALOG
    
    # Do what we're asked
    case "$EXIT" in
     save) 
       saveNewModule 
       TOPMSG="$L_TOPMSG_New_Module_Save"
       ;;
     unload) 
       unloadNewModule 
       TOPMSG="$L_TOPMSG_New_Module_Unload"
       ;;
     *) TOPMSG="$L_TOPMSG_New_Module_Cancelled"
       ;;
    esac
	
	# refresh main
	refreshMainWindowInfo
	# set new message for main dialog
	#TOPMSG="REPORT ON LOADING OF MODULE: Module '$NEWLOADf1' successfully loaded"
	
  else
    BGCOLOR="#ffc0c0"
    TOPMSG="$L_TOPMSG_Load_Module_None_Loaded"
  fi #if [ "${NEWLOADED}" ];then
} # end of showLoadModuleWindow

#=============================================================================
tryLoadModule ()
{
	#  Dougal: this used to be called with the argument quoted, which was
	#+ bad, since if the user specifies parameters, the grep will return 
	#+ false, while the driver might already be loaded! Trying to reload
	#+ will then not do anything, I assume... so remove quotes (in loadSpecificModule).
	MODULE_NAME="$1"
	if grep -q "$MODULE_NAME" /tmp/loadedeth.txt ; then
		Xdialog --screen-center --title "$L_TITLE_Netwiz_Hardware" \
		        --msgbox "$L_MESSAGE_Driver_Loaded" 0 0
		echo -n "${MODULE_NAME}" > /tmp/ethmoduleyesload.txt
		return 0
	else
		# Dougal: this had just "$MODULE_NAME", change to include parameters
		if ERROR=$(modprobe $@ 2>&1) ; then
			echo -n "$*" > /tmp/ethmoduleyesload.txt
			case "$NETWORK_MODULES" in *" $MODULE_NAME "*) ;;
			 *) echo "$@" >> /etc/networkusermodules ;;
			esac
			Xdialog --left --wrap --stdout --title "$L_TITLE_Netwiz_Hardware" --msgbox "$L_MESSAGE_Driver_Success_p1 $MODULE_NAME $L_MESSAGE_Driver_Success_p2" 0 0
			return 0
		else
			#Xdialog --stdout --msgbox "Loading ${MODULE_NAME} failed; try a different driver." 0 0
			giveErrorDialog "$L_MESSAGE_Driver_Failed_p1 $MODULE_NAME ${L_MESSAGE_Driver_Failed_p2}$ERROR
$L_MESSAGE_Driver_Failed_p3"
			return 1
		fi
	fi
} # end tryLoadModule

#=============================================================================
giveAcxDialog(){
	export NETWIZ_Acx_Module_Dialog="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\">
      <input file stock=\"gtk-dialog-warning\"></input>
    </pixmap>
  <text>
    <label>\"$L_TEXT_Acx_Module_p1 $1. $L_TEXT_Acx_Module_p2\"</label>
  </text>  
  <hbox>
    <button>
      <label>$L_BUTTON_Blacklist</label>
      <input file stock=\"gtk-yes\"></input>
      <action>EXIT:Blacklist</action>
    </button>
    <button>
	  <label>$L_BUTTON_Unload</label>
	  <input file stock=\"gtk-undo\"></input>
	  <action>EXIT:Unload</action>
	</button>
	<button cancel></button>
  </hbox>
 </vbox>
</window>"

    I=$IFS; IFS=""
    for STATEMENT in  $(gtkdialog --program NETWIZ_Acx_Module_Dialog); do
    	eval $STATEMENT
    done
    IFS=$I
    clean_up_gtkdialog NETWIZ_Acx_Module_Dialog
    unset NETWIZ_Acx_Module_Dialog
     
    case $EXIT in 
     Blacklist) blacklist_module "$1" ; return 1 ;;
     Unload) return 0 ;; # askWhichInterfaceForNdiswrapper will continue to unload it
    esac
    return 1
}

#=============================================================================
askWhichInterfaceForNdiswrapper(){
	TEMP=""
	for ONE in $INTERFACES
	do
	  [ "$ONE" ] || continue
	  TEMP="$TEMP
	<button>
      <label>$ONE</label>
      <action>EXIT:$ONE</action>
    </button>"  
	done
	# don't ask if there are no interfaces at all...
	[ "$TEMP" ] || return 0
	
	export NETWIZ_Select_Ndiswrapper_Interface_Dialog="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\">
      <input file stock=\"gtk-dialog-question\"></input>
    </pixmap>
  <text use-markup=\"true\">
    <label>\"$L_TEXT_Ask_Which_Interface_For_Ndiswrapper\"</label>
  </text>  
  <hbox>
    $TEMP
    <button>
      <label>$L_BUTTON_None</label>
      <action>EXIT:none</action>
    </button>
    <button cancel></button>
  </hbox>
 </vbox>
</window>"

	I=$IFS; IFS=""
	for STATEMENT in  $(gtkdialog --program NETWIZ_Select_Ndiswrapper_Interface_Dialog); do
	eval $STATEMENT
	done
	IFS=$I
	clean_up_gtkdialog NETWIZ_Select_Ndiswrapper_Interface_Dialog
	unset NETWIZ_Select_Ndiswrapper_Interface_Dialog
	
	case $EXIT in 
	 none) return 0 ;;
	 Cancel|abort) return 1 ;;
	esac
	# if we got here, it's an interface
	AMOD=$(readlink /sys/class/net/$EXIT/device/driver/module)
	AMOD=${AMOD##*/}
	AMOD=${AMOD//_/-}
	#echo $AMOD
	##  Need to have an exception for the acx modules, since unloading them
	##+ causes the kernel to become unstable
	case $AMOD in acx*) giveAcxDialog "$AMOD" || return 1 ;; esac
	# Try removing module
	if ERROR=$(rmmod $AMOD 2>&1) ; then
	  # ask the user if to blacklist
	  offerToBlacklistModule "$AMOD"
	  # need to refresh the main gui, since # of interfaces has changed
      setDefaultMODULEBUTTONS
      refreshMainWindowInfo
	  return 0
	else # failed to remove: give message
      giveErrorDialog "$L_MESSAGE_Remove_Module_Failed_p1 $AMOD.
$L_MESSAGE_Remove_Module_Failed_p2
$ERROR"
      return 1
    fi
} # end askWhichInterfaceForNdiswrapper

#=============================================================================
loadNdiswrapperModule ()
{
	#  Dougal: ask the user if there's an interface for the HW, so we know
	#+ to remove the driver for it.
	askWhichInterfaceForNdiswrapper || return
	showNdiswrapperGUI
	[ $? -eq 0 ] || return
	ndiswrapper -m
	#v4.00 bugfix...
	NATIVEMOD=""
	nwINTERFACE="$(grep '^alias .* ndiswrapper$' /etc/modprobe.conf | cut -f 2 -d ' ')" 
	#most likely 'wlan0'
	#if this interface is already claimed by a native linux driver,
	#then get rid of it...
	## Dougal: this isn't good: the interface name is not the problem, it's the HW!
	## Add a dialog at the top for it.
	if [ -n "$nwINTERFACE" -a -e "/sys/class/net/$nwINTERFACE" ];then
	  NATIVEMOD="$(readlink /sys/class/net/${nwINTERFACE}/device/driver/module)"
	  NATIVEMOD=${NATIVEMOD##*/}
	  if [ "$NATIVEMOD" != "ndiswrapper" ];then
	    #note 'ndiswrapper -l' also returns the native linux module.
	    if iwconfig | grep "^${nwINTERFACE} " | grep 'IEEE' | grep -q 'ESSID' ;then
	      rmmod "$NATIVEMOD"
	      sleep 6
	      [ $INTERFACE_NUM -gt 0 ] && INTERFACE_NUM=$((INTERFACE_NUM-1))
	      #...needed later to determine that number of interfaces has changed with ndiswrapper.
	      #INTERFACES="$(ifconfig -a | grep -F 'Link encap:Ethernet' | cut -f1 -d' ' | tr '\n' ' ')"
	      getInterfaceList
	      #...also needed later.
	    fi
	  else
	    NATIVEMOD=""
	  fi
	fi
	   
	tryLoadModule "ndiswrapper"
	ndRETVAL=$?
	
	#v4.00...
	if [ $ndRETVAL -eq 0 ];then
	  #well let's be radical, blacklist the native driver...
	  if [ "$NATIVEMOD" != "" ];then
		#if ! grep "^${NATIVEMOD}$" "$BLACKLIST_FILE" ;then
		. /etc/rc.d/MODULESCONFIG
		case $SKIPLIST in *" $NATIVEMOD "*|*" ${NATIVEMOD//_/-} "*) ;; *)
		  Xdialog --title "$L_TITLE_Puppy_Network_Wizard" --yesno \
"$L_MESSAGE_Blacklist_Nativemod_p1 ${NATIVEMOD} $L_MESSAGE_Blacklist_Nativemod_p2" 0 0
		  if [ $? -eq 0 ] ; then
		    #echo "$NATIVEMOD" >> "$BLACKLIST_FILE"
		    blacklist_module "$NATIVEMOD"
		  fi
		  ;;
		esac
		#fi
	  fi
	fi #if [ $ndRETVAL -eq 0 ];then
	return $ndRETVAL
} # end loadNdiswrapperModule

#=============================================================================

loadSpecificModule (){
  export NETWIZ_Load_Specific_Module_Window="<window title=\"$L_TITLE_Load_A_Module\" icon-name=\"gtk-network\" window-position=\"1\">
<vbox>
  <text>
    <label>\"$L_TEXT_Load_A_Module\"</label>
  </text>
  <entry>
    <variable>SPECIFIED_MODULE</variable>
  </entry>
  <hbox>
   <button>
     <label>$L_BUTTON_Load</label>
     <input file stock=\"gtk-ok\"></input>
     <action>EXIT:Load</action>
   </button>
   <button cancel></button>
  </hbox>
 </vbox>
</window>"

  I=$IFS; IFS=""
  for STATEMENT in  $(gtkdialog --program NETWIZ_Load_Specific_Module_Window); do
	eval $STATEMENT 2>/dev/null
  done
  IFS=$I
  clean_up_gtkdialog NETWIZ_Load_Specific_Module_Window
  unset NETWIZ_Load_Specific_Module_Window

  if [ "$EXIT" = "Load" ] ; then
    if [ "$SPECIFIED_MODULE" ] ; then #making sure there was something
      tryLoadModule $SPECIFIED_MODULE 2>&1
    fi
  fi
} # end loadSpecificModule

#=============================================================================
autoLoadModule ()
{
	#this is the autoloading...
	SOMETHINGWORKED=false
	#clear
	for CANDIDATE in $NETWORK_MODULES
	do
		#if have pcmcia, do not try loading the others...
		MDOIT="no"
		case "$CANDIDATE" in 
		 *_cs*)	[ "$MPCMCIA" = "yes" ] && MDOIT="yes" ;;
		 *)		[ "$MPCMCIA" = "yes" ] || MDOIT="yes" ;;
		esac
		
		#also, do not try if it is already loaded...?
		grep -q "$CANDIDATE" /tmp/loadedeth.txt && MDOIT="no"

		#in case of false-hits, ignore anything already tried this session...
		grep -q "$CANDIDATE" /tmp/logethtries.txt && MDOIT="no"

		if [ "$MDOIT" = "yes" ];then
			echo; echo "*** Trying $CANDIDATE."
			if modprobe "$CANDIDATE"
			then
				SOMETHINGWORKED=true
				WHATWORKED=$CANDIDATE
				#add it to the log for this session...
				echo "$CANDIDATE" >> /tmp/logethtries.txt
				break
			fi
		fi

	done
	sleep 2
	if $SOMETHINGWORKED
	then
		Xdialog --left --wrap --title "$L_TITLE_Puppy_Network_Wizard" --msgbox "$L_MESSAGE_Success_Loading_Module_p1 $WHATWORKED $L_MESSAGE_Success_Loading_Module_p2" 0 0
		echo -n "$WHATWORKED" > /tmp/ethmoduleyesload.txt
	else
		MALREADY="$(cat /tmp/loadedeth.txt)"
		Xdialog --msgbox "${L_MESSAGE_No_Module_Loaded}\n${MALREADY}" 0 0
		return 1
	fi
} # end autoLoadModule

#=============================================================================
# A function to add a module to the SKIPLIST
blacklist_module(){
  MODULE="$1"
  if grep -Fq 'SKIPLIST=' /etc/rc.d/MODULESCONFIG ; then
	sed -i "s/^SKIPLIST=.*/SKIPLIST=\"$SKIPLIST ${MODULE//_/-} \"/" /etc/rc.d/MODULESCONFIG
  else
	echo "SKIPLIST=\" ${MODULE//_/-} \"" >>/etc/rc.d/MODULESCONFIG
  fi
}


#=============================================================================
# A function that gives a dialog offering to blabklist a just-removed module
# $1: the modules
offerToBlacklistModule(){
	AMODULE="$1"
	# see if not already blacklisted
	. /etc/rc.d/MODULESCONFIG
	case $SKIPLIST in *" $AMODULE "*|*" ${AMODULE//_/-} "*) return ;; esac
	
	export NETWIZ_Blacklist_Module_Dialog="<window title=\"$L_TITLE_Puppy_Network_Wizard\" icon-name=\"gtk-network\" window-position=\"1\">
 <vbox>
  <pixmap icon_size=\"6\">
      <input file stock=\"gtk-dialog-question\"></input>
    </pixmap>
  <text>
    <label>\"$L_TEXT_Blacklist_Module_p1 $AMODULE $L_TEXT_Blacklist_Module_p2\"</label>
  </text>  
  <hbox>
    <button>
      <label>$L_BUTTON_Blacklist</label>
      <input file stock=\"gtk-yes\"></input>
      <action>EXIT:Blacklist</action>
    </button>
    <button>
	  <label>$L_BUTTON_No</label>
	  <input file stock=\"gtk-no\"></input>
	  <action>EXIT:cancel</action>
	</button>
  </hbox>
 </vbox>
</window>"

    I=$IFS; IFS=""
    for STATEMENT in  $(gtkdialog --program NETWIZ_Blacklist_Module_Dialog); do
    	eval $STATEMENT
    done
    IFS=$I
    clean_up_gtkdialog NETWIZ_Blacklist_Module_Dialog
    unset NETWIZ_Blacklist_Module_Dialog
     
    case $EXIT in Blacklist)
    	#echo "$AMODULE" >> "$BLACKLIST_FILE"
    	blacklist_module "$AMODULE"
		;;
    esac    
} # end offerToBlacklistModule

#=============================================================================
unloadSpecificModule(){
  TOPMSG=""
  LOADED_ITEMS=""
  while read ONE
  do 
    [ "$ONE" ] || continue
    LOADED_ITEMS="$LOADED_ITEMS <item>$ONE</item>"
  done</tmp/loadedeth.txt
  
  # see if there's anything at all...
  if [ ! "$LOADED_ITEMS" ] ; then
    giveErrorDialog "$L_MESSAGE_No_Loaded_Items"
    return
  fi
  
  export NETWIZ_Unload_Module_Window="<window title=\"$L_TITLE_Unload_A_Module\" icon-name=\"gtk-network\" window-position=\"1\">
<vbox>
  <text>
    <label>\"$L_TEXT_Unload_A_Module\"</label>
  </text>
  <hbox>
    <text>
      <label>$L_COMBO_Module</label>
    </text>
    <combobox>
      <variable>COMBOBOX</variable>
      $LOADED_ITEMS
    </combobox>
  </hbox>
  <hbox>
   <button>
     <label>$L_BUTTON_Unload</label>
     <input file stock=\"gtk-undo\"></input>
     <action>EXIT:Unload</action>
   </button>
   <button cancel></button>
  </hbox>
 </vbox>
</window>"

  I=$IFS; IFS=""
  for STATEMENT in  $(gtkdialog --program NETWIZ_Unload_Module_Window); do
	eval $STATEMENT 2>/dev/null
  done
  IFS=$I
  clean_up_gtkdialog NETWIZ_Unload_Module_Window
  unset NETWIZ_Unload_Module_Window

  if [ "$EXIT" = "Unload" ] ; then
    if [ "$COMBOBOX" ] ; then #making sure there was something
      if ERROR=$(rmmod $COMBOBOX 2>&1) ; then # it worked, remove from list
        sed -i "/^ $COMBOBOX*/d" /tmp/loadedeth.txt
        # ask the user about blacklisting
        offerToBlacklistModule "$COMBOBOX"
        # need to refresh the main gui, since # of interfaces has changed
        setDefaultMODULEBUTTONS
        refreshMainWindowInfo
      else # failed to remove: give message
        giveErrorDialog "$L_MESSAGE_Remove_Module_Failed_p1 $COMBOBOX.
$L_MESSAGE_Remove_Module_Failed_p2
$ERROR"
      fi #if rmmod $COMBOBOX ; then
    
    fi #if [ "$COMBOBOX" ] ; then
  fi #if [ "$EXIT" = "Unload" ] ; then
} # end unloadSpecificModule

#=============================================================================
findLoadedModules ()
{
  echo -n " " > /tmp/loadedeth.txt

  LOADED_MODULES="$(lsmod | cut -f1 -d' ' | sort)"
  NETWORK_MODULES=" $(cat $TMPDIR/networkmodules /etc/networkusermodules  2>/dev/null | cut -f1 -d' ' | tr '\n' ' ') "

  COUNT_MOD=0
  for MOD in $LOADED_MODULES
  do	COUNT_MOD=$((COUNT_MOD+1))
  done

  (
		for AMOD in $LOADED_MODULES
		do
			echo "X"
			# Dougal: use a case structure for globbing
			# Also try and retain original module names (removed "tr '-' '_')
			case "$NETWORK_MODULES" in 
			 *" $AMOD "*)
			   echo "$AMOD" >> /tmp/loadedeth.txt
			   echo -n " " >> /tmp/loadedeth.txt #space separation
			   ;;
			 *" ${AMOD/_/-} "*) # kernel shows module with underscore...
			  echo "${AMOD/_/-}" >> /tmp/loadedeth.txt
			  echo -n " " >> /tmp/loadedeth.txt #space separation
			  ;;
			esac
		done
  ) | Xdialog --title "$L_TITLE_Puppy_Network_Wizard" --progress "$L_PROGRESS_Checking_Loaded_Modules" 0 0 $COUNT_MOD

} # end of findLoadedModules
#=============================================================================
testInterface()
{
  INTERFACE="$1"
  
  (
	ifconfig "$INTERFACE" | grep ' UP ' >> $DEBUG_OUTPUT 2>&1
	if [ ! $? -eq 0 ];then #=0 if found
		#cleanUpInterface "$INTERFACE" >> $DEBUG_OUTPUT 2>&1
		# Dougal: add check for error -- maybe it fails to be raised?
		if ! ERROR=$(ifconfig "$INTERFACE" up 2>&1) ; then
		  giveErrorDialog "$L_MESSAGE_Failed_Raise_Interface_p1 $INTERFACE.
$L_MESSAGE_Failed_Raise_Interface_p2 ifconfig $INTERFACE up
$L_MESSAGE_Failed_Raise_Interface_p3
$ERROR
"
		fi
	fi

	echo "X"
	LINK_DETECTED=no
	for i in 1 2 3 4 5 ; do
		if ethtool "$INTERFACE" | grep -Fq 'Link detected: yes' ; then
			LINK_DETECTED="yes"
			break
		fi
		[ $i -lt 5 ] && sleep 1.3 || sleep 0.5 #190217
		echo "X"
	done
	if [ "$LINK_DETECTED" = "no" ] ; then
		echo -n true > /tmp/net-setup_UNPLUGGED.txt
	else
		echo -n false > /tmp/net-setup_UNPLUGGED.txt
	fi
  ) | Xdialog --title "$L_TITLE_Network_Wizard" --progress "$L_PROGRESS_Testing_Interface ${INTERFACE}" 0 0 5

  UNPLUGGED=$(cat /tmp/net-setup_UNPLUGGED.txt)

  if [ "$UNPLUGGED" != "false" ];then #BK1.0.7
    #no cable plugged in, no network connection possible...
    ifconfig "$INTERFACE" down
    BGCOLOR="#ffc0c0"
    if [ "${IS_WIRELESS}" ] ; then
      TOPMSG="$(eval echo $L_TOPMSG_Report_On_Test) 
$L_TOPMSG_Unplugged_Wireless"
    else
      TOPMSG="$(eval echo $L_TOPMSG_Report_On_Test)
$L_TOPMSG_Unplugged_Wired"
    RETTEST=1
    fi
  else
    BGCOLOR="#e0ffe0"
    TOPMSG="$(eval echo $L_TOPMSG_Report_On_Test)
$L_TOPMSG_Network_Alive"
		RETTEST=0
  fi

  return $RETTEST
} # end of testInterface

#=============================================================================
showConfigureInterfaceWindow()
{
  INTERFACE="$1"
  
  initializeConfigureInterfaceWindow
  
  RETVALUE=""
  # 1=Close window 19=Back Button 22=Save configuration
  while true
  do
    buildConfigureInterfaceWindow
    
    I=$IFS; IFS=""
    for STATEMENT in  $(gtkdialog --program NETWIZ_Configure_Interface_Window); do
      eval $STATEMENT
    done
    IFS=$I
    clean_up_gtkdialog NETWIZ_Configure_Interface_Window
    unset NETWIZ_Configure_Interface_Window

    RETVALUE=$EXIT
    [ "$RETVALUE" = "abort" ] && RETVALUE=1

    RETSETUP=99
    case $RETVALUE in
       1 | 19) # close window
          TOPMSG="$(eval echo $L_TOPMSG_Configuration_Cancelled)"
		  break
          ;;
      66) # Dougal: add "Done" button to exit (there was a wrong message) 
          cleanUpTmp
          exit
          ;;
      10) # AutoDHCP
          killOtherInterface #(if any) 190217
          # Must kill old dhcpcd first
		  killDhcpcd "$INTERFACE"
		  sleep 3
          setupDHCP
          RETSETUP=$?
          ;;
      11) # StaticIP
          showStaticIPWindow
          RETSETUP=$?
          ;;
      13) # Test
          testInterface "$INTERFACE"
          RETSETUP=$?
          ;;
      14) # Wireless
          configureWireless "$INTERFACE"
          ;;
      #21) # Help
          #showHelp
          #;;
      22) # Save configuration
          break
          ;;
    esac
	
	# Dougal: define the "Done" button here, so it doesn't appear the first time around...
	DONEBUTTON="<button>
					<label>$L_BUTTON_Done</label>
					<input file stock=\"gtk-apply\"></input>
					<action>EXIT:66</action>
				</button>"
	
    if [ $RETVALUE -eq 10 ] || [ $RETVALUE -eq 11 ] ; then
      if [ $RETSETUP -ne 0 ] ; then
        TOPMSG="$(eval echo $L_TOPMSG_Configuration_Unsuccessful)
$L_TOPMSG_Configuration_Offer_Try_Again"
      else
        RETVALUE=1
        Xdialog --yesno "$(eval echo $L_TOPMSG_Configuration_Successful)
$L_TOPMSG_Configuration_Offer_To_Save" 0 0
		if [ $? -eq 0 ] ; then
          saveInterfaceSetup "$INTERFACE"
          # Dougal: might add some info in here
          TOPMSG="$(eval echo $L_TOPMSG_Configuration_Successful)
$L_TOPMSG_Configuration_Offer_To_Finish"
        else
          TOPMSG="$(eval echo $L_TOPMSG_Configuration_Successful)
$L_TOPMSG_Configuration_Not_Saved"
        fi
      fi
    fi

  done

} # end showConfigureInterfaceWindow

#=============================================================================
buildConfigureInterfaceWindow ()
{
	export NETWIZ_Configure_Interface_Window="<window title=\"$(eval echo $L_TITLE_Configure_Interface)\" icon-name=\"gtk-network\" window-position=\"1\">
<vbox>
	<pixmap><input file>$BLANK_IMAGE</input></pixmap>
	<text><label>\"${TOPMSG}\"</label></text>
	${WIRELESSSECTION}
	<frame  $L_FRAME_Test_Interface >
		<hbox>
			<text><label>\"${TESTMSG}\"</label></text>
			<vbox>
				<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				<button>
					<label>$(eval echo $L_BUTTON_Test_Interface)</label>
					<action>EXIT:13</action>
				</button>
			</vbox>
		</hbox>
	</frame>
	<frame  $L_FRAME_Configure_Interface >
		<hbox>
			<text><label>\"${DHCPMSG}\"</label></text>
			<vbox>
				<text><label>\" \"</label></text>
				<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				<button>
					<label>$L_BUTTON_Auto_DHCP</label>
					<action>EXIT:10</action>
				</button>
			</vbox>
		</hbox>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
		<hbox>
			<text><label>\"${STATICMSG}\"</label></text>
			<vbox>
				<pixmap><input file>$BLANK_IMAGE</input></pixmap>
				<button>
					<label>$L_BUTTON_Static_IP</label>
					<action>EXIT:11</action>
				</button>
			</vbox>
		</hbox>
	</frame>
	<hbox>
		$DONEBUTTON
		<button help>
			<action>$HELP_COMMAND > /dev/null 2>&1 & </action>
		</button>
		${SAVE_SETUP_BUTTON}
		<button>
			<label>$L_BUTTON_Back</label>
			<input file stock=\"gtk-go-back\"></input>
			<action>EXIT:19</action>
		</button>
	</hbox>
</vbox>
</window>"
} # end buildConfigureInterfaceWindow

#=============================================================================
initializeConfigureInterfaceWindow ()
{
	TOPMSG="$L_TOPMSG_Initial_Lets_try $INTERFACE."

	TESTMSG="$L_TESTMSG_Initial_p1 $INTERFACE $L_TESTMSG_Initial_p2"

	DHCPMSG="$L_DHCPMSG_Initial"

	STATICMSG="$L_STATICMSG_Initial"

	if checkIfIsWireless "$INTERFACE" ; then
		WIRELESSSECTION="<frame  $L_FRAME_Configure_Wireless >
<hbox>
	<text><label>\"$L_TEXT_Configure_Wireless_p1 $INTERFACE $L_TEXT_Configure_Wireless_p2\"</label></text>
	<vbox>
		<text><label>\" \"</label></text>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
		<button>
			<label>$L_BUTTON_Wireless</label>
			<action>EXIT:14</action>
		</button>
	</vbox>
</hbox>
</frame>"
	else
		WIRELESSSECTION=""
	fi
	SAVE_SETUP_BUTTON=""
} # end initializeConfigureInterfaceWindow

#=============================================================================
checkIfIsWireless ()
{
  INTERFACE="$1"
  IS_WIRELESS=""
  INTMODULE=$(readlink /sys/class/net/$INTERFACE/device/driver)
  INTMODULE=${INTMODULE##*/}

  if interface_is_wireless ${INTERFACE} ; then
    return 0
  else
    return 1
  fi
}

#=============================================================================
configureWireless()
{
	INTERFACE="$1"
	showProfilesWindow "$INTERFACE"
	case $? in
	  0)
		testInterface "$INTERFACE"
		;;
	  2) # Dougal: add this for failed useProfile
		TOPMSG="$L_TOPMSG_Wireless_Config_Failed_p1 $INTERFACE $L_TOPMSG_Wireless_Config_Failed_p2"
		;;
	  *)
		TOPMSG="$L_TOPMSG_Wireless_Config_Cancelled_p1 $INTERFACE $L_TOPMSG_Wireless_Config_Cancelled_p2"
		;;
	esac
} # end configureWireless

#=============================================================================
showStaticIPWindow()
{
	IP_ADDRESS="$(ifconfig $INTERFACE | grep 'inet addr' | sed 's/.*inet addr://' | cut -d" " -f1)"
	NETMASK="$(ifconfig $INTERFACE | grep 'inet addr' | sed 's/.*Mask://')"
	GATEWAY="$(iproute | grep default | cut -d" " -f3)"
	# get current dns servers
	NUM=1
	while read A B ; do
	  if [ "$A" = "nameserver" ] && validip4 "$B" ; then # being really paranoid...
	    eval DNS_SERVER$NUM="$B"
	    NUM=$((NUM+1))
	  fi
	done<<EOF
$( grep -m2 nameserver /etc/resolv.conf )
EOF
	
	EXIT=""
	while true
	do
		buildStaticIPWindow
		I=$IFS; IFS=""
		for STATEMENT in  $(gtkdialog --program NETWIZ_Static_IP_Window); do
			eval $STATEMENT
		done
		IFS=$I
		clean_up_gtkdialog NETWIZ_Static_IP_Window
		unset NETWIZ_Static_IP_Window

		case "$EXIT" in
			abort|Cancel) # close window
				break
				;; # Do Nothing, It will exit without doing anything
			"OK" ) # OK
				if validateStaticIP ; then
					killOtherInterface #(if any) 190217
					setupStaticIP || EXIT=""
				else
					EXIT=""
				fi
				break
				;;
		esac
	done
	
	if [ "${EXIT}" = "OK" ] ; then
		return 0
	else
		return 1
	fi
} # end showStaticIPWindow

#=============================================================================
buildStaticIPWindow()
{
	[ -z "$IP_ADDRESS" ] && IP_ADDRESS="0.0.0.0"
	[ -z "$NETMASK" ] && NETMASK="255.255.255.0"
	[ -z "$GATEWAY" ] && GATEWAY="0.0.0.0"
	[ -z "$DNS_SERVER1" ] && DNS_SERVER1="0.0.0.0"
	[ -z "$DNS_SERVER2" ] && DNS_SERVER2="0.0.0.0"

	export NETWIZ_Static_IP_Window="<window title=\"$L_TITLE_Set_Static_IP\" icon-name=\"gtk-network\" window-position=\"1\">
<vbox>
	<text><label>\"$L_TEXT_Set_Static_IP\"</label></text>
	<frame  $L_FRAME_Static_IP_Parameters >
		<hbox>
			<vbox>
				<text><label>$L_ENTRY_IP_Address</label></text>
				<pixmap><input file>$BLANK_IMAGE</input></pixmap>
			</vbox>
			<entry>
				<variable>IP_ADDRESS</variable>
				<default>${IP_ADDRESS}</default>
			</entry>
		</hbox>
		<hbox>
			<vbox>
				<text><label>$L_ENTRY_Net_Mask</label></text>
				<pixmap><input file>$BLANK_IMAGE</input></pixmap>
			</vbox>
			<entry>
				<variable>NETMASK</variable>
				<default>${NETMASK}</default>
			</entry>
		</hbox>
		<hbox>
			<vbox>
				<text><label>$L_ENTRY_Gateway</label></text>
				<pixmap><input file>$BLANK_IMAGE</input></pixmap>
			</vbox>
			<entry>
				<variable>GATEWAY</variable>
				<default>${GATEWAY}</default>
			</entry>
		</hbox>
	</frame>
	<frame  $L_FRAME_DNS_Parameters >
		<hbox>
			<vbox>
				<text><label>$L_ENTRY_DNS_Primary</label></text>
				<pixmap><input file>$BLANK_IMAGE</input></pixmap>
			</vbox>
			<entry>
				<variable>DNS_SERVER1</variable>
				<default>${DNS_SERVER1}</default>
			</entry>
		</hbox>
		<hbox>
			<vbox>
				<text><label>$L_ENTRY_DNS_Secondary</label></text>
				<pixmap><input file>$BLANK_IMAGE</input></pixmap>
			</vbox>
			<entry>
				<variable>DNS_SERVER2</variable>
				<default>${DNS_SERVER2}</default>
			</entry>
		</hbox>
	</frame>
	<hbox>
		<button help>
			<action>$HELP_COMMAND > /dev/null 2>&1 & </action>
		</button>
		<button ok></button>
		<button cancel></button>
	</hbox>
</vbox>
</window>"
} # end buildStaticIPWindow

#=============================================================================
validateStaticIP()
{
	# Dougal: this was set as default, but obviously not used...
	[ "$GATEWAY" = "0.0.0.0" ] && GATEWAY=""
	# user might have blanked them out...
	[ -z "$DNS_SERVER1" ] && DNS_SERVER1="0.0.0.0"
	[ -z "$DNS_SERVER2" ] && DNS_SERVER2="0.0.0.0"
	ERROR_MSG=""
	if ! validip4 "${IP_ADDRESS}" ; then
		ERROR_MSG="${ERROR_MSG}\n- $L_ERROR_Invalid_IP_Address"
	fi
	if ! validip4 "${NETMASK}" ; then
		ERROR_MSG="${ERROR_MSG}\n- $L_ERROR_Invalid_Netmask"
	fi
	if [ ! -z "$GATEWAY" ] ; then
		if ! validip4 "${GATEWAY}"  ; then
			ERROR_MSG="${ERROR_MSG}\n- $L_ERROR_Invalid_Gateway"
		fi
	fi
	if ! validip4 "${DNS_SERVER1}"  ; then
		ERROR_MSG="${ERROR_MSG}\n- $L_ERROR_Invalid_DNS1"
	fi
	if ! validip4 "${DNS_SERVER2}"  ; then
		ERROR_MSG="${ERROR_MSG}\n- $L_ERROR_Invalid_DNS2"
	fi
	
	if [ "${ERROR_MSG}" != "" ] ; then
	  	ERROR_MSG="$(echo -e "$ERROR_MSG" )"
	  	giveErrorDialog "$L_MESSAGE_Bad_addresses
$ERROR_MSG
"
	  	return 1
	fi	
	
	DEFAULTMASK=$(ipcalc --netmask "$IP_ADDRESS" | cut -d= -f2)
	
	if [ "x${NETMASK}" != "x${DEFAULTMASK}" ] ; then
		Xdialog --center --title "$L_TITLE_Netwiz_Static_IP" \
	  				--yesno "$L_MESSAGE_Bad_Netmask" 0 0
		if [ $? -eq 1 ] ; then
	  		return 1
	  	fi
	fi
	
	# Check that network is right
	if [ -z "$GATEWAY" ];then
		# It is legitimate not to have a gateway at all.  In that case, it
		# doesn't have a network. :-)
		unset HOSTNET
		unset GATENET
	else
		HOSTNUM=$(ip2dec "$IP_ADDRESS") 
		MASKNUM=$(ip2dec "$NETMASK")
		GATENUM=$(ip2dec "$GATEWAY")
	fi

	return 0
} #end of validateStaticIP

#=============================================================================
# Dougal: change MODECOMMANDS entirely -- just include the basic info
setupStaticIP()
{
	ifconfig "$INTERFACE" | grep ' UP ' >> $DEBUG_OUTPUT 2>&1
	if [ ! $? -eq 0 ];then # wired interface (wireless will be up by now)
		cleanUpInterface "$INTERFACE"
	fi
	BROADCAST=$(ipcalc -b "$IP_ADDRESS" "$NETMASK" | cut -d= -f2)
	CONVO="ifconfig $INTERFACE $IP_ADDRESS netmask $NETMASK broadcast $BROADCAST"
	CONVG="route add -net default gw $GATEWAY" #dev $INTERFACE"
	# Dougal: add a cleanup, just in case
	#cleanUpInterface "$INTERFACE" >> $DEBUG_OUTPUT 2>&1
	# do the work
	# Dougal: add getting error message
	ERROR=$(ifconfig "$INTERFACE" "$IP_ADDRESS" netmask "$NETMASK" broadcast "$BROADCAST" 2>&1) #up	
	if [ $? -eq 0 ];then
		MODECOMMANDS="STATIC_IP='yes'\nIP_ADDRESS='$IP_ADDRESS'\nNETMASK='$NETMASK'"
		# Configure a nameserver, if we're supposed to.
		# This now replaces any existing resolv.conf, which
		# we will try to back up.
		if [ "$DNS_SERVER1" != "0.0.0.0" ] ; then
			# remove old backups
			rm /etc/resolv.conf.[0-9][0-9]* 2>/dev/null
			# backup previous one
			mv -f /etc/resolv.conf /etc/resolv.conf.old
			echo "nameserver $DNS_SERVER1" > /etc/resolv.conf
			if [ "$DNS_SERVER2" != "0.0.0.0" ] ; then
				echo "nameserver $DNS_SERVER2" >> /etc/resolv.conf
			fi
		fi
		MODECOMMANDS="$MODECOMMANDS\nDNS_SERVER1='$DNS_SERVER1'"
		MODECOMMANDS="$MODECOMMANDS\nDNS_SERVER2='$DNS_SERVER2'"
		
		# add default route, if we're supposed to
		if [ "$GATEWAY" ] ; then
			# Dougal: add getting error message
			ERROR=$(route add -net default gw "$GATEWAY" 2>&1)
			if [ $? -eq 0 ];then #0=ok.
				Xdialog --center --title "$L_TITLE_Netwiz_Static_IP" --msgbox "$(eval echo $L_MESSAGE_Route_Set)" 0 0
				MODECOMMANDS="${MODECOMMANDS}\nGATEWAY='$GATEWAY'"
			else
				giveErrorDialog "$L_MESSAGE_Route_Failed_p1 $GATEWAY.
$L_MESSAGE_Route_Failed_p2
$CONVG
$L_MESSAGE_Route_Failed_p3
$ERROR
"
				ifconfig "$INTERFACE" down
				return 1
			fi
		fi
		
  		return 0
	else
		giveErrorDialog "$L_MESSAGE_Ifconfig_Failed_p1
$CONVO
$L_MESSAGE_Ifconfig_Failed_p2
$ERROR
$L_MESSAGE_Ifconfig_Failed_p3"
		ifconfig "$INTERFACE" down
		MODECOMMANDS=""
		return 1
	fi
} #end of setupStaticIP

#=============================================================================
killOtherInterface() #190217...
{
  # derived from rc.network stop_all.
  for IFACE in $(ifconfig | grep -F 'Link encap:Ethernet' | cut -f 1 -d " " | grep -vw "$INTERFACE") ; do
    cleanUpInterface "$IFACE" >/dev/null 2>&1
    ip route flush dev "$IFACE"
    ifconfig "$IFACE" down
  done
} #end of killOtherInterface


#=============================================================================
saveNewModule()
{
  # save newly loaded module
  if ! grep "$NEWLOADED" /etc/ethernetmodules ;then
    echo "$NEWLOADED" >> /etc/ethernetmodules
  fi
  TOPMSG="$L_TOPMSG_Module_Saved_p1 '$NEWLOADED' $L_TOPMSG_Module_Saved_p2"
  setDefaultMODULEBUTTONS
} # end saveNewModule

#=============================================================================
unloadNewModule()
{
  # unload newly loaded module
  modprobe -r "$NEWLOADED"
  grep -v "$NEWLOADED" /etc/ethernetmodules > /etc/ethernetmodules.tmp
  #sync
  mv -f /etc/ethernetmodules.tmp /etc/ethernetmodules
  TOPMSG="$L_TOPMSG_Module_Unloaded_p1 '$NEWLOADED' $L_TOPMSG_Module_Unloaded_p2 '$NEWLOADED' $L_TOPMSG_Module_Unloaded_p3"

  setDefaultMODULEBUTTONS

  refreshMainWindowInfo
} # end unloadNewModule

#=============================================================================
setDefaultMODULEBUTTONS ()
{
  MODULEBUTTONS="
<hbox>
	<text>
		<label>\"$L_TEXT_Default_Module_Buttons\"</label>
	</text>
	<vbox>
		<pixmap><input file>$BLANK_IMAGE</input></pixmap>
		<button>
			<label>$L_BUTTON_Load_Module</label>
			<action>EXIT:10</action>
		</button>
	</vbox>
</hbox>"
} # end setDefaultMODULEBUTTONS

#=============================================================================
# Dougal: a function to find info about interface: 
findInterfaceInfo()
{
  local INT="$1"
  TYPE="" 
  INFO=""
    
  FINDTYPE="`readlink /sys/class/net/$INT/device/driver`"
  local DEVICE=${FINDTYPE##*/}
  
  FI_DRIVER=${DEVICE}
  IF_BUS=
  IF_INFO=
  while read F1 F2plus ; do
	case $F1 in
		"description:") IF_INFO="$F2plus" ;; #description: Support for Atheros 802.11n wireless LAN cards.
		"alias:") IF_BUS="${F2plus%%:*}" ;;  #alias: pci:v0000168Cd00000027sv*sd*bc*sc*i*
	esac
  done <<< "$(modinfo $FI_DRIVER 2>/dev/null)"
  if [ ! "$IF_BUS" ] && [ "$FINDTYPE" ];then
	case $FINDTYPE in
		*/bus/usb*) IF_BUS="usb" ;;
		*/bus/pci*) IF_BUS="pci" ;;
		*/bus/ieee1394*) TYPE="firewire" ;;
	esac
  fi
  TYPE=${IF_BUS}
  INFO=${IF_INFO}  

  case "$FI_DRIVER" in
   */bus/usb*) TYPE="usb" ;;
   */bus/ieee1394*) TYPE="firewire" ;;
   *) # pcmcia and pci apparently both appear as pci...
      if grep "^${FI_DRIVER##*/} " $TMPDIR/networkmodules |grep -q 'pcmcia:' ; then
        TYPE="pcmcia"
      else
        TYPE="pci"
      fi
      ;;
  esac
  FI_DRIVER=${FI_DRIVER##*/}

  if interface_is_wireless ${INTERFACE} ; then
    INTTYPE="$L_INTTYPE_Wireless"
  else
    INTTYPE="$L_INTTYPE_Ethernet"
  fi
  
  case "$TYPE" in
   pci|pcmcia) # pci device, get info from scanpci
     ## Try and replace below with actually getting the device and vendor values
     DEVICE=$(readlink /sys/class/net/$INT/device)
     DEVICE=${DEVICE#*:}
     INFO=$(lspci | grep -m1 "^${DEVICE} " | cut -d: -f3- | sed 's%Corporation%%g ; s%Co\.%%g ; s%Ltd\.%%g ; s% ,%,%g ; s%(rev [0-9a-z].)%%g' | tr -s ' ')
     ;;
   usb)
     # possible alternative to all the above:
     # get the link to the device in dir in /sys/devices 
     # (we only want the part of the top dir for it, like usb1/1-8
     local DEV_LINK=$(readlink /sys/class/net/$INT/device | grep -o ".*/usb[0-9]/[0-9]-[0-9]*")
	 if [ -z "$DEV_LINK" ] ; then
	   DEV_LINK=$(readlink /sys/class/net/$INT | grep -o ".*/usb[0-9]/[0-9]-[0-9]*")
	   read PROD < /sys/class/net/$DEV_LINK/product
	   read MANU < /sys/class/net/$DEV_LINK/manufacturer
	 else
	   read PROD < /sys/class/net/$INT/$DEV_LINK/product
	   read MANU < /sys/class/net/$INT/$DEV_LINK/manufacturer
	 fi
     if [ -n "$MANU" -a -n "$PROD" ] ; then
       case "$PROD" in
         *"$MANU"*) INFO="$PROD" ;;
         *) INFO="$MANU $PROD" ;;
       esac
     else # get info from module
       INFO=$(modinfo $FI_DRIVER |grep -m1 '^description' |tr -s ' ' |cut -d' ' -f2-)
     fi
     ;;
   firewire)
     FI_DRIVER="eth1394"
     INFO="$L_INFO_Eth_Firewire"
     ;;
  esac
  #111015 strip out chars that might upset gtkdialog...
  [ "$MANU" ] && MANU="`echo -n "$MANU" | sed -e 's%[^a-zA-Z0-9 .]%%g'`"
  [ "$PROD" ] && PROD="`echo -n "$PROD" | sed -e 's%[^a-zA-Z0-9 .]%%g'`"
  [ "$INFO" ] && INFO="`echo -n "$INFO" | sed -e 's%[^a-zA-Z0-9 .]%%g'`"
} # end findInterfaceInfo

#=============================================================================
saveInterfaceSetup()
{
  local INTERFACE="$1"
  # need to address from ifconfig, for firewire (/sys.../address gives 24-bit)
  local HWADDRESS=$(ifconfig "$1" | grep "^$1" | tr -s ' ' | cut -d' ' -f5)
  
# create config file
		
  if checkIfIsWireless "$INTERFACE" ; then
    # Dougal: only need to do this once
    if [ ! -s "${WLAN_INTERFACES_DIR}/$HWADDRESS.conf" ] ; then
      #cp -a /tmp/wireless-config "${WLAN_INTERFACES_DIR}/$HWADDRESS.conf"
      echo -e "INT_WPA_DRV='$PROFILE_WPA_DRV'\nUSE_WLAN_NG='$USE_WLAN_NG'" > ${WLAN_INTERFACES_DIR}/$HWADDRESS.conf
    fi
    # create interface config file
    echo "IS_WIRELESS='$IS_WIRELESS'" > ${NETWORK_INTERFACES_DIR}/$HWADDRESS.conf
    # Dougal: add info for static ip to profile, in case we use it
    # (note that -- currently at least -- that's the only use for MODECOMMANDS)
    #### (I am assuming the profile variable is still set...)
	# Need to clean up old info before adding new (pointed out by PaulBx1)
	sed -i '/^STATIC_IP=.*/d ; /^IP_ADDRESS=.*/d ; /^NETMASK=.*/d ; /DNS_SERVER^.*/d ; /^GATEWAY=.*/d ' "${PROFILES_DIR}/${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf"
    echo -e "${MODECOMMANDS}" >>"${PROFILES_DIR}/${PROFILE_AP_MAC}.${PROFILE_ENCRYPTION}.conf"
  else
    #echo -e "${MODECOMMANDS}" > /etc/${INTERFACE}mode
    # Dougal: maybe append? in case used both for dhcp and static.
    echo -e "${MODECOMMANDS}\nIS_WIRELESS=''" > ${NETWORK_INTERFACES_DIR}/$HWADDRESS.conf
  fi
} # end saveInterfaceSetup

#=============================================================================
# Dougal: a little function to clean up /tmp when we're done...
cleanUpTmp(){
	rm -f /tmp/ethmoduleyesload.txt 2>/dev/null
	rm -f /tmp/loadedeth.txt 2>/dev/null
#	rm -f /tmp/wag-profiles_iwconfig.sh 2>/dev/null
	rm -f /tmp/net-setup_* 2>/dev/null
	rm -f /tmp/wpa_status.txt 2>/dev/null
	rm -f /tmp/net-setup_scan*.tmp 2>/dev/null
}

#=============================================================================
#=============== START OF SCRIPT BODY ====================
#=============================================================================


# Cleanup older temp files (in case didn't exit nicely last time)
cleanUpTmp

if ps --no-headers -C 'net-setup.sh' | grep -qwv "^ *$$";then #190217
 giveErrorDialog "$L_MESSAGE_Already_Running
 $L_MESSAGE_Use_or_Terminate_Existing" #190217
 exit 1
fi #170514 end

# Do we have pcmcia hardware?...
if lspci -n | grep -E -q ' 0607: | 0605: ' ; then
  MPCMCIA="yes"
fi

setDefaultMODULEBUTTONS

refreshMainWindowInfo

BGCOLOR="#ffe0e0" #light red.
TOPMSG="$L_TOPMSG_Initial"

showMainWindow

# Dougal: clean up /tmp
cleanUpTmp

#v411 BK hack to remove old network wizard configs so rc.sysinit won't use them if old wizard installed...
[ "`ls -1 /etc/network-wizard/network/interfaces 2>/dev/null`" != "" ] && rm -f /etc/*[0-9]mode

#=============================================================================
#================ END OF SCRIPT BODY =====================
#=============================================================================
