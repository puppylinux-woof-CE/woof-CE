#!/bin/sh

# GUI to download early or late loading microcode for AMD and Intel
# GPLv2

. /etc/rc.d/PUPSTATE
. /etc/DISTRO_SPECS


exit_error() {
	box_ok "Error" error "$1"
	exit 1
}

info_msg() {
	box_ok "Info" info "$1"
}
EARLY=0 # true

#### exclusions and special cases
MSG1=$(gettext 'Your initrd.gz resides on an unsupported file system, however late loading may work if your main filesystem is writeable.')
MSG2=$(gettext 'Unsupported CPU Architecture.')
MSG3=$(gettext 'This program does not support a Virtual Machine.')
MSG4=$(gettext 'The puppy home drive is read only, however if saving session late loading is supported.')
MSG5=$(gettext 'Your CPU vendor is unsupported.')
INITRD_DIR=/mnt/home${PSUBDIR}

if [ "$PMEDIA" = 'cd' -o $PUPMODE -eq 77 ];then 
	EARLY=1
	info_msg "$MSG4"
	SENSITIVE='<sensitive>false</sensitive>'
elif echo 1 > $INITRD_DIR/test.txt >/dev/null 2>&1 ;then # check if it's writeable
	rm $INITRD_DIR/test.txt
else
	EARLY=1
	info_msg "$MSG1"
fi
case $(uname -m) in
	x86_64|i?86|amd64);;
	*) exit_error "$MSG2" ;;
esac
grep -qim1 'hypervisor' /proc/cpuinfo && exit_error "$MSG3"
####

TITLE=$(gettext 'Microcode Options')
if grep -qm1 'AuthenticAMD' /proc/cpuinfo ; then
	CVENDOR=AMD
	N_VEND=Intel # opposite
	CICON=amd_logo.svg
elif grep -qm1 'GenuineIntel' /proc/cpuinfo ; then
	CVENDOR=Intel
	N_VEND=AMD # opposite
	CICON=intel_logo.svg
else
	exit_error "$MSG5"
fi
PROCESSOR1=$(gettext 'Your system has an ')
PROCESSOR2=$(gettext ' processor.')
EL=$(gettext "Early Loading")
LL=$(gettext "Late Loading")
EARLY_BLURB=$(gettext 'Your system supports early loading of CPU microcode. This is the recommended option. Microcode files are downloaded from the Internet to fix well documented CPU bugs like Spectre and Meltdown then inserted into your boot loader so the bug fixes are available at boot. Optionally, you can include microcode from ')
EARLY_BLURB2=$(gettext ' This is useful if you have a <b>USB</b> or other portable installation.')
DOWLD_EARLY=$(gettext 'Download and install Early Microcode')
DOWLD_LATE=$(gettext 'Download and install Late Microcode')
CH_BLURB1=$(gettext 'Include microcode for ')
CH_BLURB="$CH_BLURB1 $N_VEND"
LATE_CH_BLURB=$(gettext 'Check to run Late loading after installation')
XVENDOR=$CVENDOR
if [ $EARLY -eq 1 ];then
	EARLY_BLURB=$(gettext 'Your system does not support early loading')
fi
LATE_BLURB=$(gettext 'Late loading is supported after initial boot to fix CPU bugs like Spectre and Meltdown, but can be configured to start just after boot. Early loading should be disabled. Only one file is downloaded from the internet and run from the operating system.')
LATE2=$(gettext ' microcode specific to your processor family will be downloaded and installed.')
if dmesg | grep -qm1 'microcode updated early' ;then
	LATE_BLURB=$(gettext 'Your microcode was updated early. Late loading of microcode is unsupported. If you want to use late loading then remove the ucode.cpio file where your puppy boot files are located and reboot your system then run this application again.')
	LATE2=''
	XVENDOR=''
	LSENSITIVE='<sensitive>false</sensitive>'
fi
export GUI='<window title="'$TITLE'" icon-name="gtk-execute" resizable="false">
	<vbox width-request="500">
	<frame '$EL'>
	'"$(/usr/lib/gtkdialog/xml_info fixed /usr/share/pixmaps/$CICON 60 "$PROCESSOR1 <b>$CVENDOR</b> $PROCESSOR2 $EARLY_BLURB <b>$N_VEND</b>. $EARLY_BLURB2")"' 
		<hbox>
			<text><label>"'$CH_BLURB'"</label>'$SENSITIVE'</text>
			<checkbox>
				<label>" "</label>
				<default>true</default>
				<variable>cb0</variable>
				'$SENSITIVE'
			</checkbox>
		</hbox>
		<hbox>
			<text><label>"'$DOWLD_EARLY'"</label>'$SENSITIVE'</text>
			<button>
				<label>Download</label>
				<input file stock="gtk-execute"></input>
				'$SENSITIVE'
				<action function="exit">dld_e</action>
			</button>
		</hbox>
	</frame>
	<frame '$LL'>
	'"$(/usr/lib/gtkdialog/xml_info fixed /usr/share/pixmaps/puppy/execute.svg 60 "$LATE_BLURB $XVENDOR $LATE2")"' 
		<hbox>
			<text><label>"'$LATE_CH_BLURB'"</label>'$LSENSITIVE'</text>
			<checkbox>
				<label>" "</label>
				<default>true</default>
				<variable>cb1</variable>
				'$LSENSITIVE'
			</checkbox>
		</hbox>
		<hbox>
			<text><label>"'$DOWLD_LATE'"</label>'$LSENSITIVE'</text>
			<button>
				<label>Download</label>
				<input file>/usr/share/pixmaps/'$CICON'</input>
				<width>16</width>
				'$LSENSITIVE'
				<action function="exit">dld_l</action>
			</button>
		</hbox>
	</frame>
		<hbox><button cancel></button></hbox>
	</vbox>
	
</window>
'
. /usr/lib/gtkdialog/xml_info gtk
eval $(gtkdialog -p GUI --styles=/tmp/gtkrc_xml_info.css)

case $cb0 in
	true) param='';;
	false)param=$CVENDOR;;
esac

case $EXIT in
	dld_e)
	/usr/lib/gtkdialog/box_splash -close box -icon gtk-execute -bg '#FFCC38' -text "$(gettext 'Please wait a moment ..')" &
	bpid=$!
	if latest_microcode.sh $param ; then
		kill -9 $bpid
		/usr/lib/gtkdialog/box_splash -close box -timeout 4 -icon gtk-execute -bg '#38FF44' -text "$param $(gettext 'microcode ucode.cpio is generated and installed')"
		exit 0
	else
		kill -9 $bpid
		/usr/lib/gtkdialog/box_splash -close box -timeout 4 -icon gtk-execute -bg '#FF3898' -text "$param $(gettext 'microcode ucode.cpio failed to install')"
		exit 1
	fi
	;;
	dld_l)
	/usr/lib/gtkdialog/box_splash -close box -icon gtk-execute -bg '#FFCC38' -text "$(gettext 'Please wait a moment ..')" &
	cpid=$!
	if [ "$cb1" = 'true' ];then
		if /etc/init.d/rc.ucode start ;then # calls get_ucode.sh and loads the file
			kill -9 $cpid
			/usr/lib/gtkdialog/box_splash -close box -timeout 4 -icon gtk-execute -bg '#38FF44' -text "$(gettext 'microcode for your chip is downloaded and installed')"
			exit 0	
		else
			kill -9 $cpid
			/usr/lib/gtkdialog/box_splash -close box -timeout 4 -icon gtk-execute -bg '#FF3898' -text "$param $(gettext 'microcode for your chip failed to downloaded and install')"
			exit 1	
		fi
	else
		if get_ucode.sh ;then
			kill -9 $cpid
			/usr/lib/gtkdialog/box_splash -close box -timeout 4 -icon gtk-execute -bg '#38FF44' -text "$(gettext 'microcode for your chip is downloaded and installed')"
			exit 0	
		else
			kill -9 $cpid
			/usr/lib/gtkdialog/box_splash -close box -timeout 4 -icon gtk-execute -bg '#FF3898' -text "$param $(gettext 'microcode for your chip failed to downloaded and install')"
			exit 1	
		fi
	fi
		;;
	*)exit 0;;
esac

exit 0
