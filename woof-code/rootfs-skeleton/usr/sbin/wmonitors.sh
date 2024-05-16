#!/bin/bash

# Wmonitors, GPLv2 (/usr/share/doc/legal/)
# requires bash, wlr-randr, grim, gtkdialog, cut, sed, 


# various wl functions
. /etc/rc.d/wl_func

TEMPDIR=/tmp/wmon$$
mkdir -p $TEMPDIR
CWD=`pwd`
CFGDIR="$XDG_CONFIG_HOME/wmonitors"
[ -d "$CFGDIR" ] || mkdir -p $CFGDIR
BACKTITLE="$(gettext '<b>Wmonitors</b>. These settings are for monitor resolution, placement of monitors if you have multiple monitors, and screen orientation settings. Set them and press <b>Ok</b>.')"
ICON="graphics"

MONITORS=

# construct comboboxentry <items>
rnr_gui() { # $1 next iter, $2 is the monitor gui, $3 is the next delim until EOF
	cnt=0
	x=1
	while read z ; do 
		if [ "$1" = 'x' ]; then
			echo "$z" | grep -q "$2" && x=0
		fi
		case "$z" in
			"$2"*|Make*|Model*|Serial*|Physical*|Enabled*|Modes*|Adaptive*)
				continue;;
			Position*) echo "$z"  > $TEMPDIR/${2}.pos
				continue;;
			Transform*) echo "$z"  > $TEMPDIR/${2}.t
				continue;;
			Scale*) echo "$z"  > $TEMPDIR/${2}.s
				continue;;
		esac 
		if [ -z "$3" ]; then
			if echo $z | grep -q 'preferred, current' ; then
				echo "<item>${z/\(preferred, current\)/\*}</item>" >> $TEMPDIR/${2}.xml
				cnt=$(($cnt + $x))
			elif echo $z | grep -q 'current' ; then
				echo "<item>${z/\(current\)/\*}</item>" >> $TEMPDIR/${2}.xml
				cnt=$(($cnt + $x))
			elif echo $z | grep -q 'preferred' ; then
				echo "<item>${z/\(preferred\)/\*}</item>" >> $TEMPDIR/${2}.xml
				cnt=$(($cnt + $x))
			else
				echo "<item>$z</item>" >> $TEMPDIR/${2}.xml
				cnt=$(($cnt + $x))
			fi
		elif echo "$z" | grep -q "$3" ; then
			break
		else
			if echo $z | grep -q 'preferred, current' ; then
				echo "<item>${z/\(preferred, current\)/\*}</item>" >> $TEMPDIR/${2}.xml
				cnt=$(($cnt + $x))
			elif echo $z | grep -q 'current' ; then
				echo "<item>${z/\(current\)/\*}</item>" >> $TEMPDIR/${2}.xml
				cnt=$(($cnt + $x))
			elif echo $z | grep -q 'preferred' ; then
				echo "<item>${z/\(preferred\)/\*}</item>" >> $TEMPDIR/${2}.xml
				cnt=$(($cnt + $x))
			else
				echo "<item>$z</item>" >> $TEMPDIR/${2}.xml
				cnt=$(($cnt + $x))
			fi
		fi
	done < <(wlr-randr)
	[ "$1" = 'x' ] && sed -i "1,${cnt}d" $TEMPDIR/${2}.xml
}

# capture outputs
scr_cap() {
	grim -o $1 $TEMPDIR/${1}.png
}

# defaults from config
conf_def() {
	 grep "$1" $CFGDIR/wmon_cmd | grep -o "${2}.*" | \
		sed -e 's/ \-.*//' -e "s/^${2} //" -e 's/ \\//'
}

# combo gui
combo() {
	if [ -e "$CFGDIR/wmon_cmd" ]; then
		# current defaults
		DEF=$(conf_def $1 mode)
		DEFITEM="<item>$DEF</item>"
		DEFPOS=$(conf_def $1 pos)
		DEFPOSX=${DEFPOS%,*}
		DEFPOSY=${DEFPOS#*,}
		DEFTRANS=$(conf_def $1 transform)
		DEFSCL=$(conf_def $1 scale)
	else
		# wlr-randr defaults
		DEF=$(grep '\*' $TEMPDIR/${1}.xml | sed -e 's%<item>%%' -e 's%<\/item>%%' -e 's%\*%%')
		DEFITEM=$(grep '\*' $TEMPDIR/${1}.xml | sed -e 's%\*%%')
		DEFPOS=$(cat $TEMPDIR/${1}.pos | cut -d ' ' -f2)
		DEFPOSX=${DEFPOS%,*}
		DEFPOSY=${DEFPOS#*,}
		DEFTRANS=$(cat $TEMPDIR/${1}.t | cut -d ' ' -f2)
		DEFSCL=$(cat $TEMPDIR/${1}.s | cut -d ' ' -f2)
	fi
	
	echo -e "	<frame>
		<vbox>
			<hbox space-expand=\"true\" space-fill=\"true\" height-request=\"200\">
			<vbox>
			<pixmap>
				<width>300</width>
				<input file>$TEMPDIR/${1}.png</input>
			</pixmap>
			<text use-markup=\"true\">
				<label>\"<big>$1</big>\"</label>
			</text>
			</vbox>
			</hbox>
			<hbox space-expand=\"true\" space-fill=\"true\">
				<comboboxtext space-expand=\"true\" space-fill=\"true\" tooltip-text=\"$(gettext 'Set the resolution of') $1\">
					<default>$DEF</default>
					$DEFITEM
					$(cat $TEMPDIR/${1}.xml)
					<variable>RES${2}</variable>
				</comboboxtext>
			</hbox>
			<hbox space-expand=\"true\" space-fill=\"true\">
			<vbox>
				<frame Position X>
					<spinbutton range-min=\"0\" range-max=\"6000\" range-step=\"10\" tooltip-text=\"$(gettext 'Set the X position of') ${1}. $(gettext 'Be sure to calculate the correct position in regard to other monitors')\">
						<default>$DEFPOSX</default>
						<variable>POSX${2}</variable>
					</spinbutton>
				</frame>
				<frame Position Y>
					<spinbutton range-min=\"0\" range-max=\"3000\" range-step=\"10\" tooltip-text=\"$(gettext 'Set the Y position of') ${1}. $(gettext 'Be sure to calculate the correct position in regard to other monitors')\">
						<default>$DEFPOSY</default>
						<variable>POSY${2}</variable>
					</spinbutton>
				</frame>
			</vbox>
			<vbox>
				<frame Transform>
					<comboboxtext tooltip-text=\"$(gettext 'Set the transformation of') $1\">
						<item>$DEFTRANS</item>
						<item>normal</item>
						<item>90</item>
						<item>180</item>
						<item>270</item>
						<item>flipped</item>
						<item>flipped-90</item>
						<item>flipped-180</item>
						<item>flipped-270</item>
						<variable>TRANS${2}</variable>
					</comboboxtext>
				</frame>
				<frame Scale>
					<spinbutton range-min=\"0\" range-max=\"2\" range-step=\"0.01\" tooltip-text=\"$(gettext 'Set the scale of') $1\">
						<default>$DEFSCL</default>
						<variable>SCL${2}</variable>
					</spinbutton>
				</frame>
			</vbox>
			</hbox>
		</vbox>
	</frame>" >> $TEMPDIR/combo.xml
}

# process variables $1 screen output, $2 resoluton@freq, $3 $4 position, $5 trans, $6 scale, $7 line join
proc_vars() {
	RES0="${2/ px, /@}"
	R="${RES0/ /}"
	R="${RES0/ \*/}"
	echo "--output $1 --mode $R --pos $3,$4 --transform $5 --scale $6 $7" 
	echo -e "\t--output $1 --mode $R --pos $3,$4 --transform $5 --scale $6 $7" >>  $TEMPDIR/command
}

# trap - clean up
_trap_exit() {
	cd $CWD
	rm -rf $TEMPDIR
	echo killed
}
trap _trap_exit EXIT

#wlr-randr > $TEMPDIR/wrandr

mons || exit_error "error"
i=0
read a b c d e f <<<$MONITORS
while [ 1 ]; do
	case $i in 
		0) rnr_gui y $a $b; scr_cap $a; combo $a $i;;
		1) [ -n "$b" ] || break; rnr_gui x $b $c; scr_cap $b; combo $b $i;;
		2) [ -n "$c" ] || break; rnr_gui x $c $d; scr_cap $c; combo $c $i;;
		3) [ -n "$d" ] || break; rnr_gui x $d $e; scr_cap $d; combo $d $i;;
		4) [ -n "$e" ] || break; rnr_gui x $e $f; scr_cap $e; combo $e $i;;
		5) [ -n "$f" ] || break; rnr_gui x $f $g; scr_cap $f; combo $f $i;; # support 6 monitors ($g is empty)
	esac
	i=$((i + 1))
done

XML="$(cat $TEMPDIR/combo.xml)"

# main gui
export MAIN_GUI='<window title="Wmonitors" resizable="false">
	<vbox space-expand="true" space-fill="true">
		<hbox>
		'`/usr/lib/gtkdialog/xml_info fixed "$ICON.svg" 60 "${BACKTITLE}"`'
		</hbox>
		<hbox space-expand="true" space-fill="true" scrollable="true" hscrollbar-policy="1" vscrollbar-policy="2">
		'"$XML"'
		</hbox>
		<hbox>
			<button ok></button>
			<button cancel></button>
		</hbox>
	</vbox>
</window>'
. /usr/lib/gtkdialog/xml_info gtk #build bg_pixmap for gtk-theme
eval $(gtkdialog -p MAIN_GUI --styles=/tmp/gtkrc_xml_info.css)
case $EXIT in
	OK);;
	*)exit 0;;
esac
# process vars from MAIN_GUI
c=0
num=$(echo ${MONITORS} | wc -w)
echo 'wlr-randr \' > $TEMPDIR/command
for e in $MONITORS ; do
	[ $c -lt $((num -1)) ] && d='\' || d=''
	case $c in
		0)proc_vars $e "$RES0" $POSX0 $POSY0 $TRANS0 $SCL0 $d;;
		1)[ -z "$e" ] && break; proc_vars $e "$RES1" $POSX1 $POSY1 $TRANS1 $SCL1 $d;;
		2)[ -z "$e" ] && break; proc_vars $e "$RES2" $POSX2 $POSY2 $TRANS2 $SCL2 $d;;
		3)[ -z "$e" ] && break; proc_vars $e "$RES3" $POSX3 $POSY3 $TRANS3 $SCL3 $d;;
		4)[ -z "$e" ] && break; proc_vars $e "$RES4" $POSX4 $POSY4 $TRANS4 $SCL4 $d;;
		5)[ -z "$e" ] && break; proc_vars $e "$RES5" $POSX5 $POSY5 $TRANS5 $SCL5 $d;;
	esac
	c=$(($c + 1))
done
cp -af $TEMPDIR/command $CFGDIR/wmon_cmd || exit_error failure
# execute
. $CFGDIR/wmon_cmd
if pidof -s ROX-Filer > /dev/null; then
        /usr/lib/gtkdialog/box_yesno --yes-first "Wmonitors" "$(gettext 'For the changes to effect you must restart X... Would you like to restart X now?')"
        [ $? -eq 0 ] && restartwm
fi
