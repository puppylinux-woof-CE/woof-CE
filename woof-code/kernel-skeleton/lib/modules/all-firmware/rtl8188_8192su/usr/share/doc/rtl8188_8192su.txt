Release Date: 2009-0708, ver 0002 
RTL8192SU Linux driver
   --This driver supports RealTek rtl8192SU USB Wireless LAN NIC
     for
     2.6 kernel:
     Fedora Core 2/3/4/5, Debian 3.1, Mandrake 10.2/Mandriva 2006, 
     SUSE 9.3/10.1/10.2, Gentoo 3.1, Ubuntu 7.10/8.04, etc.
     2.4 kernel:
     Redhat 9.0/9.1

===============================================================================
				Component 
===============================================================================
The driver is composed of several parts:
	1. Firmare to make nic work
           1.1 firmare/RTL8192SU

	2. Module source code
	   2.1 ieee80211 
	   2.2 HAL/rtl8192u
	   2.3 wpa_supplicant-0.5.10 (User can download the latest version from 
	       internet also, but it is suggested to use default package contained
	       in the distribution because there should less compilation issue.)
	
	3. Script to build the modules
	   3.1 Makefile 

	4. Script to load/unload modules
	   4.1 wlan0up 
	   4.2 wlan0down 

	5. Script and configuration for DHCP
 	   5.1 wlan0dhcp
	   5.2 ifcfg-wlan0

	6. Example of supplicant configuration file:
	   6.1 wpa1.conf

	7. Script to run wpa_supplicant
	   7.1 runwpa

===============================================================================
				Installation 
===============================================================================
<<Method 1>>
Runing the scripts accomplish all operations including building up modules 
from the source code, installing driver to the kernel and starting up the nic.
	1. Build up the drivers from the source code
	  make

	2. Install the driver to the kernel
          make install
          reboot

	3. bring up wlan if nic is not brought up by GUI, such as NetworkManager
	  ifconfig wlan0 up 
	  Note: use ifconfig to check whether wlan0 is brought up and use iwconfig to check your wlan interface name, 
                since it may change wlan0 to wlan1,etc.

<<Method 2>>
Or only load the driver module to kernel and start up nic.
	 1. Build up the drivers from the source code
	  make
         2. Copy firmware to /lib/firmware/ or /lib/firmware/(KERNEL_VERSION)/
            cp -rf firmware/RTL8192SU /lib/firmware
          or
            cp -rf firmware/RTL8192SU /lib/firmware/(KERNEL_VERSION)
          Note: This depends on whether (KERNEL_VERSION) subdirectory exists under /lib/firmware

	 3. Load driver module to kernel and start up nic.
	  ./wlan0up
          Note: when "insmod: error inserting 'xxxx.ko': -1 File exists" comes out
                after run ./wlan0up, please run ./wlan0down first, then it should 
                be ok..
	  Note: If you see the message of "unkown symbol" during ./wlan0up, it
		is suggested to build driver by <<Method 1>>.

===============================================================================
				Set wireless lan MIBs 
===============================================================================
This driver uses Wireless Extension as an interface allowing you to set
Wireless LAN specific parameters.

Current driver supports "iwlist" to show the device status of nic
        iwlist wlan0 [parameters]
where
        parameter explaination      	[parameters]    
        -----------------------     	-------------   
        Show available chan and freq	freq / channel  
        Show and Scan BSS and IBSS 	scan[ning]          
        Show supported bit-rate         rate / bit[rate]        

For example:
	iwlist wlan0 channel
	iwlist wlan0 scan
	iwlist wlan0 rate

Driver also supports "iwconfig", manipulate driver private ioctls, to set
MIBs.

	iwconfig wlan0 [parameters] [val]
where
	parameter explaination      [parameters]        [val] constraints
        -----------------------     -------------        ------------------
        Connect to AP by address    ap              	[mac_addr]
        Set the essid, join (I)BSS  essid             	[essid]
        Set operation mode          mode                {Managed|Ad-hoc}
        Set keys and security mode  key/enc[ryption]    {N|open|restricted|off}

For example:
	iwconfig wlan0 ap XX:XX:XX:XX:XX:XX
	iwconfig wlan0 essid "ap_name"
	iwconfig wlan0 mode Ad-hoc
	iwconfig wlan0 mode essid "name" mode Ad-hoc
	iwconfig wlan0 key 0123456789 [2] open
	iwconfig wlan0 key off
	iwconfig wlan0 key restricted [3] 0123456789
        Note: Better to set these MIBS without GUI such as NetworkManager and be sure that our
              nic has been brought up before these settings. WEP key index 2-4 is not supportted by
              NetworkManager.

===============================================================================
				Getting IP address
===============================================================================
After start up the nic, the network needs to obtain an IP address before
transmit/receive data.
This can be done by setting the static IP via "ifconfig wlan0 IP_ADDRESS"
command, or using DHCP.

If using DHCP, setting steps is as below:
	(1)connect to an AP via "iwconfig" settings
		iwconfig wlan0 essid [name]	or
		iwconfig wlan0 ap XX:XX:XX:XX:XX:XX

	(2)run the script which run the dhclient
		./wlan0dhcp
           or 
		dhcpcd wlan0
              	(Some network admins require that you use the
              	hostname and domainname provided by the DHCP server.
              	In that case, use 
		dhcpcd -HD wlan0)
		

===============================================================================
			WPAPSK/WPA2PSK 
===============================================================================
	Wpa_supplicant helps to secure wireless connection with the protection of 
WPAPSK/WPA2PSK mechanism. 

	If the version of Wireless Extension in your system is equal or larger than 18, 
WEXT driver interface is recommended. Otherwise, IPW driver interface is advised.  
	Note: Wireless Extension is defined us "#define WIRELESS_EXT" in Kernel
	Note: To check the version of wireless extension, please type "iwconfig -v"


 	If IPW driver interface is used, it us suggested to follow the steps from 1 to 6. 
If wpa_supplicant has been installed in your system, only steps 5 and 6 are required 
to be executed for WEXT driver interface.

	To see detailed description for driver interface and wpa_supplicant, please type
"man wpa_supplicant".  
	
	(1)Download latetest source code for wpa supplicant or use wpa_supplicant-0.5.10 
	   attached in this package. (It is suggested to use default package contained
           in the distribution because there should less compilation issue.)

	   Unpack source code of WPA supplicant:

	  tar -zxvf wpa_supplicant-0.5.10.tar.gz (e.g.) 
	  cd wpa_supplicant-0.5.10
	
	(2)Create .config file:
	  cp defconfig .config
	
	(3)Edit .config file, uncomment the following line if ipw driver interface 
	   will be applied:
	  #CONFIG_DRIVER_IPW=y.
		
	(4)Build and install WPA supplicant:
	  make
	  cp wpa_cli wpa_supplicant /usr/local/bin	
	
	NOTE:
	 1. If make error for lack of <include/md5.h>, install the openssl lib(two ways):
	  (1) Install the openssl lib from corresponding installation disc:
	      Fedora Core 2/3/4/5(openssl-0.9.71x-xx), 
	      Mandrake10.2/Mandriva10.2(openssl-0.9.7x-xmdk),
	      Debian 3.1(libssl-dev), Suse 9.3/10.0/10.1(openssl_devl), 
	      Gentoo(dev-libs/openssl), etc.
	  (2) Download the openssl open source package from www.openssl.org, build and 
	      install it.
	 2. If make errors happen in RedHat(and also Fedora Core) for kssl.h,
please add lines below into Makefile
	      CPPFLAGS+=-I/usr/kerboros/include
	 
	(5)Edit wpa_supplicant.conf to set up SSID and its passphrase.
	  For example, the following setting in "wpa1.conf" means SSID 
          to join is "BufAG54_Ch6" and its passphrase is "87654321".

	   Example 1: Configuration for WPA-PWK
	  network={
			ssid="BufAG54_Ch6"
			#scan_ssid=1 //see note 3
			proto=WPA
			key_mgmt=WPA-PSK
			pairwise=CCMP TKIP
			group=CCMP TKIP WEP104 WEP40
			psk="87654321"
			priority=2
		  }
	
	    Example 2: Configuration for LEAP
	    network={
			ssid="BufAG54_Ch6"
			key_mgmt=IEEE8021X
			group=WEP40 WEP104
			eap=LEAP
			identity="user1"
			password="1111"
		  }
	    Example 3: Linking to hidden ssid given AP's security policy exactly.(see note 3 below)
            ap_scan=2
	    network={
		ssid="Hidden_ssid"
		proto=WPA
		key_mgmt=WPA-PSK
		pairwise=CCMP
		group=CCMP
		psk="12345678"
	  	}
		
	    Example 4: Linking to ad-hoc (see note 4 below)
	    ap_scan=2
	    network={
		ssid="Ad-hoc"
                mode=1
		proto=WPA
		key_mgmt=WPA-NONE
		pairwise=NONE
		group=TKIP
		psk="12345678"
		}
	Note: 1. proto=WPA for WPA, proto=RSN for WPA2. 
	      2. If user needs to connect an AP with WPA or WPA2 mixed mode, it is suggested 
		 to set the cipher of pairwise and group to both CCMP and TKIP unless you 
		 know exactly which cipher type AP is configured.
	      3. When connecting to hidden ssid, explicit security policy should be given with 
		 ap_scan=2 being setting.
	      4. It is suggested setting ap_scan to 2 and mode to 1 when linking to or creating an ad-hoc. Group and pairwise
		 cipher type should also be explicit, always with group setting to TKIP or CCMP and pairwise setting
		 to NONE. Lower version wpa_supplicant may not allow setting group to CCMP with pairwise setting to NONE.
		 So if any problem, you may try to set both group and pairwise to CCMP, leaving other setting unchanged, when
	         connecting to an CCMP-encrypted ad-hoc.
	      5. More config setting option, please refer to wpa_supplicant.conf in wpa_supplicant.tar.gz that we provide.

	(6)Execute WPA supplicant (Assume rtl8192E and related modules had been
           loaded):
           ./runwpa

           Note: The script runwpa will check Wireless Extension version automatically.
                 If the version of Wireless Extension is equal or larger than 18, the
                 option of "-D wext" is selected. If the version of Wireless extension
                 is less than 18, the option of "-D ipw" is selected.

