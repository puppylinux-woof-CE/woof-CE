#!/bin/dash
# Setup desktop screen resolution (=new xorgwizard)
# Copyright (C) James Budiono 2012, 2013, 2014
# License: GNU GPL Version 3 or later
#
# This is a total re-write from the old xorgwizard for Fatdog 611
# Does everything the old one does except setting of monitor horz/vert frequencies
#
#### configuration
APPTITLE="Xorgwizard"
DRIVER_PATH=/usr/lib*/xorg/modules/drivers
OUTPUT_FILE=/etc/X11/xorg.conf.d/20-gpudriver.conf
#OUTPUT_FILE=/dev/console
TMP_XINIT=/tmp/xinit_test

### setup known resolutions and drivers
# returns AVAIL_RES, AVAIL_RES_COLOR, DRIVERS, DIALOG
setup() {
	DIALOG="dialog"
	[ "$DISPLAY" ] && DIALOG="Xdialog"
	
	# ddcprobe sometimes hangs, so make sure we only use it if it's good.
	DDCPROBE=$(which ddcprobe)
	$DDCPROBE > /dev/null &
	sleep 1	# shoudn't take more than a second to probe
	if pidof ddcprobe > /dev/null; then
		killall ddcprobe
		DDCPROBE=true	# don't probe
	fi
	
	DRIVERS=$(ls ${DRIVER_PATH}/*.so | sed "/\/dummy_/d; s_${DRIVER_PATH}/__; s/_drv\.so//")
	AVAIL_RES_COLOR=$($DDCPROBE | sed -n '/^mode:/ { s/.* //; p}')				
	AVAIL_RES="auto 
		$({ # add common resolutions so the list of not blank if ddcprobe returns nothing
		echo 640x480
		echo 800x600
		echo 1024x768
		echo 1280x1024
		# modes
		$DDCPROBE | sed -n '/^mode:/ { s/.* //; s/x/@/2; s/@.*//; p}'
		# timing
		$DDCPROBE | awk '/^[c-d]*timing/ {gsub(/@.*/,"",$2); print $2}'
		} | sort -h | uniq) 
		custom"
	AVAIL_FB=$(ls /dev/fb* 2> /dev/null)
	AVAIL_CARDS=$(lspci | sed -n '/VGA/ {s/ / "/;s/$/"/;p}')
}

### dialog or Xdialog
# input: DIALOG
dlg() {
	$DIALOG --stdout --title "$APPTITLE" "$@"
}

### choose driver
# input: DRIVERS
# output: drvchoice
choose_driver() {
	drv=
	for p in $DRIVERS; do
		case $p in # list known drivers
			ati) desc="very old ATI cards" ;;
			fbdev) desc="Generic framebuffer driver" ;;
			fglrx) desc="AMD Catalyst proprietary" ;;
			nvidia) desc="NVidia proprietary" ;;
			i128) desc="old Intel cards" ;;
			intel) desc="modern Intel cards (KMS)" ;;
			nouveau) desc="new Nvidia driver (KMS)" ;;
			nv) desc="old Nvidia driver" ;;
			radeon) desc="ATI/AMD Radeon cards (KMS)" ;;
			sis) desc="SIS cards" ;;
			sisusb) desc="SIS video over USB" ;;
			vesa) desc="Generic video driver" ;;
			vmware) desc="VMware driver" ;;
			vmwlegacy) desc="legacy VMware driver" ;;
			dummy) desc="Dummy driver - don't use this" ;;
			*) desc=$p ;;
		esac
		drv="$drv $p \"$desc\""
	done
	drvchoice=$(eval dlg --menu "\"Choose Driver\"" 20 60 10 $drv);
}

# input drvchoice; output: busid (it is actually /dev/fb for fbdev)
choose_card() {
	case $drvchoice in 
		fbdev)
			[ $(echo $AVAIL_FB | wc -l) -lt 2 ] && busid=auto && return
			busid=$(eval dlg --menu "\"Choose Framebuffer Device\"" 20 60 10 $(echo auto $AVAIL_FB | sed 's/\([^ ]*\)/\1 \1/g') );
			;;
		*)
			[ $(echo "$AVAIL_CARDS" | wc -l) -lt 2 ] && busid=auto && return
			if busid=$(eval dlg --menu "\"Choose Device\"" 20 60 10 auto auto $AVAIL_CARDS); then
				[ "$busid" != "auto" ] && busid=$(echo PCI:$busid | sed 'y/./:/') || true
			fi
			;;
	esac
}

### choose screen resolution & bit depth
# input: AVAIL_RES, AVAIL_RES_COLOR
# output reschoice, bitchoice, txtchoice, exit code 0 = ok, everything else = cancelled
choose_resolution() {
	res=
	for p in $AVAIL_RES; do
		case $p in
			auto) res="$res $p \"Let driver choose\"" ;;
			custom) res="$res $p \"Type in your own resolution\"" ;;
			*) res="$res $p \"${p%x*} x ${p#*x}\"" ;;
		esac
	done

	while true; do
	
		# 1. resolution, if cancelled, exit
		if reschoice=$(eval dlg --menu "\"Choose Resolution\"" 20 60 10 $res); then	
		
			# 2. handle special "mode"
			case $reschoice in
				custom)
					# if cancelled re-select
					! reschoice=$(dlg --inputbox "Please enter your custom resolution in WidthxHeight (e.g 800x600)" 0 0 800x600) && continue
					;;
					
				auto)
					# accept immediately
					bitchoice=auto txtchoice=auto
					break
					;;
			esac
			
			# 3. bit-depth, if re-select
			bits="auto auto 4 16-colours 8 256-colours 15 32k-colours 16 64k-colours 24 16m-colours 32 16m-colours(32-bit)"	
			if bitchoice=$(dlg --menu "Choose Bit Depth for $reschoice" 20 60 10 $bits); then

				# 4. check whether chosen resolution is in ddcprobe list 
				case $bitchoice in
					4)  res1=${reschoice}x16  txtchoice="${reschoice} 16 colours";;
					8)  res1=${reschoice}x256 txtchoice="${reschoice} 256 colours";;
					15) res1=${reschoice}x32k txtchoice="${reschoice} 32k colours";;
					16) res1=${reschoice}x64k txtchoice="${reschoice} 64k colours";;
					24) res1=${reschoice}x16m txtchoice="${reschoice} 16m colours";;
					32) res1=${reschoice}x16m txtchoice="${reschoice} 16m colours (32-bit)";;
					auto) res1=${reschoice}   txtchoice="${reschoice} auto"
				esac
				
				# 5. if listed, then accept, otherwise confirm usage, otherwise re-select
				case "$AVAIL_RES_COLOR" in
					*${res1}*) break ;;
					*) dlg --yesno "The resolution and bit depth you have chosen: 

${txtchoice} 

is not listed in the list of supported resolutions.
It may or may not work on your system.
You will be given a chance to test it later.

Choose YES if you want to use this, or NO to re-select." 0 0  && break ;;
				esac						
			fi
						
		else # resolution cancelled 
			return 1 # cancelled
		fi
	done
	return 0;
}


### write Xorg config fragment
# $1-resolution $2-bit depth $3-driver (vesa if blank), $4-fbdev/busid
write_xorg_fragment() {
	driver=$3
	[ -z "$driver" ] && driver=vesa

	# write the driver & optionally the card
	cat << EOF
Section "Device"
    Identifier             "Device0"
    Driver                 "$driver" #Choose the driver used for this monitor
EOF
    [ -n "$4" ] && [ "$4" != "auto" ] && case $driver in 
		fbdev) echo "    Option \"fbdev\" \"$4\"" ;;
		*) echo "    BusID \"$4\"" ;;
    esac
	echo "EndSection"
	
	# set resolution, if requested
	if [ "$1" != "auto" ]; then
	
		# bit depth settings
		DEFAULTDEPTH="" DEPTH="" FBBPP=""
		case $2 in
			auto) ;; # no settings, keep it blank
			32)   FBBPP=32 DEPTH=24 DEFAULTDEPTH=24 ;;
			*)    DEPTH=$2 DEFAULTDEPTH=$2 ;;
		esac
		[ $DEFAULTDEPTH ] && DEFAULTDEPTH="DefaultDepth            $DEFAULTDEPTH" 
		[ $DEPTH ] && DEPTH="Depth               $DEPTH" 
		[ $FBBPP ] && FBBPP="FbBpp               $FBBPP" 
		cat << EOF
		
Section "Monitor"
    Identifier             "Monitor0"
EndSection

Section "Screen"
    Identifier             "Screen0"
    Device                 "Device0"
    Monitor                "Monitor0"
    $DEFAULTDEPTH
    SubSection             "Display"
        Modes              "$1"
        $DEPTH
        $FBBPP
    EndSubSection
EndSection 
EOF
	fi
}

### test the chosen resolution
# $1 txtchoice $2-drvchoice $3-fbdev/busid
xtest() { 
	if [ $DISPLAY ]; then
		dlg --yesno "You are already running X server so you can't test this.
		
If you click YES these settings will be applied:
---
Resolution: \"$1\"
Driver: \"$2\"
Device/card: \"$3\"
---
or otherwise click NO to choose again." 0 0	

	else
		# 1. show summary
		dlg --msgbox "Screen Setup Testing
	
Resolution and bit-depth: $1
Driver: $2
Fbdev/BusID: $3

The screen will switch to graphics mode and show a message for 15 seconds. \
If you fail to see anything, wait for 15 seconds. \
If you still fail to see anything, try pressing Ctrl-Alt-Backspace. \
If that still doesn't work, restart the system." 0 0			

		# 2. prepare
		TMP_XINIT=$(mktemp -p /tmp xinit_test.XXXXXXXX)
		cat > $TMP_XINIT << EOF
#!/bin/dash
INFO=\$(xrandr -q | awk '/\*/ { sub(/[^0-9]*\$/,"",\$2); print \$1, \$2}')
INFO_RES=\${INFO%% *}
INFO_HZ=\${INFO##* }
xmessage -font "7x14" -center -timeout 15 -buttons "OK:10" -default OK " 
Fatdog XorgWizard: testing X

If you can see this, then X is working!

Chosen resolution :         $1
Current resolution:         \${INFO_RES} pixels
Vertical refresh frequency: \${INFO_HZ} Hz (times per second)

Please click the 'OK' button, or if your mouse isn't working,
just hit the ENTER key, or the combination CTRL-ALT-BACKSPACE.

If you don't do anything, this test will timeout in 15 seconds."	
EOF
		chmod +x $TMP_XINIT
		
		# 3. do the test
		xinit $TMP_XINIT -- /usr/bin/Xorg :9
		
		# 4. cleanup and confirm
		rm -f $TMP_XINIT
		dlg --yesno "Click YES if the screen is working for you, 
or NO if you want to choose again." 0 0		
	fi
}


############ main ########
# 1. setup
setup

# 2. access check
if [ $(id -u) -ne 0 ]; then
	dlg --msgbox "You need to be root to do this." 0 0
	exit
fi

# 3. actual setup
[ -e $OUTPUT_FILE ] && cp $OUTPUT_FILE ${OUTPUT_FILE}.bak	# make sure we can recover.
while true; do
	# 1. choose resolution
	if choose_driver && choose_card && choose_resolution; then

		# 2. write the result
		write_xorg_fragment $reschoice $bitchoice $drvchoice $busid > $OUTPUT_FILE

		# 3. test chosen resolution
		if xtest "$txtchoice" $drvchoice $busid; then
			dlg --msgbox "Configuration saved to $OUTPUT_FILE.
Restart X to use the new configuration." 0 0
			break
		fi
	else 
		rm $OUTPUT_FILE
		[ -e ${OUTPUT_FILE}.bak ] && mv ${OUTPUT_FILE}.bak $OUTPUT_FILE
		dlg --msgbox "Cancelled. Nothing changed." 5 40
		break
	fi
done
