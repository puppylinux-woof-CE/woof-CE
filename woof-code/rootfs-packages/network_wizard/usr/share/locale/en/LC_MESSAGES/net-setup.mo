## Some rules used:
#- All localization variables start with L_
#- The (possible) second part is all-caps and indicates the type of widget etc.
#- The rest gives a rough description of what the message is (content/location)
#- They appear in the order in which they exist in the script -- not running order
#  +(except for the general ones that are used in different places)
#- Hard quotes ('') should be kept when used and variables ($INTERFACE) not touched

# update: Mar. 19th '09: expanded the "function: giveNoWPADialog" section
# update: Mar. 29th: add "function: waitForPCMCIA" section

##  The command to use with the "help" button ("net_setup" can be changed for a 
##+ different help file, eg. "net_setup.de", for a file /usr/share/doc/net_setup.de.htm)
HELP_COMMAND="man 'net_setup'"

############### General text ###############
L_TITLE_Puppy_Network_Wizard="Puppy Network Wizard"
L_TITLE_Network_Wizard="Network Wizard"
L_TITLE_Netwiz_Static_IP="Puppy Network Wizard: Static IP"
L_BUTTON_Exit="Exit"
L_BUTTON_Save="Save"
L_BUTTON_Load="Load"
L_BUTTON_Unload="Unload"
L_BUTTON_Back="Back"
L_BUTTON_Blacklist="Blacklist"
L_BUTTON_No="No"

############### end General text ###############



############### net-setup.sh ###############
# function: refreshMainWindowInfo
L_LABEL_Interface_Tree_Header="Interface|Type|Module|Device description"

L_ECHO_No_Interfaces_Message="Puppy cannot see any active network interfaces.

If you have one or more network adaptors (interfaces) in the PC and you want to use them, then driver modules will have to be loaded. This is supposed to be autodetected and the correct driver loaded when Puppy boots up, but it hasn't happened in this case. Never mind, you can do it manually!"
L_ECHO_One_Interface_Message="Puppy has identified the following network interface on your computer, but it still needs to be configured.
To test or configure it, click on its button."
L_ECHO_Multiple_Interfaces_Message="Puppy has identified the following network interfaces on your computer, but they still need to be configured.
To test or configure an interface, click on its button."

# function: buildMainWindow
L_FRAME_Interfaces="Interfaces"
L_FRAME_Network_Modules="Network modules"

# function: showLoadModuleWindow
L_TITLE_Load_Network_Module="Load a network module"
L_NOTEBOOK_Modules_Header="Select module|Ndiswrapper|More"

L_TEXT_Select_Module_Tab="If you see a module below that matches your hardware (and isn't loaded yet...), select it and press the 'Load' button.
If not (or you are unsure), go to the 'More' tab."
L_LABEL_Module_Tree_Header="Module|Type|Description"

L_TEXT_Ndiswrapper_Tab="<b>Ndiswrapper</b> is a mechanism that 'wraps' a Windows driver and enables using it under Linux.

In order to use it, all you will need to do is know the location of the driver information file (.INF) for the Windows driver (usually in the driver directory of your Windows installation...).

Note that Ndiswrapper does <b>not</b> work with Windows Vista drivers.
"
L_BUTTON_Use_Ndiswrapper="Use Ndiswrapper"

L_TEXT_More_Tab="Click <b>Specify</b> to choose a module that's not listed, or specify a module followed by parameters (might be mandatory for ISA cards, see examples below).
Click <b>Unload</b> to unload a currently loaded module (so that you can then load an alternative).
Click <b>Auto-probe</b> to try loading ALL the modules in the list.

Example1: ne io=0x000, 
Example2: arlan  io=0x300 irq=11
(Example1 works for most ISA cards and does some autoprobing of io and irq)"
L_BUTTON_Specify="Specify"
L_BUTTON_Autoprobe="Auto-probe"

L_TOPMSG_Load_Module_None_Selected="REPORT ON LOADING OF MODULE: No module was selected"
L_TOPMSG_Load_Module_Cancel="REPORT ON LOADING OF MODULE: No module was loaded"

L_MESSAGE_One_New_Interface="The following new interface has been found"
L_MESSAGE_Multiple_New_Interfaces="The following new interfaces have been found"

L_FRAME_New_Interfaces="New interfaces"
L_LABEL_New_Interfaces_Tree_Header="Interface|Type|Module|Device description"
L_TEXT_New_Interfaces_p1="Click the 'Save' button to save the selection, so that Puppy will automatically load"
L_TEXT_New_Interfaces_p2="at bootup.
\\Click Cancel to just go back and configure the new interface."

L_TEXT_No_New_Interfaces1="No new interfaces were detected."
L_TEXT_No_New_Interfaces2="Click the 'Unload' button to unload the new module and try to load another one."

L_TITLE_New_Module_Loaded="New module loaded"
L_TEXT_New_Module_Loaded="The following new module has been loaded:"

L_TOPMSG_New_Module_Save="New module information saved"
L_TOPMSG_New_Module_Unload="New module unloaded"
L_TOPMSG_New_Module_Cancelled="Cancelled"

L_TOPMSG_Load_Module_None_Loaded="REPORT ON LOADING OF MODULE: No module was loaded"

# function: tryLoadModule
L_TITLE_Netwiz_Hardware="Puppy Network Wizard: hardware"
L_MESSAGE_Driver_Loaded="The driver is already loaded.\nThat does not mean it will actually work though!\nAfter clicking OK, see if a new interface\nhas been detected."
L_MESSAGE_Driver_Success_p1="Module"
L_MESSAGE_Driver_Success_p2="has loaded successfully.
That does not mean it will actually work though!
After clicking OK, see if a new interface
has been detected."

L_MESSAGE_Driver_Failed_p1="Loading "
L_MESSAGE_Driver_Failed_p2="failed with the following message:
"
L_MESSAGE_Driver_Failed_p3="Maybe try a different driver.
"

# function: giveAcxDialog
L_TEXT_Acx_Module_p1="The interface you selected uses the module"
L_TEXT_Acx_Module_p2="
Unloading this module is known to cause the system to become unstable and Ndiswrapper will most likely not work.

It is recommended to blacklist the module and reboot, then Ndiswrapper can be used without fear.

Would you like to blacklist the module, so all you need to do is reboot, or will you dare and try unloading it?
"

# function: askWhichInterfaceForNdiswrapper
L_TEXT_Ask_Which_Interface_For_Ndiswrapper="<b>One thing before we can use Ndiswrapper:</b>
Your network card can only be used with one driver at a time. This means that if there already is a driver using it (i.e. there was an interface matching it in the main dialog), we will need to unload that driver before we can use Ndiswrapper.

To do so, just press the button matching the relevant interface. If no interface matches your hardware, press 'none'.
"
L_BUTTON_None="none"

L_MESSAGE_Remove_Module_Failed_p1="Error!
Failed to unload module"
L_MESSAGE_Remove_Module_Failed_p2="
The following error was returned:"

# function: loadNdiswrapperModule
L_MESSAGE_Blacklist_Nativemod_p1="The module"
L_MESSAGE_Blacklist_Nativemod_p2="was previously loaded and had
to be removed in order for ndiswrapper to work.
Would you like to have this module added to the list 
of blacklisted modules, so that it will not be 
loaded when booting? 
Note, you can always remove it later, by running the
BootManager (see System menu)"

# function: loadSpecificModule
L_TITLE_Load_A_Module="Load A Module"
L_TEXT_Load_A_Module="Please type the name of a specific module to load
(extra parameters allowed, but don't type tab chars)."

# function: autoLoadModule
L_MESSAGE_Success_Loading_Module_p1="Success loading the"
L_MESSAGE_Success_Loading_Module_p2="module. That does not mean it will actually work though!
After clicking OK, back on the main window if you see a new active interface
proceed to configure it.

NOTE: it is possible that a module loads ok, but it is a false hit, that is, does
not actually work with your network adaptor. In that case, try autoprobing again. 
This script will remember the previous attempts (until you exit this script) and will
jump over them.
If you do get false hits, let us know about it on the Puppy Discussion Forum!"

L_MESSAGE_No_Module_Loaded="No module loaded successfully.

Note however that these modules are already loaded:"

# function: offerToBlacklistModule
L_TEXT_Blacklist_Module_p1="Module"
L_TEXT_Blacklist_Module_p2="removed successfully.

Would you like to blacklist it, so that in the
future it will not get loaded while booting?
"

# function: unloadSpecificModule
L_MESSAGE_No_Loaded_Items="Error!
It seems like no network modules are currently loaded...
"

L_TITLE_Unload_A_Module="Unload A Module"
L_TEXT_Unload_A_Module="Please select the module you
wish to unload, then press 'Unload'..."
L_COMBO_Module="Module:"

# function: findLoadedModules
L_PROGRESS_Checking_Loaded_Modules="Checking loaded modules"

# function: testInterface
L_MESSAGE_Failed_Raise_Interface_p1="Error!
Failed to raise interface"
L_MESSAGE_Failed_Raise_Interface_p2="Failed command was:"
L_MESSAGE_Failed_Raise_Interface_p3="Error returned was:"

L_PROGRESS_Testing_Interface="Testing Interface"

L_TOPMSG_Report_On_Test='REPORT ON TEST OF $INTERFACE CONNECTION:'
L_TOPMSG_Unplugged_Wireless="'Unable to connect to a wireless network'
Verify that the wireless network is available and
that you have provided the correct wireless parameters."
L_TOPMSG_Unplugged_Wired="'Unable to connect to the network'
Verify that the network is available and
that the ethernet cable is plugged in."
L_TOPMSG_Network_Alive="'Puppy was able to find a live network'
You can proceed to acquire an IP address."

# function: showConfigureInterfaceWindow
L_TOPMSG_Configuration_Cancelled='NETWORK CONFIGURATION OF $INTERFACE CANCELED!'
L_BUTTON_Done="Done"

L_TOPMSG_Configuration_Unsuccessful='NETWORK CONFIGURATION OF $INTERFACE UNSUCCESSFUL!'
L_TOPMSG_Configuration_Offer_Try_Again="Try again, click 'Back' to try a different interface or click 'Done' to give up for now."
L_TOPMSG_Configuration_Successful='NETWORK CONFIGURATION OF $INTERFACE SUCCESSFUL!'
L_TOPMSG_Configuration_Offer_To_Save="
Do you want to save this configuration?

If you want to keep this configuration for next boot: click 'Yes'.
If you just want to use this configuration for this session: click 'No'."
L_TOPMSG_Configuration_Offer_To_Finish="
If there are no more interfaces to setup and configure, just click 'Done' to get out."
L_TOPMSG_Configuration_Not_Saved="The configuration was not saved for next boot.

If there are no more interfaces to setup and configure, just click 'Done' to get out."

# function: buildConfigureInterfaceWindow
L_TITLE_Configure_Interface='Configure network interface $INTERFACE'
L_FRAME_Test_Interface="Test interface"
L_BUTTON_Test_Interface='Test $INTERFACE'
L_FRAME_Configure_Interface="Configure interface"
L_BUTTON_Auto_DHCP="Auto DHCP"
L_BUTTON_Static_IP="Static IP"

# function: initializeConfigureInterfaceWindow
L_TOPMSG_Initial_Lets_try="OK, let's try to configure"
L_TESTMSG_Initial_p1="You can test if"
L_TESTMSG_Initial_p2="is connected to a 'live' network.
After you confirm that, you can configure the interface."
L_DHCPMSG_Initial="The easiest way to configure the network is by using a DHCP server (usually provided by your network). This will enable Puppy to query the server at bootup and automatically be assigned an IP address. The 'dhcpcd' client daemon program is launched and network access happens automatically."
L_STATICMSG_Initial="If a DHCP server is not available, you will have to do everything manually by setting a static IP, but this script will make it easy."

L_FRAME_Configure_Wireless="Configure wireless network"
L_TEXT_Configure_Wireless_p1="Puppy found that"
L_TEXT_Configure_Wireless_p2="is a wireless interface.
To connect to a wireless network, you must first set the wireless network parameters by clicking on the 'Wireless' button, then assign an IP address to it, either with DHCP or Static IP (see below)."
L_BUTTON_Wireless="Wireless"

# function: configureWireless
L_TOPMSG_Wireless_Config_Failed_p1="WIRELESS CONFIGURATION OF"
L_TOPMSG_Wireless_Config_Failed_p2="FAILED!
You might want to try using a different profile. "
L_TOPMSG_Wireless_Config_Cancelled_p1="WIRELESS CONFIGURATION OF"
L_TOPMSG_Wireless_Config_Cancelled_p2="CANCELED!
To connect to a wireless network you have to select a profile to use. "

# function: buildStaticIPWindow
L_TITLE_Set_Static_IP="Set Static IP"
L_TEXT_Set_Static_IP="Please enter your static IP parameters:
- If you use a router, check its status page for these values. 
- If you connect directly to your modem, you will need
to get these values from your ISP.
(To directly connect two computers: set all but the IP and 
Netmask to 0.0.0.0)

Use only dotted-quad decimal format (xxx.xxx.xxx.xxx).
Other formats will not be recognized.
"
L_FRAME_Static_IP_Parameters="Static IP parameters"
L_ENTRY_IP_Address="IP address:"
L_ENTRY_Net_Mask="Net Mask:"
L_ENTRY_Gateway="Gateway:"
L_FRAME_DNS_Parameters="DNS parameters"
L_ENTRY_DNS_Primary="Primary:"
L_ENTRY_DNS_Secondary="Secondary:"

# function: validateStaticIP
L_ERROR_Invalid_IP="Invalid IP Address"
L_ERROR_Invalid_Netmask="Invalid Netmask"
L_ERROR_Invalid_Gateway="Invalid Gateway address"
L_ERROR_Invalid_DNS1="Invalid DNS server 1 address"
L_ERROR_Invalid_DNS2="Invalid DNS server 2 address"

L_MESSAGE_Bad_addresses="Error!
Some of the addresses provided are invalid."

L_MESSAGE_Bad_Netmask="WARNING:
Your netmask does not correspond to your network address class.

Are you sure it is correct?"

L_MESSAGE_Bad_Gateway_p1="Error!
Your gateway"
L_MESSAGE_Bad_Gateway_p2="is not on this network.
(You may have entered your address, gateway or netmask incorrectly.)
"

# function: setupStaticIP
L_MESSAGE_Route_Set='Default route set through $GATEWAY.'
L_MESSAGE_Route_Failed_p1="Error!
Could not set default route through"
L_MESSAGE_Route_Failed_p2="Note that Puppy has tried to do this:"
L_MESSAGE_Route_Failed_p3="and got the following error message:"

L_MESSAGE_Ifconfig_Failed_p1="Error! Interface configuration failed.

Puppy has just tried to do this:"
L_MESSAGE_Ifconfig_Failed_p2="and got the following error message:"
L_MESSAGE_Ifconfig_Failed_p3="
If you think that this is incorrect for your system 
and you can come up with something else that works,
please post it on the forum, so we can improve the wizard."

# function: saveNewModule
L_TOPMSG_Module_Saved_p1="MODULE"
L_TOPMSG_Module_Saved_p2="RECORDED IN /etc/ethernetmodules
Puppy will read this when booting up."

# function: unloadNewModule
L_TOPMSG_Module_Unloaded_p1="MODULE"
L_TOPMSG_Module_Unloaded_p2="UNLOADED.
Also,"
L_TOPMSG_Module_Unloaded_p3="removed from /etc/ethernetmodules (if it was there)."

# function: setDefaultMODULEBUTTONS
L_TEXT_Default_Module_Buttons="If it appears the driver module for a network adaptor isn't loaded, or you want a different one (such as a Windows driver with Ndiswrapper), click on the 'Load module' button."
L_BUTTON_Load_Module="Load module"

# function: findInterfaceInfo
L_INTTYPE_Wireless="Wireless"
L_INTTYPE_Ethernet="Ethernet"
L_INFO_Eth_Firewire="Ethernet over firewire"

L_MESSAGE_Already_Running="Network Wizard cannot start now because it is already active."
L_MESSAGE_Use_or_Terminate_Existing="Please use the active Network Wizard session or terminate it and start it again."
L_TOPMSG_Initial="Hi, networking is not always easy to setup, but let's give it a go!"

############### end net-setup.sh ###############


############### wag-profiles.sh ###############
L_FRAME_Progress="Progress"
L_BUTTON_Abort="Abort"
L_BUTTON_Retry="Retry"

# function: setupDHCP
L_TEXT_Dhcpcd_Progress='Connecting to DHCP server... timeout is $MAX_TIME seconds.'

# function: giveNoWPADialog
L_TEXT_No_Wpa_p1="Note: The interface you have selected uses the "
L_TEXT_No_Wpa_p2=" module, which is not included in our list of modules supporting WPA encryption."
L_BUTTON_Add_WPA="Add To List"
L_TEXT_No_Wpa_Ask="However, if you know for a fact that it <i>does</i> support WPA, or wish to test if it does (the only difference is being offered more options in the configuration dialog...), click the '$L_BUTTON_Add_WPA' button. This will add the module to a configuration file for future use."
L_TEXT_Wpa_Add_p1="The following details will be added to the configuration file, "
L_TEXT_Wpa_Add_p2="."
L_ENTRY_Wpa_Add_Module="Module:"
L_ENTRY_Wpa_Add_WEXT="wpa_supplicant driver:"

# function: buildProfilesWindow
L_TEXT_Profiles_Window="Please select a network profile to use.
To create a new profile, start by scanning for available 
networks and select the one you would like to configure. 
Newly created profiles should be <b>saved</b> in order to be used."
L_BUTTON_Scan="Scan"
L_FRAME_Load_Existing_Profile="Load an existing profile"
L_TEXT_Select_Profile="Select a profile to load:"
L_FRAME_Edit_Profile="Edit profile"
L_TEXT_Encryption="Encryption:    "
L_BUTTON_Open="Open"
L_TEXT_Profile_Nmae="Profile
Name:   "
L_TEXT_Essid="ESSID:    "
L_TEXT_Mode="Mode:"
L_CHECKBOX_Managed="Managed"
L_CHECKBOX_Adhoc="Ad-hoc "
L_TEXT_Security="Security: "
L_CHECKBOX_Open="Open"
L_CHECKBOX_Restricted="Restricted"
L_BUTTON_Delete="Delete"
L_BUTTON_Use_Profile="Use This Profile"
L_BUTTON_New_Profile="New Profile"

# function: setWepFields
L_TEXT_Key="Key:"

# function: setWpaFields
L_TEXT_AP_Scan="AP Scan:"
L_CHECKBOX_Hidden_SSID="Hidden SSID"
L_CHECKBOX_Broadcast_SSID="Broadcast SSID"
L_CHECKBOX_Driver="Driver"
L_TEXT_Shared_Key="Shared Key:"

# function: setAdvancedFields
L_LABEL_Advanced="Advanced"
L_LABEL_Basic="Basic"
L_TEXT_Frequency="Frequency:"
L_TEXT_Channel="Channel:"
L_TEXT_AP_MAC="Access Point
     MAC:"

# function: saveProfiles
L_MESSAGE_Bad_Profile="Error!
The profile had no network associated with it.
You must run a wireless scan and select a
network, then create a profile for it."

# function: getWpaPSK
L_MESSAGE_Bad_PSK="Error!
wpa_passphrase failed to generate the psk
from your key and SSID!
Please report this on the forum, so that
we can try and find the problem.
"

# function: cleanUpInterface
L_MESSAGE_Failed_To_Raise_p1="Error!
Failed to raise interface "
L_MESSAGE_Failed_To_Raise_p2=".
Failed command was:"
L_MESSAGE_Failed_To_Raise_p3="Error returned was:"

# function: useIwconfig / useWlanctl
L_MESSAGE_Configuring_Interface_p1="Configuring interface "
L_MESSAGE_Configuring_Interface_p2=" 
to network "

# function: validateWpaAuthentication
L_ECHO_Status_p1="Time: "
L_ECHO_Status_p2="	Status: "

# function: useWpaSupplicant
L_MESSAGE_No_Wpaconfig_p1="Error!
Could not find the wpa_supplicant configuration file:"
L_MESSAGE_No_Wpaconfig_p2="
Note that you must save the profile before you can use it!"

L_TEXT_WPA_Progress_p1="Acquiring "
L_TEXT_WPA_Progress_p2=" connection from "
L_TEXT_WPA_Progress_p3="...(30 sec. timeout)"

L_ECHO_Starting="Starting"
L_ECHO_Initializing_Wpa="Initializing wpa_supplicant"

#131224 shinobar: retry with WPA/AES
L_MESSAGE_TKIP_Failed="WPA/TKIP failed, but you can retry with AES."
L_MESSAGE_WPA_Failed="Unable to establish WPA connection"
L_BUTTON_Details="Details"

L_FRAME_Connection_Info="Connection info"
L_FRAME_wpa_cli_Outeput="Output of "
L_BUTTON_Refresh="Refresh"

# function: waitForPCMCIA
L_PROGRESS_Waiting_For_PCMCIA="Waiting for pcmcia device to settle"

# function: showScanWindow
L_PROGRESS_Scanning_Wireless="Scanning wireless networks"

# function: buildScanWindow
L_SCANWINDOW_Encryption="Encryption:"
L_SCANWINDOW_Channel="Channel:"
L_SCANWINDOW_Frequency="Frequency:"
L_SCANWINDOW_AP_MAC="AP MAC:"
L_SCANWINDOW_Strength="Strength:"

L_TEXT_Scanwindow="Select one of the available networks
	Move the mouse over to see more details."

# function: createNoNetworksDialog
L_TEXT_No_Networks_Detected="No networks were detected.

Maybe your router is turned off?
Maybe there is a Wireless switch on your laptop
that needs to be turned on?"

# function: createRetryScanDialog
L_TEXT_No_Networks_Retry=" No networks were detected. 
 Would you like to try and scan again?
"

# function: createRetryPCMCIAScanDialog
L_TEXT_No_Networks_Retry_Pcmcia="No networks were detected.
However, you seem to be using a PCMCIA device, 
which might require resetting in order for the scan to work.
Would you like to reset the card and scan again?
"

# function: buildPrismScanWindow (many used from buildScanWindow above)
L_SCANWINDOW_Hidden_SSID="(hidden SSID)"
L_TEXT_Prism_Scan="Select one of the available networks
	Move the mouse over to see more details."

# function: setupScannedProfile
L_TEXT_Provide_Key="Provide a key"
############### end wag-profiles.sh ###############



############### ndiswrapperGUI.sh ###############
L_TITLE_Netwiz_Ndiswrapper="Puppy Network Wizard: Ndiswrapper"
L_TEXT_Ndiswrapper_Chooser="Please select the driver information file (.INF)."

L_MESSAGE_Bad_Inf_Name="
Error!
The file name should end in .inf
Please try again.
"

############### end ndiswrapperGUI.sh ###############


############### rc.network ###############
L_TITLE_Success="Success"
L_MESSAGE_Success="Success"
L_TITLE_Failure="Failure"
L_MESSGAE_Failed="Failed"

L_MESSAGE_Failed_To_Connect="
  Failed to connect to any networks.
  If you have not yet configured any network interfaces,
  you should do so with the Network Wizard.
  (debug messages can be found in /tmp/network-connect.log)"

############### end rc.network ###############
