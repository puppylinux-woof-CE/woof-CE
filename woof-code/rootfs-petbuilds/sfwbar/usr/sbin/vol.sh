#!/bin/bash

type gtkdialog >/dev/null 2>&1 || exec pavucontrol

#*******************            functions           *******************#
check_exit() { # kill gui on leave-notify-event
	sleep 0.5
	for i in $(busybox ps | grep -wF HSCALE | grep -o '[1-9][0-9]*'); do 
		kill -9 $i >/dev/null 2>&1
	done
}

get_vol() { # get volume
	pactl list sinks |\
	grep -o 'Volume.*right'|grep -o '[0-9]*%.*/'|sed 's/% \///'
}

set_vol() { # set volume
	VAL=$1
	pactl -- set-sink-volume 0 ${VAL}%
	echo $VAL > /tmp/vol
}

find_color() {
	printf "%d" "0x${1}"
}

find_opacity() {
	DEC=$(printf "%d" "0x${1}")
	OP=$(dc -e "$DEC  256 2 k / p")
	echo "0${OP}"
}

export -f check_exit get_vol set_vol find_color find_opacity

#**************************     theme     *****************************#

OPT=''
CURTHEME=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
BCOL=$(grep -m1 'theme_bg_color' /usr/share/themes/$CURTHEME/gtk-3.0/gtk.css)
BCOL=${BCOL##*\ }
BCOL=${BCOL##*\#}
BCOL=${BCOL%%\;*}
BR=${BCOL:0:2}; BG=${BCOL:2:2}; BB=${BCOL:4:2};
BHR=$(find_color $BR)
BHG=$(find_color $BG)
BHB=$(find_color $BB)
BHO=0.85
# openbox border
if pidof labwc >/dev/null 2>&1 ; then
	BD=$(grep 'window.active.border.color' /usr/share/themes/$CURTHEME/openbox-3/themerc|cut -d' ' -f2)
	BR=$(grep -o '<cornerRadius>.*[0-9]' ~/.config/labwc/rc.xml | tail -c2)
else
	BD='#dddddd'
	BR=2
fi
cat > /tmp/${0##*\/}.css <<_S
window {
	background-color: rgba($BHR, $BHG, $BHB, $BHO);
	border: 1px solid $BD;
	border-radius: ${BR}px;
}
_S

#**************************     main      *****************************#

OPT="--styles=/tmp/${0##*\/}.css"
TGT="$(grep -n -m1 '\-GtkWidget-direction' $HOME/.config/sfwbar/sfwbar.config)"
TGT_LN=${TGT%%\:*}
TGT_STR="${TGT#*\ \ }"
echo $TGT_STR | grep -qo 'top' && POSITION=topright
echo $TGT_STR | grep -qo 'bottom' && POSITION=bottomright

CVOL=`get_vol`

export HSCALE='<window edge="'$POSITION'" layer="overlay">
	<hbox>
		<pixmap auto-refresh="true">
			<height>20</height>
			<input file icon="multimedia-volume-control"></input>
		</pixmap>
		<hscale width-request="375" height-request="40" \
range-min="0" range-max="150" range-step="0.5" value-pos="3" digits="2">
			<default>'$CVOL'</default>
			<variable>VOL</variable>
			<action>set_vol ${VOL%\.*}</action>
			<item>"0 |2|0"</item>
			<item>"50 |2|50"</item>
			<item>"100|2|100"</item>
			<item>"150|2|150"</item>
			<action signal="leave-notify-event">check_exit</action>
		</hscale>
	</hbox>
</window>'

gtkdialog -p HSCALE "$OPT" >/dev/null 2>&1
